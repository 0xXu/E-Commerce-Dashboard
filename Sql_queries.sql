-- ============================================================================
-- OLIST 巴西电子商务看板
-- SQL 查询：25 个业务问题
-- ============================================================================
-- 这些查询分别解答了 25 个不同的商业问题
-- 这是展现分析思维与深厚 SQL 功底的核心代码
-- ============================================================================

-- ============================================================================
-- 第一部分：收入与销售表现分析 (问题1-4)
-- ============================================================================

-- 问题1：我们的总收入是多少？近期的增长趋势如何？
SELECT 
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS monthly_revenue,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(AVG(oi.price + oi.freight_value)::NUMERIC, 2) AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY month DESC;

-- 问题2：哪些产品类目创造了最多的收入？
SELECT 
    ct.product_category_name_english AS category,
    COUNT(DISTINCT oi.order_id) AS orders,
    COUNT(oi.order_item_sequence) AS items_sold,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS revenue,
    ROUND(AVG(oi.price)::NUMERIC, 2) AS avg_price,
    ROUND((ROUND(SUM(oi.price)::NUMERIC, 2) / (SELECT ROUND(SUM(oi2.price)::NUMERIC, 2) FROM order_items oi2) * 100)::NUMERIC, 2) AS revenue_share_pct
FROM products p
JOIN category_translation ct ON p.product_category_name = ct.product_category_name
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY ct.product_category_name_english
ORDER BY revenue DESC;

-- 问题3：平台上总收入排名前 10 的核心产品是哪些？
SELECT 
    p.product_id,
    p.product_name_length,
    ct.product_category_name_english,
    COUNT(DISTINCT oi.order_id) AS times_ordered,
    SUM(oi.price) AS total_revenue,
    ROUND(AVG(oi.price)::NUMERIC, 2) AS avg_price,
    SUM(oi.freight_value) AS total_freight
FROM products p
JOIN category_translation ct ON p.product_category_name = ct.product_category_name
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name_length, ct.product_category_name_english
ORDER BY total_revenue DESC
LIMIT 10;

-- 问题4：客单价 (AOV) 处于什么水平？它是否有提升的趋势？
SELECT 
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    ROUND(AVG(oi.price + oi.freight_value)::NUMERIC, 2) AS avg_order_value,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS total_revenue
FROM orders o
JOIN order_items oi ON o.order_id = o.order_id
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY month DESC;

-- ============================================================================
-- 第二部分：产品表现深度分析 (问题5-8)
-- ============================================================================

-- 问题5：哪些产品拥有最高/最低的消费者评分？
SELECT 
    p.product_id,
    ct.product_category_name_english,
    COUNT(DISTINCT or2.review_id) AS review_count,
    ROUND(AVG(or2.review_score)::NUMERIC, 2) AS avg_rating,
    COUNT(CASE WHEN or2.review_score >= 4 THEN 1 END) AS positive_reviews,
    COUNT(CASE WHEN or2.review_score <= 2 THEN 1 END) AS negative_reviews
FROM products p
JOIN category_translation ct ON p.product_category_name = ct.product_category_name
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN order_reviews or2 ON o.order_id = or2.order_id
WHERE or2.review_id IS NOT NULL
GROUP BY p.product_id, ct.product_category_name_english
HAVING COUNT(DISTINCT or2.review_id) >= 5
ORDER BY avg_rating DESC;

-- 问题6：产品重量是否与运费成本表现出正相关关系？
SELECT 
    p.product_weight_g,
    COUNT(DISTINCT oi.order_id) AS orders,
    ROUND(AVG(oi.freight_value)::NUMERIC, 2) AS avg_freight,
    ROUND(AVG(oi.price)::NUMERIC, 2) AS avg_price
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
WHERE p.product_weight_g IS NOT NULL
GROUP BY p.product_weight_g
ORDER BY p.product_weight_g DESC
LIMIT 20;

-- 问题7：哪些类目获取了最高频次的用户评价反馈？
SELECT 
    ct.product_category_name_english,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(DISTINCT or2.review_id) AS total_reviews,
    ROUND((COUNT(DISTINCT or2.review_id)::NUMERIC / COUNT(DISTINCT oi.order_id) * 100)::NUMERIC, 2) AS review_rate_pct,
    ROUND(AVG(or2.review_score)::NUMERIC, 2) AS avg_score
FROM category_translation ct
JOIN products p ON ct.product_category_name = p.product_category_name
JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN order_reviews or2 ON o.order_id = or2.order_id
GROUP BY ct.product_category_name_english
ORDER BY review_rate_pct DESC;

-- 问题8：不同产品类目之间的投资回报率 (净利润与物流损耗的对比) 如何？
SELECT 
    ct.product_category_name_english,
    COUNT(DISTINCT oi.order_id) AS orders,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS revenue,
    ROUND(SUM(oi.freight_value)::NUMERIC, 2) AS shipping_cost,
    ROUND((SUM(oi.price) - SUM(oi.freight_value))::NUMERIC, 2) AS net_revenue,
    ROUND(AVG(or2.review_score)::NUMERIC, 2) AS avg_satisfaction
FROM category_translation ct
JOIN products p ON ct.product_category_name = p.product_category_name
JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN order_reviews or2 ON o.order_id = or2.order_id
GROUP BY ct.product_category_name_english
ORDER BY net_revenue DESC;

-- ============================================================================
-- 第三部分：物流与运营表现分析 (问题9-12)
-- ============================================================================

-- 问题9：订单能在规定时间内履约送达的比率是多少？
SELECT 
    CASE 
        WHEN o.order_delivered_customer_date IS NULL THEN 'Not Delivered'
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Late'
        ELSE 'On Time'
    END AS delivery_status,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND((COUNT(DISTINCT o.order_id)::NUMERIC / (SELECT COUNT(*) FROM orders) * 100)::NUMERIC, 2) AS pct_of_total
FROM orders o
GROUP BY delivery_status
ORDER BY order_count DESC;

-- 问题10：平台平均派送耗时为几天？这种耗时在不同州际间存在怎样的差异？
SELECT 
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(AVG(CAST((o.order_delivered_customer_date - o.order_purchase_timestamp) AS NUMERIC))::NUMERIC, 1) AS avg_delivery_days,
    MIN(CAST((o.order_delivered_customer_date - o.order_purchase_timestamp) AS NUMERIC)) AS min_days,
    MAX(CAST((o.order_delivered_customer_date - o.order_purchase_timestamp) AS NUMERIC)) AS max_days
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC;

-- 问题11：延期送达的包裹是否会导致大量差评？
SELECT 
    CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Late'
        ELSE 'On Time'
    END AS delivery_performance,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(AVG(or2.review_score)::NUMERIC, 2) AS avg_review_score,
    COUNT(CASE WHEN or2.review_score >= 4 THEN 1 END) AS positive_reviews,
    COUNT(CASE WHEN or2.review_score <= 2 THEN 1 END) AS negative_reviews
FROM orders o
LEFT JOIN order_reviews or2 ON o.order_id = or2.order_id
WHERE or2.review_score IS NOT NULL AND o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery_performance
ORDER BY avg_review_score DESC;

-- 问题12：用户对平台整体的满意度是否在呈现缓慢上升的态势？
SELECT 
    DATE_TRUNC('month', or2.review_creation_date) AS month,
    COUNT(DISTINCT or2.review_id) AS review_count,
    ROUND(AVG(or2.review_score)::NUMERIC, 2) AS avg_score,
    COUNT(CASE WHEN or2.review_score >= 4 THEN 1 END) AS positive_reviews,
    COUNT(CASE WHEN or2.review_score <= 2 THEN 1 END) AS negative_reviews
FROM order_reviews or2
GROUP BY DATE_TRUNC('month', or2.review_creation_date)
ORDER BY month DESC;

-- ============================================================================
-- 第四部分：消费者行为洞察分析 (问题13-17)
-- ============================================================================

-- 问题13：平台的拉新与获客趋势情况表现如何？
SELECT 
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    COUNT(DISTINCT o.customer_id) AS new_customers_ordering,
    COUNT(DISTINCT o.order_id) AS orders
FROM orders o
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY month DESC;

-- 问题14：哪些城市和州能够为我们带来绝大部分的营业额？
SELECT 
    c.customer_state,
    c.customer_city,
    COUNT(DISTINCT c.customer_id) AS customers,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS revenue,
    ROUND(AVG(oi.price + oi.freight_value)::NUMERIC, 2) AS avg_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_state, c.customer_city
ORDER BY revenue DESC
LIMIT 20;

-- 问题15：什么才是客户终身价值 (CLV)？如何找出我们的高净值 VIP 客户群体？
SELECT 
    c.customer_id,
    c.customer_city,
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS lifetime_orders,
    ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS total_spent,
    ROUND(AVG(oi.price + oi.freight_value)::NUMERIC, 2) AS avg_order_value,
    MIN(DATE(o.order_purchase_timestamp)) AS first_order_date,
    MAX(DATE(o.order_purchase_timestamp)) AS last_order_date,
    CAST((MAX(DATE(o.order_purchase_timestamp)) - MIN(DATE(o.order_purchase_timestamp))) AS INT) AS customer_age_days,
    ROUND(AVG(or2.review_score)::NUMERIC, 2) AS avg_review_score
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN order_reviews or2 ON o.order_id = or2.order_id
GROUP BY c.customer_id, c.customer_city, c.customer_state
ORDER BY total_spent DESC
LIMIT 100;

-- 问题16：消费群体中有多少比例会产生复购行为？
WITH customer_order_counts AS (
    SELECT 
        c.customer_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id
)
SELECT 
    CASE 
        WHEN order_count = 1 THEN 'One-time Buyer'
        WHEN order_count BETWEEN 2 AND 3 THEN '2-3 Orders'
        WHEN order_count BETWEEN 4 AND 5 THEN '4-5 Orders'
        ELSE '6+ Orders'
    END AS customer_segment,
    COUNT(*) AS customer_count,
    ROUND((COUNT(*)::NUMERIC / (SELECT COUNT(*) FROM customer_order_counts) * 100)::NUMERIC, 2) AS pct_of_customers
FROM customer_order_counts
GROUP BY customer_segment
ORDER BY customer_count DESC;

-- 问题17：客户体量的纯地理区位分布特征探讨（配合地图渲染使用）
SELECT 
    c.customer_state,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS total_revenue,
    ROUND(AVG(oi.price + oi.freight_value)::NUMERIC, 2) AS avg_order_value
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_state
ORDER BY total_revenue DESC;

-- ============================================================================
-- 第五部分：卖家及商户端表现分析 (问题18-20)
-- ============================================================================

-- 问题18：哪部分头部商户占据着流量和营收的半壁江山？
SELECT 
    s.seller_id,
    s.seller_state,
    s.seller_city,
    COUNT(DISTINCT oi.order_id) AS orders,
    SUM(oi.order_item_sequence) AS items_sold,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS revenue,
    ROUND(AVG(oi.price)::NUMERIC, 2) AS avg_item_price,
    ROUND(AVG(or2.review_score)::NUMERIC, 2) AS avg_rating,
    COUNT(DISTINCT or2.review_id) AS total_reviews
FROM sellers s
JOIN order_items oi ON s.seller_id = oi.seller_id
LEFT JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN order_reviews or2 ON o.order_id = or2.order_id
GROUP BY s.seller_id, s.seller_state, s.seller_city
ORDER BY revenue DESC
LIMIT 20;

-- 问题19：是否存在某些发达州的地方商团能在同级商战中获得巨大优势？
SELECT 
    s.seller_state,
    COUNT(DISTINCT s.seller_id) AS seller_count,
    COUNT(DISTINCT oi.order_id) AS orders,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS total_revenue,
    ROUND(AVG(oi.price)::NUMERIC, 2) AS avg_price,
    ROUND(AVG(or2.review_score)::NUMERIC, 2) AS avg_rating
FROM sellers s
JOIN order_items oi ON s.seller_id = oi.seller_id
LEFT JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN order_reviews or2 ON o.order_id = or2.order_id
GROUP BY s.seller_state
ORDER BY total_revenue DESC;

-- 问题20：SKU（多产品线）非常丰富的老板是否注定能取得更高的流水？
SELECT 
    s.seller_id,
    COUNT(DISTINCT oi.product_id) AS unique_products,
    COUNT(DISTINCT oi.order_id) AS orders,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS revenue,
    ROUND(AVG(or2.review_score)::NUMERIC, 2) AS avg_rating
FROM sellers s
JOIN order_items oi ON s.seller_id = oi.seller_id
LEFT JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN order_reviews or2 ON o.order_id = or2.order_id
GROUP BY s.seller_id
ORDER BY unique_products DESC
LIMIT 20;

-- ============================================================================
-- 第六部分：支付金融链路分析 (问题21-22)
-- ============================================================================

-- 问题21：消费者普遍采用何种支付手段完成支付清算？
SELECT 
    op.payment_type,
    COUNT(DISTINCT op.order_id) AS orders,
    ROUND(SUM(op.payment_value)::NUMERIC, 2) AS total_value,
    ROUND(AVG(op.payment_value)::NUMERIC, 2) AS avg_payment,
    ROUND((COUNT(DISTINCT op.order_id)::NUMERIC / (SELECT COUNT(DISTINCT order_id) FROM order_payments) * 100)::NUMERIC, 2) AS pct_of_orders
FROM order_payments op
GROUP BY op.payment_type
ORDER BY orders DESC;

-- 问题22：客户使用的分期策略与他本身的大额订单是否有因果关联？
SELECT 
    op.payment_installments,
    COUNT(DISTINCT op.order_id) AS orders,
    ROUND(AVG(op.payment_value)::NUMERIC, 2) AS avg_order_value,
    ROUND(SUM(op.payment_value)::NUMERIC, 2) AS total_value,
    ROUND(AVG(or2.review_score)::NUMERIC, 2) AS avg_review_score
FROM order_payments op
LEFT JOIN orders o ON op.order_id = o.order_id
LEFT JOIN order_reviews or2 ON o.order_id = or2.order_id
GROUP BY op.payment_installments
ORDER BY payment_installments ASC;

-- ============================================================================
-- 第七部分：售后服务与满意度分析 (问题23-25)
-- ============================================================================

-- 问题23：我们平台的总体声誉度/打分配比的健康程度如何测算？
SELECT 
    COUNT(DISTINCT or2.review_id) AS total_reviews,
    ROUND(AVG(or2.review_score)::NUMERIC, 2) AS avg_score,
    COUNT(CASE WHEN or2.review_score = 5 THEN 1 END) AS five_star,
    COUNT(CASE WHEN or2.review_score = 4 THEN 1 END) AS four_star,
    COUNT(CASE WHEN or2.review_score = 3 THEN 1 END) AS three_star,
    COUNT(CASE WHEN or2.review_score = 2 THEN 1 END) AS two_star,
    COUNT(CASE WHEN or2.review_score = 1 THEN 1 END) AS one_star
FROM order_reviews or2;

-- 问题24：哪些粗制滥造的类目正在疯狂败坏我们的核心口碑？
SELECT 
    ct.product_category_name_english,
    COUNT(DISTINCT or2.review_id) AS review_count,
    ROUND(AVG(or2.review_score)::NUMERIC, 2) AS avg_rating,
    COUNT(CASE WHEN or2.review_score >= 4 THEN 1 END) AS positive_reviews_pct,
    COUNT(CASE WHEN or2.review_score <= 2 THEN 1 END) AS negative_reviews_pct
FROM order_reviews or2
LEFT JOIN orders o ON or2.order_id = o.order_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
WHERE or2.review_score IS NOT NULL
GROUP BY ct.product_category_name_english
ORDER BY avg_rating ASC;

-- 问题25：极端高昂的客运流通费用 (邮费飙升) 是否会显著引发差评如潮？
SELECT 
    ROUND(oi.freight_value, -1)::INT AS freight_bucket,
    COUNT(DISTINCT oi.order_id) AS orders,
    ROUND(AVG(or2.review_score)::NUMERIC, 2) AS avg_score,
    ROUND(AVG(oi.price)::NUMERIC, 2) AS avg_item_price
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN order_reviews or2 ON o.order_id = or2.order_id
WHERE oi.freight_value > 0
GROUP BY ROUND(oi.freight_value, -1)
ORDER BY freight_bucket ASC;

-- ============================================================================
-- 所有的 25 个商业问题在此解答完毕
-- ============================================================================
-- ============================================================================
-- OLIST 巴西电子商务看板
-- SQL 查询：25 个业务问题分析
-- ============================================================================
-- 以下查询语句用于解答涵盖核心运营场景的 25 个商业问题
-- 这是展现数据分析能力与 SQL 结构化查询设计的核心逻辑库
-- ============================================================================

-- ============================================================================
-- 第一部分：收入与销售表现分析 (问题1-4)
-- ============================================================================

-- 问题1：平台的总收入是多少？近期的增长趋势如何？
SELECT 
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS monthly_revenue,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(AVG(oi.price + oi.freight_value)::NUMERIC, 2) AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY month DESC;

-- 问题2：哪些产品类目创造了最多的总收入？
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

-- 问题3：平台上总收入排名前 10 的核心单品指标分析
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

-- 问题4：客单价 (AOV) 处于什么水平？月度客单价是否具备提升的趋势？
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

-- 问题5：哪些产品款式拥有极高（满分区间）和极低的消费者口碑评分？
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

-- 问题6：产品的物理重量参数是否与加收的运费成本表现出直接的正相关性？
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

-- 问题7：哪些类目获取了最高频次的用户评价反馈率（反馈渗透率排序）？
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

-- 问题8：不同产品类目之间的投资净回报能力 (综合考量净利润与随单物流损耗的对比) 分析
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

-- 问题9：全盘订单能在系统承诺规定时间内准点履约签收的比率考量
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

-- 问题10：统计包裹平均派送流转时间周期以及基于地理州际间的时效差异表现
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

-- 问题11：延期送达服务降级是否直接引发并导致大量产生产品服务方面的1-2星差评？
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

-- 问题12：用户对本电商平台端到端服务整体的满意度是否随运营周期呈现增长趋势？
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

-- 问题13：平台的月度拉新表现及新客下单获客量级走势一览
SELECT 
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    COUNT(DISTINCT o.customer_id) AS new_customers_ordering,
    COUNT(DISTINCT o.order_id) AS orders
FROM orders o
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY month DESC;

-- 问题14：哪些核心城市集群和州版块能够为平台贡献绝对主力的消费额度？
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

-- 问题15：全案量测算客户终身价值 (CLV)，挖掘并提取高净值忠诚 VIP 客群清单
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

-- 问题16：历史全量消费群体群覆盖面中，复购行为占比率呈现何种漏斗转化？
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

-- 问题17：客户规模容量的基础地理坐标分布分析（配合构建 Power BI 地图展现渲染使用）
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

-- 问题18：分析头部商家（Top Sellers）梯队个体对平台整体销售流量和累积营收的掌控度
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

-- 问题19：是否存在某些经济大州的入驻商户群在同级商战中展现出绝对的营收总盘统治力？
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

-- 问题20：商家的供货丰富度（多态 SKU 开发度）与其平台累加营收之间是否存在因果关联？
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

-- 问题21：消费者群体在平台结清财务的工具选取及各个偏好占比结构明细
SELECT 
    op.payment_type,
    COUNT(DISTINCT op.order_id) AS orders,
    ROUND(SUM(op.payment_value)::NUMERIC, 2) AS total_value,
    ROUND(AVG(op.payment_value)::NUMERIC, 2) AS avg_payment,
    ROUND((COUNT(DISTINCT op.order_id)::NUMERIC / (SELECT COUNT(DISTINCT order_id) FROM order_payments) * 100)::NUMERIC, 2) AS pct_of_orders
FROM order_payments op
GROUP BY op.payment_type
ORDER BY orders DESC;

-- 问题22：对用户使用信用卡分期账单策略的依赖度与其大额客单交易意愿的因果关系审查
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

-- 问题23：我们平台大体量订单下的用户满意度的总体声誉矩阵健康程度如何构成算比？
SELECT 
    COUNT(DISTINCT or2.review_id) AS total_reviews,
    ROUND(AVG(or2.review_score)::NUMERIC, 2) AS avg_score,
    COUNT(CASE WHEN or2.review_score = 5 THEN 1 END) AS five_star,
    COUNT(CASE WHEN or2.review_score = 4 THEN 1 END) AS four_star,
    COUNT(CASE WHEN or2.review_score = 3 THEN 1 END) AS three_star,
    COUNT(CASE WHEN or2.review_score = 2 THEN 1 END) AS two_star,
    COUNT(CASE WHEN or2.review_score = 1 THEN 1 END) AS one_star
FROM order_reviews or2;

-- 问题24：识别并筛选出差评投诉率较高、从而严重影响大盘满意度声望的预警危险产品类目
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

-- 问题25：超出合理认知期望边界的高昂运费是否会激化用户对货品产生负向评级行为？
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
-- 业务问题数据诊断提取完毕结束
-- ============================================================================
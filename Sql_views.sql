-- ============================================================================
-- OLIST 巴西电子商务数据分析看板
-- 专为 Power BI 数据接入设计处理的 SQL 聚合视图构建文件
-- 基于物理表提炼生成 8 个生产级别的核心多维分析视图 (Views)
-- ============================================================================

-- 视图 1：多维产品商品表现视图 (Product Performance)
-- 目的：聚合基于单一产品(SKU)角度维度的关键商业指标(KPI), 并串联呈现相应的销量金额及客户口碑满意度评分。
CREATE VIEW v_product_performance AS
SELECT 
    p.product_id,
    p.product_category_name,
    ct.product_category_name_english AS category_english,
    p.product_name_length,
    p.product_weight_g,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(DISTINCT oi.order_item_sequence) AS total_items_sold,
    ROUND(AVG(oi.price)::NUMERIC, 2) AS avg_price,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS total_revenue,
    ROUND(SUM(oi.freight_value)::NUMERIC, 2) AS total_freight_cost,
    ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS total_gross_revenue,
    ROUND(AVG(or2.review_score)::NUMERIC, 2) AS avg_review_score,
    COUNT(DISTINCT or2.review_id) AS total_reviews,
    ROUND((COUNT(DISTINCT or2.review_id)::NUMERIC / NULLIF(COUNT(DISTINCT oi.order_id), 0) * 100)::NUMERIC, 2) AS review_rate_pct
FROM products p
LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN order_reviews or2 ON o.order_id = or2.order_id
GROUP BY p.product_id, p.product_category_name, ct.product_category_name_english, 
         p.product_name_length, p.product_weight_g
ORDER BY total_revenue DESC;

-- ============================================================================

-- 视图 2：产品类目宏观表现视图 (Category Performance)
-- 目的：提炼产品类目标签下的合并聚合数据特征簇，涵盖类别流水收益、利润净率与对应的消费者总池满意度预期。
CREATE VIEW v_category_performance AS
SELECT 
    ct.product_category_name_english AS category,
    COUNT(DISTINCT p.product_id) AS product_count,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(DISTINCT oi.order_item_sequence) AS total_items_sold,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS total_revenue,
    ROUND(SUM(oi.freight_value)::NUMERIC, 2) AS total_freight,
    ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS total_gross_revenue,
    ROUND(AVG(oi.price)::NUMERIC, 2) AS avg_item_price,
    ROUND(AVG(or2.review_score)::NUMERIC, 2) AS avg_review_score,
    ROUND((COUNT(DISTINCT or2.review_id)::NUMERIC / NULLIF(COUNT(DISTINCT oi.order_id), 0) * 100)::NUMERIC, 2) AS review_rate_pct
FROM category_translation ct
LEFT JOIN products p ON ct.product_category_name = p.product_category_name
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN order_reviews or2 ON o.order_id = or2.order_id
GROUP BY ct.product_category_name_english
ORDER BY total_revenue DESC;

-- ============================================================================

-- 视图 3：全平台每日销售业绩趋势大观 (Daily Sales Trends)
-- 目的：按照时间截面（日度精度）抽取转化产生的资金流入量序列表，适用于前端的各类随时间推移的曲线表现和年/月份拆分解读。
CREATE VIEW v_daily_sales AS
SELECT 
    DATE(o.order_purchase_timestamp) AS order_date,
    EXTRACT(YEAR FROM o.order_purchase_timestamp) AS order_year,
    EXTRACT(MONTH FROM o.order_purchase_timestamp) AS order_month,
    TO_CHAR(o.order_purchase_timestamp, 'Mon') AS month_name,
    EXTRACT(QUARTER FROM o.order_purchase_timestamp) AS order_quarter,
    TO_CHAR(o.order_purchase_timestamp, 'Day') AS day_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT oi.order_item_sequence) AS total_items,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS total_revenue,
    ROUND(SUM(oi.freight_value)::NUMERIC, 2) AS total_freight,
    ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS total_gross_revenue,
    ROUND(AVG(oi.price)::NUMERIC, 2) AS avg_item_price,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    COUNT(DISTINCT op.payment_type) AS payment_methods_used
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN order_payments op ON o.order_id = op.order_id
GROUP BY DATE(o.order_purchase_timestamp)
ORDER BY order_date DESC;

-- ============================================================================

-- 视图 4：终端订单物流履约效能管理 (Order Delivery Analysis)
-- 目的：梳理记录核心物流体系配送状态节点追踪系统，负责精准捕捉出包裹实单流产延时率特征及交货长周期天数。
CREATE VIEW v_order_delivery AS
SELECT 
    o.order_id,
    o.customer_id,
    DATE(o.order_purchase_timestamp) AS order_date,
    o.order_status,
    DATE(o.order_delivered_customer_date) AS delivery_date,
    CAST((o.order_delivered_customer_date::DATE - o.order_purchase_timestamp::DATE) AS INT) AS delivery_days,
    CAST((o.order_estimated_delivery_date::DATE - o.order_delivered_customer_date::DATE) AS INT) AS delivery_variance_days,
    CASE 
        WHEN o.order_delivered_customer_date IS NULL THEN 'Not Delivered'
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Late'
        ELSE 'On Time'
    END AS delivery_status,
    ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS order_total,
    COUNT(oi.order_item_sequence) AS items_in_order,
    or2.review_score
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN order_reviews or2 ON o.order_id = or2.order_id
GROUP BY o.order_id, o.customer_id, o.order_purchase_timestamp, o.order_status, 
         o.order_delivered_customer_date, o.order_estimated_delivery_date, or2.review_score
ORDER BY order_date DESC;

-- ============================================================================

-- 视图 5：商户终端(第三方卖家)经营业绩纵览 (Seller Performance)
-- 目的：汇总计算各第三方商户机构在系统网络内吸资获取及分发生意总流水的实力及他们随之对应的整体可托付好评层级。
CREATE VIEW v_seller_performance AS
SELECT 
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(DISTINCT oi.order_item_sequence) AS total_items_sold,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS total_revenue,
    ROUND(SUM(oi.freight_value)::NUMERIC, 2) AS total_freight,
    ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS total_gross_revenue,
    ROUND(AVG(oi.price)::NUMERIC, 2) AS avg_item_price,
    ROUND(AVG(or2.review_score)::NUMERIC, 2) AS avg_review_score,
    COUNT(DISTINCT or2.review_id) AS total_reviews,
    ROUND((CAST(SUM(CASE WHEN or2.review_score >= 4 THEN 1 ELSE 0 END) AS NUMERIC) 
           / NULLIF(COUNT(DISTINCT or2.review_id), 0) * 100)::NUMERIC, 2) AS positive_review_pct
FROM sellers s
LEFT JOIN order_items oi ON s.seller_id = oi.seller_id
LEFT JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN order_reviews or2 ON o.order_id = or2.order_id
GROUP BY s.seller_id, s.seller_city, s.seller_state
ORDER BY total_revenue DESC;

-- ============================================================================

-- 视图 6：客户群体粘度及终身价值量度 (Customer Behavior & Lifetime Value)
-- 目的：通过抽调各唯一客户在所有业务记录上的重复出没及支出记录，建立客户分层、留存归因与客户终身价值量尺(CLV)。
CREATE VIEW v_customer_behavior AS
SELECT 
    c.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS total_spent,
    ROUND(AVG(oi.price + oi.freight_value)::NUMERIC, 2) AS avg_order_value,
    MIN(DATE(o.order_purchase_timestamp)) AS first_order_date,
    MAX(DATE(o.order_purchase_timestamp)) AS last_order_date,
    CAST((MAX(DATE(o.order_purchase_timestamp)) - MIN(DATE(o.order_purchase_timestamp))) AS INT) AS customer_lifetime_days,
    ROUND(AVG(or2.review_score)::NUMERIC, 2) AS avg_review_score,
    COUNT(DISTINCT or2.review_id) AS total_reviews
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN order_reviews or2 ON o.order_id = or2.order_id
GROUP BY c.customer_id, c.customer_unique_id, c.customer_city, c.customer_state
ORDER BY total_spent DESC;

-- ============================================================================

-- 视图 7：客户评价及售后满意度跟踪分析总表 (Review & Satisfaction Analysis)
-- 目的：从海量客户星级评价记录源中挖掘对售后评价随季度和月份发展的满意度大盘波动跟踪表现。
CREATE VIEW v_review_analysis AS
SELECT 
    DATE(or2.review_creation_date) AS review_date,
    EXTRACT(MONTH FROM or2.review_creation_date) AS review_month,
    EXTRACT(YEAR FROM or2.review_creation_date) AS review_year,
    or2.review_score,
    COUNT(DISTINCT or2.review_id) AS review_count,
    COUNT(DISTINCT CASE WHEN or2.review_comment_message IS NOT NULL THEN or2.review_id END) AS comments_count,
    ROUND(AVG(or2.review_score)::NUMERIC, 2) AS avg_score
FROM order_reviews or2
GROUP BY DATE(or2.review_creation_date), review_month, review_year, or2.review_score
ORDER BY review_date DESC;

-- ============================================================================

-- 视图 8：用户金融账户支付类型及分期习惯剖析表 (Payment Method Analysis)
-- 目的：深入审视各类型付款渠道对产生销售结流的普及影响面，并洞察包含信贷分期机制所催生对应的高客货订单数据。
CREATE VIEW v_payment_analysis AS
SELECT 
    op.payment_type,
    COUNT(DISTINCT op.order_id) AS total_orders,
    ROUND(SUM(op.payment_value)::NUMERIC, 2) AS total_payment_value,
    ROUND(AVG(op.payment_value)::NUMERIC, 2) AS avg_payment_value,
    ROUND(AVG(op.payment_installments)::NUMERIC, 2) AS avg_installments,
    ROUND((COUNT(DISTINCT op.order_id)::NUMERIC / (SELECT COUNT(DISTINCT order_id) FROM order_payments) * 100)::NUMERIC, 2) AS payment_type_pct
FROM order_payments op
GROUP BY op.payment_type
ORDER BY total_orders DESC;

-- ============================================================================
-- 系统全部分析视图构建定义完成
-- 确认操作及查验执行语句支持：
-- 执行：SELECT * FROM information_schema.views WHERE table_schema = 'public';
-- ============================================================================
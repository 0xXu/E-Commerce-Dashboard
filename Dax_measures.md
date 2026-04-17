# Olist 看板 - DAX 度量值功能手册

本文档详尽列出了本项目 Power BI 应用数据建模中所运用的核心 DAX (Data Analysis Expressions) 聚合度量值。度量值已被分类，以反映其所属的具体商业分析应用场景。

## 目录
1. [营业收入指标 (Revenue Metrics)](#revenue)
2. [客户与单量指标 (Order & Customer Metrics)](#orders-customers)
3. [产品综合指标 (Product Metrics)](#products)
4. [物流履约情况指标 (Delivery & Fulfillment)](#delivery)
5. [客户满意度评估 (Review & Satisfaction)](#satisfaction)
6. [供应商与卖家管理 (Seller Performance)](#sellers)
7. [消费者金融分期分析 (Payment & Installments)](#payments)
8. [同环比及智能时间逻辑 (Time Intelligence)](#time-intelligence)

---

## 1. 营业收入指标 {#revenue}

### 营业总收入 (Total Revenue)
```dax
Total Revenue = SUM(v_daily_sales[total_revenue])
```
**业务含义：** 平台在指定统计维度内的合计全部收入流入（包含商品零售进价与配套发生的承运人加收运费）。

### 净商品流水 (Total Net Revenue)
```dax
Total Net Revenue = SUM(v_daily_sales[total_revenue]) - SUM(v_daily_sales[total_freight])
```
**业务含义：** 扣除承办运货等必要物流折耗后单独核算的有效实物商品产出的净账款额。

### 合计承运交付成本 (Total Freight Cost)
```dax
Total Freight Cost = SUM(v_daily_sales[total_freight])
```
**业务含义：** 统计客户支出的包裹物流等配送成本累计金额。

### 物流成本在营收中的相对比控分析 (Freight as % of Revenue)
```dax
Freight % of Revenue = DIVIDE([Total Freight Cost], [Total Revenue], 0) * 100
```
**业务含义：** 反映和监控物流及调度资金成本侵蚀总体营业额的风险比重，可用于指导制定满减与包邮免单促销战略测算依据。

### 货物单位平均获利期望 (Revenue per Item)
```dax
Revenue per Item = DIVIDE([Total Revenue], SUM(v_daily_sales[total_items]), 0)
```
**业务含义：** 单个卖出的独立计量库存单位可带来的平均流水进项。

---

## 2. 客户与单量指标 {#orders-customers}

### 总转化提单量 (Total Orders)
```dax
Total Orders = DISTINCTCOUNT(v_daily_sales[total_orders])
```
**业务含义：** 记录独立不重复的付款结算发单总笔数量。

### 综合出货配件总计 (Total Items Sold)
```dax
Total Items Sold = SUM(v_daily_sales[total_items])
```
**业务含义：** 多项子订单累积的零售出货打包件数散数汇总。

### 全局平滑客单价均值 (Avg Order Value - AOV)
```dax
Avg Order Value = DIVIDE([Total Revenue], [Total Orders], 0)
```
**业务含义：** 统计平均每一次用户落定单笔时所生成的贡献收入指标。

### 活跃独立用户总数 (Total Customers)
```dax
Total Customers = DISTINCTCOUNT(v_customer_behavior[customer_id])
```
**业务含义：** 基于唯一ID过滤查重后最终识别出覆盖及影响过的总触达且付款落地真实消费者人头基数。

### 客户终身单客产出价值 (Customer Lifetime Value - CLV)
```dax
Customer Lifetime Value = 
DIVIDE(
    SUMX(VALUES(v_customer_behavior[customer_id]), [Total Revenue]),
    [Total Customers], 0
)
```
**业务含义：** 平均预估从生命开始入池后直至其留存在平台全周期结束阶段合计带给大盘公司的单入账。

### 全盘复购留存转换比重 (Repeat Customer Rate %)
```dax
Repeat Customer Rate % = 
DIVIDE(
    CALCULATE(DISTINCTCOUNT(v_customer_behavior[customer_id]), FILTER(v_customer_behavior, v_customer_behavior[total_orders] > 1)),
    [Total Customers], 0
) * 100
```
**业务含义：** 全球客群体内能够形成第二次重归光顾以上高频粘性回头用户的总体保有分层占比。

---

## 3. 产品综合指标 {#products}

### 总活跃供应款式种类 (Total Products)
```dax
Total Products = DISTINCTCOUNT(v_product_performance[product_id])
```
**业务含义：** 可见在售的独立挂架商品不同品类的款数。

### 高评价标杆优质产品甄选数量 (High-Rated Products)
```dax
High-Rated Products = CALCULATE(DISTINCTCOUNT(v_product_performance[product_id]), FILTER(v_product_performance, v_product_performance[avg_review_score] >= 4))
```
**业务含义：** 得分评价严格稳定维持大于或等于优质 4 星标准以上的强势优质引流商品的SKU保有选量。

### 低劣待优化/下架清退预警品控数 (Low-Rated Products)
```dax
Low-Rated Products = CALCULATE(DISTINCTCOUNT(v_product_performance[product_id]), FILTER(v_product_performance, v_product_performance[avg_review_score] < 3))
```
**业务含义：** 产品长期口碑失衡（降级低至劣质 2 星及以下恶劣分层）且严重引发后端售后投诉隐患的预警货品质控集合。

---

## 4. 物流履约情况指标 {#delivery}

### 成功并确实完成最终核销签收量的有效单量 (Total Orders Delivered)
```dax
Total Orders Delivered = CALCULATE(DISTINCTCOUNT(v_order_delivery[order_id]), FILTER(v_order_delivery, v_order_delivery[delivery_status] <> "Not Delivered"))
```
**业务含义：** 系统回签已实质派发落实抵达顾客手中的完整有效配送服务凭证总量计数。

### 按时安全投递达标合规单次基数 (On-Time Orders)
```dax
On-Time Orders = CALCULATE(DISTINCTCOUNT(v_order_delivery[order_id]), FILTER(v_order_delivery, v_order_delivery[delivery_status] = "On Time"))
```
**业务含义：** 未发生超时迟延事件，均在客户购买时系统承诺约定预期前安全闭环交接完成的卓越执行纪录大盘量。

### 全程优质履约无晚滞投期合格率 (On-Time Delivery %)
```dax
On-Time Delivery % = DIVIDE([On-Time Orders], [Total Orders Delivered], 0) * 100
```
**业务含义：** 评估监控公司承办物流第三方供应链运转可靠性效能和管控安全力核心重要KPI风标。

### 违约晚送造成恶性体验及客服补偿危机迟滞率 (Late Delivery %)
```dax
Late Delivery % = DIVIDE([Late Orders], [Total Orders Delivered], 0) * 100
```
**业务含义：** 因第三方物流调度慢、拥堵所造成交付迟于规定承诺时间的严重运效故障统计百分数。

### 周转流通总长周期时效期望值 (Avg Delivery Days)
```dax
Avg Delivery Days = AVERAGE(v_order_delivery[delivery_days])
```
**业务含义：** 消费者生成意向直至彻底收到包裹开箱耗去的实际跨日天数宏观预期平均天数值标尺（通常用以界定本企业的仓干配周转标基准时限长段）。

---

## 5. 客户满意度评估 {#satisfaction}

### 总体均分体验加权的平台大满意值线标杆 (Avg Review Score)
```dax
Avg Review Score = AVERAGE(v_review_analysis[avg_score])
```
**业务含义：** 根据总数据库评价矩阵做绝对算术均等分化之后的大盘声誉值参考表现，用于公司制定公关风评分数阈值的安全水位。

### 提供售后与舆情分析留存总反馈表样卷宗数量 (Total Reviews)
```dax
Total Reviews = DISTINCTCOUNT(v_review_analysis[review_id])
```
**业务含义：** 用户端发起主动作文反馈以及打分的口碑发文体量的基础样板数据源的丰富程度基数。

### 具备五星绝对信任度优质褒评体量占比重 (5-Star Reviews %)
```dax
5-Star Reviews % = DIVIDE([5-Star Reviews], [Total Reviews], 0) * 100
```
**业务含义：** 代表了在全网意见池子中可引发品牌力护城河绝对忠诚度和向其他群体裂变能力的高价值正面宣发的强度。

### 低劣差评恶性意见负面覆盖范围侵占影响率 (Negative Reviews %)
```dax
Negative Reviews % = DIVIDE([Negative Reviews], [Total Reviews], 0) * 100
```
**业务含义：** 全品类收到的1星与2星不适感抗议表决占据池的浓重性成分测量度。

---

## 6. 供应商与卖家管理 {#sellers}

### 活跃在驻承保卖家库容底仓池 (Total Sellers)
```dax
Total Sellers = DISTINCTCOUNT(v_seller_performance[seller_id])
```
**业务含义：** 能常态化在前端支撑交易业务流水进行正常开展运转的背后中微小型企业主或者代理分销供销体系老板机构独立户数。

### 分析特定个体供主获取口碑信任健康稳定评级 (Avg Seller Rating)
```dax
Avg Seller Rating = AVERAGE(v_seller_performance[avg_review_score])
```
**业务含义：** 用于评定一个或某一类别提供商品销售供应业务合作方的历史诚信和其履约质量优渥等级底分。

---

## 7. 消费者金融分期分析 {#payments}

### 采用信用卡支付类工具覆盖结算比例渗透深度 (Credit Card Orders %)
```dax
Credit Card Orders % = DIVIDE([Credit Card Orders], SUM(v_payment_analysis[total_orders]), 0) * 100
```
**业务含义：** 使用金融挂账户或大放贷信贷支付（含各类联名通存金账信用卡刷支项业务类型）形式成交的市场接受份额量级。

### 基于透支性资金实施的大促期单次付款大标配分期比重期望 (Orders with Installments)
```dax
Orders with Installments = CALCULATE(SUM(v_payment_analysis[total_orders]), FILTER(v_payment_analysis, v_payment_analysis[payment_type] = "credit_card" && v_payment_analysis[avg_installments] > 1))
```
**业务含义：** 对于在资金支出上显露匮乏并主动寻求缓冲采取主动提出分多期账面去执行消化的大盘结款总量，有助于辅助预测潜在金融不良断供账呆滞风险规模。

---

## 8. 同环比及智能时间逻辑 {#time-intelligence}

### MTD 单月内自溯累进叠加追账法线总营 (Revenue MTD)
```dax
Revenue MTD = CALCULATE([Total Revenue], DATESMTD(v_daily_sales[order_date]))
```
**业务含义：** 表示在目前所锚定或者正在推演中的时间周期刻度标内，仅就某一日历单月尺度中随着交易每一日向后递进而发生逐渐累计叠加入库结算归档总财报走势的汇总账面数。(Month-To-Date)

### YTD 全年终考考核段大期自清零迄今进项流水长跑计分走步式追踪榜 (Revenue YTD)
```dax
Revenue YTD = CALCULATE([Total Revenue], DATESYTD(v_daily_sales[order_date]))
```
**业务含义：** 代表以年审、审计度结报为一个循环节点单位。反映一个纪元初起到结算当令时刻点的全息累计收盘总进款额度值基数。有助于追踪公司能否达到其原定的预设全年业绩最终预期天际线。(Year-To-Date)

### YoY 去年同周期间距绝对参考标尺对向增进涨跌位差强行锚比 (YoY Growth %)
```dax
YoY Growth % = IFERROR(DIVIDE(([Total Revenue] - [Revenue Last Year]), [Revenue Last Year], 0) * 100, 0)
```
**业务含义：** 将正在查究计算的主核业务数据直接抛入时空缝隙回置于一年前同一历史绝对区间坐标切线上发生相互比价对搏，能清晰算出摆脱周期律衰减大自然波动下实际本质上增长还是收缩衰退的变迁幅标化值。

---

## 其他模型优化与维护建议

- 应对计算逻辑除数为零可能导致的致命空载级联计算层叠崩溃： 业务数据表不可避免包含 `0` (例如包邮带来的 `$0` 或者在个别不常用无使用案例过滤断层里为零的值等)，此时应用并包装 `DIVIDE` 操作或是包裹添加强外壁盾级保护性过滤逻辑函数 `IFERROR()` 处理是最佳防御配置选择。
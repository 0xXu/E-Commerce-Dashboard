# Olist 数据库模型 - 数据字典

## 目录
1. [Customers (客户维度表)](#customers)
2. [Sellers (卖家维度表)](#sellers)
3. [Products (产品维度表)](#products)
4. [Category Translation (品类语言翻译表)](#category_translation)
5. [Orders (订单事实表)](#orders)
6. [Order Items (订单明细事实表)](#order_items)
7. [Order Payments (支付明细表)](#order_payments)
8. [Order Reviews (评价反馈表)](#order_reviews)
9. [Key Relationships (核心表关联参考)](#relationships)

---

## 1. Customers (客户维度表) {#customers}

**业务含义：** 存储客户的人口统计数据及地理位置基础信息。

| 字段名称 | 数据类型 | 属性说明 | 示例 |
|---|---|---|---|
| `customer_id` | VARCHAR(50) | **主键**。每笔订单关联的唯一客户标识。该ID每次订单独立。 | 06b8999e2fba1a6ff2af236402169e1b |
| `customer_unique_id` | VARCHAR(50) | 账户级全局唯一ID，用于计算客户留存与复购率分析。 | 06b8999e2fba1a6ff2af236402169e1b |
| `customer_zip_code_prefix` | VARCHAR(10) | 客户注册邮政编码前5位。 | 01310 |
| `customer_city` | VARCHAR(100) | 客户登记所在城市名称。 | são paulo |
| `customer_state` | VARCHAR(2) | 客户登记所在州别代码（2位缩写）。 | SP |

**基础总记录级数：** 约 100,000 行。

---

## 2. Sellers (卖家维度表) {#sellers}

**业务含义：** 管理平台承接销售业务的商家基础档案数据。

| 字段名称 | 数据类型 | 属性说明 | 示例 |
|---|---|---|---|
| `seller_id` | VARCHAR(50) | **主键**。唯一的卖家系统标识。 | 3442f8c38cffe371485fb33f26375be2 |
| `seller_zip_code_prefix` | VARCHAR(10) | 卖家登记业务点邮政编码前5位。 | 04710 |
| `seller_city` | VARCHAR(100) | 卖家所处城市。 | são paulo |
| `seller_state` | VARCHAR(2) | 卖家所处的州代码。 | SP |

**基础总记录级数：** 约 3,600 行。

---

## 3. Products (产品维度表) {#products}

**业务含义：** 提供标准化产品基础规格、类型以及重量参数等供物流与定价分析所需的参数集。

| 字段名称 | 数据类型 | 属性说明 | 示例 |
|---|---|---|---|
| `product_id` | VARCHAR(50) | **主键**。平台内产品或SKU的绝对唯一标识。 | 1e9e8ef04869676eb03228e73270e693 |
| `product_category_name` | VARCHAR(100) | 葡萄牙语原始产品分类标签。 | beleza_saude |
| `product_name_length` | INT | 产品陈列名称使用的字符长度记录。 | 85 |
| `product_description_length` | INT | 商品描述文本长度。 | 1024 |
| `product_photos_qty` | INT | 该产品上传的主示图片总计数量。 | 5 |
| `product_weight_g` | INT | 商品估称重量参数（单位：克） | 500 |
| `product_length_cm` | INT | 商品规格长度（单位：厘米） | 20 |
| `product_height_cm` | INT | 商品规格高度（单位：厘米） | 10 |
| `product_width_cm` | INT | 商品规格宽度（单位：厘米） | 15 |

**基础总记录级数：** 约 32,000 行。

---

## 4. Category Translation (品类语言翻译表) {#category_translation}

**业务含义：** 静态映射维表，负责将原始的葡萄牙语品类名转译为统一英语口径供 BI 端展现展现标准使用。

| 字段名称 | 数据类型 | 属性说明 | 示例 |
|---|---|---|---|
| `product_category_name` | VARCHAR(100) | **主键**。原始葡萄牙语品类名。 | beleza_saude |
| `product_category_name_english` | VARCHAR(100) | 转换后的标准化英语名称。 | beauty_health |

**基础总记录级数：** 71 个映射字典。

---

## 5. Orders (订单事实表) {#orders}

**业务含义：** 构建分析模型核心的关键事实单据主表，整合管理订单宏观状态及物流各节点的完整时间戳痕迹。

| 字段名称 | 数据类型 | 属性说明 | 示例 |
|---|---|---|---|
| `order_id` | VARCHAR(50) | **主键**。订单全局唯一标识。 | e481f51cbdc54678b7cc49136f2d6af7 |
| `customer_id` | VARCHAR(50) | 指向维表 *customers.customer_id* 的键连接引用，为该单定位客户归属属性。 | 06b8999e2fba1a6ff2af236402169e1b |
| `order_status` | VARCHAR(50) | 系统回传的当前单据推进状态节点定义。 | delivered |
| `order_purchase_timestamp` | TIMESTAMP | 订单发起付款核实的确切创建时间。 | 2016-09-21 11:09:46 |
| `order_approved_at` | TIMESTAMP | 订单审核通过状态生效时间。 | 2016-09-21 11:10:05 |
| `order_delivered_carrier_date` | TIMESTAMP | 移交首位物流承运方处理的确切时间。 | 2016-09-24 17:43:00 |
| `order_delivered_customer_date` | TIMESTAMP | 包裹签收交付并完单的确切时间（如未派送则为 NULL）。 | 2016-10-26 11:23:00 |
| `order_estimated_delivery_date` | TIMESTAMP | 创建单据时生成平台预期向用户承诺的可抵达日期。 | 2016-10-21 11:09:46 |

**基础总记录级数：** 约 100,000 行。

---

## 6. Order Items (订单明细事实表) {#order_items}

**业务含义：** 从属并从 `Orders` 派生的包含最低分析粒度的产品/SKU级订单详情实体表。 

| 字段名称 | 数据类型 | 属性说明 | 示例 |
|---|---|---|---|
| `order_id` | VARCHAR(50) | **复合主键** 之一，指向对应母订单号。 | e481f51cbdc54678b7cc49136f2d6af7 |
| `order_item_sequence` | INT | **复合主键** 之二，同一包裹下多商品件数的记录序列号。 | 1 |
| `product_id` | VARCHAR(50) | 该明细关联的具体商品产品标识引用。 | 1e9e8ef04869676eb03228e73270e693 |
| `seller_id` | VARCHAR(50) | 该商品由哪个承接商负责寄售发出的卖家信息引用。 | 3442f8c38cffe371485fb33f26375be2 |
| `shipping_limit_date` | TIMESTAMP | 商家交单至合作承运人的服务保障上限期。 | 2016-09-28 17:43:00 |
| `price` | DECIMAL(10,2) | 本件商品本身的基础出售价值基盘（净收入）。 | 29.99 |
| `freight_value` | DECIMAL(10,2) | 按量分摊在本件货体之上的运输交付折损费分摊。 | 9.99 |

**基础总记录级数：** 约 300,000 行。

---

## 7. Order Payments (支付明细表) {#order_payments}

**业务含义：** 收录了各种消费者选择的支付类型方式偏好记录，及金融属性分析中的信贷分期数据。

| 字段名称 | 数据类型 | 属性说明 | 示例 |
|---|---|---|---|
| `order_id` | VARCHAR(50) | 追溯和挂载付款去向母订单表单连接符。 | e481f51cbdc54678b7cc49136f2d6af7 |
| `payment_sequential` | INT | 用以分辨买家是否在单次结算触发过拆分采用组合多付帐手段支付，按先后序号顺标。 | 1 |
| `payment_type` | VARCHAR(50) | 买家完成此账结清时执行的金融系统交易介质类型。 | credit_card |
| `payment_installments` | INT | 通过金融渠道发起的拆借分期付款的期数统计（如无则固定为 1）。 | 1 |
| `payment_value` | DECIMAL(10,2) | 按本方案扣去的有效现金/等同额度。 | 39.98 |

**基础总记录级数：** 约 100,000 行。

---

## 8. Order Reviews (评价反馈表) {#order_reviews}

**业务含义：** 取自商品端收集回传的最终履约打分和消费者口碑信函文字详情集。

| 字段名称 | 数据类型 | 属性说明 | 示例 |
|---|---|---|---|
| `review_id` | VARCHAR(50) | **主键**。独立派生且不可更改变动的单笔评论绝对码索引。 | 1d0304b362e7896bd946edcc8d4ee688 |
| `order_id` | VARCHAR(50) | 被做评价背书对应的购买记录标识号码挂索。 | e481f51cbdc54678b7cc49136f2d6af7 |
| `review_score` | INT | 消费者进行直观评级的定量区间评分量度，值域被划为 `[1, 5]` 星级。 | 4 |
| `review_comment_title` | VARCHAR(255) | 买客补充描述该单评论使用的主内容前置短标题（非必要空置项）。 | Excellent product |
| `review_comment_message` | TEXT | 获取到的冗长完整版内容补充叙述大文本（非必要空置项）。 | Great quality and fast shipping... |
| `review_creation_date` | TIMESTAMP | 表内该口碑项发生成立触发产生的那一秒具体时刻记录。 | 2016-10-28 23:45:30 |
| `review_answer_timestamp` | TIMESTAMP | 系统抓取到承接主体/卖家做出了干预或对应文本答复事件时刻点。 | 2016-10-29 08:15:00 |

**基础总记录级数：** 约 100,000 行。

---

## 9. Key Relationships (核心表关联参考) {#relationships}

整体数据集遵循标准的 **Star Schema (星型建模架构)** 进行规范化组织。所有事实业务过程均可通过中心键进行扩展分析：

### 外键连接定义参考
| 当前数据表 (子表) | 参照连接外键 | 绑定主体表 (母表) | 主体目标标识 |
|---|---|---|---|
| orders | `customer_id` | customers | `customer_id` |
| order_items | `order_id` | orders | `order_id` |
| order_items | `product_id` | products | `product_id` |
| order_items | `seller_id` | sellers | `seller_id` |
| order_payments | `order_id` | orders | `order_id` |
| order_reviews | `order_id` | orders | `order_id` |
| products | `product_category_name` | category_translation | `product_category_name` |

---

## 本系统数据质量与处理规范 (Data Quality & Conventions)

### 常用字段数据类型管理
- **VARCHAR** : 所有用以追查对应源表的主外键(如 ID 值组合)全部长度设为标准 50 个字符。属性修饰等描述设为不低于 100 个字符安全冗余界限。
- **TIMESTAMP** : 格式为常规化的 `YYYY-MM-DD HH:MM:SS` ，由于该业务系统跨州产生，为规避异常默认采纳按 `UTC` 标准核对落盘记录。
- **DECIMAL(10,2)** : 相关于一切价款、资费报销以及扣除的计算统一限定为最高 10 位数宽，且精确至 2 位小数点以完成财会对齐。

### 缺失值 (NULL) 标准规则
- 退回、未达与在途等**由于进度引起的非确定状态逻辑**应表现为正常的预设 `NULL`。 （如 `orders.order_delivered_customer_date` 由于包裹被劫未达被长期呈现未结档的空白保留期）。
- 未作强制硬性必输入的扩展类项 (例如评价内正文字段 `order_reviews.review_comment_message`)，系统会包含一定的 `NULL`。但主外键体系下保证绝对完全无悬空的“孤儿数据关联”。
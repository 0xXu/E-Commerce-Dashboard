# Olist 看板 - 环境部署与搭建指南

本指南将提供在本地完整重现 Olist 电子商务看板的步骤。整个流程涵盖从数据库部署到数据导入，以及最后的 Power BI 工程连接。

## 一、系统前置需求 (Prerequisites)

- 需要预先安装配置 **PostgreSQL 12 或以上版本**。
- 需要安装最新版的 **Power BI Desktop**。
- 下载从 Kaggle 取得的 **Olist 电子商务开源数据集** (包含 8 个 CSV 数据文件)。
- 至少确保硬盘存放空间不低于 500 MB 剩余容量。

---

## 二、部署 PostgreSQL 底层数据库

### 1. 安装 PostgreSQL
**Windows 环境：**
1. 访问官网下载路径：[PostgreSQL Windows 下载](https://www.postgresql.org/download/windows/)
2. 运行安装程序，选取合适的安装目录 (如 `C:\Program Files\PostgreSQL\16`)。
3. 为默认的后台超级用户账号 `postgres` 设置安全的登录密码。
4. 保持默认端口位为 `5432`，完成全部安装。

**Mac 环境：**
```bash
brew install postgresql@16
brew services start postgresql@16
psql --version  # 测试安装连接是否稳定
```

**Linux (Ubuntu) 环境：**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
psql --version  # 验证安装版本信息
```

### 2. 创建独立业务数据库
打开操作系统对应的命令行或终端，并作为 `postgres` 超级管理员身份进入：
```bash
psql -U postgres
```
向控制台提供安装时设置的密码后，开始新建核心数据目录：
```sql
CREATE DATABASE olist_ecommerce;
\c olist_ecommerce
\q
```
当控制台完成切换并输出成功状态时，基础数据库结构体即已创建完毕。

### 3. 初始化物理数据表
利用项目中配套提供的 SQL 语句来建立所需的表结构：

在命令行输入：
```bash
psql -U postgres -d olist_ecommerce -f SQL_VIEWS.sql
```
*(注意：请确保您只需运行文件中最初负责 `CREATE TABLE` 部分建表的 SQL 语句，而非底部生成视图的过程命令)*

您可以使用以下指令快速核对创建效果：
```sql
\dt
```
应输出如下结构对应的 8 张物理表：
`customers`, `sellers`, `products`, `category_translation`, `orders`, `order_items`, `order_payments`, `order_reviews`。

---

## 三、导入本地数据集 (Data Import)

### 1. 下载原始资源包
1. 转到 [Olist 数据集公开源 (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)。
2. 获取完整的 8 张 CSV 表结构文档并解压到指定地址（建议地址为 Windows: `C:\Data\Olist\` 或 Mac: `/Users/YourName/Data/Olist/`）。

### 2. 执行 COPY 导入计划
推荐使用高度优化的 `COPY` 语句以缩短数十万条级别的数据加载时间。

启动 PostgreSQL 会话：
```bash
psql -U postgres -d olist_ecommerce
```
执行系列导入语句（以下示范以 `C:/Data/Olist/` 绝对路径为例，若您使用 Mac，请调整为您实际的 `/Users/YourName/Data/Olist/` 路径）:

```sql
COPY customers(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
FROM 'C:/Data/Olist/olist_customers_dataset.csv' DELIMITER ',' CSV HEADER ENCODING 'UTF8';

COPY sellers(seller_id, seller_zip_code_prefix, seller_city, seller_state)
FROM 'C:/Data/Olist/olist_sellers_dataset.csv' DELIMITER ',' CSV HEADER ENCODING 'UTF8';

COPY products(product_id, product_category_name, product_name_length, product_description_length, product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm)
FROM 'C:/Data/Olist/olist_products_dataset.csv' DELIMITER ',' CSV HEADER ENCODING 'UTF8';

COPY category_translation(product_category_name, product_category_name_english)
FROM 'C:/Data/Olist/olist_category_name_translation.csv' DELIMITER ',' CSV HEADER ENCODING 'UTF8';

COPY orders(order_id, customer_id, order_status, order_purchase_timestamp, order_approved_at, order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date)
FROM 'C:/Data/Olist/olist_orders_dataset.csv' DELIMITER ',' CSV HEADER ENCODING 'UTF8';

COPY order_items(order_id, order_item_sequence, product_id, seller_id, shipping_limit_date, price, freight_value)
FROM 'C:/Data/Olist/olist_order_items_dataset.csv' DELIMITER ',' CSV HEADER ENCODING 'UTF8';

COPY order_payments(order_id, payment_sequential, payment_type, payment_installments, payment_value)
FROM 'C:/Data/Olist/olist_order_payments_dataset.csv' DELIMITER ',' CSV HEADER ENCODING 'UTF8';

COPY order_reviews(review_id, order_id, review_score, review_comment_title, review_comment_message, review_creation_date, review_answer_timestamp)
FROM 'C:/Data/Olist/olist_order_reviews_dataset.csv' DELIMITER ',' CSV HEADER ENCODING 'UTF8';
```

### 3. 数据合规性检查
加载后进行单表数据的统计以确保无记录丢失状况：
```sql
SELECT COUNT(*) FROM customers;     -- 应约返回 100,000 条
SELECT COUNT(*) FROM orders;        -- 应约返回 100,000 条
SELECT COUNT(*) FROM order_items;   -- 应约返回 300,000 条
SELECT COUNT(*) FROM products;      -- 应约返回 32,000 条
```

---

## 四、创建分析专用视图 (Views)

为简化后续复杂调用及加速 Power BI 查询请求处理性能，我们建立 8 个主要分析视图：

应用命令行执行建标操作（如之前已有运行则可跳过该步骤）：
```bash
psql -U postgres -d olist_ecommerce -f SQL_VIEWS.sql
```
执行完毕后，使用校验命令核实验收视图表单列表：
```sql
\dv
```
列表应涵盖： `v_product_performance`, `v_category_performance`, `v_daily_sales`, `v_order_delivery`, `v_seller_performance`, `v_customer_behavior`, `v_review_analysis`, `v_payment_analysis`。

---

## 五、连接 Power BI 看板应用

### 1. 挂接关联数据源
1. 启动本地计算机中的 **Power BI Desktop**。
2. 在顶部导航栏选择：**首页 (Home) → 获取数据 (Get Data)**。
3. 查找并选中 **PostgreSQL 数据库**。

### 2. 配置服务器权限集
- **服务器 (Server)**: `localhost`
- **数据库 (Database)**: `olist_ecommerce`
- **账号**: `postgres`
- **密码**: 设置阶段的数据库密码。

连接生效后，全选界面展示的全部 **8 套预设视图表 (v_ 开头)**，并点击 **加载 (Load)** 进行导入缓存配置。

完成接驳和运算后，您即可完整预览并浏览本项目构建的 Olist 商业分析控制台整体面板及其可视化互动。
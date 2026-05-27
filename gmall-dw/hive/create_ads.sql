
-- ============================================
-- ADS层建表脚本
-- ============================================

USE gmall_ads;

-- 1. GMV日报表
DROP TABLE IF EXISTS ads_gmv_day;
CREATE EXTERNAL TABLE ads_gmv_day(
    dt STRING COMMENT '统计日期',
    recent_days INT COMMENT '最近天数',
    gmv DECIMAL(16,2) COMMENT 'GMV',
    order_count BIGINT COMMENT '订单数',
    order_user_count BIGINT COMMENT '下单人数',
    payment_amount DECIMAL(16,2) COMMENT '支付金额',
    payment_user_count BIGINT COMMENT '支付人数'
) COMMENT 'GMV日报表'
STORED AS ORC
LOCATION '/warehouse/gmall/ads/ads_gmv_day'
TBLPROPERTIES('orc.compress'='snappy');

-- 2. 用户留存表
DROP TABLE IF EXISTS ads_user_retention;
CREATE EXTERNAL TABLE ads_user_retention(
    dt STRING COMMENT '统计日期',
    create_date STRING COMMENT '用户注册日期',
    retention_day INT COMMENT '留存天数',
    new_user_count BIGINT COMMENT '新增用户数',
    retention_count BIGINT COMMENT '留存用户数',
    retention_rate DECIMAL(10,2) COMMENT '留存率'
) COMMENT '用户留存表'
STORED AS ORC
LOCATION '/warehouse/gmall/ads/ads_user_retention'
TBLPROPERTIES('orc.compress'='snappy');

-- 3. 转化率表
DROP TABLE IF EXISTS ads_conversion_rate;
CREATE EXTERNAL TABLE ads_conversion_rate(
    dt STRING COMMENT '统计日期',
    recent_days INT COMMENT '最近天数',
    visit_count BIGINT COMMENT '访问人数',
    cart_count BIGINT COMMENT '加购人数',
    order_count BIGINT COMMENT '下单人数',
    payment_count BIGINT COMMENT '支付人数',
    visit_to_cart_rate DECIMAL(10,2) COMMENT '访问到加购转化率',
    cart_to_order_rate DECIMAL(10,2) COMMENT '加购到下单转化率',
    order_to_payment_rate DECIMAL(10,2) COMMENT '下单到支付转化率'
) COMMENT '转化率表'
STORED AS ORC
LOCATION '/warehouse/gmall/ads/ads_conversion_rate'
TBLPROPERTIES('orc.compress'='snappy');

-- 4. 商品销售排行表
DROP TABLE IF EXISTS ads_sku_sales_rank;
CREATE EXTERNAL TABLE ads_sku_sales_rank(
    dt STRING COMMENT '统计日期',
    recent_days INT COMMENT '最近天数',
    sku_id STRING COMMENT 'SKU ID',
    sku_name STRING COMMENT 'SKU名称',
    order_count BIGINT COMMENT '订单数',
    order_amount DECIMAL(16,2) COMMENT '销售金额',
    rank INT COMMENT '排名'
) COMMENT '商品销售排行表'
STORED AS ORC
LOCATION '/warehouse/gmall/ads/ads_sku_sales_rank'
TBLPROPERTIES('orc.compress'='snappy');

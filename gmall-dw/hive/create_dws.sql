
-- ============================================
-- DWS层建表脚本
-- ============================================

USE gmall_dws;

-- 1. 用户每日汇总表
DROP TABLE IF EXISTS dws_user_day;
CREATE EXTERNAL TABLE dws_user_day(
    user_id STRING COMMENT '用户ID',
    date_id STRING COMMENT '日期ID',
    order_count BIGINT COMMENT '下单次数',
    order_amount DECIMAL(16,2) COMMENT '下单金额',
    payment_count BIGINT COMMENT '支付次数',
    payment_amount DECIMAL(16,2) COMMENT '支付金额'
) COMMENT '用户每日汇总表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dws/dws_user_day'
TBLPROPERTIES('orc.compress'='snappy');

-- 2. 商品每日汇总表
DROP TABLE IF EXISTS dws_sku_day;
CREATE EXTERNAL TABLE dws_sku_day(
    sku_id STRING COMMENT 'SKU ID',
    date_id STRING COMMENT '日期ID',
    order_count BIGINT COMMENT '下单次数',
    order_num BIGINT COMMENT '下单件数',
    order_amount DECIMAL(16,2) COMMENT '下单金额'
) COMMENT '商品每日汇总表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dws/dws_sku_day'
TBLPROPERTIES('orc.compress'='snappy');

-- 3. 订单每日汇总表
DROP TABLE IF EXISTS dws_order_day;
CREATE EXTERNAL TABLE dws_order_day(
    date_id STRING COMMENT '日期ID',
    order_count BIGINT COMMENT '订单数',
    order_user_count BIGINT COMMENT '下单人数',
    order_amount DECIMAL(16,2) COMMENT '订单金额',
    payment_count BIGINT COMMENT '支付订单数',
    payment_user_count BIGINT COMMENT '支付人数',
    payment_amount DECIMAL(16,2) COMMENT '支付金额'
) COMMENT '订单每日汇总表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dws/dws_order_day'
TBLPROPERTIES('orc.compress'='snappy');

-- 4. 地区每日汇总表
DROP TABLE IF EXISTS dws_province_day;
CREATE EXTERNAL TABLE dws_province_day(
    province_id STRING COMMENT '省份ID',
    date_id STRING COMMENT '日期ID',
    order_count BIGINT COMMENT '订单数',
    order_user_count BIGINT COMMENT '下单人数',
    order_amount DECIMAL(16,2) COMMENT '订单金额'
) COMMENT '地区每日汇总表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dws/dws_province_day'
TBLPROPERTIES('orc.compress'='snappy');


-- ============================================
-- DWD层建表脚本
-- ============================================

USE gmall_dwd;

-- 1. 订单明细表
DROP TABLE IF EXISTS dwd_order_detail;
CREATE EXTERNAL TABLE dwd_order_detail(
    id STRING COMMENT '订单明细ID',
    order_id STRING COMMENT '订单ID',
    user_id STRING COMMENT '用户ID',
    sku_id STRING COMMENT 'SKU ID',
    province_id STRING COMMENT '省份ID',
    create_time STRING COMMENT '创建时间',
    sku_num BIGINT COMMENT '商品数量',
    original_amount DECIMAL(16,2) COMMENT '原始金额',
    activity_reduce DECIMAL(16,2) COMMENT '活动减免',
    coupon_reduce DECIMAL(16,2) COMMENT '优惠券减免',
    final_amount DECIMAL(16,2) COMMENT '最终金额',
    date_id STRING COMMENT '日期ID'
) COMMENT '订单明细表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dwd/dwd_order_detail'
TBLPROPERTIES('orc.compress'='snappy');

-- 2. 订单表
DROP TABLE IF EXISTS dwd_order_info;
CREATE EXTERNAL TABLE dwd_order_info(
    id STRING COMMENT '订单ID',
    user_id STRING COMMENT '用户ID',
    province_id STRING COMMENT '省份ID',
    order_status STRING COMMENT '订单状态',
    total_amount DECIMAL(16,2) COMMENT '订单金额',
    payment_way STRING COMMENT '支付方式',
    create_time STRING COMMENT '创建时间',
    date_id STRING COMMENT '日期ID'
) COMMENT '订单表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dwd/dwd_order_info'
TBLPROPERTIES('orc.compress'='snappy');

-- 3. 支付表
DROP TABLE IF EXISTS dwd_payment;
CREATE EXTERNAL TABLE dwd_payment(
    id STRING COMMENT '支付ID',
    order_id STRING COMMENT '订单ID',
    user_id STRING COMMENT '用户ID',
    payment_type STRING COMMENT '支付方式',
    trade_no STRING COMMENT '交易编号',
    total_amount DECIMAL(16,2) COMMENT '支付金额',
    callback_time STRING COMMENT '回调时间',
    date_id STRING COMMENT '日期ID'
) COMMENT '支付表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dwd/dwd_payment'
TBLPROPERTIES('orc.compress'='snappy');


-- ============================================
-- DWS层建表脚本
-- 汇总数据层，按主题轻度聚合
-- ============================================

-- 创建DWS数据库
CREATE DATABASE IF NOT EXISTS dws_ecommerce;
USE dws_ecommerce;

-- 1. 交易域：用户商品粒度订单最近1日汇总表
DROP TABLE IF EXISTS dws_trade_user_sku_order_1d;
CREATE EXTERNAL TABLE dws_trade_user_sku_order_1d(
    `user_id` STRING COMMENT '用户ID',
    `sku_id` STRING COMMENT '商品SKU ID',
    `k1` STRING COMMENT '开始日期',
    `k2` STRING COMMENT '结束日期',
    `order_count_1d` BIGINT COMMENT '最近1日下单次数',
    `order_num_1d` BIGINT COMMENT '最近1日下单件数',
    `order_original_amount_1d` DECIMAL(16,2) COMMENT '最近1日下单原始金额',
    `order_activity_reduce_amount_1d` DECIMAL(16,2) COMMENT '最近1日下单活动减免金额',
    `order_coupon_reduce_amount_1d` DECIMAL(16,2) COMMENT '最近1日下单优惠券减免金额',
    `order_total_amount_1d` DECIMAL(16,2) COMMENT '最近1日下单最终金额'
) COMMENT '交易域用户商品粒度订单最近1日汇总表'
PARTITIONED BY (`dt` STRING)
STORED AS ORC
LOCATION '/warehouse/dws_ecommerce/dws_trade_user_sku_order_1d'
TBLPROPERTIES('orc.compress'='snappy');

-- 2. 交易域：用户粒度订单最近1日汇总表
DROP TABLE IF EXISTS dws_trade_user_order_1d;
CREATE EXTERNAL TABLE dws_trade_user_order_1d(
    `user_id` STRING COMMENT '用户ID',
    `k1` STRING COMMENT '开始日期',
    `k2` STRING COMMENT '结束日期',
    `order_count_1d` BIGINT COMMENT '最近1日下单次数',
    `order_num_1d` BIGINT COMMENT '最近1日下单商品件数',
    `order_original_amount_1d` DECIMAL(16,2) COMMENT '最近1日下单原始金额',
    `order_activity_reduce_amount_1d` DECIMAL(16,2) COMMENT '最近1日下单活动减免金额',
    `order_coupon_reduce_amount_1d` DECIMAL(16,2) COMMENT '最近1日下单优惠券减免金额',
    `order_total_amount_1d` DECIMAL(16,2) COMMENT '最近1日下单最终金额'
) COMMENT '交易域用户粒度订单最近1日汇总表'
PARTITIONED BY (`dt` STRING)
STORED AS ORC
LOCATION '/warehouse/dws_ecommerce/dws_trade_user_order_1d'
TBLPROPERTIES('orc.compress'='snappy');

-- 3. 交易域：商品粒度订单最近1日汇总表
DROP TABLE IF EXISTS dws_trade_sku_order_1d;
CREATE EXTERNAL TABLE dws_trade_sku_order_1d(
    `sku_id` STRING COMMENT '商品SKU ID',
    `k1` STRING COMMENT '开始日期',
    `k2` STRING COMMENT '结束日期',
    `order_count_1d` BIGINT COMMENT '最近1日下单次数',
    `order_num_1d` BIGINT COMMENT '最近1日下单件数',
    `order_original_amount_1d` DECIMAL(16,2) COMMENT '最近1日下单原始金额',
    `order_activity_reduce_amount_1d` DECIMAL(16,2) COMMENT '最近1日下单活动减免金额',
    `order_coupon_reduce_amount_1d` DECIMAL(16,2) COMMENT '最近1日下单优惠券减免金额',
    `order_total_amount_1d` DECIMAL(16,2) COMMENT '最近1日下单最终金额'
) COMMENT '交易域商品粒度订单最近1日汇总表'
PARTITIONED BY (`dt` STRING)
STORED AS ORC
LOCATION '/warehouse/dws_ecommerce/dws_trade_sku_order_1d'
TBLPROPERTIES('orc.compress'='snappy');

-- 4. 交易域：省份粒度订单最近1日汇总表
DROP TABLE IF EXISTS dws_trade_province_order_1d;
CREATE EXTERNAL TABLE dws_trade_province_order_1d(
    `province_id` STRING COMMENT '省份ID',
    `k1` STRING COMMENT '开始日期',
    `k2` STRING COMMENT '结束日期',
    `order_count_1d` BIGINT COMMENT '最近1日下单次数',
    `order_num_1d` BIGINT COMMENT '最近1日下单件数',
    `order_original_amount_1d` DECIMAL(16,2) COMMENT '最近1日下单原始金额',
    `order_activity_reduce_amount_1d` DECIMAL(16,2) COMMENT '最近1日下单活动减免金额',
    `order_coupon_reduce_amount_1d` DECIMAL(16,2) COMMENT '最近1日下单优惠券减免金额',
    `order_total_amount_1d` DECIMAL(16,2) COMMENT '最近1日下单最终金额'
) COMMENT '交易域省份粒度订单最近1日汇总表'
PARTITIONED BY (`dt` STRING)
STORED AS ORC
LOCATION '/warehouse/dws_ecommerce/dws_trade_province_order_1d'
TBLPROPERTIES('orc.compress'='snappy');

-- 5. 交易域：用户粒度支付最近1日汇总表
DROP TABLE IF EXISTS dws_trade_user_payment_1d;
CREATE EXTERNAL TABLE dws_trade_user_payment_1d(
    `user_id` STRING COMMENT '用户ID',
    `k1` STRING COMMENT '开始日期',
    `k2` STRING COMMENT '结束日期',
    `payment_count_1d` BIGINT COMMENT '最近1日支付次数',
    `payment_num_1d` BIGINT COMMENT '最近1日支付商品件数',
    `payment_amount_1d` DECIMAL(16,2) COMMENT '最近1日支付金额'
) COMMENT '交易域用户粒度支付最近1日汇总表'
PARTITIONED BY (`dt` STRING)
STORED AS ORC
LOCATION '/warehouse/dws_ecommerce/dws_trade_user_payment_1d'
TBLPROPERTIES('orc.compress'='snappy');

-- 6. 用户域：用户粒度登录最近1日汇总表
DROP TABLE IF EXISTS dws_user_user_login_1d;
CREATE EXTERNAL TABLE dws_user_user_login_1d(
    `user_id` STRING COMMENT '用户ID',
    `k1` STRING COMMENT '开始日期',
    `k2` STRING COMMENT '结束日期',
    `login_count_1d` BIGINT COMMENT '最近1日登录次数'
) COMMENT '用户域用户粒度登录最近1日汇总表'
PARTITIONED BY (`dt` STRING)
STORED AS ORC
LOCATION '/warehouse/dws_ecommerce/dws_user_user_login_1d'
TBLPROPERTIES('orc.compress'='snappy');

-- 7. 流量域：会话粒度页面浏览最近1日汇总表
DROP TABLE IF EXISTS dws_traffic_session_page_view_1d;
CREATE EXTERNAL TABLE dws_traffic_session_page_view_1d(
    `province_id` STRING COMMENT '省份ID',
    `channel` STRING COMMENT '渠道',
    `is_new` STRING COMMENT '是否新用户',
    `mid_id` STRING COMMENT '设备ID',
    `brand` STRING COMMENT '品牌',
    `operate_system` STRING COMMENT '操作系统',
    `page_id` STRING COMMENT '页面ID',
    `k1` STRING COMMENT '开始日期',
    `k2` STRING COMMENT '结束日期',
    `during_time_1d` BIGINT COMMENT '最近1日浏览时长',
    `page_count_1d` BIGINT COMMENT '最近1日访问页面数'
) COMMENT '流量域会话粒度页面浏览最近1日汇总表'
PARTITIONED BY (`dt` STRING)
STORED AS ORC
LOCATION '/warehouse/dws_ecommerce/dws_traffic_session_page_view_1d'
TBLPROPERTIES('orc.compress'='snappy');

-- 8. 流量域：访客粒度页面浏览最近1日汇总表
DROP TABLE IF EXISTS dws_traffic_visitor_page_view_1d;
CREATE EXTERNAL TABLE dws_traffic_visitor_page_view_1d(
    `province_id` STRING COMMENT '省份ID',
    `channel` STRING COMMENT '渠道',
    `is_new` STRING COMMENT '是否新用户',
    `mid_id` STRING COMMENT '设备ID',
    `brand` STRING COMMENT '品牌',
    `operate_system` STRING COMMENT '操作系统',
    `k1` STRING COMMENT '开始日期',
    `k2` STRING COMMENT '结束日期',
    `during_time_1d` BIGINT COMMENT '最近1日浏览时长',
    `page_count_1d` BIGINT COMMENT '最近1日访问页面数'
) COMMENT '流量域访客粒度页面浏览最近1日汇总表'
PARTITIONED BY (`dt` STRING)
STORED AS ORC
LOCATION '/warehouse/dws_ecommerce/dws_traffic_visitor_page_view_1d'
TBLPROPERTIES('orc.compress'='snappy');

-- 9. 交易域：用户商品粒度购物车最近1日汇总表
DROP TABLE IF EXISTS dws_trade_user_sku_cart_1d;
CREATE EXTERNAL TABLE dws_trade_user_sku_cart_1d(
    `user_id` STRING COMMENT '用户ID',
    `sku_id` STRING COMMENT '商品SKU ID',
    `k1` STRING COMMENT '开始日期',
    `k2` STRING COMMENT '结束日期',
    `cart_count_1d` BIGINT COMMENT '最近1日加购次数',
    `cart_num_1d` BIGINT COMMENT '最近1日加购件数'
) COMMENT '交易域用户商品粒度购物车最近1日汇总表'
PARTITIONED BY (`dt` STRING)
STORED AS ORC
LOCATION '/warehouse/dws_ecommerce/dws_trade_user_sku_cart_1d'
TBLPROPERTIES('orc.compress'='snappy');

-- 10. 交易域：用户商品粒度收藏最近1日汇总表
DROP TABLE IF EXISTS dws_trade_user_sku_favor_1d;
CREATE EXTERNAL TABLE dws_trade_user_sku_favor_1d(
    `user_id` STRING COMMENT '用户ID',
    `sku_id` STRING COMMENT '商品SKU ID',
    `k1` STRING COMMENT '开始日期',
    `k2` STRING COMMENT '结束日期',
    `favor_count_1d` BIGINT COMMENT '最近1日收藏次数'
) COMMENT '交易域用户商品粒度收藏最近1日汇总表'
PARTITIONED BY (`dt` STRING)
STORED AS ORC
LOCATION '/warehouse/dws_ecommerce/dws_trade_user_sku_favor_1d'
TBLPROPERTIES('orc.compress'='snappy');


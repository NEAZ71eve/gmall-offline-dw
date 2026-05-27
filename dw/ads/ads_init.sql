
-- ============================================
-- ADS层建表脚本
-- 应用数据层，指标报表、大屏、接口输出
-- ============================================

-- 创建ADS数据库
CREATE DATABASE IF NOT EXISTS ads_ecommerce;
USE ads_ecommerce;

-- 1. 交易统计主题：交易综合统计
DROP TABLE IF EXISTS ads_trade_stats;
CREATE EXTERNAL TABLE ads_trade_stats(
    `dt` STRING COMMENT '统计日期',
    `recent_days` BIGINT COMMENT '最近天数',
    `order_count` BIGINT COMMENT '订单数',
    `order_user_count` BIGINT COMMENT '下单人数',
    `order_original_amount` DECIMAL(16,2) COMMENT '下单原始金额',
    `order_activity_reduce_amount` DECIMAL(16,2) COMMENT '下单活动减免金额',
    `order_coupon_reduce_amount` DECIMAL(16,2) COMMENT '下单优惠券减免金额',
    `order_total_amount` DECIMAL(16,2) COMMENT '下单最终金额'
) COMMENT '交易统计主题：交易综合统计'
STORED AS ORC
LOCATION '/warehouse/ads_ecommerce/ads_trade_stats'
TBLPROPERTIES('orc.compress'='snappy');

-- 2. 交易统计主题：商品交易综合统计（省份
DROP TABLE IF EXISTS ads_province_stats;
CREATE EXTERNAL TABLE ads_province_stats(
    `dt` STRING COMMENT '统计日期',
    `recent_days` BIGINT COMMENT '最近天数',
    `province_id` STRING COMMENT '省份ID',
    `province_name` STRING COMMENT '省份名称',
    `area_code` STRING COMMENT '地区编码',
    `iso_code` STRING COMMENT 'ISO编码',
    `order_count` BIGINT COMMENT '订单数',
    `order_user_count` BIGINT COMMENT '下单人数',
    `order_original_amount` DECIMAL(16,2) COMMENT '下单原始金额',
    `order_activity_reduce_amount` DECIMAL(16,2) COMMENT '下单活动减免金额',
    `order_coupon_reduce_amount` DECIMAL(16,2) COMMENT '下单优惠券减免金额',
    `order_total_amount` DECIMAL(16,2) COMMENT '下单最终金额'
) COMMENT '交易统计主题：交易综合统计（省份'
STORED AS ORC
LOCATION '/warehouse/ads_ecommerce/ads_province_stats'
TBLPROPERTIES('orc.compress'='snappy');

-- 3. 交易统计主题：商品交易综合统计（商品
DROP TABLE IF EXISTS ads_sku_stats;
CREATE EXTERNAL TABLE ads_sku_stats(
    `dt` STRING COMMENT '统计日期',
    `recent_days` BIGINT COMMENT '最近天数',
    `sku_id` STRING COMMENT '商品SKU ID',
    `sku_name` STRING COMMENT '商品名称',
    `order_count` BIGINT COMMENT '订单数',
    `order_num` BIGINT COMMENT '下单件数',
    `order_original_amount` DECIMAL(16,2) COMMENT '下单原始金额',
    `order_activity_reduce_amount` DECIMAL(16,2) COMMENT '下单活动减免金额',
    `order_coupon_reduce_amount` DECIMAL(16,2) COMMENT '下单优惠券减免金额',
    `order_total_amount` DECIMAL(16,2) COMMENT '下单最终金额'
) COMMENT '交易统计主题：商品交易综合统计'
STORED AS ORC
LOCATION '/warehouse/ads_ecommerce/ads_sku_stats'
TBLPROPERTIES('orc.compress'='snappy');

-- 4. 交易统计主题：交易综合统计（品牌
DROP TABLE IF EXISTS ads_trademark_stats;
CREATE EXTERNAL TABLE ads_trademark_stats(
    `dt` STRING COMMENT '统计日期',
    `recent_days` BIGINT COMMENT '最近天数',
    `tm_id` STRING COMMENT '品牌ID',
    `tm_name` STRING COMMENT '品牌名称',
    `order_count` BIGINT COMMENT '订单数',
    `order_user_count` BIGINT COMMENT '下单人数',
    `order_original_amount` DECIMAL(16,2) COMMENT '下单原始金额',
    `order_activity_reduce_amount` DECIMAL(16,2) COMMENT '下单活动减免金额',
    `order_coupon_reduce_amount` DECIMAL(16,2) COMMENT '下单优惠券减免金额',
    `order_total_amount` DECIMAL(16,2) COMMENT '下单最终金额'
) COMMENT '交易统计主题：交易综合统计（品牌'
STORED AS ORC
LOCATION '/warehouse/ads_ecommerce/ads_trademark_stats'
TBLPROPERTIES('orc.compress'='snappy');

-- 5. 交易统计主题：交易综合统计（分类
DROP TABLE IF EXISTS ads_category_stats;
CREATE EXTERNAL TABLE ads_category_stats(
    `dt` STRING COMMENT '统计日期',
    `recent_days` BIGINT COMMENT '最近天数',
    `category_id` STRING COMMENT '分类ID',
    `category_name` STRING COMMENT '分类名称',
    `order_count` BIGINT COMMENT '订单数',
    `order_user_count` BIGINT COMMENT '下单人数',
    `order_original_amount` DECIMAL(16,2) COMMENT '下单原始金额',
    `order_activity_reduce_amount` DECIMAL(16,2) COMMENT '下单活动减免金额',
    `order_coupon_reduce_amount` DECIMAL(16,2) COMMENT '下单优惠券减免金额',
    `order_total_amount` DECIMAL(16,2) COMMENT '下单最终金额'
) COMMENT '交易统计主题：交易综合统计（分类'
STORED AS ORC
LOCATION '/warehouse/ads_ecommerce/ads_category_stats'
TBLPROPERTIES('orc.compress'='snappy');

-- 6. 流量统计主题：页面路径分析
DROP TABLE IF EXISTS ads_page_path;
CREATE EXTERNAL TABLE ads_page_path(
    `dt` STRING COMMENT '统计日期',
    `recent_days` BIGINT COMMENT '最近天数',
    `source` STRING COMMENT '跳转来源页面',
    `destination` STRING COMMENT '跳转目标页面',
    `path_count` BIGINT COMMENT '跳转次数'
) COMMENT '流量统计主题：页面路径分析'
STORED AS ORC
LOCATION '/warehouse/ads_ecommerce/ads_page_path'
TBLPROPERTIES('orc.compress'='snappy');

-- 7. 用户统计主题：用户综合统计
DROP TABLE IF EXISTS ads_user_stats;
CREATE EXTERNAL TABLE ads_user_stats(
    `dt` STRING COMMENT '统计日期',
    `recent_days` BIGINT COMMENT '最近天数',
    `new_user_count` BIGINT COMMENT '新增用户数',
    `order_user_count` BIGINT COMMENT '下单人数',
    `payment_user_count` BIGINT COMMENT '支付人数'
) COMMENT '用户统计主题：用户综合统计'
STORED AS ORC
LOCATION '/warehouse/ads_ecommerce/ads_user_stats'
TBLPROPERTIES('orc.compress'='snappy');

-- 8. 用户统计主题：用户留存分析
DROP TABLE IF EXISTS ads_user_retention;
CREATE EXTERNAL TABLE ads_user_retention(
    `dt` STRING COMMENT '统计日期',
    `create_date` STRING COMMENT '用户注册日期',
    `retention_day` BIGINT COMMENT '留存天数',
    `new_user_count` BIGINT COMMENT '新增用户数',
    `retention_count` BIGINT COMMENT '留存用户数'
) COMMENT '用户统计主题：用户留存分析'
STORED AS ORC
LOCATION '/warehouse/ads_ecommerce/ads_user_retention'
TBLPROPERTIES('orc.compress'='snappy');

-- 9. 用户统计主题：用户变化表
DROP TABLE IF EXISTS ads_user_change;
CREATE EXTERNAL TABLE ads_user_change(
    `dt` STRING COMMENT '统计日期',
    `user_churn_count` BIGINT COMMENT '流失用户数',
    `user_back_count` BIGINT COMMENT '回流用户数'
) COMMENT '用户统计主题：用户变化表'
STORED AS ORC
LOCATION '/warehouse/ads_ecommerce/ads_user_change'
TBLPROPERTIES('orc.compress'='snappy');

-- 10. 用户统计主题：用户行为漏斗分析
DROP TABLE IF EXISTS ads_user_action;
CREATE EXTERNAL TABLE ads_user_action(
    `dt` STRING COMMENT '统计日期',
    `recent_days` BIGINT COMMENT '最近天数',
    `home_count` BIGINT COMMENT '首页访问人数',
    `cart_count` BIGINT COMMENT '加购人数',
    `order_count` BIGINT COMMENT '下单人数',
    `payment_count` BIGINT COMMENT '支付人数'
) COMMENT '用户统计主题：用户行为漏斗分析'
STORED AS ORC
LOCATION '/warehouse/ads_ecommerce/ads_user_action'
TBLPROPERTIES('orc.compress'='snappy');

-- 11. 用户统计主题：用户复购率分析
DROP TABLE IF EXISTS ads_user_repeat_purchase;
CREATE EXTERNAL TABLE ads_user_repeat_purchase(
    `dt` STRING COMMENT '统计日期',
    `recent_days` BIGINT COMMENT '最近天数',
    `order_count` BIGINT COMMENT '下单次数',
    `order_user_count` BIGINT COMMENT '下单人数',
    `order_repeat_count` BIGINT COMMENT '复购人数'
) COMMENT '用户统计主题：用户复购率分析'
STORED AS ORC
LOCATION '/warehouse/ads_ecommerce/ads_user_repeat_purchase'
TBLPROPERTIES('orc.compress'='snappy');

-- 12. 用户统计主题：用户订单统计
DROP TABLE IF EXISTS ads_user_order_stats;
CREATE EXTERNAL TABLE ads_user_order_stats(
    `dt` STRING COMMENT '统计日期',
    `recent_days` BIGINT COMMENT '最近天数',
    `order_count_avg` DECIMAL(16,2) COMMENT '下单次数均值',
    `order_amount_avg` DECIMAL(16,2) COMMENT '下单金额均值'
) COMMENT '用户统计主题：用户订单统计'
STORED AS ORC
LOCATION '/warehouse/ads_ecommerce/ads_user_order_stats'
TBLPROPERTIES('orc.compress'='snappy');


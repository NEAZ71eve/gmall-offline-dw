
-- ============================================
-- DWS层建表脚本 - 完整版
-- 包含电商核心汇总表：用户、商品、订单、地区、品牌、类目、活动、优惠券等
-- ============================================

USE gmall_dws;

-- ============================================
-- 1. 交易域汇总表
-- ============================================

-- 1.1 订单每日汇总表
DROP TABLE IF EXISTS dws_order_day;
CREATE EXTERNAL TABLE dws_order_day(
    date_id STRING COMMENT '日期ID',
    order_count BIGINT COMMENT '下单订单数',
    order_user_count BIGINT COMMENT '下单用户数',
    order_amount DECIMAL(16,2) COMMENT '下单金额',
    payment_count BIGINT COMMENT '支付订单数',
    payment_user_count BIGINT COMMENT '支付用户数',
    payment_amount DECIMAL(16,2) COMMENT '支付金额',
    refund_count BIGINT COMMENT '退款订单数',
    refund_amount DECIMAL(16,2) COMMENT '退款金额',
    coupon_count BIGINT COMMENT '使用优惠券订单数',
    coupon_amount DECIMAL(16,2) COMMENT '优惠券减免金额',
    activity_count BIGINT COMMENT '参与活动订单数',
    activity_amount DECIMAL(16,2) COMMENT '活动减免金额'
) COMMENT '订单每日汇总表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dws/dws_order_day'
TBLPROPERTIES('orc.compress'='snappy');

-- 1.2 订单周汇总表
DROP TABLE IF EXISTS dws_order_week;
CREATE EXTERNAL TABLE dws_order_week(
    week_id STRING COMMENT '周ID',
    week_start_date STRING COMMENT '周开始日期',
    week_end_date STRING COMMENT '周结束日期',
    order_count BIGINT COMMENT '下单订单数',
    order_user_count BIGINT COMMENT '下单用户数',
    order_amount DECIMAL(16,2) COMMENT '下单金额',
    payment_count BIGINT COMMENT '支付订单数',
    payment_user_count BIGINT COMMENT '支付用户数',
    payment_amount DECIMAL(16,2) COMMENT '支付金额',
    refund_count BIGINT COMMENT '退款订单数',
    refund_amount DECIMAL(16,2) COMMENT '退款金额'
) COMMENT '订单周汇总表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dws/dws_order_week'
TBLPROPERTIES('orc.compress'='snappy');

-- 1.3 订单月汇总表
DROP TABLE IF EXISTS dws_order_month;
CREATE EXTERNAL TABLE dws_order_month(
    month_id STRING COMMENT '月ID',
    month_start_date STRING COMMENT '月开始日期',
    month_end_date STRING COMMENT '月结束日期',
    order_count BIGINT COMMENT '下单订单数',
    order_user_count BIGINT COMMENT '下单用户数',
    order_amount DECIMAL(16,2) COMMENT '下单金额',
    payment_count BIGINT COMMENT '支付订单数',
    payment_user_count BIGINT COMMENT '支付用户数',
    payment_amount DECIMAL(16,2) COMMENT '支付金额',
    refund_count BIGINT COMMENT '退款订单数',
    refund_amount DECIMAL(16,2) COMMENT '退款金额'
) COMMENT '订单月汇总表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dws/dws_order_month'
TBLPROPERTIES('orc.compress'='snappy');

-- ============================================
-- 2. 用户域汇总表
-- ============================================

-- 2.1 用户每日汇总表
DROP TABLE IF EXISTS dws_user_day;
CREATE EXTERNAL TABLE dws_user_day(
    user_id STRING COMMENT '用户ID',
    user_level STRING COMMENT '用户等级',
    date_id STRING COMMENT '日期ID',
    order_count BIGINT COMMENT '下单次数',
    order_amount DECIMAL(16,2) COMMENT '下单金额',
    payment_count BIGINT COMMENT '支付次数',
    payment_amount DECIMAL(16,2) COMMENT '支付金额',
    cart_count BIGINT COMMENT '加购次数',
    cart_num BIGINT COMMENT '加购商品数',
    favor_count BIGINT COMMENT '收藏次数',
    comment_count BIGINT COMMENT '评价次数'
) COMMENT '用户每日汇总表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dws/dws_user_day'
TBLPROPERTIES('orc.compress'='snappy');

-- 2.2 用户新增表
DROP TABLE IF EXISTS dws_user_new_day;
CREATE EXTERNAL TABLE dws_user_new_day(
    user_id STRING COMMENT '用户ID',
    user_level STRING COMMENT '用户等级',
    gender STRING COMMENT '性别',
    birthday STRING COMMENT '生日',
    date_id STRING COMMENT '注册日期ID',
    create_time STRING COMMENT '注册时间'
) COMMENT '用户新增表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dws/dws_user_new_day'
TBLPROPERTIES('orc.compress'='snappy');

-- 2.3 用户留存表
DROP TABLE IF EXISTS dws_user_retention_day;
CREATE EXTERNAL TABLE dws_user_retention_day(
    stat_date STRING COMMENT '统计日期',
    user_id STRING COMMENT '用户ID',
    date_id STRING COMMENT '新增日期ID',
    retention_day BIGINT COMMENT '留存天数',
    retention_date STRING COMMENT '留存日期'
) COMMENT '用户留存表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dws/dws_user_retention_day'
TBLPROPERTIES('orc.compress'='snappy');

-- ============================================
-- 3. 商品域汇总表
-- ============================================

-- 3.1 商品每日汇总表
DROP TABLE IF EXISTS dws_sku_day;
CREATE EXTERNAL TABLE dws_sku_day(
    sku_id STRING COMMENT 'SKU ID',
    sku_name STRING COMMENT '商品名称',
    category3_id STRING COMMENT '三级分类ID',
    category3_name STRING COMMENT '三级分类名称',
    tm_id STRING COMMENT '品牌ID',
    tm_name STRING COMMENT '品牌名称',
    date_id STRING COMMENT '日期ID',
    order_count BIGINT COMMENT '下单次数',
    order_num BIGINT COMMENT '下单件数',
    order_amount DECIMAL(16,2) COMMENT '下单金额',
    payment_count BIGINT COMMENT '支付次数',
    payment_num BIGINT COMMENT '支付件数',
    payment_amount DECIMAL(16,2) COMMENT '支付金额',
    refund_count BIGINT COMMENT '退款次数',
    refund_num BIGINT COMMENT '退款件数',
    refund_amount DECIMAL(16,2) COMMENT '退款金额',
    cart_count BIGINT COMMENT '加购次数',
    favor_count BIGINT COMMENT '收藏次数'
) COMMENT '商品每日汇总表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dws/dws_sku_day'
TBLPROPERTIES('orc.compress'='snappy');

-- 3.2 品牌每日汇总表
DROP TABLE IF EXISTS dws_trademark_day;
CREATE EXTERNAL TABLE dws_trademark_day(
    tm_id STRING COMMENT '品牌ID',
    tm_name STRING COMMENT '品牌名称',
    date_id STRING COMMENT '日期ID',
    order_count BIGINT COMMENT '下单次数',
    order_num BIGINT COMMENT '下单件数',
    order_amount DECIMAL(16,2) COMMENT '下单金额',
    payment_count BIGINT COMMENT '支付次数',
    payment_num BIGINT COMMENT '支付件数',
    payment_amount DECIMAL(16,2) COMMENT '支付金额'
) COMMENT '品牌每日汇总表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dws/dws_trademark_day'
TBLPROPERTIES('orc.compress'='snappy');

-- 3.3 类目每日汇总表
DROP TABLE IF EXISTS dws_category3_day;
CREATE EXTERNAL TABLE dws_category3_day(
    category3_id STRING COMMENT '三级分类ID',
    category3_name STRING COMMENT '三级分类名称',
    category2_id STRING COMMENT '二级分类ID',
    category2_name STRING COMMENT '二级分类名称',
    category1_id STRING COMMENT '一级分类ID',
    category1_name STRING COMMENT '一级分类名称',
    date_id STRING COMMENT '日期ID',
    order_count BIGINT COMMENT '下单次数',
    order_num BIGINT COMMENT '下单件数',
    order_amount DECIMAL(16,2) COMMENT '下单金额',
    payment_count BIGINT COMMENT '支付次数',
    payment_num BIGINT COMMENT '支付件数',
    payment_amount DECIMAL(16,2) COMMENT '支付金额'
) COMMENT '类目每日汇总表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dws/dws_category3_day'
TBLPROPERTIES('orc.compress'='snappy');

-- ============================================
-- 4. 地区域汇总表
-- ============================================

-- 4.1 地区每日汇总表
DROP TABLE IF EXISTS dws_province_day;
CREATE EXTERNAL TABLE dws_province_day(
    province_id STRING COMMENT '省份ID',
    province_name STRING COMMENT '省份名称',
    area_code STRING COMMENT '地区编码',
    region_id STRING COMMENT '区域ID',
    region_name STRING COMMENT '区域名称',
    date_id STRING COMMENT '日期ID',
    order_count BIGINT COMMENT '下单订单数',
    order_user_count BIGINT COMMENT '下单用户数',
    order_amount DECIMAL(16,2) COMMENT '下单金额',
    payment_count BIGINT COMMENT '支付订单数',
    payment_user_count BIGINT COMMENT '支付用户数',
    payment_amount DECIMAL(16,2) COMMENT '支付金额'
) COMMENT '地区每日汇总表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dws/dws_province_day'
TBLPROPERTIES('orc.compress'='snappy');

-- ============================================
-- 5. 促销域汇总表
-- ============================================

-- 5.1 优惠券每日汇总表
DROP TABLE IF EXISTS dws_coupon_day;
CREATE EXTERNAL TABLE dws_coupon_day(
    coupon_id STRING COMMENT '优惠券ID',
    coupon_name STRING COMMENT '优惠券名称',
    coupon_type STRING COMMENT '优惠券类型',
    date_id STRING COMMENT '日期ID',
    get_count BIGINT COMMENT '领取数量',
    get_user_count BIGINT COMMENT '领取用户数',
    used_count BIGINT COMMENT '使用数量',
    used_user_count BIGINT COMMENT '使用用户数',
    order_count BIGINT COMMENT '优惠订单数',
    coupon_amount DECIMAL(16,2) COMMENT '优惠金额'
) COMMENT '优惠券每日汇总表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dws/dws_coupon_day'
TBLPROPERTIES('orc.compress'='snappy');

-- 5.2 活动每日汇总表
DROP TABLE IF EXISTS dws_activity_day;
CREATE EXTERNAL TABLE dws_activity_day(
    activity_id STRING COMMENT '活动ID',
    activity_name STRING COMMENT '活动名称',
    activity_type STRING COMMENT '活动类型',
    date_id STRING COMMENT '日期ID',
    order_count BIGINT COMMENT '参与订单数',
    order_user_count BIGINT COMMENT '参与用户数',
    reduce_amount DECIMAL(16,2) COMMENT '优惠金额'
) COMMENT '活动每日汇总表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dws/dws_activity_day'
TBLPROPERTIES('orc.compress'='snappy');

-- ============================================
-- 6. 流量域汇总表
-- ============================================

-- 6.1 页面浏览每日汇总表
DROP TABLE IF EXISTS dws_page_view_day;
CREATE EXTERNAL TABLE dws_page_view_day(
    date_id STRING COMMENT '日期ID',
    hour_id STRING COMMENT '小时ID',
    view_count BIGINT COMMENT '浏览次数',
    visitor_count BIGINT COMMENT '访客数',
    session_count BIGINT COMMENT '会话数',
    avg_duration_sec BIGINT COMMENT '平均停留时长(秒)',
    bounce_rate DECIMAL(16,2) COMMENT '跳出率'
) COMMENT '页面浏览每日汇总表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/workspace/gmall/dws/dws_page_view_day'
TBLPROPERTIES('orc.compress'='snappy');

-- ============================================
-- 7. 客服域汇总表
-- ============================================

-- 7.1 客服工单每日汇总表
DROP TABLE IF EXISTS dws_customer_service_day;
CREATE EXTERNAL TABLE dws_customer_service_day(
    date_id STRING COMMENT '日期ID',
    service_type STRING COMMENT '服务类型',
    total_count BIGINT COMMENT '总工单数',
    pending_count BIGINT COMMENT '待处理工单数',
    resolved_count BIGINT COMMENT '已解决工单数',
    resolved_rate DECIMAL(16,2) COMMENT '解决率'
) COMMENT '客服工单每日汇总表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dws/dws_customer_service_day'
TBLPROPERTIES('orc.compress'='snappy');

-- ============================================
-- 生命周期管理
-- ============================================

-- DWS层数据保留策略：永久保留
-- DWS层是汇总层，数据有分析价值，建议永久保留

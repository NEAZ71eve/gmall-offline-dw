
-- ============================================
-- ADS层建表脚本 - 完整版
-- 包含电商核心报表：GMV、用户、商品、地区、品牌、类目、转化漏斗等
-- ============================================

USE gmall_ads;

-- ============================================
-- 1. 交易域报表
-- ============================================

-- 1.1 GMV日报表
DROP TABLE IF EXISTS ads_gmv_day;
CREATE EXTERNAL TABLE ads_gmv_day(
    dt STRING COMMENT '统计日期',
    recent_days INT COMMENT '最近天数',
    gmv DECIMAL(16,2) COMMENT 'GMV(成交总额)',
    order_count BIGINT COMMENT '下单订单数',
    order_user_count BIGINT COMMENT '下单用户数',
    payment_amount DECIMAL(16,2) COMMENT '支付金额(实付)',
    payment_count BIGINT COMMENT '支付订单数',
    payment_user_count BIGINT COMMENT '支付用户数',
    refund_amount DECIMAL(16,2) COMMENT '退款金额',
    refund_count BIGINT COMMENT '退款订单数',
    net_sales_amount DECIMAL(16,2) COMMENT '净销售额',
    avg_order_amount DECIMAL(16,2) COMMENT '平均订单金额',
    avg_pay_amount DECIMAL(16,2) COMMENT '平均支付金额'
) COMMENT 'GMV日报表'
STORED AS ORC
LOCATION '/warehouse/gmall/ads/ads_gmv_day'
TBLPROPERTIES('orc.compress'='snappy');

-- 1.2 GMV地区分布报表
DROP TABLE IF EXISTS ads_gmv_province;
CREATE EXTERNAL TABLE ads_gmv_province(
    dt STRING COMMENT '统计日期',
    recent_days INT COMMENT '最近天数',
    province_id STRING COMMENT '省份ID',
    province_name STRING COMMENT '省份名称',
    region_name STRING COMMENT '区域名称',
    gmv DECIMAL(16,2) COMMENT 'GMV',
    gmv_share DECIMAL(10,4) COMMENT 'GMV占比',
    order_count BIGINT COMMENT '订单数',
    order_user_count BIGINT COMMENT '用户数',
    payment_amount DECIMAL(16,2) COMMENT '支付金额'
) COMMENT 'GMV地区分布报表'
STORED AS ORC
LOCATION '/warehouse/gmall/ads/ads_gmv_province'
TBLPROPERTIES('orc.compress'='snappy');

-- 1.3 GMV品牌分布报表
DROP TABLE IF EXISTS ads_gmv_trademark;
CREATE EXTERNAL TABLE ads_gmv_trademark(
    dt STRING COMMENT '统计日期',
    recent_days INT COMMENT '最近天数',
    tm_id STRING COMMENT '品牌ID',
    tm_name STRING COMMENT '品牌名称',
    gmv DECIMAL(16,2) COMMENT 'GMV',
    gmv_share DECIMAL(10,4) COMMENT 'GMV占比',
    order_count BIGINT COMMENT '订单数',
    order_num BIGINT COMMENT '商品件数',
    payment_amount DECIMAL(16,2) COMMENT '支付金额'
) COMMENT 'GMV品牌分布报表'
STORED AS ORC
LOCATION '/workspace/gmall/ads/ads_gmv_trademark'
TBLPROPERTIES('orc.compress'='snappy');

-- 1.4 GMV类目分布报表
DROP TABLE IF EXISTS ads_gmv_category;
CREATE EXTERNAL TABLE ads_gmv_category(
    dt STRING COMMENT '统计日期',
    recent_days INT COMMENT '最近天数',
    category1_id STRING COMMENT '一级分类ID',
    category1_name STRING COMMENT '一级分类名称',
    category2_id STRING COMMENT '二级分类ID',
    category2_name STRING COMMENT '二级分类名称',
    category3_id STRING COMMENT '三级分类ID',
    category3_name STRING COMMENT '三级分类名称',
    gmv DECIMAL(16,2) COMMENT 'GMV',
    gmv_share DECIMAL(10,4) COMMENT 'GMV占比',
    order_count BIGINT COMMENT '订单数',
    order_num BIGINT COMMENT '商品件数'
) COMMENT 'GMV类目分布报表'
STORED AS ORC
LOCATION '/warehouse/gmall/ads/ads_gmv_category'
TBLPROPERTIES('orc.compress'='snappy');

-- ============================================
-- 2. 用户域报表
-- ============================================

-- 2.1 用户留存报表
DROP TABLE IF EXISTS ads_user_retention;
CREATE EXTERNAL TABLE ads_user_retention(
    dt STRING COMMENT '统计日期',
    create_date STRING COMMENT '用户注册日期',
    retention_day INT COMMENT '留存天数',
    new_user_count BIGINT COMMENT '新增用户数',
    retention_count BIGINT COMMENT '留存用户数',
    retention_rate DECIMAL(10,4) COMMENT '留存率',
    active_user_count BIGINT COMMENT '活跃用户数'
) COMMENT '用户留存报表'
STORED AS ORC
LOCATION '/warehouse/gmall/ads/ads_user_retention'
TBLPROPERTIES('orc.compress'='snappy');

-- 2.2 用户新增报表
DROP TABLE IF EXISTS ads_user_new_day;
CREATE EXTERNAL TABLE ads_user_new_day(
    dt STRING COMMENT '统计日期',
    new_user_count BIGINT COMMENT '新增用户数',
    new_male_count BIGINT COMMENT '新增男性用户数',
    new_female_count BIGINT COMMENT '新增女性用户数',
    new_user_level1_count BIGINT COMMENT '新增用户等级1数量',
    new_user_level2_count BIGINT COMMENT '新增用户等级2数量',
    new_user_level3_count BIGINT COMMENT '新增用户等级3数量',
    new_user_level4_count BIGINT COMMENT '新增用户等级4数量',
    new_user_level5_count BIGINT COMMENT '新增用户等级5数量'
) COMMENT '用户新增报表'
STORED AS ORC
LOCATION '/workspace/gmall/ads/ads_user_new_day'
TBLPROPERTIES('orc.compress'='snappy');

-- 2.3 用户活跃报表
DROP TABLE IF EXISTS ads_user_active_day;
CREATE EXTERNAL TABLE ads_user_active_day(
    dt STRING COMMENT '统计日期',
    recent_days INT COMMENT '最近天数',
    dau BIGINT COMMENT '日活跃用户数(DAU)',
    wau BIGINT COMMENT '周活跃用户数(WAU)',
    mau BIGINT COMMENT '月活跃用户数(MAU)'
) COMMENT '用户活跃报表'
STORED AS ORC
LOCATION '/workspace/gmall/ads/ads_user_active_day'
TBLPROPERTIES('orc.compress'='snappy');

-- 2.4 用户复购报表
DROP TABLE IF EXISTS ads_user_repurchase;
CREATE EXTERNAL TABLE ads_user_repurchase(
    dt STRING COMMENT '统计日期',
    recent_days INT COMMENT '最近天数',
    total_user_count BIGINT COMMENT '总用户数',
    repeat_purchase_user_count BIGINT COMMENT '复购用户数',
    repeat_purchase_rate DECIMAL(10,4) COMMENT '复购率',
    avg_purchase_times DECIMAL(10,2) COMMENT '平均购买次数',
    max_purchase_times BIGINT COMMENT '最大购买次数'
) COMMENT '用户复购报表'
STORED AS ORC
LOCATION '/workspace/gmall/ads/ads_user_repurchase'
TBLPROPERTIES('orc.compress'='snappy');

-- ============================================
-- 3. 商品域报表
-- ============================================

-- 3.1 商品销售排行报表
DROP TABLE IF EXISTS ads_sku_sales_rank;
CREATE EXTERNAL TABLE ads_sku_sales_rank(
    dt STRING COMMENT '统计日期',
    recent_days INT COMMENT '最近天数',
    sku_id STRING COMMENT 'SKU ID',
    sku_name STRING COMMENT 'SKU名称',
    tm_id STRING COMMENT '品牌ID',
    tm_name STRING COMMENT '品牌名称',
    category3_id STRING COMMENT '三级分类ID',
    category3_name STRING COMMENT '三级分类名称',
    order_count BIGINT COMMENT '订单数',
    order_num BIGINT COMMENT '商品件数',
    order_amount DECIMAL(16,2) COMMENT '销售金额',
    payment_count BIGINT COMMENT '支付订单数',
    payment_amount DECIMAL(16,2) COMMENT '支付金额',
    refund_count BIGINT COMMENT '退款订单数',
    refund_amount DECIMAL(16,2) COMMENT '退款金额',
    sales_rank INT COMMENT '销售排行',
    amount_rank INT COMMENT '金额排行'
) COMMENT '商品销售排行报表'
STORED AS ORC
LOCATION '/warehouse/gmall/ads/ads_sku_sales_rank'
TBLPROPERTIES('orc.compress'='snappy');

-- 3.2 商品曝光点击报表
DROP TABLE IF EXISTS ads_sku_exposure_click;
CREATE EXTERNAL TABLE ads_sku_exposure_click(
    dt STRING COMMENT '统计日期',
    sku_id STRING COMMENT 'SKU ID',
    sku_name STRING COMMENT 'SKU名称',
    exposure_count BIGINT COMMENT '曝光次数',
    click_count BIGINT COMMENT '点击次数',
    click_rate DECIMAL(10,4) COMMENT '点击率',
    cart_count BIGINT COMMENT '加购次数',
    cart_rate DECIMAL(10,4) COMMENT '加购率'
) COMMENT '商品曝光点击报表'
STORED AS ORC
LOCATION '/warehouse/gmall/ads/ads_sku_exposure_click'
TBLPROPERTIES('orc.compress'='snappy');

-- ============================================
-- 4. 转化域报表
-- ============================================

-- 4.1 转化漏斗报表
DROP TABLE IF EXISTS ads_conversion_rate;
CREATE EXTERNAL TABLE ads_conversion_rate(
    dt STRING COMMENT '统计日期',
    recent_days INT COMMENT '最近天数',
    step1_name STRING COMMENT '步骤1名称',
    step1_count BIGINT COMMENT '步骤1人数',
    step2_name STRING COMMENT '步骤2名称',
    step2_count BIGINT COMMENT '步骤2人数',
    step3_name STRING COMMENT '步骤3名称',
    step3_count BIGINT COMMENT '步骤3人数',
    step4_name STRING COMMENT '步骤4名称',
    step4_count BIGINT COMMENT '步骤4人数',
    step5_name STRING COMMENT '步骤5名称',
    step5_count BIGINT COMMENT '步骤5人数',
    step1_to_step2_rate DECIMAL(10,4) COMMENT '步骤1到步骤2转化率',
    step2_to_step3_rate DECIMAL(10,4) COMMENT '步骤2到步骤3转化率',
    step3_to_step4_rate DECIMAL(10,4) COMMENT '步骤3到步骤4转化率',
    step4_to_step5_rate DECIMAL(10,4) COMMENT '步骤4到步骤5转化率',
    total_conversion_rate DECIMAL(10,4) COMMENT '总体转化率'
) COMMENT '转化漏斗报表'
STORED AS ORC
LOCATION '/warehouse/gmall/ads/ads_conversion_rate'
TBLPROPERTIES('orc.compress'='snappy');

-- ============================================
-- 5. 促销域报表
-- ============================================

-- 5.1 优惠券使用报表
DROP TABLE IF EXISTS ads_coupon_usage;
CREATE EXTERNAL TABLE ads_coupon_usage(
    dt STRING COMMENT '统计日期',
    recent_days INT COMMENT '最近天数',
    coupon_id STRING COMMENT '优惠券ID',
    coupon_name STRING COMMENT '优惠券名称',
    coupon_type STRING COMMENT '优惠券类型',
    get_count BIGINT COMMENT '领取数量',
    get_user_count BIGINT COMMENT '领取用户数',
    used_count BIGINT COMMENT '使用数量',
    used_user_count BIGINT COMMENT '使用用户数',
    used_rate DECIMAL(10,4) COMMENT '使用率',
    order_count BIGINT COMMENT '优惠订单数',
    coupon_amount DECIMAL(16,2) COMMENT '优惠金额'
) COMMENT '优惠券使用报表'
STORED AS ORC
LOCATION '/workspace/gmall/ads/ads_coupon_usage'
TBLPROPERTIES('orc.compress'='snappy');

-- 5.2 活动效果报表
DROP TABLE IF EXISTS ads_activity_stats;
CREATE EXTERNAL TABLE ads_activity_stats(
    dt STRING COMMENT '统计日期',
    recent_days INT COMMENT '最近天数',
    activity_id STRING COMMENT '活动ID',
    activity_name STRING COMMENT '活动名称',
    activity_type STRING COMMENT '活动类型',
    participant_count BIGINT COMMENT '参与人数',
    participant_order_count BIGINT COMMENT '参与订单数',
    reduce_amount DECIMAL(16,2) COMMENT '优惠金额',
    avg_reduce_per_order DECIMAL(16,2) COMMENT '每单平均优惠'
) COMMENT '活动效果报表'
STORED AS ORC
LOCATION '/workspace/gmall/ads/ads_activity_stats'
TBLPROPERTIES('orc.compress'='snappy');

-- ============================================
-- 6. 地区域报表
-- ============================================

-- 6.1 地区销售报表
DROP TABLE IF EXISTS ads_province_stats;
CREATE EXTERNAL TABLE ads_province_stats(
    dt STRING COMMENT '统计日期',
    recent_days INT COMMENT '最近天数',
    province_id STRING COMMENT '省份ID',
    province_name STRING COMMENT '省份名称',
    region_id STRING COMMENT '区域ID',
    region_name STRING COMMENT '区域名称',
    order_count BIGINT COMMENT '订单数',
    order_user_count BIGINT COMMENT '用户数',
    order_amount DECIMAL(16,2) COMMENT '订单金额',
    payment_count BIGINT COMMENT '支付订单数',
    payment_amount DECIMAL(16,2) COMMENT '支付金额',
    refund_count BIGINT COMMENT '退款订单数',
    refund_amount DECIMAL(16,2) COMMENT '退款金额'
) COMMENT '地区销售报表'
STORED AS ORC
LOCATION '/workspace/gmall/ads/ads_province_stats'
TBLPROPERTIES('orc.compress'='snappy');

-- ============================================
-- 7. 品牌域报表
-- ============================================

-- 7.1 品牌销售报表
DROP TABLE IF EXISTS ads_trademark_stats;
CREATE EXTERNAL TABLE ads_trademark_stats(
    dt STRING COMMENT '统计日期',
    recent_days INT COMMENT '最近天数',
    tm_id STRING COMMENT '品牌ID',
    tm_name STRING COMMENT '品牌名称',
    order_count BIGINT COMMENT '订单数',
    order_num BIGINT COMMENT '商品件数',
    order_amount DECIMAL(16,2) COMMENT '订单金额',
    payment_count BIGINT COMMENT '支付订单数',
    payment_num BIGINT COMMENT '支付件数',
    payment_amount DECIMAL(16,2) COMMENT '支付金额',
    refund_count BIGINT COMMENT '退款订单数',
    refund_num BIGINT COMMENT '退款件数',
    refund_amount DECIMAL(16,2) COMMENT '退款金额',
    gmv_share DECIMAL(10,4) COMMENT 'GMV占比',
    amount_rank INT COMMENT '金额排行'
) COMMENT '品牌销售报表'
STORED AS ORC
LOCATION '/workspace/gmall/ads/ads_trademark_stats'
TBLPROPERTIES('orc.compress'='snappy');

-- ============================================
-- 8. 客服域报表
-- ============================================

-- 8.1 客服服务报表
DROP TABLE IF EXISTS ads_customer_service;
CREATE EXTERNAL TABLE ads_customer_service(
    dt STRING COMMENT '统计日期',
    recent_days INT COMMENT '最近天数',
    service_type STRING COMMENT '服务类型',
    total_count BIGINT COMMENT '总工单数',
    pending_count BIGINT COMMENT '待处理工单数',
    processing_count BIGINT COMMENT '处理中工单数',
    resolved_count BIGINT COMMENT '已解决工单数',
    unsolved_count BIGINT COMMENT '未解决工单数',
    resolved_rate DECIMAL(10,4) COMMENT '解决率',
    avg_handle_time_minutes DECIMAL(10,2) COMMENT '平均处理时长(分钟)'
) COMMENT '客服服务报表'
STORED AS ORC
LOCATION '/workspace/gmall/ads/ads_customer_service'
TBLPROPERTIES('orc.compress'='snappy');

-- ============================================
-- 生命周期管理
-- ============================================

-- ADS层数据保留策略：永久保留
-- ADS层是应用层，为业务报表提供数据，建议永久保留

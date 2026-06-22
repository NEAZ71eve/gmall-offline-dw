-- ============================================================================
-- ADS层核心指标计算脚本 - 补充版
-- 包含：日活(DAU)、GMV、留存率、复购率、转化率等核心指标
-- ============================================================================

USE gmall_ads;

-- ============================================================================
-- 1. 日活用户报表（按设备类型）
-- ============================================================================
DROP TABLE IF EXISTS ads_dau_by_device;
CREATE EXTERNAL TABLE ads_dau_by_device(
    dt STRING COMMENT '统计日期',
    device_type STRING COMMENT '设备类型(PC/MOBILE/APP)',
    dau_count BIGINT COMMENT '日活用户数',
    new_user_count BIGINT COMMENT '新增用户数',
    return_user_count BIGINT COMMENT '回流用户数',
    avg_duration DECIMAL(10,2) COMMENT '平均在线时长(分钟)',
    avg_page_view DECIMAL(10,2) COMMENT '平均页面浏览量'
) COMMENT '日活用户报表(按设备类型)'
PARTITIONED BY (dt = '${biz_date}')
STORED AS ORC
LOCATION '/warehouse/gmall/ads/ads_dau_by_device'
TBLPROPERTIES('orc.compress'='snappy');

INSERT OVERWRITE TABLE ads_dau_by_device PARTITION(dt = '${biz_date}')
SELECT
    '${biz_date}' AS dt,
    device_type,
    COUNT(DISTINCT user_id) AS dau_count,
    COUNT(DISTINCT CASE WHEN is_new = 1 THEN user_id END) AS new_user_count,
    COUNT(DISTINCT CASE WHEN is_return = 1 THEN user_id END) AS return_user_count,
    AVG(duration_minutes) AS avg_duration,
    AVG(page_view_count) AS avg_page_view
FROM gmall_dws.dws_user_device_stats
WHERE dt = '${biz_date}'
GROUP BY device_type;

-- ============================================================================
-- 2. GMV趋势报表（含同比环比）
-- ============================================================================
DROP TABLE IF EXISTS ads_gmv_trend;
CREATE EXTERNAL TABLE ads_gmv_trend(
    dt STRING COMMENT '统计日期',
    gmv DECIMAL(16,2) COMMENT '当日GMV',
    order_count BIGINT COMMENT '订单数',
    order_user_count BIGINT COMMENT '下单人数',
    avg_order_amount DECIMAL(10,2) COMMENT '客单价',
    gmv_yoy DECIMAL(10,2) COMMENT '同比增长率(%)',
    gmv_mom DECIMAL(10,2) COMMENT '环比增长率(%)',
    order_count_yoy DECIMAL(10,2) COMMENT '订单数同比(%)',
    order_count_mom DECIMAL(10,2) COMMENT '订单数环比(%)'
) COMMENT 'GMV趋势报表'
PARTITIONED BY (dt = '${biz_date}')
STORED AS ORC
LOCATION '/warehouse/gmall/ads/ads_gmv_trend'
TBLPROPERTIES('orc.compress'='snappy');

INSERT OVERWRITE TABLE ads_gmv_trend PARTITION(dt = '${biz_date}')
SELECT
    '${biz_date}' AS dt,
    curr.gmv,
    curr.order_count,
    curr.order_user_count,
    curr.avg_order_amount,
    CASE WHEN prev_year.gmv > 0 THEN ROUND((curr.gmv - prev_year.gmv) * 100.0 / prev_year.gmv, 2) ELSE 0 END AS gmv_yoy,
    CASE WHEN prev_day.gmv > 0 THEN ROUND((curr.gmv - prev_day.gmv) * 100.0 / prev_day.gmv, 2) ELSE 0 END AS gmv_mom,
    CASE WHEN prev_year.order_count > 0 THEN ROUND((curr.order_count - prev_year.order_count) * 100.0 / prev_year.order_count, 2) ELSE 0 END AS order_count_yoy,
    CASE WHEN prev_day.order_count > 0 THEN ROUND((curr.order_count - prev_day.order_count) * 100.0 / prev_day.order_count, 2) ELSE 0 END AS order_count_mom
FROM (
    SELECT 
        SUM(gmv) AS gmv,
        SUM(order_count) AS order_count,
        SUM(order_user_count) AS order_user_count,
        AVG(avg_order_amount) AS avg_order_amount
    FROM gmall_dws.dws_gmv_stats
    WHERE dt = '${biz_date}'
) curr
LEFT JOIN (
    SELECT SUM(gmv) AS gmv, SUM(order_count) AS order_count
    FROM gmall_dws.dws_gmv_stats
    WHERE dt = DATE_SUB('${biz_date}', 365)
) prev_year ON 1=1
LEFT JOIN (
    SELECT SUM(gmv) AS gmv, SUM(order_count) AS order_count
    FROM gmall_dws.dws_gmv_stats
    WHERE dt = DATE_SUB('${biz_date}', 1)
) prev_day ON 1=1;

-- ============================================================================
-- 3. 用户留存明细报表（每日留存）
-- ============================================================================
DROP TABLE IF EXISTS ads_user_retention_detail;
CREATE EXTERNAL TABLE ads_user_retention_detail(
    dt STRING COMMENT '统计日期',
    create_date STRING COMMENT '用户注册日期',
    day_1_retention BIGINT COMMENT '1日留存数',
    day_3_retention BIGINT COMMENT '3日留存数',
    day_7_retention BIGINT COMMENT '7日留存数',
    day_14_retention BIGINT COMMENT '14日留存数',
    day_30_retention BIGINT COMMENT '30日留存数',
    total_new_users BIGINT COMMENT '注册用户总数',
    day_1_rate DECIMAL(10,2) COMMENT '1日留存率(%)',
    day_3_rate DECIMAL(10,2) COMMENT '3日留存率(%)',
    day_7_rate DECIMAL(10,2) COMMENT '7日留存率(%)',
    day_14_rate DECIMAL(10,2) COMMENT '14日留存率(%)',
    day_30_rate DECIMAL(10,2) COMMENT '30日留存率(%)'
) COMMENT '用户留存明细报表'
PARTITIONED BY (dt = '${biz_date}')
STORED AS ORC
LOCATION '/warehouse/gmall/ads/ads_user_retention_detail'
TBLPROPERTIES('orc.compress'='snappy');

INSERT OVERWRITE TABLE ads_user_retention_detail PARTITION(dt = '${biz_date}')
SELECT
    '${biz_date}' AS dt,
    create_date,
    SUM(CASE WHEN retention_day = 1 THEN retention_count ELSE 0 END) AS day_1_retention,
    SUM(CASE WHEN retention_day = 3 THEN retention_count ELSE 0 END) AS day_3_retention,
    SUM(CASE WHEN retention_day = 7 THEN retention_count ELSE 0 END) AS day_7_retention,
    SUM(CASE WHEN retention_day = 14 THEN retention_count ELSE 0 END) AS day_14_retention,
    SUM(CASE WHEN retention_day = 30 THEN retention_count ELSE 0 END) AS day_30_retention,
    SUM(new_user_count) AS total_new_users,
    ROUND(SUM(CASE WHEN retention_day = 1 THEN retention_count ELSE 0 END) * 100.0 / SUM(new_user_count), 2) AS day_1_rate,
    ROUND(SUM(CASE WHEN retention_day = 3 THEN retention_count ELSE 0 END) * 100.0 / SUM(new_user_count), 2) AS day_3_rate,
    ROUND(SUM(CASE WHEN retention_day = 7 THEN retention_count ELSE 0 END) * 100.0 / SUM(new_user_count), 2) AS day_7_rate,
    ROUND(SUM(CASE WHEN retention_day = 14 THEN retention_count ELSE 0 END) * 100.0 / SUM(new_user_count), 2) AS day_14_rate,
    ROUND(SUM(CASE WHEN retention_day = 30 THEN retention_count ELSE 0 END) * 100.0 / SUM(new_user_count), 2) AS day_30_rate
FROM gmall_ads.ads_user_retention
WHERE create_date BETWEEN DATE_SUB('${biz_date}', 90) AND '${biz_date}'
GROUP BY create_date;

-- ============================================================================
-- 4. 商品复购分析报表
-- ============================================================================
DROP TABLE IF EXISTS ads_sku_repurchase_analysis;
CREATE EXTERNAL TABLE ads_sku_repurchase_analysis(
    dt STRING COMMENT '统计日期',
    sku_id STRING COMMENT 'SKU ID',
    sku_name STRING COMMENT 'SKU名称',
    category3_id STRING COMMENT '三级类目ID',
    category3_name STRING COMMENT '三级类目名称',
    total_order_count BIGINT COMMENT '总订单数',
    repurchase_order_count BIGINT COMMENT '复购订单数',
    repurchase_user_count BIGINT COMMENT '复购用户数',
    total_user_count BIGINT COMMENT '总购买用户数',
    repurchase_rate DECIMAL(10,2) COMMENT '复购率(%)',
    avg_repurchase_times DECIMAL(10,2) COMMENT '平均复购次数',
    repurchase_amount DECIMAL(16,2) COMMENT '复购金额'
) COMMENT '商品复购分析报表'
PARTITIONED BY (dt = '${biz_date}')
STORED AS ORC
LOCATION '/warehouse/gmall/ads/ads_sku_repurchase_analysis'
TBLPROPERTIES('orc.compress'='snappy');

INSERT OVERWRITE TABLE ads_sku_repurchase_analysis PARTITION(dt = '${biz_date}')
SELECT
    '${biz_date}' AS dt,
    sku_id,
    sku_name,
    category3_id,
    category3_name,
    SUM(order_count) AS total_order_count,
    SUM(repurchase_order_count) AS repurchase_order_count,
    COUNT(DISTINCT CASE WHEN repurchase_count >= 2 THEN user_id END) AS repurchase_user_count,
    COUNT(DISTINCT user_id) AS total_user_count,
    ROUND(COUNT(DISTINCT CASE WHEN repurchase_count >= 2 THEN user_id END) * 100.0 / COUNT(DISTINCT user_id), 2) AS repurchase_rate,
    AVG(repurchase_count) AS avg_repurchase_times,
    SUM(repurchase_amount) AS repurchase_amount
FROM (
    SELECT
        sku_id,
        sku_name,
        category3_id,
        category3_name,
        user_id,
        COUNT(order_id) AS order_count,
        COUNT(DISTINCT CASE WHEN row_num > 1 THEN order_id END) AS repurchase_order_count,
        COUNT(DISTINCT order_id) AS repurchase_count,
        SUM(order_amount) AS repurchase_amount
    FROM (
        SELECT
            sku_id,
            sku_name,
            category3_id,
            category3_name,
            user_id,
            order_id,
            order_amount,
            ROW_NUMBER() OVER (PARTITION BY sku_id, user_id ORDER BY create_time) AS row_num
        FROM gmall_dwd.dwd_order_detail
        WHERE dt BETWEEN DATE_SUB('${biz_date}', 30) AND '${biz_date}'
    ) t
    GROUP BY sku_id, sku_name, category3_id, category3_name, user_id
) sku_user_stats
GROUP BY sku_id, sku_name, category3_id, category3_name;

-- ============================================================================
-- 5. 活动效果分析报表
-- ============================================================================
DROP TABLE IF EXISTS ads_campaign_effect;
CREATE EXTERNAL TABLE ads_campaign_effect(
    dt STRING COMMENT '统计日期',
    campaign_id STRING COMMENT '活动ID',
    campaign_name STRING COMMENT '活动名称',
    start_date STRING COMMENT '活动开始日期',
    end_date STRING COMMENT '活动结束日期',
    channel STRING COMMENT '渠道',
    exposure_count BIGINT COMMENT '曝光量',
    click_count BIGINT COMMENT '点击量',
    click_rate DECIMAL(10,2) COMMENT '点击率(%)',
    order_count BIGINT COMMENT '订单数',
    order_amount DECIMAL(16,2) COMMENT '订单金额',
    conversion_rate DECIMAL(10,2) COMMENT '转化率(%)',
    roi DECIMAL(10,2) COMMENT '投资回报率',
    cost DECIMAL(16,2) COMMENT '活动成本'
) COMMENT '活动效果分析报表'
PARTITIONED BY (dt = '${biz_date}')
STORED AS ORC
LOCATION '/warehouse/gmall/ads/ads_campaign_effect'
TBLPROPERTIES('orc.compress'='snappy');

INSERT OVERWRITE TABLE ads_campaign_effect PARTITION(dt = '${biz_date}')
SELECT
    '${biz_date}' AS dt,
    campaign_id,
    campaign_name,
    start_date,
    end_date,
    channel,
    SUM(exposure_count) AS exposure_count,
    SUM(click_count) AS click_count,
    ROUND(SUM(click_count) * 100.0 / SUM(exposure_count), 2) AS click_rate,
    SUM(order_count) AS order_count,
    SUM(order_amount) AS order_amount,
    ROUND(SUM(order_count) * 100.0 / SUM(click_count), 2) AS conversion_rate,
    CASE WHEN SUM(cost) > 0 THEN ROUND(SUM(order_amount) / SUM(cost), 2) ELSE 0 END AS roi,
    SUM(cost) AS cost
FROM gmall_dws.dws_campaign_stats
WHERE dt = '${biz_date}'
GROUP BY campaign_id, campaign_name, start_date, end_date, channel;

-- ============================================================================
-- 6. 退款分析报表
-- ============================================================================
DROP TABLE IF EXISTS ads_refund_analysis;
CREATE EXTERNAL TABLE ads_refund_analysis(
    dt STRING COMMENT '统计日期',
    refund_count BIGINT COMMENT '退款订单数',
    refund_amount DECIMAL(16,2) COMMENT '退款金额',
    refund_user_count BIGINT COMMENT '退款用户数',
    order_count BIGINT COMMENT '总订单数',
    order_amount DECIMAL(16,2) COMMENT '总订单金额',
    refund_rate DECIMAL(10,2) COMMENT '退款率(%)',
    avg_refund_days DECIMAL(10,2) COMMENT '平均退款时长(天)',
    top_refund_category STRING COMMENT '退款最多类目',
    refund_reason_distribution STRING COMMENT '退款原因分布(Json)'
) COMMENT '退款分析报表'
PARTITIONED BY (dt = '${biz_date}')
STORED AS ORC
LOCATION '/warehouse/gmall/ads/ads_refund_analysis'
TBLPROPERTIES('orc.compress'='snappy');

INSERT OVERWRITE TABLE ads_refund_analysis PARTITION(dt = '${biz_date}')
SELECT
    '${biz_date}' AS dt,
    refund.refund_count,
    refund.refund_amount,
    refund.refund_user_count,
    order.order_count,
    order.order_amount,
    ROUND(refund.refund_count * 100.0 / order.order_count, 2) AS refund_rate,
    refund.avg_refund_days,
    refund.top_refund_category,
    refund.refund_reason_distribution
FROM (
    SELECT
        COUNT(DISTINCT order_id) AS refund_count,
        SUM(refund_amount) AS refund_amount,
        COUNT(DISTINCT user_id) AS refund_user_count,
        AVG(DATEDIFF(refund_time, create_time)) AS avg_refund_days,
        MAX(category_name) AS top_refund_category,
        '' AS refund_reason_distribution
    FROM gmall_dwd.dwd_refund_info
    WHERE dt = '${biz_date}'
) refund
LEFT JOIN (
    SELECT COUNT(*) AS order_count, SUM(total_amount) AS order_amount
    FROM gmall_dwd.dwd_order_info
    WHERE dt = '${biz_date}'
) order ON 1=1;

-- ============================================================================
-- 7. 流量来源分析报表
-- ============================================================================
DROP TABLE IF EXISTS ads_traffic_source;
CREATE EXTERNAL TABLE ads_traffic_source(
    dt STRING COMMENT '统计日期',
    source_type STRING COMMENT '来源类型(直接/搜索/社交/广告/邮件)',
    source_name STRING COMMENT '来源名称',
    channel STRING COMMENT '渠道',
    pv BIGINT COMMENT '页面浏览量',
    uv BIGINT COMMENT '独立访客数',
    bounce_rate DECIMAL(10,2) COMMENT '跳出率(%)',
    avg_session_duration DECIMAL(10,2) COMMENT '平均会话时长(秒)',
    conversion_count BIGINT COMMENT '转化数',
    conversion_rate DECIMAL(10,2) COMMENT '转化率(%)'
) COMMENT '流量来源分析报表'
PARTITIONED BY (dt = '${biz_date}')
STORED AS ORC
LOCATION '/warehouse/gmall/ads/ads_traffic_source'
TBLPROPERTIES('orc.compress'='snappy');

INSERT OVERWRITE TABLE ads_traffic_source PARTITION(dt = '${biz_date}')
SELECT
    '${biz_date}' AS dt,
    source_type,
    source_name,
    channel,
    SUM(pv) AS pv,
    COUNT(DISTINCT user_id) AS uv,
    ROUND(SUM(bounce_count) * 100.0 / SUM(session_count), 2) AS bounce_rate,
    AVG(session_duration) AS avg_session_duration,
    SUM(conversion_count) AS conversion_count,
    ROUND(SUM(conversion_count) * 100.0 / COUNT(DISTINCT user_id), 2) AS conversion_rate
FROM gmall_dws.dws_traffic_source_stats
WHERE dt = '${biz_date}'
GROUP BY source_type, source_name, channel;

-- ============================================================================
-- 8. 实时大屏指标表（用于可视化展示）
-- ============================================================================
DROP TABLE IF EXISTS ads_realtime_dashboard;
CREATE EXTERNAL TABLE ads_realtime_dashboard(
    dt STRING COMMENT '统计日期',
    hour STRING COMMENT '统计小时',
    current_gmv DECIMAL(16,2) COMMENT '当前GMV',
    today_gmv DECIMAL(16,2) COMMENT '今日累计GMV',
    current_order_count BIGINT COMMENT '当前小时订单数',
    today_order_count BIGINT COMMENT '今日累计订单数',
    current_user_count BIGINT COMMENT '当前小时用户数',
    today_user_count BIGINT COMMENT '今日累计用户数',
    current_conversion_rate DECIMAL(10,2) COMMENT '当前转化率',
    today_conversion_rate DECIMAL(10,2) COMMENT '今日转化率',
    gmv_target DECIMAL(16,2) COMMENT 'GMV目标',
    gmv_progress DECIMAL(10,2) COMMENT 'GMV完成进度(%)',
    peak_hour STRING COMMENT '峰值时段',
    hot_sku STRING COMMENT '热销商品',
    hot_category STRING COMMENT '热销类目'
) COMMENT '实时大屏指标表'
PARTITIONED BY (dt = '${biz_date}')
STORED AS ORC
LOCATION '/warehouse/gmall/ads/ads_realtime_dashboard'
TBLPROPERTIES('orc.compress'='snappy');

INSERT OVERWRITE TABLE ads_realtime_dashboard PARTITION(dt = '${biz_date}')
SELECT
    '${biz_date}' AS dt,
    HOUR(CURRENT_TIMESTAMP()) AS hour,
    current.gmv AS current_gmv,
    today.total_gmv AS today_gmv,
    current.order_count AS current_order_count,
    today.total_order_count AS today_order_count,
    current.user_count AS current_user_count,
    today.total_user_count AS today_user_count,
    current.conversion_rate AS current_conversion_rate,
    today.conversion_rate AS today_conversion_rate,
    10000000.00 AS gmv_target,
    ROUND(today.total_gmv * 100.0 / 10000000.00, 2) AS gmv_progress,
    today.peak_hour AS peak_hour,
    today.hot_sku AS hot_sku,
    today.hot_category AS hot_category
FROM (
    SELECT
        SUM(gmv) AS gmv,
        SUM(order_count) AS order_count,
        SUM(order_user_count) AS user_count,
        AVG(conversion_rate) AS conversion_rate
    FROM gmall_dws.dws_gmv_stats
    WHERE dt = '${biz_date}'
      AND HOUR(create_time) = HOUR(CURRENT_TIMESTAMP())
) current,
(
    SELECT
        SUM(gmv) AS total_gmv,
        SUM(order_count) AS total_order_count,
        SUM(order_user_count) AS total_user_count,
        AVG(conversion_rate) AS conversion_rate,
        '' AS peak_hour,
        '' AS hot_sku,
        '' AS hot_category
    FROM gmall_dws.dws_gmv_stats
    WHERE dt = '${biz_date}'
) today;
-- ============================================================================
-- ETL脚本：DWS层 -> ADS层（应用数据层）
-- 功能：计算最终业务指标，为报表和大屏提供数据
-- 作者：电商数仓项目
-- ============================================================================

-- ============================================================================
-- 1. GMV日报表（ADS_GMV_DAY）
-- ============================================================================
INSERT OVERWRITE TABLE gmall_ads.ads_gmv_day PARTITION(dt = '${biz_date}')
SELECT
    '${biz_date}' AS date_id,
    recent_days,
    SUM(gmv) AS gmv,
    SUM(order_count) AS order_count,
    SUM(order_user_count) AS order_user_count,
    SUM(goods_amount) AS goods_amount,
    SUM(feight_fee) AS feight_fee,
    SUM(discount_amount) AS discount_amount,
    AVG(avg_order_amount) AS avg_order_amount,
    -- 支付相关
    SUM(paid_gmv) AS payment_amount,
    SUM(paid_order_count) AS payment_count,
    SUM(completed_gmv) AS completed_amount,
    SUM(completed_order_count) AS completed_count,
    FROM_UNIXTIME(UNIX_TIMESTAMP()) AS etl_time
FROM (
    -- 1天
    SELECT
        1 AS recent_days,
        gmv,
        order_count,
        order_user_count,
        goods_amount,
        feight_fee,
        discount_amount,
        avg_order_amount,
        paid_gmv,
        paid_order_count,
        completed_gmv,
        completed_order_count
    FROM gmall_dws.dws_gmv_stats
    WHERE dt = '${biz_date}'

    UNION ALL

    -- 7天
    SELECT
        7 AS recent_days,
        SUM(gmv) AS gmv,
        SUM(order_count) AS order_count,
        SUM(order_user_count) AS order_user_count,
        SUM(goods_amount) AS goods_amount,
        SUM(feight_fee) AS feight_fee,
        SUM(discount_amount) AS discount_amount,
        AVG(avg_order_amount) AS avg_order_amount,
        SUM(paid_gmv) AS paid_gmv,
        SUM(paid_order_count) AS paid_order_count,
        SUM(completed_gmv) AS completed_gmv,
        SUM(completed_order_count) AS completed_order_count
    FROM gmall_dws.dws_gmv_stats
    WHERE dt BETWEEN DATE_SUB('${biz_date}', 6) AND '${biz_date}'
    GROUP BY date_id

    UNION ALL

    -- 30天
    SELECT
        30 AS recent_days,
        SUM(gmv) AS gmv,
        SUM(order_count) AS order_count,
        SUM(order_user_count) AS order_user_count,
        SUM(goods_amount) AS goods_amount,
        SUM(feight_fee) AS feight_fee,
        SUM(discount_amount) AS discount_amount,
        AVG(avg_order_amount) AS avg_order_amount,
        SUM(paid_gmv) AS paid_gmv,
        SUM(paid_order_count) AS paid_order_count,
        SUM(completed_gmv) AS completed_gmv,
        SUM(completed_order_count) AS completed_order_count
    FROM gmall_dws.dws_gmv_stats
    WHERE dt BETWEEN DATE_SUB('${biz_date}', 29) AND '${biz_date}'
    GROUP BY date_id
) gmv_stats
GROUP BY recent_days;

-- ============================================================================
-- 2. 用户留存报表（ADS_USER_RETENTION）
-- ============================================================================
INSERT OVERWRITE TABLE gmall_ads.ads_user_retention PARTITION(dt = '${biz_date}')
SELECT
    '${biz_date}' AS date_id,
    create_date,
    retention_day,
    new_user_count,
    retention_count,
    ROUND(retention_count * 100.0 / new_user_count, 2) AS retention_rate,
    FROM_UNIXTIME(UNIX_TIMESTAMP()) AS etl_time
FROM (
    SELECT
        user.create_date,
        1 AS retention_day,
        COUNT(*) AS new_user_count,
        COUNT(DISTINCT CASE WHEN stat.order_count > 0 THEN user.user_id END) AS retention_count
    FROM (
        SELECT user_id, MIN(dt) AS create_date
        FROM gmall_dwd.dwd_order_info
        GROUP BY user_id
        HAVING MIN(dt) >= DATE_SUB('${biz_date}', 30)
    ) user
    JOIN gmall_dws.dws_user_action_stats stat ON user.user_id = stat.user_id
        AND stat.dt = '${biz_date}'
    WHERE user.create_date = DATE_SUB('${biz_date}', 0)
    GROUP BY user.create_date

    UNION ALL

    SELECT
        user.create_date,
        7 AS retention_day,
        COUNT(*) AS new_user_count,
        COUNT(DISTINCT CASE WHEN stat.order_count > 0 THEN user.user_id END) AS retention_count
    FROM (
        SELECT user_id, MIN(dt) AS create_date
        FROM gmall_dwd.dwd_order_info
        GROUP BY user_id
        HAVING MIN(dt) >= DATE_SUB('${biz_date}', 30)
    ) user
    JOIN gmall_dws.dws_user_action_stats stat ON user.user_id = stat.user_id
        AND stat.dt = '${biz_date}'
    WHERE user.create_date = DATE_SUB('${biz_date}', 6)
    GROUP BY user.create_date

    UNION ALL

    SELECT
        user.create_date,
        30 AS retention_day,
        COUNT(*) AS new_user_count,
        COUNT(DISTINCT CASE WHEN stat.order_count > 0 THEN user.user_id END) AS retention_count
    FROM (
        SELECT user_id, MIN(dt) AS create_date
        FROM gmall_dwd.dwd_order_info
        GROUP BY user_id
        HAVING MIN(dt) >= DATE_SUB('${biz_date}', 30)
    ) user
    JOIN gmall_dws.dws_user_action_stats stat ON user.user_id = stat.user_id
        AND stat.dt = '${biz_date}'
    WHERE user.create_date = DATE_SUB('${biz_date}', 29)
    GROUP BY user.create_date
) retention;

-- ============================================================================
-- 3. 商品销售排行（ADS_SKU_SALES_RANK）
-- ============================================================================
INSERT OVERWRITE TABLE gmall_ads.ads_sku_sales_rank PARTITION(dt = '${biz_date}')
SELECT
    '${biz_date}' AS date_id,
    recent_days,
    sku_id,
    sku_name,
    category1_name,
    category2_name,
    category3_name,
    tm_name,
    order_count,
    order_num,
    order_amount,
    ROW_NUMBER() OVER (PARTITION BY recent_days ORDER BY order_amount DESC) AS rank,
    FROM_UNIXTIME(UNIX_TIMESTAMP()) AS etl_time
FROM (
    SELECT
        1 AS recent_days,
        sku_id,
        sku_name,
        category1_name,
        category2_name,
        category3_name,
        tm_name,
        SUM(order_count) AS order_count,
        SUM(order_num) AS order_num,
        SUM(order_amount) AS order_amount
    FROM gmall_dws.dws_sku_stats
    WHERE dt = '${biz_date}'
    GROUP BY sku_id, sku_name, category1_name, category2_name, category3_name, tm_name

    UNION ALL

    SELECT
        7 AS recent_days,
        sku_id,
        sku_name,
        category1_name,
        category2_name,
        category3_name,
        tm_name,
        SUM(order_count) AS order_count,
        SUM(order_num) AS order_num,
        SUM(order_amount) AS order_amount
    FROM gmall_dws.dws_sku_stats
    WHERE dt BETWEEN DATE_SUB('${biz_date}', 6) AND '${biz_date}'
    GROUP BY sku_id, sku_name, category1_name, category2_name, category3_name, tm_name

    UNION ALL

    SELECT
        30 AS recent_days,
        sku_id,
        sku_name,
        category1_name,
        category2_name,
        category3_name,
        tm_name,
        SUM(order_count) AS order_count,
        SUM(order_num) AS order_num,
        SUM(order_amount) AS order_amount
    FROM gmall_dws.dws_sku_stats
    WHERE dt BETWEEN DATE_SUB('${biz_date}', 29) AND '${biz_date}'
    GROUP BY sku_id, sku_name, category1_name, category2_name, category3_name, tm_name
) sku_sales;

-- ============================================================================
-- 4. 转化率分析（ADS_CONVERSION_RATE）
-- ============================================================================
INSERT OVERWRITE TABLE gmall_ads.ads_conversion_rate PARTITION(dt = '${biz_date}')
SELECT
    '${biz_date}' AS date_id,
    recent_days,
    visit_count,
    cart_count,
    order_count,
    payment_count,
    ROUND(cart_count * 100.0 / visit_count, 2) AS visit_to_cart_rate,
    ROUND(order_count * 100.0 / cart_count, 2) AS cart_to_order_rate,
    ROUND(payment_count * 100.0 / order_count, 2) AS order_to_payment_rate,
    ROUND(payment_count * 100.0 / visit_count, 2) AS total_conversion_rate,
    FROM_UNIXTIME(UNIX_TIMESTAMP()) AS etl_time
FROM (
    SELECT
        1 AS recent_days,
        SUM(page_view_count) AS visit_count,
        SUM(cart_add_count) AS cart_count,
        SUM(order_count) AS order_count,
        SUM(payment_count) AS payment_count
    FROM gmall_dws.dws_user_action_stats
    WHERE dt = '${biz_date}'

    UNION ALL

    SELECT
        7 AS recent_days,
        SUM(page_view_count) AS visit_count,
        SUM(cart_add_count) AS cart_count,
        SUM(order_count) AS order_count,
        SUM(payment_count) AS payment_count
    FROM gmall_dws.dws_user_action_stats
    WHERE dt BETWEEN DATE_SUB('${biz_date}', 6) AND '${biz_date}'

    UNION ALL

    SELECT
        30 AS recent_days,
        SUM(page_view_count) AS visit_count,
        SUM(cart_add_count) AS cart_count,
        SUM(order_count) AS order_count,
        SUM(payment_count) AS payment_count
    FROM gmall_dws.dws_user_action_stats
    WHERE dt BETWEEN DATE_SUB('${biz_date}', 29) AND '${biz_date}'
) conversion;

-- ============================================================================
-- 5. 用户复购率（ADS_USER_REPURCHASE_RATE）
-- ============================================================================
INSERT OVERWRITE TABLE gmall_ads.ads_user_repurchase_rate PARTITION(dt = '${biz_date}')
SELECT
    '${biz_date}' AS date_id,
    recent_days,
    total_user_count,
    repeat_user_count,
    ROUND(repeat_user_count * 100.0 / total_user_count, 2) AS repurchase_rate,
    AVG(order_count) AS avg_order_per_user,
    FROM_UNIXTIME(UNIX_TIMESTAMP()) AS etl_time
FROM (
    SELECT
        7 AS recent_days,
        COUNT(DISTINCT user_id) AS total_user_count,
        COUNT(DISTINCT CASE WHEN order_count >= 2 THEN user_id END) AS repeat_user_count,
        AVG(order_count) AS avg_order_per_user
    FROM (
        SELECT user_id, SUM(order_count) AS order_count
        FROM gmall_dws.dws_user_action_stats
        WHERE dt BETWEEN DATE_SUB('${biz_date}', 6) AND '${biz_date}'
        GROUP BY user_id
    ) user_stats

    UNION ALL

    SELECT
        30 AS recent_days,
        COUNT(DISTINCT user_id) AS total_user_count,
        COUNT(DISTINCT CASE WHEN order_count >= 2 THEN user_id END) AS repeat_user_count,
        AVG(order_count) AS avg_order_per_user
    FROM (
        SELECT user_id, SUM(order_count) AS order_count
        FROM gmall_dws.dws_user_action_stats
        WHERE dt BETWEEN DATE_SUB('${biz_date}', 29) AND '${biz_date}'
        GROUP BY user_id
    ) user_stats
) repurchase;

-- ============================================================================
-- 6. 用户活跃报表（ADS_USER_ACTIVITY）
-- ============================================================================
INSERT OVERWRITE TABLE gmall_ads.ads_user_activity PARTITION(dt = '${biz_date}')
SELECT
    '${biz_date}' AS date_id,
    recent_days,
    dau AS daily_active_users,
    wau AS weekly_active_users,
    mau AS monthly_active_users,
    ROUND(dau * 100.0 / mau, 2) AS dau_to_mau_rate,
    ROUND(wau * 100.0 / mau, 2) AS wau_to_mau_rate,
    FROM_UNIXTIME(UNIX_TIMESTAMP()) AS etl_time
FROM (
    SELECT
        COUNT(DISTINCT user_id) AS dau
    FROM gmall_dws.dws_user_action_stats
    WHERE dt = '${biz_date}'
      AND (page_view_count > 0 OR cart_add_count > 0 OR favor_add_count > 0
           OR order_count > 0 OR payment_count > 0)
) daily,
(
    SELECT
        COUNT(DISTINCT user_id) AS wau
    FROM gmall_dws.dws_user_action_stats
    WHERE dt BETWEEN DATE_SUB('${biz_date}', 6) AND '${biz_date}'
      AND (page_view_count > 0 OR cart_add_count > 0 OR favor_add_count > 0
           OR order_count > 0 OR payment_count > 0)
) weekly,
(
    SELECT
        COUNT(DISTINCT user_id) AS mau
    FROM gmall_dws.dws_user_action_stats
    WHERE dt BETWEEN DATE_SUB('${biz_date}', 29) AND '${biz_date}'
      AND (page_view_count > 0 OR cart_add_count > 0 OR favor_add_count > 0
           OR order_count > 0 OR payment_count > 0)
) monthly,
(SELECT 1 AS recent_days UNION SELECT 7 AS recent_days UNION SELECT 30 AS recent_days) days;

-- ============================================================================
-- 7. 类目销售分析（ADS_CATEGORY_SALE_ANALYSIS）
-- ============================================================================
INSERT OVERWRITE TABLE gmall_ads.ads_category_sale_analysis PARTITION(dt = '${biz_date}')
SELECT
    '${biz_date}' AS date_id,
    category1_id,
    category1_name,
    category2_id,
    category2_name,
    recent_days,
    SUM(order_count) AS order_count,
    SUM(order_num) AS sale_num,
    SUM(order_amount) AS sale_amount,
    AVG(avg_price) AS avg_price,
    SUM(payment_count) AS payment_count,
    SUM(payment_amount) AS payment_amount,
    SUM(refund_count) AS refund_count,
    SUM(refund_amount) AS refund_amount,
    ROUND(SUM(payment_amount) * 100.0 / SUM(order_amount), 2) AS payment_rate,
    ROUND(SUM(refund_amount) * 100.0 / SUM(payment_amount), 2) AS refund_rate,
    FROM_UNIXTIME(UNIX_TIMESTAMP()) AS etl_time
FROM (
    SELECT
        1 AS recent_days,
        category1_id,
        category1_name,
        category2_id,
        category2_name,
        order_count,
        order_num,
        order_amount,
        avg_price,
        payment_count,
        payment_amount,
        refund_count,
        refund_amount
    FROM gmall_dws.dws_sku_stats
    WHERE dt = '${biz_date}'

    UNION ALL

    SELECT
        7 AS recent_days,
        category1_id,
        category1_name,
        category2_id,
        category2_name,
        SUM(order_count),
        SUM(order_num),
        SUM(order_amount),
        AVG(avg_price),
        SUM(payment_count),
        SUM(payment_amount),
        SUM(refund_count),
        SUM(refund_amount)
    FROM gmall_dws.dws_sku_stats
    WHERE dt BETWEEN DATE_SUB('${biz_date}', 6) AND '${biz_date}'
    GROUP BY category1_id, category1_name, category2_id, category2_name

    UNION ALL

    SELECT
        30 AS recent_days,
        category1_id,
        category1_name,
        category2_id,
        category2_name,
        SUM(order_count),
        SUM(order_num),
        SUM(order_amount),
        AVG(avg_price),
        SUM(payment_count),
        SUM(payment_amount),
        SUM(refund_count),
        SUM(refund_amount)
    FROM gmall_dws.dws_sku_stats
    WHERE dt BETWEEN DATE_SUB('${biz_date}', 29) AND '${biz_date}'
    GROUP BY category1_id, category1_name, category2_id, category2_name
) category_stats
GROUP BY category1_id, category1_name, category2_id, category2_name, recent_days;

-- ============================================================================
-- 8. 地区销售报表（ADS_PROVINCE_SALE）
-- ============================================================================
INSERT OVERWRITE TABLE gmall_ads.ads_province_sale PARTITION(dt = '${biz_date}')
SELECT
    '${biz_date}' AS date_id,
    province_id,
    province_name,
    region_id,
    region_name,
    recent_days,
    SUM(order_count) AS order_count,
    SUM(order_user_count) AS order_user_count,
    SUM(gmv) AS gmv,
    AVG(avg_order_amount) AS avg_order_amount,
    SUM(discount_amount) AS discount_amount,
    ROW_NUMBER() OVER (PARTITION BY recent_days ORDER BY gmv DESC) AS rank,
    FROM_UNIXTIME(UNIX_TIMESTAMP()) AS etl_time
FROM (
    SELECT
        1 AS recent_days,
        province_id,
        province_name,
        region_id,
        region_name,
        order_count,
        order_user_count,
        gmv,
        avg_order_amount,
        discount_amount
    FROM gmall_dws.dws_province_stats
    WHERE dt = '${biz_date}'

    UNION ALL

    SELECT
        7 AS recent_days,
        province_id,
        province_name,
        region_id,
        region_name,
        SUM(order_count),
        SUM(order_user_count),
        SUM(gmv),
        AVG(avg_order_amount),
        SUM(discount_amount)
    FROM gmall_dws.dws_province_stats
    WHERE dt BETWEEN DATE_SUB('${biz_date}', 6) AND '${biz_date}'
    GROUP BY province_id, province_name, region_id, region_name

    UNION ALL

    SELECT
        30 AS recent_days,
        province_id,
        province_name,
        region_id,
        region_name,
        SUM(order_count),
        SUM(order_user_count),
        SUM(gmv),
        AVG(avg_order_amount),
        SUM(discount_amount)
    FROM gmall_dws.dws_province_stats
    WHERE dt BETWEEN DATE_SUB('${biz_date}', 29) AND '${biz_date}'
    GROUP BY province_id, province_name, region_id, region_name
) province_stats
GROUP BY province_id, province_name, region_id, region_name, recent_days;

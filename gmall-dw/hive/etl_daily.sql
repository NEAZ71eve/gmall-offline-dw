
-- ============================================
-- 每日ETL脚本
-- 参数: dt = 'YYYY-MM-DD'
-- ============================================

SET hive.exec.dynamic.partition.mode=nonstrict;
SET hivevar dt='${dt}';

-- ============================================
-- 步骤1: ODS -> DWD 清洗
-- ============================================

-- DWD订单明细表
INSERT OVERWRITE TABLE gmall_dwd.dwd_order_detail PARTITION(dt='${dt}')
SELECT 
    od.id,
    od.order_id,
    oi.user_id,
    od.sku_id,
    oi.province_id,
    od.create_time,
    od.sku_num,
    od.order_price * od.sku_num AS original_amount,
    0 AS activity_reduce,
    0 AS coupon_reduce,
    od.order_price * od.sku_num AS final_amount,
    DATE_FORMAT(od.create_time, 'yyyy-MM-dd') AS date_id
FROM gmall_ods.ods_order_detail od
JOIN gmall_ods.ods_order_info oi 
ON od.order_id = oi.id
WHERE od.dt='${dt}' AND oi.dt='${dt}';

-- DWD订单表
INSERT OVERWRITE TABLE gmall_dwd.dwd_order_info PARTITION(dt='${dt}')
SELECT 
    id,
    user_id,
    province_id,
    order_status,
    total_amount,
    payment_way,
    create_time,
    DATE_FORMAT(create_time, 'yyyy-MM-dd') AS date_id
FROM gmall_ods.ods_order_info
WHERE dt='${dt}';

-- ============================================
-- 步骤2: DWD -> DWS 汇总
-- ============================================

-- DWS订单每日汇总
INSERT OVERWRITE TABLE gmall_dws.dws_order_day PARTITION(dt='${dt}')
SELECT 
    date_id,
    COUNT(DISTINCT order_id) AS order_count,
    COUNT(DISTINCT user_id) AS order_user_count,
    SUM(final_amount) AS order_amount,
    0 AS payment_count,
    0 AS payment_user_count,
    0 AS payment_amount
FROM gmall_dwd.dwd_order_detail
WHERE dt='${dt}'
GROUP BY date_id;

-- DWS用户每日汇总
INSERT OVERWRITE TABLE gmall_dws.dws_user_day PARTITION(dt='${dt}')
SELECT 
    user_id,
    date_id,
    COUNT(DISTINCT order_id) AS order_count,
    SUM(final_amount) AS order_amount,
    0 AS payment_count,
    0 AS payment_amount
FROM gmall_dwd.dwd_order_detail
WHERE dt='${dt}'
GROUP BY user_id, date_id;

-- DWS商品每日汇总
INSERT OVERWRITE TABLE gmall_dws.dws_sku_day PARTITION(dt='${dt}')
SELECT 
    sku_id,
    date_id,
    COUNT(DISTINCT order_id) AS order_count,
    SUM(sku_num) AS order_num,
    SUM(final_amount) AS order_amount
FROM gmall_dwd.dwd_order_detail
WHERE dt='${dt}'
GROUP BY sku_id, date_id;

-- ============================================
-- 步骤3: DWS -> ADS 指标计算
-- ============================================

-- ADS GMV日报
INSERT OVERWRITE TABLE gmall_ads.ads_gmv_day
SELECT 
    '${dt}' AS dt,
    1 AS recent_days,
    SUM(order_amount) AS gmv,
    SUM(order_count) AS order_count,
    SUM(order_user_count) AS order_user_count,
    SUM(payment_amount) AS payment_amount,
    SUM(payment_user_count) AS payment_user_count
FROM gmall_dws.dws_order_day
WHERE dt='${dt}'
UNION
SELECT 
    '${dt}' AS dt,
    7 AS recent_days,
    SUM(order_amount) AS gmv,
    SUM(order_count) AS order_count,
    SUM(order_user_count) AS order_user_count,
    SUM(payment_amount) AS payment_amount,
    SUM(payment_user_count) AS payment_user_count
FROM gmall_dws.dws_order_day
WHERE dt >= DATE_SUB('${dt}', 6) AND dt <= '${dt}'
UNION
SELECT 
    '${dt}' AS dt,
    30 AS recent_days,
    SUM(order_amount) AS gmv,
    SUM(order_count) AS order_count,
    SUM(order_user_count) AS order_user_count,
    SUM(payment_amount) AS payment_amount,
    SUM(payment_user_count) AS payment_user_count
FROM gmall_dws.dws_order_day
WHERE dt >= DATE_SUB('${dt}', 29) AND dt <= '${dt}';

-- ADS商品销售排行
INSERT OVERWRITE TABLE gmall_ads.ads_sku_sales_rank
SELECT 
    '${dt}' AS dt,
    7 AS recent_days,
    sku_id,
    sku_name,
    order_count,
    order_amount,
    ROW_NUMBER() OVER(ORDER BY order_amount DESC) AS rank
FROM (
    SELECT 
        sd.sku_id,
        ds.sku_name,
        SUM(sd.order_count) AS order_count,
        SUM(sd.order_amount) AS order_amount
    FROM gmall_dws.dws_sku_day sd
    LEFT JOIN gmall_dim.dim_sku ds ON sd.sku_id = ds.id
    WHERE sd.dt >= DATE_SUB('${dt}', 6) AND sd.dt <= '${dt}'
    GROUP BY sd.sku_id, ds.sku_name
) t
ORDER BY order_amount DESC
LIMIT 100;

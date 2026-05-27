
-- ============================================
-- DWS到ADS层：交易统计主题：交易综合统计ETL脚本
-- ============================================

-- 设置动态分区模式
set hive.exec.dynamic.partition.mode=nonstrict;

-- 交易综合统计
with
-- 最近1日
stats_1d as (
    select
        '${dt}' dt,
        1 recent_days,
        sum(order_count) order_count,
        count(distinct user_id) order_user_count,
        sum(order_original_amount) order_original_amount,
        sum(order_activity_reduce_amount) order_activity_reduce_amount,
        sum(order_coupon_reduce_amount) order_coupon_reduce_amount,
        sum(order_total_amount) order_total_amount
    from dws_ecommerce.dws_trade_user_order_1d
    where dt='${dt}'
),
-- 最近7日
stats_7d as (
    select
        '${dt}' dt,
        7 recent_days,
        sum(order_count) order_count,
        count(distinct user_id) order_user_count,
        sum(order_original_amount) order_original_amount,
        sum(order_activity_reduce_amount) order_activity_reduce_amount,
        sum(order_coupon_reduce_amount) order_coupon_reduce_amount,
        sum(order_total_amount) order_total_amount
    from dws_ecommerce.dws_trade_user_order_1d
    where dt&gt;=date_sub('${dt}',6) and dt&lt;='${dt}'
),
-- 最近30日
stats_30d as (
    select
        '${dt}' dt,
        30 recent_days,
        sum(order_count) order_count,
        count(distinct user_id) order_user_count,
        sum(order_original_amount) order_original_amount,
        sum(order_activity_reduce_amount) order_activity_reduce_amount,
        sum(order_coupon_reduce_amount) order_coupon_reduce_amount,
        sum(order_total_amount) order_total_amount
    from dws_ecommerce.dws_trade_user_order_1d
    where dt&gt;=date_sub('${dt}',29) and dt&lt;='${dt}'
)
-- 插入到ADS表
insert overwrite table ads_ecommerce.ads_trade_stats
select * from stats_1d
union
select * from stats_7d
union
select * from stats_30d;


-- ============================================
-- DWD到DWS层：交易域用户商品粒度订单最近1日汇总表ETL脚本
-- ============================================

-- 设置动态分区模式
set hive.exec.dynamic.partition.mode=nonstrict;

-- 交易域用户商品粒度订单最近1日汇总表
with
-- 统计每日的订单粒度数据
order_detail as (
    select
        user_id,
        sku_id,
        count(*) order_count,
        sum(sku_num) order_num,
        sum(split_original_amount) order_original_amount,
        sum(split_activity_reduce_amount) order_activity_reduce_amount,
        sum(split_coupon_reduce_amount) order_coupon_reduce_amount,
        sum(split_total_amount) order_total_amount
    from dwd_ecommerce.dwd_order_detail_inc
    where dt='${dt}'
    group by user_id, sku_id
)
insert overwrite table dws_ecommerce.dws_trade_user_sku_order_1d partition(dt='${dt}')
select
    user_id,
    sku_id,
    '${dt}',
    '9999-12-31',
    order_count,
    order_num,
    order_original_amount,
    order_activity_reduce_amount,
    order_coupon_reduce_amount,
    order_total_amount
from order_detail;

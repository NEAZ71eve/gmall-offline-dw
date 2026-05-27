
-- ============================================
-- ODS到DWD层：订单明细事务型事实表ETL脚本
-- ============================================

-- 设置动态分区模式
set hive.exec.dynamic.partition.mode=nonstrict;

-- 订单明细事务型事实表
with order_detail as (
    select
        data.id id,
        data.order_id,
        data.sku_id,
        data.sku_name,
        data.order_price,
        data.sku_num,
        data.create_time,
        data.source_type,
        data.source_id,
        oi.user_id,
        oi.province_id,
        oi.benefit_reduce_amount,
        oi.original_total_amount,
        oi.feight_fee,
        oi.operate_time,
        oi.order_status,
        date_format(data.create_time,'yyyy-MM-dd') date_id
    from
    (
        select * from ods_ecommerce.ods_order_detail_inc where dt='${dt}'
    )data
    join
    (
        select * from ods_ecommerce.ods_order_info_inc where dt='${dt}'
    )oi
    on data.order_id = oi.id
)
insert overwrite table dwd_ecommerce.dwd_order_detail_inc partition(dt='${dt}')
select
    id,
    order_id,
    user_id,
    sku_id,
    province_id,
    null,
    null,
    date_id,
    create_time,
    sku_num,
    order_price * sku_num,
    case when source_type='2401' then round(benefit_reduce_amount / original_total_amount * order_price * sku_num,2) else 0 end,
    case when source_type='3201' then round(benefit_reduce_amount / original_total_amount * order_price * sku_num,2) else 0 end,
    order_price * sku_num - round(benefit_reduce_amount / original_total_amount * order_price * sku_num,2)
from order_detail;

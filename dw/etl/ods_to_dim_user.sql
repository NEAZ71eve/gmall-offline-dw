
-- ============================================
-- ODS到DIM层：用户维度表ETL脚本
-- ============================================

-- 设置动态分区模式
set hive.exec.dynamic.partition.mode=nonstrict;

-- 插入数据到用户维度表（拉链表）
insert overwrite table dim_ecommerce.dim_user_zip partition(dt='9999-12-31')
select
    data.id,
    '2020-06-14',
    '9999-12-31',
    data.login_name,
    data.nick_name,
    md5(data.name),
    md5(data.phone_num),
    md5(data.email),
    data.head_img,
    data.user_level,
    data.birthday,
    data.gender,
    data.create_time,
    data.operate_time,
    data.status
from
(
    select * from ods_ecommerce.ods_user_info_full
    where dt='${dt}'
)data;

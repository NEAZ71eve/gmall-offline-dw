-- ============================================
-- 维度表ETL脚本 - 拉链表、快照表、累计快照表
-- ============================================

USE gmall_dim;

-- ============================================
-- 1. 用户拉链表SCD2更新逻辑
-- ============================================
-- 每日增量更新用户维度拉链表

SET hive.exec.dynamic.partition.mode=nonstrict;

-- Step 1: 创建临时表存储当日新增和变更数据
DROP TABLE IF EXISTS tmp_user_update;
CREATE TABLE tmp_user_update AS
SELECT
    id,
    login_name,
    nick_name,
    name,
    phone_num,
    email,
    head_img,
    user_level,
    birthday,
    gender,
    create_time,
    status
FROM gmall_ods.ods_user_info
WHERE dt = '${dt}';

-- Step 2: 更新历史数据的end_date
INSERT OVERWRITE TABLE dim_user_scd2 PARTITION(dt='${dt}')
SELECT
    a.id,
    a.login_name,
    a.nick_name,
    a.name,
    a.phone_num,
    a.email,
    a.head_img,
    a.user_level,
    a.birthday,
    a.gender,
    a.create_time,
    a.status,
    a.start_date,
    CASE 
        WHEN b.id IS NOT NULL THEN date_sub('${dt}', 1) 
        ELSE a.end_date 
    END AS end_date,
    CASE 
        WHEN b.id IS NOT NULL THEN '0' 
        ELSE a.is_current 
    END AS is_current
FROM dim_user_scd2 a
LEFT JOIN tmp_user_update b ON a.id = b.id
WHERE a.is_current = '1'
UNION ALL
-- Step 3: 插入新数据
SELECT
    id,
    login_name,
    nick_name,
    name,
    phone_num,
    email,
    head_img,
    user_level,
    birthday,
    gender,
    create_time,
    status,
    '${dt}' AS start_date,
    '9999-12-31' AS end_date,
    '1' AS is_current
FROM tmp_user_update;

-- ============================================
-- 2. 用户快照表生成
-- ============================================
-- 每日生成全量快照

DROP TABLE IF EXISTS dim_user_snapshot;
CREATE EXTERNAL TABLE dim_user_snapshot(
    id STRING COMMENT '用户ID',
    login_name STRING COMMENT '登录名',
    nick_name STRING COMMENT '昵称',
    name STRING COMMENT '姓名',
    phone_num STRING COMMENT '手机号(脱敏)',
    email STRING COMMENT '邮箱(脱敏)',
    head_img STRING COMMENT '头像',
    user_level STRING COMMENT '用户等级',
    birthday STRING COMMENT '生日',
    gender STRING COMMENT '性别',
    create_time STRING COMMENT '创建时间',
    status STRING COMMENT '状态',
    snapshot_date STRING COMMENT '快照日期'
) COMMENT '用户快照表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dim/dim_user_snapshot'
TBLPROPERTIES('orc.compress'='snappy');

-- 每日快照生成
INSERT OVERWRITE TABLE dim_user_snapshot PARTITION(dt='${dt}')
SELECT
    id,
    login_name,
    nick_name,
    name,
    phone_num,
    email,
    head_img,
    user_level,
    birthday,
    gender,
    create_time,
    status,
    '${dt}' AS snapshot_date
FROM gmall_ods.ods_user_info
WHERE dt <= '${dt}';

-- ============================================
-- 3. 订单累计快照表
-- ============================================
-- 订单状态流转快照

DROP TABLE IF EXISTS dim_order_accumulate_snapshot;
CREATE EXTERNAL TABLE dim_order_accumulate_snapshot(
    order_id STRING COMMENT '订单ID',
    user_id STRING COMMENT '用户ID',
    total_amount DECIMAL(16,2) COMMENT '订单金额',
    order_status STRING COMMENT '当前订单状态',
    create_time STRING COMMENT '创建时间',
    pay_time STRING COMMENT '支付时间',
    ship_time STRING COMMENT '发货时间',
    finish_time STRING COMMENT '完成时间',
    refund_time STRING COMMENT '退款时间',
    update_time STRING COMMENT '快照更新时间',
    snapshot_date STRING COMMENT '快照日期'
) COMMENT '订单累计快照表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dim/dim_order_accumulate_snapshot'
TBLPROPERTIES('orc.compress'='snappy');

-- 累计快照更新逻辑
INSERT OVERWRITE TABLE dim_order_accumulate_snapshot PARTITION(dt='${dt}')
SELECT
    COALESCE(b.id, a.order_id) AS order_id,
    COALESCE(b.user_id, a.user_id) AS user_id,
    COALESCE(b.total_amount, a.total_amount) AS total_amount,
    COALESCE(b.order_status, a.order_status) AS order_status,
    COALESCE(a.create_time, b.create_time) AS create_time,
    CASE 
        WHEN b.order_status = 'paid' AND a.pay_time IS NULL THEN b.operate_time
        ELSE COALESCE(a.pay_time, b.pay_time) 
    END AS pay_time,
    CASE 
        WHEN b.order_status = 'shipped' AND a.ship_time IS NULL THEN b.operate_time
        ELSE COALESCE(a.ship_time, b.ship_time) 
    END AS ship_time,
    CASE 
        WHEN b.order_status = 'finished' AND a.finish_time IS NULL THEN b.operate_time
        ELSE COALESCE(a.finish_time, b.finish_time) 
    END AS finish_time,
    CASE 
        WHEN b.order_status = 'refunded' AND a.refund_time IS NULL THEN b.operate_time
        ELSE COALESCE(a.refund_time, b.refund_time) 
    END AS refund_time,
    '${dt}' AS update_time,
    '${dt}' AS snapshot_date
FROM dim_order_accumulate_snapshot a
FULL OUTER JOIN gmall_ods.ods_order_info b ON a.order_id = b.id
WHERE b.dt = '${dt}' OR a.dt = date_sub('${dt}', 1);

-- ============================================
-- 4. SCD3用户维度表更新
-- ============================================
-- SCD3使用多版本列记录变更

INSERT OVERWRITE TABLE dim_user_scd3
SELECT
    COALESCE(b.id, a.id) AS id,
    COALESCE(b.login_name, a.login_name) AS login_name,
    COALESCE(b.nick_name, a.nick_name) AS nick_name,
    COALESCE(b.name, a.name) AS name,
    COALESCE(b.phone_num, a.phone_num) AS phone_num,
    COALESCE(b.email, a.email) AS email,
    COALESCE(b.head_img, a.head_img) AS head_img,
    COALESCE(b.user_level, a.user_level) AS user_level,
    CASE 
        WHEN b.user_level IS NOT NULL AND a.user_level != b.user_level THEN a.user_level
        ELSE a.user_level_last 
    END AS user_level_last,
    COALESCE(b.birthday, a.birthday) AS birthday,
    COALESCE(b.gender, a.gender) AS gender,
    CASE 
        WHEN b.gender IS NOT NULL AND a.gender != b.gender THEN a.gender
        ELSE a.gender_last 
    END AS gender_last,
    COALESCE(a.create_time, b.create_time) AS create_time,
    COALESCE(b.status, a.status) AS status,
    '${dt}' AS update_time,
    COALESCE(a.version, 0) + 1 AS version
FROM dim_user_scd3 a
RIGHT JOIN gmall_ods.ods_user_info b ON a.id = b.id
WHERE b.dt = '${dt}';

-- ============================================
-- 5. 商品分类雪花模型关联示例
-- ============================================
-- 从SKU关联到品牌、三级分类、二级分类、一级分类

DROP TABLE IF EXISTS dim_sku_full;
CREATE EXTERNAL TABLE dim_sku_full(
    sku_id STRING COMMENT 'SKU ID',
    spu_id STRING COMMENT 'SPU ID',
    sku_name STRING COMMENT 'SKU名称',
    price DECIMAL(16,2) COMMENT '价格',
    tm_id STRING COMMENT '品牌ID',
    tm_name STRING COMMENT '品牌名称',
    category3_id STRING COMMENT '三级分类ID',
    category3_name STRING COMMENT '三级分类名称',
    category2_id STRING COMMENT '二级分类ID',
    category2_name STRING COMMENT '二级分类名称',
    category1_id STRING COMMENT '一级分类ID',
    category1_name STRING COMMENT '一级分类名称',
    create_time STRING COMMENT '创建时间'
) COMMENT '商品SKU全维度表(雪花模型关联)'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dim/dim_sku_full'
TBLPROPERTIES('orc.compress'='snappy');

-- 雪花模型关联查询
INSERT OVERWRITE TABLE dim_sku_full PARTITION(dt='${dt}')
SELECT
    s.id AS sku_id,
    s.spu_id,
    s.sku_name,
    s.price,
    s.tm_id,
    b.tm_name,
    s.category3_id,
    c3.category3_name,
    c2.category2_id,
    c2.category2_name,
    c1.category1_id,
    c1.category1_name,
    s.create_time
FROM gmall_ods.ods_sku_info s
LEFT JOIN dim_brand b ON s.tm_id = b.tm_id
LEFT JOIN dim_category3 c3 ON s.category3_id = c3.category3_id
LEFT JOIN dim_category2 c2 ON c3.category2_id = c2.category2_id
LEFT JOIN dim_category1 c1 ON c2.category1_id = c1.category1_id
WHERE s.dt = '${dt}';
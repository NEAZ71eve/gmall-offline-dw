-- ============================================
-- DIM层建表脚本 - 雪花模型 + SCD1/SCD2/SCD3
-- ============================================

USE gmall_dim;

-- ============================================
-- 雪花模型维度表
-- ============================================

-- 1. 品牌维度表 (SCD1 - 覆盖更新)
DROP TABLE IF EXISTS dim_brand;
CREATE EXTERNAL TABLE dim_brand(
    tm_id STRING COMMENT '品牌ID',
    tm_name STRING COMMENT '品牌名称',
    tm_logo STRING COMMENT '品牌Logo',
    tm_desc STRING COMMENT '品牌描述',
    create_time STRING COMMENT '创建时间',
    update_time STRING COMMENT '更新时间'
) COMMENT '品牌维度表 (SCD1)'
STORED AS ORC
LOCATION '/warehouse/gmall/dim/dim_brand'
TBLPROPERTIES('orc.compress'='snappy');

-- 2. 一级分类维度表 (SCD1 - 覆盖更新)
DROP TABLE IF EXISTS dim_category1;
CREATE EXTERNAL TABLE dim_category1(
    category1_id STRING COMMENT '一级分类ID',
    category1_name STRING COMMENT '一级分类名称',
    category1_desc STRING COMMENT '一级分类描述',
    create_time STRING COMMENT '创建时间',
    update_time STRING COMMENT '更新时间'
) COMMENT '一级分类维度表 (SCD1)'
STORED AS ORC
LOCATION '/warehouse/gmall/dim/dim_category1'
TBLPROPERTIES('orc.compress'='snappy');

-- 3. 二级分类维度表 (SCD1 - 覆盖更新)
DROP TABLE IF EXISTS dim_category2;
CREATE EXTERNAL TABLE dim_category2(
    category2_id STRING COMMENT '二级分类ID',
    category1_id STRING COMMENT '一级分类ID',
    category2_name STRING COMMENT '二级分类名称',
    category2_desc STRING COMMENT '二级分类描述',
    create_time STRING COMMENT '创建时间',
    update_time STRING COMMENT '更新时间'
) COMMENT '二级分类维度表 (SCD1)'
STORED AS ORC
LOCATION '/warehouse/gmall/dim/dim_category2'
TBLPROPERTIES('orc.compress'='snappy');

-- 4. 三级分类维度表 (SCD1 - 覆盖更新)
DROP TABLE IF EXISTS dim_category3;
CREATE EXTERNAL TABLE dim_category3(
    category3_id STRING COMMENT '三级分类ID',
    category2_id STRING COMMENT '二级分类ID',
    category3_name STRING COMMENT '三级分类名称',
    category3_desc STRING COMMENT '三级分类描述',
    create_time STRING COMMENT '创建时间',
    update_time STRING COMMENT '更新时间'
) COMMENT '三级分类维度表 (SCD1)'
STORED AS ORC
LOCATION '/warehouse/gmall/dim/dim_category3'
TBLPROPERTIES('orc.compress'='snappy');

-- ============================================
-- SCD类型对比维度表
-- ============================================

-- 5. 用户维度表 - SCD1 (覆盖更新)
DROP TABLE IF EXISTS dim_user_scd1;
CREATE EXTERNAL TABLE dim_user_scd1(
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
    update_time STRING COMMENT '更新时间'
) COMMENT '用户维度表 (SCD1 - 覆盖更新)'
STORED AS ORC
LOCATION '/warehouse/gmall/dim/dim_user_scd1'
TBLPROPERTIES('orc.compress'='snappy');

-- 6. 用户维度表 - SCD2 (拉链表)
DROP TABLE IF EXISTS dim_user_scd2;
CREATE EXTERNAL TABLE dim_user_scd2(
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
    start_date STRING COMMENT '开始日期',
    end_date STRING COMMENT '结束日期',
    is_current STRING COMMENT '是否当前版本'
) COMMENT '用户维度表 (SCD2 - 拉链表)'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dim/dim_user_scd2'
TBLPROPERTIES('orc.compress'='snappy');

-- 7. 用户维度表 - SCD3 (多版本列)
DROP TABLE IF EXISTS dim_user_scd3;
CREATE EXTERNAL TABLE dim_user_scd3(
    id STRING COMMENT '用户ID',
    login_name STRING COMMENT '登录名',
    nick_name STRING COMMENT '昵称',
    name STRING COMMENT '姓名',
    phone_num STRING COMMENT '手机号(脱敏)',
    email STRING COMMENT '邮箱(脱敏)',
    head_img STRING COMMENT '头像',
    user_level STRING COMMENT '用户等级',
    user_level_last STRING COMMENT '上一版本用户等级',
    birthday STRING COMMENT '生日',
    gender STRING COMMENT '性别',
    gender_last STRING COMMENT '上一版本性别',
    create_time STRING COMMENT '创建时间',
    status STRING COMMENT '状态',
    update_time STRING COMMENT '更新时间',
    version INT COMMENT '版本号'
) COMMENT '用户维度表 (SCD3 - 多版本列)'
STORED AS ORC
LOCATION '/warehouse/gmall/dim/dim_user_scd3'
TBLPROPERTIES('orc.compress'='snappy');

-- ============================================
-- 商品维度表 (雪花模型)
-- ============================================

-- 8. 商品SPU维度表
DROP TABLE IF EXISTS dim_spu;
CREATE EXTERNAL TABLE dim_spu(
    spu_id STRING COMMENT 'SPU ID',
    spu_name STRING COMMENT 'SPU名称',
    spu_desc STRING COMMENT 'SPU描述',
    tm_id STRING COMMENT '品牌ID',
    category3_id STRING COMMENT '三级分类ID',
    create_time STRING COMMENT '创建时间',
    update_time STRING COMMENT '更新时间'
) COMMENT '商品SPU维度表'
STORED AS ORC
LOCATION '/warehouse/gmall/dim/dim_spu'
TBLPROPERTIES('orc.compress'='snappy');

-- 9. 商品SKU维度表 (雪花模型关联)
DROP TABLE IF EXISTS dim_sku;
CREATE EXTERNAL TABLE dim_sku(
    id STRING COMMENT 'SKU ID',
    spu_id STRING COMMENT 'SPU ID',
    price DECIMAL(16,2) COMMENT '价格',
    sku_name STRING COMMENT '商品名称',
    sku_desc STRING COMMENT '商品描述',
    weight DECIMAL(16,2) COMMENT '重量',
    tm_id STRING COMMENT '品牌ID',
    category3_id STRING COMMENT '三级分类ID',
    create_time STRING COMMENT '创建时间',
    update_time STRING COMMENT '更新时间'
) COMMENT '商品SKU维度表 (雪花模型)'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dim/dim_sku'
TBLPROPERTIES('orc.compress'='snappy');

-- ============================================
-- 其他维度表
-- ============================================

-- 10. 日期维度表
DROP TABLE IF EXISTS dim_time;
CREATE EXTERNAL TABLE dim_time(
    date_id STRING COMMENT '日期ID',
    week_id STRING COMMENT '周ID',
    week_day STRING COMMENT '周几',
    day STRING COMMENT '日',
    month STRING COMMENT '月',
    quarter STRING COMMENT '季度',
    year STRING COMMENT '年',
    is_workday STRING COMMENT '是否工作日',
    holiday_name STRING COMMENT '节假日名称',
    week_of_year STRING COMMENT '年内第几周',
    month_of_quarter STRING COMMENT '季度内第几月'
) COMMENT '日期维度表'
STORED AS ORC
LOCATION '/warehouse/gmall/dim/dim_time'
TBLPROPERTIES('orc.compress'='snappy');

-- 11. 地区维度表
DROP TABLE IF EXISTS dim_province;
CREATE EXTERNAL TABLE dim_province(
    id STRING COMMENT '地区ID',
    name STRING COMMENT '地区名称',
    area_code STRING COMMENT '地区编码',
    region_id STRING COMMENT '大区ID',
    region_name STRING COMMENT '大区名称',
    province_type STRING COMMENT '省份类型(直辖市/普通省份)',
    population BIGINT COMMENT '人口数量',
    area_km2 DECIMAL(12,2) COMMENT '面积(平方公里)'
) COMMENT '地区维度表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dim/dim_province'
TBLPROPERTIES('orc.compress'='snappy');

-- 12. 支付方式维度表
DROP TABLE IF EXISTS dim_payment_type;
CREATE EXTERNAL TABLE dim_payment_type(
    payment_type_id STRING COMMENT '支付方式ID',
    payment_type_name STRING COMMENT '支付方式名称',
    payment_type_code STRING COMMENT '支付方式编码',
    payment_channel STRING COMMENT '支付渠道',
    create_time STRING COMMENT '创建时间',
    update_time STRING COMMENT '更新时间'
) COMMENT '支付方式维度表'
STORED AS ORC
LOCATION '/warehouse/gmall/dim/dim_payment_type'
TBLPROPERTIES('orc.compress'='snappy');
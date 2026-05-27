
-- ============================================
-- DIM层建表脚本
-- ============================================

USE gmall_dim;

-- 1. 用户维度表（拉链表）
DROP TABLE IF EXISTS dim_user;
CREATE EXTERNAL TABLE dim_user(
    id STRING COMMENT '用户ID',
    start_date STRING COMMENT '开始日期',
    end_date STRING COMMENT '结束日期',
    login_name STRING COMMENT '登录名',
    nick_name STRING COMMENT '昵称',
    name STRING COMMENT '姓名',
    phone_num STRING COMMENT '手机号',
    email STRING COMMENT '邮箱',
    head_img STRING COMMENT '头像',
    user_level STRING COMMENT '用户等级',
    birthday STRING COMMENT '生日',
    gender STRING COMMENT '性别',
    create_time STRING COMMENT '创建时间',
    status STRING COMMENT '状态'
) COMMENT '用户维度表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dim/dim_user'
TBLPROPERTIES('orc.compress'='snappy');

-- 2. 商品维度表
DROP TABLE IF EXISTS dim_sku;
CREATE EXTERNAL TABLE dim_sku(
    id STRING COMMENT 'SKU ID',
    spu_id STRING COMMENT 'SPU ID',
    price DECIMAL(16,2) COMMENT '价格',
    sku_name STRING COMMENT '商品名称',
    sku_desc STRING COMMENT '商品描述',
    weight DECIMAL(16,2) COMMENT '重量',
    tm_id STRING COMMENT '品牌ID',
    tm_name STRING COMMENT '品牌名称',
    category3_id STRING COMMENT '三级分类ID',
    category3_name STRING COMMENT '三级分类名称',
    category2_id STRING COMMENT '二级分类ID',
    category2_name STRING COMMENT '二级分类名称',
    category1_id STRING COMMENT '一级分类ID',
    category1_name STRING COMMENT '一级分类名称',
    create_time STRING COMMENT '创建时间'
) COMMENT '商品维度表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dim/dim_sku'
TBLPROPERTIES('orc.compress'='snappy');

-- 3. 日期维度表
DROP TABLE IF EXISTS dim_time;
CREATE EXTERNAL TABLE dim_time(
    date_id STRING COMMENT '日期ID',
    week_id STRING COMMENT '周ID',
    week_day STRING COMMENT '周几',
    day STRING COMMENT '日',
    month STRING COMMENT '月',
    quarter STRING COMMENT '季度',
    year STRING COMMENT '年',
    is_workday STRING COMMENT '是否工作日'
) COMMENT '日期维度表'
STORED AS ORC
LOCATION '/warehouse/gmall/dim/dim_time'
TBLPROPERTIES('orc.compress'='snappy');

-- 4. 地区维度表
DROP TABLE IF EXISTS dim_province;
CREATE EXTERNAL TABLE dim_province(
    id STRING COMMENT '地区ID',
    name STRING COMMENT '地区名称',
    area_code STRING COMMENT '地区编码',
    region_id STRING COMMENT '大区ID',
    region_name STRING COMMENT '大区名称'
) COMMENT '地区维度表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dim/dim_province'
TBLPROPERTIES('orc.compress'='snappy');

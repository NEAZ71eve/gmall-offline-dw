
-- ============================================
-- DIM层建表脚本
-- 公共维度层，存储用户、商品、时间等维度
-- ============================================

-- 创建DIM数据库
CREATE DATABASE IF NOT EXISTS dim_ecommerce;
USE dim_ecommerce;

-- 1. 维度表：用户维度表
DROP TABLE IF EXISTS dim_user_zip;
CREATE EXTERNAL TABLE dim_user_zip(
    `id` STRING COMMENT '用户ID',
    `k1` STRING COMMENT '开始日期',
    `k2` STRING COMMENT '结束日期',
    `user_name` STRING COMMENT '用户名',
    `nick_name` STRING COMMENT '昵称',
    `name` STRING COMMENT '姓名',
    `phone_num` STRING COMMENT '手机号',
    `email` STRING COMMENT '邮箱',
    `head_img` STRING COMMENT '头像',
    `user_level` STRING COMMENT '用户等级',
    `birthday` STRING COMMENT '生日',
    `gender` STRING COMMENT '性别',
    `create_time` STRING COMMENT '创建时间',
    `operate_time` STRING COMMENT '操作时间',
    `status` STRING COMMENT '状态'
) COMMENT '用户维度表'
PARTITIONED BY (`dt` STRING)
STORED AS ORC
LOCATION '/warehouse/dim_ecommerce/dim_user_zip'
TBLPROPERTIES('orc.compress'='snappy');

-- 2. 维度表：商品维度表
DROP TABLE IF EXISTS dim_sku_full;
CREATE EXTERNAL TABLE dim_sku_full(
    `id` STRING COMMENT 'SKU ID',
    `price` DECIMAL(16,2) COMMENT '价格',
    `sku_name` STRING COMMENT '商品名称',
    `sku_desc` STRING COMMENT '商品描述',
    `weight` DECIMAL(16,2) COMMENT '重量',
    `is_sale` BOOLEAN COMMENT '是否在售',
    `spu_id` STRING COMMENT 'SPU ID',
    `spu_name` STRING COMMENT 'SPU名称',
    `category_id` STRING COMMENT '分类ID',
    `category_name` STRING COMMENT '分类名称',
    `tm_id` STRING COMMENT '品牌ID',
    `tm_name` STRING COMMENT '品牌名称',
    `create_time` STRING COMMENT '创建时间'
) COMMENT '商品维度表'
PARTITIONED BY (`dt` STRING)
STORED AS ORC
LOCATION '/warehouse/dim_ecommerce/dim_sku_full'
TBLPROPERTIES('orc.compress'='snappy');

-- 3. 维度表：地区维度表
DROP TABLE IF EXISTS dim_province_full;
CREATE EXTERNAL TABLE dim_province_full(
    `id` STRING COMMENT '地区ID',
    `name` STRING COMMENT '地区名称',
    `area_code` STRING COMMENT '地区编码',
    `iso_code` STRING COMMENT 'ISO编码',
    `iso_3166_2` STRING COMMENT 'ISO_3166_2',
    `region_id` STRING COMMENT '大区ID',
    `region_name` STRING COMMENT '大区名称'
) COMMENT '地区维度表'
PARTITIONED BY (`dt` STRING)
STORED AS ORC
LOCATION '/warehouse/dim_ecommerce/dim_province_full'
TBLPROPERTIES('orc.compress'='snappy');

-- 4. 维度表：日期维度表
DROP TABLE IF EXISTS dim_date;
CREATE EXTERNAL TABLE dim_date(
    `date_id` STRING COMMENT '日期ID',
    `week_id` STRING COMMENT '周ID',
    `week_day` STRING COMMENT '周几',
    `day` STRING COMMENT '日',
    `month` STRING COMMENT '月',
    `quarter` STRING COMMENT '季度',
    `year` STRING COMMENT '年',
    `is_workday` STRING COMMENT '是否工作日'
) COMMENT '日期维度表'
STORED AS ORC
LOCATION '/warehouse/dim_ecommerce/dim_date'
TBLPROPERTIES('orc.compress'='snappy');

-- 5. 维度表：优惠券维度表
DROP TABLE IF EXISTS dim_coupon_full;
CREATE EXTERNAL TABLE dim_coupon_full(
    `id` STRING COMMENT '优惠券ID',
    `coupon_name` STRING COMMENT '优惠券名称',
    `coupon_type` STRING COMMENT '优惠券类型',
    `condition_amount` DECIMAL(16,2) COMMENT '满额数',
    `condition_num` BIGINT COMMENT '满件数',
    `activity_id` STRING COMMENT '活动ID',
    `benefit_amount` DECIMAL(16,2) COMMENT '减免金额',
    `benefit_discount` DECIMAL(16,2) COMMENT '折扣',
    `benefit_rule` STRING COMMENT '优惠规则',
    `create_time` STRING COMMENT '创建时间',
    `range_type` STRING COMMENT '范围类型',
    `limit_num` BIGINT COMMENT '最大发放张数',
    `taken_count` BIGINT COMMENT '已经领取的张数',
    `start_time` STRING COMMENT '可以领取的开始时间',
    `end_time` STRING COMMENT '可以领取的结束时间',
    `operate_time` STRING COMMENT '修改时间',
    `expire_time` STRING COMMENT '过期时间'
) COMMENT '优惠券维度表'
PARTITIONED BY (`dt` STRING)
STORED AS ORC
LOCATION '/warehouse/dim_ecommerce/dim_coupon_full'
TBLPROPERTIES('orc.compress'='snappy');

-- 6. 维度表：活动维度表
DROP TABLE IF EXISTS dim_activity_full;
CREATE EXTERNAL TABLE dim_activity_full(
    `activity_rule_id` STRING COMMENT '活动规则ID',
    `activity_id` STRING COMMENT '活动ID',
    `activity_name` STRING COMMENT '活动名称',
    `activity_type` STRING COMMENT '活动类型',
    `start_time` STRING COMMENT '开始时间',
    `end_time` STRING COMMENT '结束时间',
    `create_time` STRING COMMENT '创建时间',
    `condition_amount` DECIMAL(16,2) COMMENT '满额数',
    `condition_num` BIGINT COMMENT '满件数',
    `benefit_amount` DECIMAL(16,2) COMMENT '减免金额',
    `benefit_discount` DECIMAL(16,2) COMMENT '折扣',
    `benefit_rule` STRING COMMENT '优惠规则',
    `benefit_level` BIGINT COMMENT '优惠级别'
) COMMENT '活动维度表'
PARTITIONED BY (`dt` STRING)
STORED AS ORC
LOCATION '/warehouse/dim_ecommerce/dim_activity_full'
TBLPROPERTIES('orc.compress'='snappy');


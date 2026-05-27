
-- ============================================
-- ODS层建表脚本
-- 原始数据层，直接同步业务库与日志数据
-- ============================================

-- 创建ODS数据库
CREATE DATABASE IF NOT EXISTS ods_ecommerce;
USE ods_ecommerce;

-- 1. ODS用户表（全量同步）
DROP TABLE IF EXISTS ods_user_info_full;
CREATE EXTERNAL TABLE ods_user_info_full(
    `id` STRING COMMENT '用户ID',
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
) COMMENT '用户表'
PARTITIONED BY (`dt` STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/ods_ecommerce/ods_user_info_full';

-- 2. ODS商品表（全量同步）
DROP TABLE IF EXISTS ods_sku_info_full;
CREATE EXTERNAL TABLE ods_sku_info_full(
    `id` STRING COMMENT 'SKU ID',
    `spu_id` STRING COMMENT 'SPU ID',
    `price` DECIMAL(16,2) COMMENT '价格',
    `sku_name` STRING COMMENT '商品名称',
    `sku_desc` STRING COMMENT '商品描述',
    `weight` DECIMAL(16,2) COMMENT '重量',
    `tm_id` STRING COMMENT '品牌ID',
    `category3_id` STRING COMMENT '三级分类ID',
    `create_time` STRING COMMENT '创建时间'
) COMMENT 'SKU表'
PARTITIONED BY (`dt` STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/ods_ecommerce/ods_sku_info_full';

-- 3. ODS商品SPU表（全量同步）
DROP TABLE IF EXISTS ods_spu_info_full;
CREATE EXTERNAL TABLE ods_spu_info_full(
    `id` STRING COMMENT 'SPU ID',
    `spu_name` STRING COMMENT 'SPU名称',
    `description` STRING COMMENT '描述',
    `category3_id` STRING COMMENT '三级分类ID',
    `tm_id` STRING COMMENT '品牌ID'
) COMMENT 'SPU表'
PARTITIONED BY (`dt` STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/ods_ecommerce/ods_spu_info_full';

-- 4. ODS品牌表（全量同步）
DROP TABLE IF EXISTS ods_base_trademark_full;
CREATE EXTERNAL TABLE ods_base_trademark_full(
    `id` STRING COMMENT '品牌ID',
    `tm_name` STRING COMMENT '品牌名称',
    `logo_url` STRING COMMENT 'LOGO地址'
) COMMENT '品牌表'
PARTITIONED BY (`dt` STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/ods_ecommerce/ods_base_trademark_full';

-- 5. ODS分类表（全量同步）
DROP TABLE IF EXISTS ods_base_category1_full;
CREATE EXTERNAL TABLE ods_base_category1_full(
    `id` STRING COMMENT '一级分类ID',
    `name` STRING COMMENT '一级分类名称'
) COMMENT '一级分类表'
PARTITIONED BY (`dt` STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/ods_ecommerce/ods_base_category1_full';

DROP TABLE IF EXISTS ods_base_category2_full;
CREATE EXTERNAL TABLE ods_base_category2_full(
    `id` STRING COMMENT '二级分类ID',
    `name` STRING COMMENT '二级分类名称',
    `category1_id` STRING COMMENT '一级分类ID'
) COMMENT '二级分类表'
PARTITIONED BY (`dt` STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/ods_ecommerce/ods_base_category2_full';

DROP TABLE IF EXISTS ods_base_category3_full;
CREATE EXTERNAL TABLE ods_base_category3_full(
    `id` STRING COMMENT '三级分类ID',
    `name` STRING COMMENT '三级分类名称',
    `category2_id` STRING COMMENT '二级分类ID'
) COMMENT '三级分类表'
PARTITIONED BY (`dt` STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/ods_ecommerce/ods_base_category3_full';

-- 6. ODS订单表（增量同步）
DROP TABLE IF EXISTS ods_order_info_inc;
CREATE EXTERNAL TABLE ods_order_info_inc(
    `id` STRING COMMENT '订单ID',
    `consignee` STRING COMMENT '收货人',
    `consignee_tel` STRING COMMENT '收货人电话',
    `total_amount` DECIMAL(16,2) COMMENT '订单金额',
    `order_status` STRING COMMENT '订单状态',
    `user_id` STRING COMMENT '用户ID',
    `payment_way` STRING COMMENT '支付方式',
    `delivery_address` STRING COMMENT '配送地址',
    `order_comment` STRING COMMENT '订单备注',
    `out_trade_no` STRING COMMENT '交易流水号',
    `trade_body` STRING COMMENT '交易内容',
    `create_time` STRING COMMENT '创建时间',
    `operate_time` STRING COMMENT '操作时间',
    `expire_time` STRING COMMENT '失效时间',
    `tracking_no` STRING COMMENT '物流单号',
    `parent_order_id` STRING COMMENT '父订单ID',
    `img_url` STRING COMMENT '订单图片',
    `province_id` STRING COMMENT '省份ID',
    `benefit_reduce_amount` DECIMAL(16,2) COMMENT '优惠金额',
    `original_total_amount` DECIMAL(16,2) COMMENT '原价金额',
    `feight_fee` DECIMAL(16,2) COMMENT '运费'
) COMMENT '订单表'
PARTITIONED BY (`dt` STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/ods_ecommerce/ods_order_info_inc';

-- 7. ODS订单明细表（增量同步）
DROP TABLE IF EXISTS ods_order_detail_inc;
CREATE EXTERNAL TABLE ods_order_detail_inc(
    `id` STRING COMMENT '订单明细ID',
    `order_id` STRING COMMENT '订单ID',
    `sku_id` STRING COMMENT 'SKU ID',
    `sku_name` STRING COMMENT '商品名称',
    `img_url` STRING COMMENT '图片',
    `order_price` DECIMAL(16,2) COMMENT '商品原价',
    `sku_num` BIGINT COMMENT '商品数量',
    `create_time` STRING COMMENT '创建时间',
    `source_type` STRING COMMENT '来源类型',
    `source_id` STRING COMMENT '来源ID'
) COMMENT '订单明细表'
PARTITIONED BY (`dt` STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/ods_ecommerce/ods_order_detail_inc';

-- 8. ODS支付表（增量同步）
DROP TABLE IF EXISTS ods_payment_info_inc;
CREATE EXTERNAL TABLE ods_payment_info_inc(
    `id` STRING COMMENT '支付ID',
    `out_trade_no` STRING COMMENT '对外业务编号',
    `order_id` STRING COMMENT '订单ID',
    `user_id` STRING COMMENT '用户ID',
    `payment_type` STRING COMMENT '支付方式',
    `trade_no` STRING COMMENT '交易编号',
    `total_amount` DECIMAL(16,2) COMMENT '支付金额',
    `subject` STRING COMMENT '交易内容',
    `payment_status` STRING COMMENT '支付状态',
    `create_time` STRING COMMENT '创建时间',
    `callback_time` STRING COMMENT '回调时间',
    `callback_content` STRING COMMENT '回调内容'
) COMMENT '支付表'
PARTITIONED BY (`dt` STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/ods_ecommerce/ods_payment_info_inc';

-- 9. ODS日志表（增量同步）
DROP TABLE IF EXISTS ods_log_inc;
CREATE EXTERNAL TABLE ods_log_inc(
    `common` STRUCT&lt;ar:STRING,ba:STRING,ch:STRING,md:STRING,mid:STRING,os:STRING,uid:STRING,vc:STRING&gt; COMMENT '公共信息',
    `page` STRUCT&lt;during_time:BIGINT,item:STRING,item_type:STRING,last_page_id:STRING,page_id:STRING,source_type:STRING&gt; COMMENT '页面信息',
    `displays` ARRAY&lt;STRUCT&lt;display_type:STRING,item:STRING,item_type:STRING,order:BIGINT,pos_id:STRING&gt;&gt; COMMENT '曝光信息',
    `actions` ARRAY&lt;STRUCT&lt;action_id:STRING,item:STRING,item_type:STRING,ts:BIGINT&gt;&gt; COMMENT '动作信息',
    `start` STRUCT&lt;entry:STRING,loading_time:BIGINT,open_ad_id:BIGINT,open_ad_ms:BIGINT,open_ad_skip_ms:BIGINT&gt; COMMENT '启动信息',
    `err` STRUCT&lt;error_code:BIGINT,msg:STRING&gt; COMMENT '错误信息',
    `ts` BIGINT COMMENT '时间戳'
) COMMENT '日志表'
PARTITIONED BY (`dt` STRING)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.JsonSerDe'
STORED AS TEXTFILE
LOCATION '/warehouse/ods_ecommerce/ods_log_inc';


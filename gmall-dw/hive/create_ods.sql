
-- ============================================
-- ODS层建表脚本
-- ============================================

USE gmall_ods;

-- 1. 用户表
DROP TABLE IF EXISTS ods_user_info;
CREATE EXTERNAL TABLE ods_user_info(
    id STRING COMMENT '用户ID',
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
    operate_time STRING COMMENT '操作时间',
    status STRING COMMENT '状态'
) COMMENT '用户表'
PARTITIONED BY (dt STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/gmall/ods/ods_user_info';

-- 2. 订单表
DROP TABLE IF EXISTS ods_order_info;
CREATE EXTERNAL TABLE ods_order_info(
    id STRING COMMENT '订单ID',
    consignee STRING COMMENT '收货人',
    consignee_tel STRING COMMENT '收货人电话',
    total_amount DECIMAL(16,2) COMMENT '订单金额',
    order_status STRING COMMENT '订单状态',
    user_id STRING COMMENT '用户ID',
    payment_way STRING COMMENT '支付方式',
    delivery_address STRING COMMENT '配送地址',
    order_comment STRING COMMENT '订单备注',
    out_trade_no STRING COMMENT '交易流水号',
    trade_body STRING COMMENT '交易内容',
    create_time STRING COMMENT '创建时间',
    operate_time STRING COMMENT '操作时间',
    province_id STRING COMMENT '省份ID'
) COMMENT '订单表'
PARTITIONED BY (dt STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/gmall/ods/ods_order_info';

-- 3. 订单明细表
DROP TABLE IF EXISTS ods_order_detail;
CREATE EXTERNAL TABLE ods_order_detail(
    id STRING COMMENT '订单明细ID',
    order_id STRING COMMENT '订单ID',
    sku_id STRING COMMENT 'SKU ID',
    sku_name STRING COMMENT '商品名称',
    img_url STRING COMMENT '图片',
    order_price DECIMAL(16,2) COMMENT '商品原价',
    sku_num BIGINT COMMENT '商品数量',
    create_time STRING COMMENT '创建时间',
    source_type STRING COMMENT '来源类型',
    source_id STRING COMMENT '来源ID'
) COMMENT '订单明细表'
PARTITIONED BY (dt STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/gmall/ods/ods_order_detail';

-- 4. 商品SKU表
DROP TABLE IF EXISTS ods_sku_info;
CREATE EXTERNAL TABLE ods_sku_info(
    id STRING COMMENT 'SKU ID',
    spu_id STRING COMMENT 'SPU ID',
    price DECIMAL(16,2) COMMENT '价格',
    sku_name STRING COMMENT '商品名称',
    sku_desc STRING COMMENT '商品描述',
    weight DECIMAL(16,2) COMMENT '重量',
    tm_id STRING COMMENT '品牌ID',
    category3_id STRING COMMENT '三级分类ID',
    create_time STRING COMMENT '创建时间'
) COMMENT 'SKU表'
PARTITIONED BY (dt STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/gmall/ods/ods_sku_info';

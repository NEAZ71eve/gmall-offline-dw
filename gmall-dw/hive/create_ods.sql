
-- ============================================
-- ODS层建表脚本 - 完整版
-- 包含电商核心业务表：用户、订单、商品、支付、活动、优惠券等
-- ============================================

USE gmall_ods;

-- ============================================
-- 1. 用户域
-- ============================================

-- 1.1 用户信息表
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
) COMMENT '用户信息表'
PARTITIONED BY (dt STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/gmall/ods/ods_user_info';

-- ============================================
-- 2. 订单域
-- ============================================

-- 2.1 订单主表
DROP TABLE IF EXISTS ods_order_info;
CREATE EXTERNAL TABLE ods_order_info(
    id STRING COMMENT '订单ID',
    consignee STRING COMMENT '收货人',
    consignee_tel STRING COMMENT '收货人电话',
    total_amount DECIMAL(16,2) COMMENT '订单总金额',
    order_status STRING COMMENT '订单状态',
    user_id STRING COMMENT '用户ID',
    payment_way STRING COMMENT '支付方式',
    delivery_address STRING COMMENT '配送地址',
    order_comment STRING COMMENT '订单备注',
    out_trade_no STRING COMMENT '交易流水号',
    trade_body STRING COMMENT '交易内容',
    create_time STRING COMMENT '创建时间',
    operate_time STRING COMMENT '操作时间',
    expire_time STRING COMMENT '过期时间',
    refund_time STRING COMMENT '退款时间',
    refund_status STRING COMMENT '退款状态',
    province_id STRING COMMENT '省份ID'
) COMMENT '订单主表'
PARTITIONED BY (dt STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/gmall/ods/ods_order_info';

-- 2.2 订单明细表
DROP TABLE IF EXISTS ods_order_detail;
CREATE EXTERNAL TABLE ods_order_detail(
    id STRING COMMENT '订单明细ID',
    order_id STRING COMMENT '订单ID',
    sku_id STRING COMMENT 'SKU ID',
    sku_name STRING COMMENT '商品名称',
    img_url STRING COMMENT '商品图片URL',
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

-- 2.3 订单状态日志表
DROP TABLE IF EXISTS ods_order_status_log;
CREATE EXTERNAL TABLE ods_order_status_log(
    id STRING COMMENT '日志ID',
    order_id STRING COMMENT '订单ID',
    order_status STRING COMMENT '订单状态',
    operate_time STRING COMMENT '操作时间',
    operate_user_id STRING COMMENT '操作用户ID',
    remark STRING COMMENT '备注'
) COMMENT '订单状态日志表'
PARTITIONED BY (dt STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/gmall/ods/ods_order_status_log';

-- ============================================
-- 3. 商品域
-- ============================================

-- 3.1 SKU商品表
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
) COMMENT 'SKU商品表'
PARTITIONED BY (dt STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/gmall/ods/ods_sku_info';

-- 3.2 SPU商品表
DROP TABLE IF EXISTS ods_spu_info;
CREATE EXTERNAL TABLE ods_spu_info(
    id STRING COMMENT 'SPU ID',
    spu_name STRING COMMENT 'SPU名称',
    description STRING COMMENT '商品描述',
    tm_id STRING COMMENT '品牌ID',
    category3_id STRING COMMENT '三级分类ID',
    create_time STRING COMMENT '创建时间'
) COMMENT 'SPU商品表'
PARTITIONED BY (dt STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/gmall/ods/ods_spu_info';

-- 3.3 品牌表
DROP TABLE IF EXISTS ods_base_trademark;
CREATE EXTERNAL TABLE ods_base_trademark(
    tm_id STRING COMMENT '品牌ID',
    tm_name STRING COMMENT '品牌名称',
    logo_url STRING COMMENT '品牌Logo',
    create_time STRING COMMENT '创建时间'
) COMMENT '品牌表'
PARTITIONED BY (dt STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/gmall/ods/ods_base_trademark';

-- 3.4 商品三级分类表
DROP TABLE IF EXISTS ods_base_category3;
CREATE EXTERNAL TABLE ods_base_category3(
    id STRING COMMENT '三级分类ID',
    name STRING COMMENT '三级分类名称',
    category2_id STRING COMMENT '二级分类ID',
    create_time STRING COMMENT '创建时间'
) COMMENT '商品三级分类表'
PARTITIONED BY (dt STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/gmall/ods/ods_base_category3';

-- 3.5 商品二级分类表
DROP TABLE IF EXISTS ods_base_category2;
CREATE EXTERNAL TABLE ods_base_category2(
    id STRING COMMENT '二级分类ID',
    name STRING COMMENT '二级分类名称',
    category1_id STRING COMMENT '一级分类ID',
    create_time STRING COMMENT '创建时间'
) COMMENT '商品二级分类表'
PARTITIONED BY (dt STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/gmall/ods/ods_base_category2';

-- 3.6 商品一级分类表
DROP TABLE IF EXISTS ods_base_category1;
CREATE EXTERNAL TABLE ods_base_category1(
    id STRING COMMENT '一级分类ID',
    name STRING COMMENT '一级分类名称',
    create_time STRING COMMENT '创建时间'
) COMMENT '商品一级分类表'
PARTITIONED BY (dt STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/gmall/ods/ods_base_category1';

-- ============================================
-- 4. 支付域
-- ============================================

-- 4.1 支付表
DROP TABLE IF EXISTS ods_payment_info;
CREATE EXTERNAL TABLE ods_payment_info(
    id STRING COMMENT '支付ID',
    out_trade_no STRING COMMENT '交易订单号',
    order_id STRING COMMENT '订单ID',
    user_id STRING COMMENT '用户ID',
    payment_type STRING COMMENT '支付类型',
    trade_no STRING COMMENT '第三方交易流水号',
    total_amount DECIMAL(16,2) COMMENT '支付金额',
    subject STRING COMMENT '交易内容',
    payment_status STRING COMMENT '支付状态',
    create_time STRING COMMENT '创建时间',
    callback_time STRING COMMENT '回调时间'
) COMMENT '支付表'
PARTITIONED BY (dt STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/gmall/ods/ods_payment_info';

-- ============================================
-- 5. 退款域
-- ============================================

-- 5.1 退款表
DROP TABLE IF EXISTS ods_order_refund_info;
CREATE EXTERNAL TABLE ods_order_refund_info(
    id STRING COMMENT '退款ID',
    order_id STRING COMMENT '订单ID',
    sku_id STRING COMMENT 'SKU ID',
    refund_type STRING COMMENT '退款类型',
    refund_num BIGINT COMMENT '退款数量',
    refund_amount DECIMAL(16,2) COMMENT '退款金额',
    refund_reason_type STRING COMMENT '退款原因类型',
    refund_reason_txt STRING COMMENT '退款原因',
    refund_status STRING COMMENT '退款状态',
    create_time STRING COMMENT '创建时间',
    operate_time STRING COMMENT '操作时间'
) COMMENT '退款表'
PARTITIONED BY (dt STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/gmall/ods/ods_order_refund_info';

-- ============================================
-- 6. 促销域
-- ============================================

-- 6.1 优惠活动表
DROP TABLE IF EXISTS ods_coupon_info;
CREATE EXTERNAL TABLE ods_coupon_info(
    id STRING COMMENT '优惠券ID',
    coupon_name STRING COMMENT '优惠券名称',
    coupon_type STRING COMMENT '优惠券类型',
    coupon_desc STRING COMMENT '优惠券描述',
    discount_amount DECIMAL(16,2) COMMENT '优惠金额',
    threshold_amount DECIMAL(16,2) COMMENT '使用门槛金额',
    start_time STRING COMMENT '开始时间',
    end_time STRING COMMENT '结束时间',
    create_time STRING COMMENT '创建时间'
) COMMENT '优惠活动表'
PARTITIONED BY (dt STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/gmall/ods/ods_coupon_info';

-- 6.2 优惠劵使用表
DROP TABLE IF EXISTS ods_coupon_use;
CREATE EXTERNAL TABLE ods_coupon_use(
    id STRING COMMENT '使用记录ID',
    coupon_id STRING COMMENT '优惠券ID',
    user_id STRING COMMENT '用户ID',
    order_id STRING COMMENT '订单ID',
    coupon_status STRING COMMENT '优惠券状态',
    create_time STRING COMMENT '获取时间',
    used_time STRING COMMENT '使用时间',
    expire_time STRING COMMENT '过期时间'
) COMMENT '优惠券使用表'
PARTITIONED BY (dt STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/gmall/ods/ods_coupon_use';

-- 6.3 活动表
DROP TABLE IF EXISTS ods_activity_info;
CREATE EXTERNAL TABLE ods_activity_info(
    id STRING COMMENT '活动ID',
    activity_name STRING COMMENT '活动名称',
    activity_type STRING COMMENT '活动类型',
    activity_desc STRING COMMENT '活动描述',
    start_time STRING COMMENT '开始时间',
    end_time STRING COMMENT '结束时间',
    create_time STRING COMMENT '创建时间'
) COMMENT '活动表'
PARTITIONED BY (dt STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/gmall/ods/ods_activity_info';

-- 6.4 活动订单关联表
DROP TABLE IF EXISTS ods_activity_order;
CREATE EXTERNAL TABLE ods_activity_order(
    id STRING COMMENT 'ID',
    activity_id STRING COMMENT '活动ID',
    order_id STRING COMMENT '订单ID',
    create_time STRING COMMENT '创建时间'
) COMMENT '活动订单关联表'
PARTITIONED BY (dt STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/gmall/ods/ods_activity_order';

-- ============================================
-- 7. 评价域
-- ============================================

-- 7.1 商品评论表
DROP TABLE IF EXISTS ods_comment_info;
CREATE EXTERNAL TABLE ods_comment_info(
    id STRING COMMENT '评论ID',
    user_id STRING COMMENT '用户ID',
    sku_id STRING COMMENT 'SKU ID',
    order_id STRING COMMENT '订单ID',
    appraisal_star STRING COMMENT '评价星级',
    ip_opt STRING COMMENT '评论IP',
    create_time STRING COMMENT '评论时间',
    appraise STRING COMMENT '评价内容'
) COMMENT '商品评论表'
PARTITIONED BY (dt STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/gmall/ods/ods_comment_info';

-- ============================================
-- 8. 地区域
-- ============================================

-- 8.1 地区表
DROP TABLE IF EXISTS ods_base_province;
CREATE EXTERNAL TABLE ods_base_province(
    id STRING COMMENT '地区ID',
    name STRING COMMENT '地区名称',
    region_id STRING COMMENT '区域ID',
    area_code STRING COMMENT '地区编码',
    iso_code STRING COMMENT 'ISO编码'
) COMMENT '地区表'
PARTITIONED BY (dt STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/gmall/ods/ods_base_province';

-- 8.2 区域表
DROP TABLE IF EXISTS ods_base_region;
CREATE EXTERNAL TABLE ods_base_region(
    id STRING COMMENT '区域ID',
    region_name STRING COMMENT '区域名称'
) COMMENT '区域表'
PARTITIONED BY (dt STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/gmall/ods/ods_base_region';

-- ============================================
-- 9. 收藏域
-- ============================================

-- 9.1 商品收藏表
DROP TABLE IF EXISTS ods_favor_info;
CREATE EXTERNAL TABLE ods_favor_info(
    id STRING COMMENT '收藏ID',
    user_id STRING COMMENT '用户ID',
    sku_id STRING COMMENT 'SKU ID',
    create_time STRING COMMENT '收藏时间',
    cancel_time STRING COMMENT '取消时间'
) COMMENT '商品收藏表'
PARTITIONED BY (dt STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/gmall/ods/ods_favor_info';

-- 9.2 购物车表
DROP TABLE IF EXISTS ods_cart_info;
CREATE EXTERNAL TABLE ods_cart_info(
    id STRING COMMENT '购物车ID',
    user_id STRING COMMENT '用户ID',
    sku_id STRING COMMENT 'SKU ID',
    sku_num BIGINT COMMENT '商品数量',
    create_time STRING COMMENT '创建时间',
    operate_time STRING COMMENT '操作时间'
) COMMENT '购物车表'
PARTITIONED BY (dt STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/gmall/ods/ods_cart_info';

-- ============================================
-- 10. 客服域
-- ============================================

-- 10.1 客服工单表
DROP TABLE IF EXISTS ods_customer_service;
CREATE EXTERNAL TABLE ods_customer_service(
    id STRING COMMENT '工单ID',
    user_id STRING COMMENT '用户ID',
    order_id STRING COMMENT '订单ID',
    sku_id STRING COMMENT 'SKU ID',
    service_type STRING COMMENT '服务类型',
    service_content STRING COMMENT '服务内容',
    create_time STRING COMMENT '创建时间',
    handle_time STRING COMMENT '处理时间',
    handle_result STRING COMMENT '处理结果'
) COMMENT '客服工单表'
PARTITIONED BY (dt STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/warehouse/gmall/ods/ods_customer_service';

-- ============================================
-- 生命周期管理
-- ============================================

-- ODS层数据保留策略：保留90天
-- ALTER TABLE ods_user_info SET TBLPROPERTIES ('retention'='90');
-- ALTER TABLE ods_order_info SET TBLPROPERTIES ('retention'='90');
-- ALTER TABLE ods_order_detail SET TBLPROPERTIES ('retention'='90');
-- ALTER TABLE ods_sku_info SET TBLPROPERTIES ('retention'='90');

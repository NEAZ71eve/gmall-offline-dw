
-- ============================================
-- DWD层建表脚本 - 完整版
-- 包含电商核心事实表：订单、支付、退款、商品、活动、优惠券等
-- ============================================

USE gmall_dwd;

-- ============================================
-- 1. 订单域事实表
-- ============================================

-- 1.1 订单明细事实表
DROP TABLE IF EXISTS dwd_order_detail;
CREATE EXTERNAL TABLE dwd_order_detail(
    id STRING COMMENT '订单明细ID',
    order_id STRING COMMENT '订单ID',
    user_id STRING COMMENT '用户ID',
    sku_id STRING COMMENT 'SKU ID',
    sku_name STRING COMMENT '商品名称',
    province_id STRING COMMENT '省份ID',
    order_status STRING COMMENT '订单状态',
    create_time STRING COMMENT '创建时间',
    sku_num BIGINT COMMENT '商品数量',
    original_amount DECIMAL(16,2) COMMENT '原始金额(单价*数量)',
    activity_reduce DECIMAL(16,2) COMMENT '活动减免金额',
    coupon_reduce DECIMAL(16,2) COMMENT '优惠券减免金额',
    final_amount DECIMAL(16,2) COMMENT '最终金额(应付金额)',
    date_id STRING COMMENT '日期ID'
) COMMENT '订单明细事实表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dwd/dwd_order_detail'
TBLPROPERTIES('orc.compress'='snappy');

-- 1.2 订单主事实表
DROP TABLE IF EXISTS dwd_order_info;
CREATE EXTERNAL TABLE dwd_order_info(
    id STRING COMMENT '订单ID',
    order_status STRING COMMENT '订单状态',
    user_id STRING COMMENT '用户ID',
    province_id STRING COMMENT '省份ID',
    payment_way STRING COMMENT '支付方式',
    delivery_address STRING COMMENT '配送地址',
    total_amount DECIMAL(16,2) COMMENT '订单总金额',
    out_trade_no STRING COMMENT '交易流水号',
    create_time STRING COMMENT '创建时间',
    operate_time STRING COMMENT '操作时间',
    expire_time STRING COMMENT '过期时间',
    refund_time STRING COMMENT '退款时间',
    refund_status STRING COMMENT '退款状态',
    date_id STRING COMMENT '日期ID'
) COMMENT '订单主事实表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dwd/dwd_order_info'
TBLPROPERTIES('orc.compress'='snappy');

-- 1.3 订单状态流转事实表
DROP TABLE IF EXISTS dwd_order_status_log;
CREATE EXTERNAL TABLE dwd_order_status_log(
    id STRING COMMENT '日志ID',
    order_id STRING COMMENT '订单ID',
    order_status STRING COMMENT '订单状态',
    change_time STRING COMMENT '状态变更时间',
    operate_user_id STRING COMMENT '操作用户ID',
    operate_time STRING COMMENT '操作时间',
    remark STRING COMMENT '备注',
    date_id STRING COMMENT '日期ID'
) COMMENT '订单状态流转事实表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dwd/dwd_order_status_log'
TBLPROPERTIES('orc.compress'='snappy');

-- ============================================
-- 2. 支付域事实表
-- ============================================

-- 2.1 支付事实表
DROP TABLE IF EXISTS dwd_payment_info;
CREATE EXTERNAL TABLE dwd_payment_info(
    id STRING COMMENT '支付ID',
    order_id STRING COMMENT '订单ID',
    user_id STRING COMMENT '用户ID',
    payment_type STRING COMMENT '支付类型',
    trade_no STRING COMMENT '第三方交易流水号',
    out_trade_no STRING COMMENT '交易订单号',
    total_amount DECIMAL(16,2) COMMENT '支付金额',
    subject STRING COMMENT '交易内容',
    payment_status STRING COMMENT '支付状态',
    create_time STRING COMMENT '创建时间',
    callback_time STRING COMMENT '回调时间',
    date_id STRING COMMENT '日期ID'
) COMMENT '支付事实表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dwd/dwd_payment_info'
TBLPROPERTIES('orc.compress'='snappy');

-- ============================================
-- 3. 退款域事实表
-- ============================================

-- 3.1 退款事实表
DROP TABLE IF EXISTS dwd_order_refund_info;
CREATE EXTERNAL TABLE dwd_order_refund_info(
    id STRING COMMENT '退款ID',
    order_id STRING COMMENT '订单ID',
    user_id STRING COMMENT '用户ID',
    sku_id STRING COMMENT 'SKU ID',
    refund_type STRING COMMENT '退款类型',
    refund_num BIGINT COMMENT '退款数量',
    refund_amount DECIMAL(16,2) COMMENT '退款金额',
    refund_reason_type STRING COMMENT '退款原因类型',
    refund_reason_txt STRING COMMENT '退款原因描述',
    refund_status STRING COMMENT '退款状态',
    create_time STRING COMMENT '创建时间',
    operate_time STRING COMMENT '操作时间',
    date_id STRING COMMENT '日期ID'
) COMMENT '退款事实表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dwd/dwd_order_refund_info'
TBLPROPERTIES('orc.compress'='snappy');

-- ============================================
-- 4. 商品域事实表
-- ============================================

-- 4.1 商品SKU事实表
DROP TABLE IF EXISTS dwd_sku_info;
CREATE EXTERNAL TABLE dwd_sku_info(
    id STRING COMMENT 'SKU ID',
    spu_id STRING COMMENT 'SPU ID',
    sku_name STRING COMMENT '商品名称',
    sku_desc STRING COMMENT '商品描述',
    price DECIMAL(16,2) COMMENT '价格',
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
) COMMENT '商品SKU事实表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dwd/dwd_sku_info'
TBLPROPERTIES('orc.compress'='snappy');

-- ============================================
-- 5. 促销域事实表
-- ============================================

-- 5.1 优惠券事实表
DROP TABLE IF EXISTS dwd_coupon_info;
CREATE EXTERNAL TABLE dwd_coupon_info(
    id STRING COMMENT '优惠券ID',
    coupon_name STRING COMMENT '优惠券名称',
    coupon_type STRING COMMENT '优惠券类型',
    coupon_desc STRING COMMENT '优惠券描述',
    discount_amount DECIMAL(16,2) COMMENT '优惠金额',
    threshold_amount DECIMAL(16,2) COMMENT '使用门槛金额',
    start_time STRING COMMENT '开始时间',
    end_time STRING COMMENT '结束时间',
    create_time STRING COMMENT '创建时间'
) COMMENT '优惠券事实表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dwd/dwd_coupon_info'
TBLPROPERTIES('orc.compress'='snappy');

-- 5.2 优惠券使用事实表
DROP TABLE IF EXISTS dwd_coupon_use;
CREATE EXTERNAL TABLE dwd_coupon_use(
    id STRING COMMENT '使用记录ID',
    coupon_id STRING COMMENT '优惠券ID',
    user_id STRING COMMENT '用户ID',
    order_id STRING COMMENT '订单ID',
    coupon_status STRING COMMENT '优惠券状态',
    get_time STRING COMMENT '获取时间',
    used_time STRING COMMENT '使用时间',
    expire_time STRING COMMENT '过期时间',
    date_id STRING COMMENT '日期ID'
) COMMENT '优惠券使用事实表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dwd/dwd_coupon_use'
TBLPROPERTIES('orc.compress'='snappy');

-- 5.3 活动事实表
DROP TABLE IF EXISTS dwd_activity_info;
CREATE EXTERNAL TABLE dwd_activity_info(
    id STRING COMMENT '活动ID',
    activity_name STRING COMMENT '活动名称',
    activity_type STRING COMMENT '活动类型',
    activity_desc STRING COMMENT '活动描述',
    start_time STRING COMMENT '开始时间',
    end_time STRING COMMENT '结束时间',
    create_time STRING COMMENT '创建时间'
) COMMENT '活动事实表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dwd/dwd_activity_info'
TBLPROPERTIES('orc.compress'='snappy');

-- 5.4 活动优惠关联事实表
DROP TABLE IF EXISTS dwd_activity_order;
CREATE EXTERNAL TABLE dwd_activity_order(
    id STRING COMMENT 'ID',
    activity_id STRING COMMENT '活动ID',
    activity_rule_id STRING COMMENT '活动规则ID',
    order_id STRING COMMENT '订单ID',
    user_id STRING COMMENT '用户ID',
    sku_id STRING COMMENT 'SKU ID',
    reduce_amount DECIMAL(16,2) COMMENT '优惠金额',
    create_time STRING COMMENT '创建时间',
    date_id STRING COMMENT '日期ID'
) COMMENT '活动优惠关联事实表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dwd/dwd_activity_order'
TBLPROPERTIES('orc.compress'='snappy');

-- ============================================
-- 6. 评价域事实表
-- ============================================

-- 6.1 商品评论事实表
DROP TABLE IF EXISTS dwd_comment_info;
CREATE EXTERNAL TABLE dwd_comment_info(
    id STRING COMMENT '评论ID',
    user_id STRING COMMENT '用户ID',
    sku_id STRING COMMENT 'SKU ID',
    order_id STRING COMMENT '订单ID',
    appraisal_star STRING COMMENT '评价星级',
    ip_opt STRING COMMENT '评论IP',
    create_time STRING COMMENT '评论时间',
    appraise STRING COMMENT '评价内容',
    date_id STRING COMMENT '日期ID'
) COMMENT '商品评论事实表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dwd/dwd_comment_info'
TBLPROPERTIES('orc.compress'='snappy');

-- ============================================
-- 7. 收藏域事实表
-- ============================================

-- 7.1 商品收藏事实表
DROP TABLE IF EXISTS dwd_favor_info;
CREATE EXTERNAL TABLE dwd_favor_info(
    id STRING COMMENT '收藏ID',
    user_id STRING COMMENT '用户ID',
    sku_id STRING COMMENT 'SKU ID',
    create_time STRING COMMENT '收藏时间',
    cancel_time STRING COMMENT '取消时间',
    date_id STRING COMMENT '日期ID'
) COMMENT '商品收藏事实表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/workspace/gmall/dwd/dwd_favor_info'
TBLPROPERTIES('orc.compress'='snappy');

-- 7.2 购物车事实表
DROP TABLE IF EXISTS dwd_cart_info;
CREATE EXTERNAL TABLE dwd_cart_info(
    id STRING COMMENT '购物车ID',
    user_id STRING COMMENT '用户ID',
    sku_id STRING COMMENT 'SKU ID',
    sku_num BIGINT COMMENT '商品数量',
    create_time STRING COMMENT '创建时间',
    operate_time STRING COMMENT '操作时间',
    is_ordered STRING COMMENT '是否已下单',
    date_id STRING COMMENT '日期ID'
) COMMENT '购物车事实表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dwd/dwd_cart_info'
TBLPROPERTIES('orc.compress'='snappy');

-- ============================================
-- 8. 客服域事实表
-- ============================================

-- 8.1 客服工单事实表
DROP TABLE IF EXISTS dwd_customer_service;
CREATE EXTERNAL TABLE dwd_customer_service(
    id STRING COMMENT '工单ID',
    user_id STRING COMMENT '用户ID',
    order_id STRING COMMENT '订单ID',
    sku_id STRING COMMENT 'SKU ID',
    service_type STRING COMMENT '服务类型',
    service_content STRING COMMENT '服务内容',
    create_time STRING COMMENT '创建时间',
    handle_time STRING COMMENT '处理时间',
    handle_result STRING COMMENT '处理结果',
    date_id STRING COMMENT '日期ID'
) COMMENT '客服工单事实表'
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/dwd/dwd_customer_service'
TBLPROPERTIES('orc.compress'='snappy');

-- ============================================
-- 生命周期管理
-- ============================================

-- DWD层数据保留策略：保留30天
-- ALTER TABLE dwd_order_detail SET TBLPROPERTIES ('retention'='30');
-- ALTER TABLE dwd_order_info SET TBLPROPERTIES ('retention'='30');
-- ALTER TABLE dwd_payment_info SET TBLPROPERTIES ('retention'='30');

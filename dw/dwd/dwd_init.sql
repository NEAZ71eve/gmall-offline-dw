
-- ============================================
-- DWD层建表脚本
-- 明细数据层，清洗、脱敏、去重、统一规范
-- ============================================

-- 创建DWD数据库
CREATE DATABASE IF NOT EXISTS dwd_ecommerce;
USE dwd_ecommerce;

-- 1. 订单明细表（事务型事实表）
DROP TABLE IF EXISTS dwd_order_detail_inc;
CREATE EXTERNAL TABLE dwd_order_detail_inc(
    `id` STRING COMMENT '订单明细ID',
    `order_id` STRING COMMENT '订单ID',
    `user_id` STRING COMMENT '用户ID',
    `sku_id` STRING COMMENT 'SKU ID',
    `province_id` STRING COMMENT '地区ID',
    `activity_id` STRING COMMENT '活动ID',
    `coupon_id` STRING COMMENT '优惠券ID',
    `date_id` STRING COMMENT '日期ID',
    `create_time` STRING COMMENT '创建时间',
    `sku_num` BIGINT COMMENT '商品数量',
    `split_original_amount` DECIMAL(16,2) COMMENT '原始价格',
    `split_activity_amount` DECIMAL(16,2) COMMENT '活动减免',
    `split_coupon_amount` DECIMAL(16,2) COMMENT '优惠券减免',
    `split_total_amount` DECIMAL(16,2) COMMENT '实际支付'
) COMMENT '订单明细事务型事实表'
PARTITIONED BY (`dt` STRING)
STORED AS ORC
LOCATION '/warehouse/dwd_ecommerce/dwd_order_detail_inc'
TBLPROPERTIES('orc.compress'='snappy');

-- 2. 支付明细表（事务型事实表）
DROP TABLE IF EXISTS dwd_payment_info_inc;
CREATE EXTERNAL TABLE dwd_payment_info_inc(
    `id` STRING COMMENT '支付ID',
    `order_id` STRING COMMENT '订单ID',
    `user_id` STRING COMMENT '用户ID',
    `payment_type` STRING COMMENT '支付方式',
    `trade_no` STRING COMMENT '交易编号',
    `date_id` STRING COMMENT '日期ID',
    `callback_time` STRING COMMENT '回调时间',
    `total_amount` DECIMAL(16,2) COMMENT '支付金额'
) COMMENT '支付事实表'
PARTITIONED BY (`dt` STRING)
STORED AS ORC
LOCATION '/warehouse/dwd_ecommerce/dwd_payment_info_inc'
TBLPROPERTIES('orc.compress'='snappy');

-- 3. 退单明细表（事务型事实表）
DROP TABLE IF EXISTS dwd_order_refund_info_inc;
CREATE EXTERNAL TABLE dwd_order_refund_info_inc(
    `id` STRING COMMENT '退单ID',
    `user_id` STRING COMMENT '用户ID',
    `order_id` STRING COMMENT '订单ID',
    `sku_id` STRING COMMENT 'SKU ID',
    `province_id` STRING COMMENT '地区ID',
    `date_id` STRING COMMENT '日期ID',
    `create_time` STRING COMMENT '创建时间',
    `refund_type` STRING COMMENT '退单类型',
    `refund_num` BIGINT COMMENT '退单数量',
    `refund_amount` DECIMAL(16,2) COMMENT '退单金额'
) COMMENT '退单事实表'
PARTITIONED BY (`dt` STRING)
STORED AS ORC
LOCATION '/warehouse/dwd_ecommerce/dwd_order_refund_info_inc'
TBLPROPERTIES('orc.compress'='snappy');

-- 4. 页面日志表（事务型事实表）
DROP TABLE IF EXISTS dwd_page_log_full;
CREATE EXTERNAL TABLE dwd_page_log_full(
    `date_id` STRING COMMENT '日期ID',
    `user_id` STRING COMMENT '用户ID',
    `province_id` STRING COMMENT '地区ID',
    `version_code` STRING COMMENT '版本号',
    `channel` STRING COMMENT '渠道',
    `is_new` STRING COMMENT '是否新用户',
    `model` STRING COMMENT '设备型号',
    `mid_id` STRING COMMENT '设备ID',
    `brand` STRING COMMENT '品牌',
    `operate_system` STRING COMMENT '操作系统',
    `page_id` STRING COMMENT '页面ID',
    `last_page_id` STRING COMMENT '上页ID',
    `page_item` STRING COMMENT '页面项',
    `page_item_type` STRING COMMENT '页面项类型',
    `during_time` BIGINT COMMENT '持续时间',
    `ts` BIGINT COMMENT '时间戳'
) COMMENT '页面日志事实表'
PARTITIONED BY (`dt` STRING)
STORED AS ORC
LOCATION '/warehouse/dwd_ecommerce/dwd_page_log_full'
TBLPROPERTIES('orc.compress'='snappy');

-- 5. 启动日志表（事务型事实表）
DROP TABLE IF EXISTS dwd_start_log_full;
CREATE EXTERNAL TABLE dwd_start_log_full(
    `date_id` STRING COMMENT '日期ID',
    `user_id` STRING COMMENT '用户ID',
    `province_id` STRING COMMENT '地区ID',
    `version_code` STRING COMMENT '版本号',
    `channel` STRING COMMENT '渠道',
    `is_new` STRING COMMENT '是否新用户',
    `model` STRING COMMENT '设备型号',
    `mid_id` STRING COMMENT '设备ID',
    `brand` STRING COMMENT '品牌',
    `operate_system` STRING COMMENT '操作系统',
    `entry` STRING COMMENT '入口',
    `open_ad_id` STRING COMMENT '广告ID',
    `loading_time` BIGINT COMMENT '加载时间',
    `open_ad_ms` BIGINT COMMENT '广告加载时间',
    `open_ad_skip_ms` BIGINT COMMENT '广告跳过时间',
    `ts` BIGINT COMMENT '时间戳'
) COMMENT '启动日志事实表'
PARTITIONED BY (`dt` STRING)
STORED AS ORC
LOCATION '/warehouse/dwd_ecommerce/dwd_start_log_full'
TBLPROPERTIES('orc.compress'='snappy');

-- 6. 加购明细表（事务型事实表）
DROP TABLE IF EXISTS dwd_cart_info_inc;
CREATE EXTERNAL TABLE dwd_cart_info_inc(
    `id` STRING COMMENT '购物车ID',
    `user_id` STRING COMMENT '用户ID',
    `sku_id` STRING COMMENT 'SKU ID',
    `date_id` STRING COMMENT '日期ID',
    `create_time` STRING COMMENT '创建时间',
    `source_type` STRING COMMENT '来源类型',
    `source_id` STRING COMMENT '来源ID',
    `sku_num` BIGINT COMMENT '商品数量',
    `is_checked` STRING COMMENT '是否选中',
    `order_time` STRING COMMENT '下单时间',
    `order_id` STRING COMMENT '订单ID'
) COMMENT '加购事实表'
PARTITIONED BY (`dt` STRING)
STORED AS ORC
LOCATION '/warehouse/dwd_ecommerce/dwd_cart_info_inc'
TBLPROPERTIES('orc.compress'='snappy');

-- 7. 收藏明细表（事务型事实表）
DROP TABLE IF EXISTS dwd_favor_info_inc;
CREATE EXTERNAL TABLE dwd_favor_info_inc(
    `id` STRING COMMENT '收藏ID',
    `user_id` STRING COMMENT '用户ID',
    `sku_id` STRING COMMENT 'SKU ID',
    `date_id` STRING COMMENT '日期ID',
    `create_time` STRING COMMENT '创建时间'
) COMMENT '收藏事实表'
PARTITIONED BY (`dt` STRING)
STORED AS ORC
LOCATION '/warehouse/dwd_ecommerce/dwd_favor_info_inc'
TBLPROPERTIES('orc.compress'='snappy');

-- 8. 评论明细表（事务型事实表）
DROP TABLE IF EXISTS dwd_comment_info_inc;
CREATE EXTERNAL TABLE dwd_comment_info_inc(
    `id` STRING COMMENT '评论ID',
    `user_id` STRING COMMENT '用户ID',
    `sku_id` STRING COMMENT 'SKU ID',
    `order_id` STRING COMMENT '订单ID',
    `date_id` STRING COMMENT '日期ID',
    `create_time` STRING COMMENT '创建时间',
    `appraise` STRING COMMENT '评价',
    `comment_txt` STRING COMMENT '评论内容'
) COMMENT '评论事实表'
PARTITIONED BY (`dt` STRING)
STORED AS ORC
LOCATION '/warehouse/dwd_ecommerce/dwd_comment_info_inc'
TBLPROPERTIES('orc.compress'='snappy');


-- ============================================================================
-- ETL脚本：ODS层 -> DWD层（明细数据层）
-- 功能：数据清洗、去重、脱敏、格式统一、维度关联
-- 作者：电商数仓项目
-- 创建时间：2024-01-01
-- ============================================================================

-- ============================================================================
-- 1. 订单明细事实表（DWD_ORDER_DETAIL）
-- ============================================================================
-- 数据清洗规则：
-- 1. 过滤脏数据（订单ID为空、商品ID为空、数量<=0）
-- 2. 数据脱敏（可选）
-- 3. 关联维度信息
-- 4. 去重处理

INSERT OVERWRITE TABLE gmall_dwd.dwd_order_detail PARTITION(dt = '${biz_date}')
SELECT
    od.id,                           -- 订单明细ID
    od.order_id,                     -- 订单ID
    od.sku_id,                       -- 商品SKU ID
    od.sku_name,                     -- 商品名称
    od.img_url,                      -- 商品图片
    od.order_price,                  -- 订单价格
    od.sku_num,                      -- 购买数量
    od.create_time,                  -- 创建时间
    od.source_id,                    -- 来源ID
    od.source_type,                   -- 来源类型
    -- 关联商品维度
    sku.category1_id,                -- 一级分类ID
    sku.category1_name,              -- 一级分类名称
    sku.category2_id,                -- 二级分类ID
    sku.category2_name,              -- 二级分类名称
    sku.category3_id,                -- 三级分类ID
    sku.category3_name,              -- 三级分类名称
    sku.tm_id,                       -- 品牌ID
    sku.tm_name,                     -- 品牌名称
    -- 计算字段
    od.order_price * od.sku_num AS order_amount,  -- 订单明细金额
    FROM_UNIXTIME(UNIX_TIMESTAMP()) AS etl_time   -- ETL时间
FROM gmall_ods.ods_order_detail od
LEFT JOIN gmall_dim.dim_sku sku ON od.sku_id = sku.id AND sku.dt = '${biz_date}'
WHERE od.dt = '${biz_date}'
-- 过滤脏数据
AND od.id IS NOT NULL AND od.id != ''
AND od.order_id IS NOT NULL AND od.order_id != ''
AND od.sku_id IS NOT NULL AND od.sku_id != ''
AND od.sku_num > 0
AND od.order_price >= 0;

-- ============================================================================
-- 2. 订单信息事实表（DWD_ORDER_INFO）
-- ============================================================================
-- 数据清洗规则：
-- 1. 过滤脏数据（订单ID为空、用户ID为空）
-- 2. 标准化订单状态
-- 3. 标准化支付方式
-- 4. 关联用户维度（获取用户基本信息）
-- 5. 关联地区维度

INSERT OVERWRITE TABLE gmall_dwd.dwd_order_info PARTITION(dt = '${biz_date}')
SELECT
    oi.id,                            -- 订单ID
    oi.order_id,                      -- 订单编号
    oi.user_id,                       -- 用户ID
    oi.province_id,                   -- 地区ID
    oi.order_status,                  -- 订单状态
    -- 订单状态标准化
    CASE oi.order_status
        WHEN '1001' THEN 'UNPAID'
        WHEN '1002' THEN 'PAID'
        WHEN '1003' THEN 'SHIPPED'
        WHEN '1004' THEN 'COMPLETED'
        WHEN '1005' THEN 'CLOSED'
        WHEN '1006' THEN 'REFUNDED'
        ELSE 'UNKNOWN'
    END AS order_status_name,         -- 订单状态名称
    oi.payment_way,                   -- 支付方式
    -- 支付方式标准化
    CASE oi.payment_way
        WHEN '1' THEN 'ONLINE'
        WHEN '2' THEN 'OFFLINE'
        WHEN '3' THEN 'COUPON'
        ELSE 'UNKNOWN'
    END AS payment_way_name,          -- 支付方式名称
    oi.delivery_address,              -- 收货地址
    oi.out_trade_no,                  -- 外部交易编号
    oi.trade_body,                    -- 交易描述
    oi.total_amount,                  -- 总金额
    oi.benefit_reduce_amount,         -- 优惠金额
    oi.original_total_amount,         -- 原价总金额
    oi.feight_fee,                    -- 运费
    oi.create_time,                   -- 创建时间
    oi.operate_time,                  -- 操作时间
    oi.expire_time,                   -- 过期时间
    oi.tracking_no,                   -- 物流单号
    oi.parent_order_id,               -- 父订单ID
    oi.img_url,                       -- 图片URL
    -- 关联用户维度
    COALESCE(user.user_level, 'UNKNOWN') AS user_level,     -- 用户等级
    COALESCE(user.gender, 'UNKNOWN') AS user_gender,         -- 用户性别
    -- 关联地区维度
    COALESCE(province.province_name, 'UNKNOWN') AS province_name,
    -- 计算字段
    oi.total_amount - oi.feight_fee AS goods_amount,  -- 商品金额（去除运费）
    CASE WHEN oi.order_status IN ('1002', '1003', '1004') THEN 1 ELSE 0 END AS is_paid,  -- 是否已支付
    FROM_UNIXTIME(UNIX_TIMESTAMP()) AS etl_time  -- ETL时间
FROM gmall_ods.ods_order_info oi
LEFT JOIN gmall_dim.dim_user user ON oi.user_id = user.id
    AND user.dt = '${biz_date}'
    AND user.end_date = '9999-12-31'
LEFT JOIN gmall_dim.dim_province province ON oi.province_id = province.id
    AND province.dt = '${biz_date}'
WHERE oi.dt = '${biz_date}'
-- 过滤脏数据
AND oi.id IS NOT NULL AND oi.id != ''
AND oi.user_id IS NOT NULL AND oi.user_id != '';

-- ============================================================================
-- 3. 支付信息事实表（DWD_PAYMENT_INFO）
-- ============================================================================
INSERT OVERPLACE TABLE gmall_dwd.dwd_payment_info PARTITION(dt = '${biz_date}')
SELECT
    pi.payment_id,                     -- 支付ID
    pi.order_id,                      -- 订单ID
    pi.user_id,                        -- 用户ID
    pi.payment_type,                   -- 支付类型
    pi.trade_no,                       -- 交易编号
    pi.total_amount,                   -- 支付金额
    pi.subject,                        -- 支付主题
    pi.payment_status,                 -- 支付状态
    pi.create_time,                    -- 创建时间
    pi.callback_time,                  -- 回调时间
    oi.province_id,                    -- 地区ID
    FROM_UNIXTIME(UNIX_TIMESTAMP()) AS etl_time
FROM gmall_ods.ods_payment_info pi
LEFT JOIN gmall_dwd.dwd_order_info oi ON pi.order_id = oi.order_id AND oi.dt = '${biz_date}'
WHERE pi.dt = '${biz_date}'
AND pi.order_id IS NOT NULL AND pi.order_id != '';

-- ============================================================================
-- 4. 用户行为事实表（DWD_ACTION）
-- ============================================================================
-- 合并多个用户行为日志：浏览、收藏、加购、下单

INSERT OVERWRITE TABLE gmall_dwd.dwd_action PARTITION(dt = '${biz_date}')
SELECT
    -- 公共字段
    user_id,
    sku_id,
    session_id,
    dt,
    -- 行为详情
    action_id,
    action_code,
    action_name,
    action_time,
    action_target_id,
    action_target_type,
    -- 关联维度
    sku.category1_id,
    sku.category1_name,
    sku.category2_id,
    sku.category2_name,
    sku.category3_id,
    sku.category3_name,
    sku.tm_id,
    sku.tm_name,
    sku.sku_name,
    FROM_UNIXTIME(UNIX_TIMESTAMP()) AS etl_time
FROM (
    -- 页面浏览
    SELECT
        user_id,
        sku_id,
        session_id,
        dt,
        NULL AS action_id,
        'page_view' AS action_code,
        '页面浏览' AS action_name,
        action_time,
        page_id AS action_target_id,
        'page' AS action_target_type
    FROM gmall_ods.ods_action_page_view
    WHERE dt = '${biz_date}'
    AND user_id IS NOT NULL

    UNION ALL

    -- 商品收藏
    SELECT
        user_id,
        sku_id,
        session_id,
        dt,
        favor_id AS action_id,
        'favor_add' AS action_code,
        '收藏商品' AS action_name,
        create_time AS action_time,
        sku_id AS action_target_id,
        'sku' AS action_target_type
    FROM gmall_ods.ods_action_favor_add
    WHERE dt = '${biz_date}'
    AND user_id IS NOT NULL

    UNION ALL

    -- 加购物车
    SELECT
        user_id,
        sku_id,
        session_id,
        dt,
        cart_id AS action_id,
        'cart_add' AS action_code,
        '加购物车' AS action_name,
        create_time AS action_time,
        sku_id AS action_target_id,
        'sku' AS action_target_type
    FROM gmall_ods.ods_action_cart_add
    WHERE dt = '${biz_date}'
    AND user_id IS NOT NULL

    UNION ALL

    -- 下单
    SELECT
        user_id,
        sku_id,
        session_id,
        dt,
        order_detail_id AS action_id,
        'order' AS action_code,
        '下单' AS action_name,
        create_time AS action_time,
        order_id AS action_target_id,
        'order' AS action_target_type
    FROM gmall_ods.ods_action_order
    WHERE dt = '${biz_date}'
    AND user_id IS NOT NULL
) action_log
LEFT JOIN gmall_dim.dim_sku sku ON action_log.sku_id = sku.id AND sku.dt = '${biz_date}';

-- ============================================================================
-- 5. 退单事实表（DWD_ORDER_REFUND）
-- ============================================================================
INSERT OVERWRITE TABLE gmall_dwd.dwd_order_refund PARTITION(dt = '${biz_date}')
SELECT
    rr.refund_id,                      -- 退单ID
    rr.user_id,                        -- 用户ID
    rr.order_id,                       -- 订单ID
    rr.sku_id,                         -- 商品ID
    rr.refund_type,                    -- 退单类型
    rr.refund_num,                     -- 退单数量
    rr.refund_amount,                  -- 退单金额
    rr.refund_reason_type,             -- 退单原因类型
    rr.refund_reason_msg,              -- 退单原因
    rr.create_time,                    -- 创建时间
    oi.province_id,                    -- 地区ID
    sku.category1_id,                  -- 一级分类ID
    sku.category1_name,
    sku.category2_id,
    sku.category2_name,
    sku.category3_id,
    sku.category3_name,
    sku.tm_id,
    sku.tm_name,
    FROM_UNIXTIME(UNIX_TIMESTAMP()) AS etl_time
FROM gmall_ods.ods_order_refund_info rr
LEFT JOIN gmall_dwd.dwd_order_info oi ON rr.order_id = oi.order_id AND oi.dt = '${biz_date}'
LEFT JOIN gmall_dim.dim_sku sku ON rr.sku_id = sku.id AND sku.dt = '${biz_date}'
WHERE rr.dt = '${biz_date}'
AND rr.order_id IS NOT NULL;

-- ============================================================================
-- 6. 评价事实表（DWD_REVIEW）
-- ============================================================================
INSERT OVERWRITE TABLE gmall_dwd.dwd_review_info PARTITION(dt = '${biz_date}')
SELECT
    review_id,
    user_id,
    sku_id,
    order_id,
    review_star,
    review_timestamp,
    create_time,
    modify_time,
    sku.category1_id,
    sku.category1_name,
    sku.category2_id,
    sku.category2_name,
    sku.category3_id,
    sku.category3_name,
    sku.tm_id,
    sku.tm_name,
    FROM_UNIXTIME(UNIX_TIMESTAMP()) AS etl_time
FROM gmall_ods.ods_review_info review
LEFT JOIN gmall_dim.dim_sku sku ON review.sku_id = sku.id AND sku.dt = '${biz_date}'
WHERE review.dt = '${biz_date}'
AND user_id IS NOT NULL;

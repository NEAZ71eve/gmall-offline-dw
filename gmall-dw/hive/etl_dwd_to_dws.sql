-- ============================================================================
-- ETL脚本：DWD层 -> DWS层（汇总数据层）
-- 功能：按主题轻度聚合，为ADS层提供基础汇总数据
-- 作者：电商数仓项目
-- ============================================================================

-- ============================================================================
-- 1. GMV统计汇总表（DWS_GMV_STATS）
-- ============================================================================
-- 核心指标：每日GMV、订单数、下单人数、客单价

INSERT OVERWRITE TABLE gmall_dws.dws_gmv_stats PARTITION(dt = '${biz_date}')
SELECT
    '${biz_date}' AS date_id,                -- 日期ID
    COUNT(DISTINCT order_id) AS order_count,  -- 订单数
    COUNT(DISTINCT user_id) AS order_user_count,  -- 下单人数
    SUM(total_amount) AS gmv,                 -- GMV
    SUM(goods_amount) AS goods_amount,        -- 商品总额
    SUM(feight_fee) AS feight_fee,            -- 运费
    SUM(benefit_reduce_amount) AS discount_amount,  -- 优惠金额
    AVG(total_amount) AS avg_order_amount,     -- 平均客单价
    -- 按订单状态分组统计
    SUM(CASE WHEN order_status = 'PAID' THEN 1 ELSE 0 END) AS paid_order_count,    -- 已支付订单数
    SUM(CASE WHEN order_status = 'PAID' THEN total_amount ELSE 0 END) AS paid_gmv,  -- 已支付GMV
    SUM(CASE WHEN order_status = 'COMPLETED' THEN 1 ELSE 0 END) AS completed_order_count,  -- 已完成订单数
    SUM(CASE WHEN order_status = 'COMPLETED' THEN total_amount ELSE 0 END) AS completed_gmv  -- 已完成GMV
FROM gmall_dwd.dwd_order_info
WHERE dt = '${biz_date}';

-- ============================================================================
-- 2. 用户行为统计表（DWS_USER_ACTION_STATS）- 每日用户行为聚合
-- ============================================================================
INSERT OVERWRITE TABLE gmall_dws.dws_user_action_stats PARTITION(dt = '${biz_date}')
SELECT
    user_id,
    sku_id,
    date_id,
    SUM(page_view_count) AS page_view_count,      -- 浏览次数
    SUM(cart_add_count) AS cart_add_count,         -- 加购次数
    SUM(favor_add_count) AS favor_add_count,       -- 收藏次数
    SUM(order_count) AS order_count,               -- 下单次数
    SUM(order_amount) AS order_amount,             -- 下单金额
    SUM(payment_count) AS payment_count,           -- 支付次数
    SUM(payment_amount) AS payment_amount,         -- 支付金额
    SUM(refund_count) AS refund_count,             -- 退单次数
    SUM(refund_amount) AS refund_amount,           -- 退单金额
    FROM_UNIXTIME(UNIX_TIMESTAMP()) AS etl_time
FROM (
    -- 页面浏览
    SELECT
        user_id,
        sku_id,
        dt AS date_id,
        COUNT(*) AS page_view_count,
        0 AS cart_add_count,
        0 AS favor_add_count,
        0 AS order_count,
        0 AS order_amount,
        0 AS payment_count,
        0 AS payment_amount,
        0 AS refund_count,
        0 AS refund_amount
    FROM gmall_dwd.dwd_action
    WHERE dt = '${biz_date}'
    AND action_code = 'page_view'
    GROUP BY user_id, sku_id, dt

    UNION ALL

    -- 加购物车
    SELECT
        user_id,
        sku_id,
        dt AS date_id,
        0 AS page_view_count,
        COUNT(*) AS cart_add_count,
        0 AS favor_add_count,
        0 AS order_count,
        0 AS order_amount,
        0 AS payment_count,
        0 AS payment_amount,
        0 AS refund_count,
        0 AS refund_amount
    FROM gmall_dwd.dwd_action
    WHERE dt = '${biz_date}'
    AND action_code = 'cart_add'
    GROUP BY user_id, sku_id, dt

    UNION ALL

    -- 收藏
    SELECT
        user_id,
        sku_id,
        dt AS date_id,
        0 AS page_view_count,
        0 AS cart_add_count,
        COUNT(*) AS favor_add_count,
        0 AS order_count,
        0 AS order_amount,
        0 AS payment_count,
        0 AS payment_amount,
        0 AS refund_count,
        0 AS refund_amount
    FROM gmall_dwd.dwd_action
    WHERE dt = '${biz_date}'
    AND action_code = 'favor_add'
    GROUP BY user_id, sku_id, dt

    UNION ALL

    -- 下单
    SELECT
        user_id,
        sku_id,
        dt AS date_id,
        0 AS page_view_count,
        0 AS cart_add_count,
        0 AS favor_add_count,
        COUNT(DISTINCT order_id) AS order_count,
        SUM(order_amount) AS order_amount,
        0 AS payment_count,
        0 AS payment_amount,
        0 AS refund_count,
        0 AS refund_amount
    FROM gmall_dwd.dwd_order_detail
    WHERE dt = '${biz_date}'
    GROUP BY user_id, sku_id, dt

    UNION ALL

    -- 支付
    SELECT
        user_id,
        sku_id,
        dt AS date_id,
        0 AS page_view_count,
        0 AS cart_add_count,
        0 AS favor_add_count,
        0 AS order_count,
        0 AS order_amount,
        COUNT(DISTINCT order_id) AS payment_count,
        SUM(order_amount) AS payment_amount,
        0 AS refund_count,
        0 AS refund_amount
    FROM gmall_dwd.dwd_order_detail d
    JOIN gmall_dwd.dwd_order_info o
    ON d.order_id = o.order_id AND d.dt = o.dt
    WHERE d.dt = '${biz_date}'
    AND o.order_status IN ('PAID', 'SHIPPED', 'COMPLETED')
    GROUP BY user_id, sku_id, d.dt

    UNION ALL

    -- 退单
    SELECT
        user_id,
        sku_id,
        dt AS date_id,
        0 AS page_view_count,
        0 AS cart_add_count,
        0 AS favor_add_count,
        0 AS order_count,
        0 AS order_amount,
        0 AS payment_count,
        0 AS payment_amount,
        COUNT(DISTINCT refund_id) AS refund_count,
        SUM(refund_amount) AS refund_amount
    FROM gmall_dwd.dwd_order_refund
    WHERE dt = '${biz_date}'
    GROUP BY user_id, sku_id, dt
) user_action
GROUP BY user_id, sku_id, date_id;

-- ============================================================================
-- 3. 商品统计表（DWS_SKU_STATS）- 商品粒度统计
-- ============================================================================
INSERT OVERWRITE TABLE gmall_dws.dws_sku_stats PARTITION(dt = '${biz_date}')
SELECT
    sku_id,
    sku_name,
    category1_id,
    category1_name,
    category2_id,
    category2_name,
    category3_id,
    category3_name,
    tm_id,
    tm_name,
    '${biz_date}' AS date_id,
    -- 订单统计
    COUNT(DISTINCT order_id) AS order_count,        -- 订单数
    SUM(sku_num) AS order_num,                      -- 订单商品数
    SUM(order_amount) AS order_amount,              -- 订单金额
    -- 支付统计
    SUM(CASE WHEN order_id IN (
        SELECT order_id
        FROM gmall_dwd.dwd_order_info
        WHERE dt = '${biz_date}'
        AND order_status IN ('PAID', 'SHIPPED', 'COMPLETED')
    ) THEN 1 ELSE 0 END) AS payment_count,          -- 支付订单数
    SUM(CASE WHEN order_id IN (
        SELECT order_id
        FROM gmall_dwd.dwd_order_info
        WHERE dt = '${biz_date}'
        AND order_status IN ('PAID', 'SHIPPED', 'COMPLETED')
    ) THEN sku_num ELSE 0 END) AS payment_num,      -- 支付商品数
    SUM(CASE WHEN order_id IN (
        SELECT order_id
        FROM gmall_dwd.dwd_order_info
        WHERE dt = '${biz_date}'
        AND order_status IN ('PAID', 'SHIPPED', 'COMPLETED')
    ) THEN order_amount ELSE 0 END) AS payment_amount,  -- 支付金额
    -- 退单统计
    COUNT(DISTINCT refund_id) AS refund_count,       -- 退单数
    SUM(refund_num) AS refund_num,                   -- 退单商品数
    SUM(refund_amount) AS refund_amount,             -- 退单金额
    FROM_UNIXTIME(UNIX_TIMESTAMP()) AS etl_time
FROM gmall_dwd.dwd_order_detail
WHERE dt = '${biz_date}'
GROUP BY sku_id, sku_name, category1_id, category1_name,
         category2_id, category2_name, category3_id, category3_name,
         tm_id, tm_name;

-- ============================================================================
-- 4. 用户统计表（DWS_USER_STATS）- 用户粒度统计
-- ============================================================================
INSERT OVERWRITE TABLE gmall_dws.dws_user_stats PARTITION(dt = '${biz_date}')
SELECT
    user_id,
    user_level,
    gender,
    '${biz_date}' AS date_id,
    -- 订单统计
    COUNT(DISTINCT order_id) AS order_count,
    SUM(total_amount) AS order_amount,
    AVG(total_amount) AS avg_order_amount,
    -- 支付统计
    SUM(CASE WHEN is_paid = 1 THEN 1 ELSE 0 END) AS paid_order_count,
    SUM(CASE WHEN is_paid = 1 THEN total_amount ELSE 0 END) AS paid_amount,
    -- 商品统计
    SUM(goods_num) AS goods_num,
    -- 下单时段偏好
    MAX(CASE WHEN order_hour BETWEEN 0 AND 6 THEN '凌晨'
             WHEN order_hour BETWEEN 7 AND 12 THEN '上午'
             WHEN order_hour BETWEEN 13 AND 18 THEN '下午'
             ELSE '晚间' END) AS favorite_period,
    MIN(order_time) AS first_order_time,
    MAX(order_time) AS last_order_time,
    DATEDIFF('${biz_date}', MAX(order_time)) AS days_since_last_order,
    FROM_UNIXTIME(UNIX_TIMESTAMP()) AS etl_time
FROM (
    SELECT
        oi.user_id,
        oi.user_level,
        oi.user_gender AS gender,
        oi.order_id,
        oi.total_amount,
        oi.is_paid,
        HOUR(oi.create_time) AS order_hour,
        oi.create_time AS order_time,
        COUNT(DISTINCT od.id) AS goods_num
    FROM gmall_dwd.dwd_order_info oi
    LEFT JOIN gmall_dwd.dwd_order_detail od ON oi.order_id = od.order_id AND oi.dt = od.dt
    WHERE oi.dt = '${biz_date}'
    GROUP BY oi.user_id, oi.user_level, oi.user_gender, oi.order_id,
             oi.total_amount, oi.is_paid, oi.create_time
) user_orders
GROUP BY user_id, user_level, gender;

-- ============================================================================
-- 5. 地区统计表（DWS_PROVINCE_STATS）
-- ============================================================================
INSERT OVERWRITE TABLE gmall_dws.dws_province_stats PARTITION(dt = '${biz_date}')
SELECT
    province_id,
    province_name,
    region_id,
    region_name,
    '${biz_date}' AS date_id,
    COUNT(DISTINCT user_id) AS order_user_count,
    COUNT(DISTINCT order_id) AS order_count,
    SUM(total_amount) AS gmv,
    AVG(total_amount) AS avg_order_amount,
    SUM(goods_amount) AS goods_amount,
    SUM(feight_fee) AS feight_fee,
    SUM(benefit_reduce_amount) AS discount_amount,
    FROM_UNIXTIME(UNIX_TIMESTAMP()) AS etl_time
FROM gmall_dwd.dwd_order_info
WHERE dt = '${biz_date}'
GROUP BY province_id, province_name, region_id, region_name;

-- ============================================================================
-- 6. 品牌统计表（DWS_TRADEMARK_STATS）
-- ============================================================================
INSERT OVERWRITE TABLE gmall_dws.dws_trademark_stats PARTITION(dt = '${biz_date}')
SELECT
    tm_id,
    tm_name,
    '${biz_date}' AS date_id,
    COUNT(DISTINCT order_id) AS order_count,
    SUM(sku_num) AS sale_num,
    SUM(order_amount) AS sale_amount,
    AVG(order_price) AS avg_price,
    FROM_UNIXTIME(UNIX_TIMESTAMP()) AS etl_time
FROM gmall_dwd.dwd_order_detail
WHERE dt = '${biz_date}'
GROUP BY tm_id, tm_name;

-- ============================================================================
-- 7. 分类统计表（DWS_CATEGORY_STATS）
-- ============================================================================
INSERT OVERWRITE TABLE gmall_dws.dws_category_stats PARTITION(dt = '${biz_date}')
SELECT
    category1_id,
    category1_name,
    category2_id,
    category2_name,
    category3_id,
    category3_name,
    '${biz_date}' AS date_id,
    COUNT(DISTINCT order_id) AS order_count,
    SUM(sku_num) AS sale_num,
    SUM(order_amount) AS sale_amount,
    AVG(order_price) AS avg_price,
    FROM_UNIXTIME(UNIX_TIMESTAMP()) AS etl_time
FROM gmall_dwd.dwd_order_detail
WHERE dt = '${biz_date}'
GROUP BY category1_id, category1_name, category2_id, category2_name,
         category3_id, category3_name;

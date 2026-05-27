"""
Superset 图表SQL查询配置
包含所有业务报表的SQL查询
"""

# ============================================
# GMV统计报表
# ============================================

GMV_DAILY_SQL = """
SELECT
    dt AS 日期,
    gmv AS GMV,
    order_count AS 订单数,
    order_user_count AS 下单人数,
    payment_amount AS 支付金额,
    payment_user_count AS 支付人数
FROM gmall_ads.ads_gmv_day
WHERE recent_days = 1
ORDER BY dt DESC
"""

GMV_TREND_SQL = """
SELECT
    dt AS 日期,
    gmv AS GMV,
    order_count AS 订单数,
    order_user_count AS 下单人数
FROM gmall_dws.dws_gmv_stats
WHERE dt >= DATE_SUB(CURRENT_DATE(), 30)
ORDER BY dt ASC
"""

GMV_BY_PERIOD_SQL = """
SELECT
    recent_days AS 统计周期,
    SUM(gmv) AS 总GMV,
    SUM(order_count) AS 总订单数,
    SUM(order_user_count) AS 总下单人数,
    AVG(gmv / order_count) AS 平均客单价
FROM gmall_ads.ads_gmv_day
WHERE dt = CURRENT_DATE()
GROUP BY recent_days
ORDER BY recent_days
"""

# ============================================
# 商品销售报表
# ============================================

SKU_SALES_RANK_SQL = """
SELECT
    rank AS 排名,
    sku_id AS 商品ID,
    sku_name AS 商品名称,
    order_count AS 销量,
    order_amount AS 销售额
FROM gmall_ads.ads_sku_sales_rank
WHERE recent_days = 7
ORDER BY rank ASC
LIMIT 20
"""

SKU_CATEGORY_SALES_SQL = """
SELECT
    dim.category1_name AS 一级分类,
    dim.category2_name AS 二级分类,
    SUM(dwd.order_num) AS 销售数量,
    SUM(dwd.order_amount) AS 销售额
FROM gmall_dwd.dwd_order_detail dwd
LEFT JOIN gmall_dim.dim_sku dim ON dwd.sku_id = dim.id
WHERE dwd.dt >= DATE_SUB(CURRENT_DATE(), 7)
GROUP BY dim.category1_name, dim.category2_name
ORDER BY 销售额 DESC
"""

SKU_TREND_SQL = """
SELECT
    dwd.dt AS 日期,
    dim.sku_name AS 商品名称,
    SUM(dwd.sku_num) AS 销售数量,
    SUM(dwd.order_price * dwd.sku_num) AS 销售额
FROM gmall_dwd.dwd_order_detail dwd
LEFT JOIN gmall_dim.dim_sku dim ON dwd.sku_id = dim.id
WHERE dwd.dt >= DATE_SUB(CURRENT_DATE(), 30)
GROUP BY dwd.dt, dim.sku_name
ORDER BY dwd.dt ASC, 销售额 DESC
"""

# ============================================
# 用户分析报表
# ============================================

USER_RETENTION_SQL = """
SELECT
    create_date AS 注册日期,
    retention_day AS 留存天数,
    new_user_count AS 新增用户,
    retention_count AS 留存用户,
    retention_rate AS 留存率
FROM gmall_ads.ads_user_retention
WHERE dt = CURRENT_DATE()
ORDER BY create_date, retention_day
"""

USER_ORDER_STATS_SQL = """
SELECT
    user_id AS 用户ID,
    order_count AS 订单数,
    order_amount AS 消费总额,
    AVG(order_amount / order_count) AS 平均订单金额,
    MIN(first_order_date) AS 首次购买,
    MAX(last_order_date) AS 最后购买
FROM gmall_dws.dws_user_stats
GROUP BY user_id
ORDER BY 消费总额 DESC
LIMIT 100
"""

USER_LTV_SQL = """
SELECT
    CASE
        WHEN total_amount < 500 THEN '0-500'
        WHEN total_amount < 1000 THEN '500-1000'
        WHEN total_amount < 2000 THEN '1000-2000'
        WHEN total_amount < 5000 THEN '2000-5000'
        ELSE '5000+'
    END AS 消费区间,
    COUNT(*) AS 用户数,
    AVG(total_amount) AS 平均消费,
    SUM(total_amount) AS 总消费
FROM (
    SELECT
        user_id,
        SUM(order_amount) AS total_amount
    FROM gmall_dws.dws_user_stats
    GROUP BY user_id
) user_stats
GROUP BY CASE
    WHEN total_amount < 500 THEN '0-500'
    WHEN total_amount < 1000 THEN '500-1000'
    WHEN total_amount < 2000 THEN '1000-2000'
    WHEN total_amount < 5000 THEN '2000-5000'
    ELSE '5000+'
END
ORDER BY MIN(total_amount)
"""

# ============================================
# 转化率分析
# ============================================

CONVERSION_RATE_SQL = """
SELECT
    recent_days AS 统计周期,
    visit_count AS 访问数,
    cart_count AS 加购数,
    order_count AS 下单数,
    payment_count AS 支付数,
    ROUND(cart_count * 100.0 / visit_count, 2) AS 访问转加购率,
    ROUND(order_count * 100.0 / cart_count, 2) AS 加购转下单率,
    ROUND(payment_count * 100.0 / order_count, 2) AS 下单转支付率,
    ROUND(payment_count * 100.0 / visit_count, 2) AS 总体转化率
FROM gmall_ads.ads_conversion_rate
WHERE dt = CURRENT_DATE()
ORDER BY recent_days
"""

FUNNEL_ANALYSIS_SQL = """
SELECT
    '访问' AS 阶段,
    SUM(visit_count) AS 人数
FROM gmall_ads.ads_conversion_rate
WHERE dt = CURRENT_DATE() AND recent_days = 1
UNION ALL
SELECT
    '加购' AS 阶段,
    SUM(cart_count) AS 人数
FROM gmall_ads.ads_conversion_rate
WHERE dt = CURRENT_DATE() AND recent_days = 1
UNION ALL
SELECT
    '下单' AS 阶段,
    SUM(order_count) AS 人数
FROM gmall_ads.ads_conversion_rate
WHERE dt = CURRENT_DATE() AND recent_days = 1
UNION ALL
SELECT
    '支付' AS 阶段,
    SUM(payment_count) AS 人数
FROM gmall_ads.ads_conversion_rate
WHERE dt = CURRENT_DATE() AND recent_days = 1
"""

# ============================================
# 订单分析
# ============================================

ORDER_STATUS_SQL = """
SELECT
    order_status AS 订单状态,
    COUNT(*) AS 订单数,
    SUM(total_amount) AS 订单金额,
    AVG(total_amount) AS 平均金额
FROM gmall_dwd.dwd_order_info
WHERE dt >= DATE_SUB(CURRENT_DATE(), 7)
GROUP BY order_status
ORDER BY 订单数 DESC
"""

ORDER_HOUR_SQL = """
SELECT
    HOUR(create_time) AS 下单小时,
    COUNT(*) AS 订单数,
    SUM(total_amount) AS 订单金额
FROM gmall_dwd.dwd_order_info
WHERE dt >= DATE_SUB(CURRENT_DATE(), 7)
GROUP BY HOUR(create_time)
ORDER BY 下单小时
"""

ORDER_AMOUNT_DIST_SQL = """
SELECT
    CASE
        WHEN total_amount < 100 THEN '0-100'
        WHEN total_amount < 300 THEN '100-300'
        WHEN total_amount < 500 THEN '300-500'
        WHEN total_amount < 1000 THEN '500-1000'
        WHEN total_amount < 2000 THEN '1000-2000'
        ELSE '2000+'
    END AS 金额区间,
    COUNT(*) AS 订单数,
    SUM(total_amount) AS 总金额
FROM gmall_dwd.dwd_order_info
WHERE dt >= DATE_SUB(CURRENT_DATE(), 7)
GROUP BY CASE
    WHEN total_amount < 100 THEN '0-100'
    WHEN total_amount < 300 THEN '100-300'
    WHEN total_amount < 500 THEN '300-500'
    WHEN total_amount < 1000 THEN '500-1000'
    WHEN total_amount < 2000 THEN '1000-2000'
    ELSE '2000+'
END
ORDER BY MIN(total_amount)
"""

# ============================================
# 数据质量监控
# ============================================

DATA_QUALITY_SQL = """
SELECT
    'ads_gmv_day' AS 表名,
    COUNT(*) AS 记录数,
    MAX(dt) AS 最新分区,
    COUNT(DISTINCT dt) AS 分区数
FROM gmall_ads.ads_gmv_day
UNION ALL
SELECT
    'dws_gmv_stats' AS 表名,
    COUNT(*) AS 记录数,
    MAX(dt) AS 最新分区,
    COUNT(DISTINCT dt) AS 分区数
FROM gmall_dws.dws_gmv_stats
UNION ALL
SELECT
    'dwd_order_info' AS 表名,
    COUNT(*) AS 记录数,
    MAX(dt) AS 最新分区,
    COUNT(DISTINCT dt) AS 分区数
FROM gmall_dwd.dwd_order_info
UNION ALL
SELECT
    'dwd_order_detail' AS 表名,
    COUNT(*) AS 记录数,
    MAX(dt) AS 最新分区,
    COUNT(DISTINCT dt) AS 分区数
FROM gmall_dwd.dwd_order_detail
"""

# 导出所有查询为字典格式
ALL_QUERIES = {
    "GMV日报": GMV_DAILY_SQL,
    "GMV趋势": GMV_TREND_SQL,
    "GMV周期统计": GMV_BY_PERIOD_SQL,
    "商品销售排行": SKU_SALES_RANK_SQL,
    "商品分类销售": SKU_CATEGORY_SALES_SQL,
    "商品销售趋势": SKU_TREND_SQL,
    "用户留存": USER_RETENTION_SQL,
    "用户订单统计": USER_ORDER_STATS_SQL,
    "用户生命周期价值": USER_LTV_SQL,
    "转化率分析": CONVERSION_RATE_SQL,
    "漏斗分析": FUNNEL_ANALYSIS_SQL,
    "订单状态分布": ORDER_STATUS_SQL,
    "订单时段分析": ORDER_HOUR_SQL,
    "订单金额分布": ORDER_AMOUNT_DIST_SQL,
    "数据质量监控": DATA_QUALITY_SQL,
}

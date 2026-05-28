-- ============================================================================
-- ETL脚本：ODS层 -> DIM层（维度表）
-- 功能：构建和管理维度表，包括拉链表实现
-- 作者：电商数仓项目
-- 创建时间：2024-01-01
-- 更新时间：2024-01-08
-- ============================================================================

-- ============================================================================
-- 1. 用户维度表（拉链表）- 缓慢变化维 Type 2
-- ============================================================================
-- 拉链表核心思想：
-- 1. 记录数据的历史状态和当前状态
-- 2. 使用 start_date 和 end_date 确定数据的有效时间范围
-- 3. end_date = '9999-12-31' 表示当前有效数据
-- 4. 当数据发生变化时，关闭旧记录，开启新记录

-- Step 1: 初始化拉链表（首次执行）
-- 将 ODS 层用户数据初始化到 DIM 层
INSERT OVERWRITE TABLE gmall_dim.dim_user
PARTITION(dt = '${biz_date}')
SELECT
    id,                      -- 用户ID
    login_name,              -- 登录名
    nick_name,               -- 昵称
    name,                    -- 姓名
    phone_num,               -- 手机号
    email,                   -- 邮箱
    head_img,                -- 头像
    user_level,              -- 用户等级
    birthday,                 -- 生日
    gender,                   -- 性别
    create_time,             -- 创建时间
    operate_time,            -- 操作时间
    status,                   -- 状态
    '${biz_date}' AS start_date,   -- 开始日期
    '9999-12-31' AS end_date      -- 结束日期（表示当前有效）
FROM gmall_ods.ods_user_info
WHERE dt = '${biz_date}'
AND id IS NOT NULL
AND id != '';

-- Step 2: 拉链更新（每日增量执行）
-- 方案：先获取变化的数据，再更新拉链表

-- 2.1 先把该日变化的数据插入临时表
DROP TABLE IF EXISTS tmp_dim_user_changed;
CREATE TEMPORARY TABLE tmp_dim_user_changed AS
SELECT
    id,
    login_name,
    nick_name,
    name,
    phone_num,
    email,
    head_img,
    user_level,
    birthday,
    gender,
    create_time,
    operate_time,
    status,
    start_date,
    end_date
FROM gmall_dim.dim_user
WHERE 1 = 0;  -- 仅复制结构

-- 2.2 插入未变化的历史数据（保持原样）
INSERT INTO tmp_dim_user_changed
SELECT *
FROM gmall_dim.dim_user
WHERE end_date != '9999-12-31';  -- 已关闭的历史数据保留

-- 2.3 插入之前已关闭的数据（2024-01-08之前的）
INSERT INTO tmp_dim_user_changed
SELECT *
FROM gmall_dim.dim_user
WHERE end_date = '9999-12-31'
AND start_date < '${biz_date}'
AND id NOT IN (
    SELECT id
    FROM gmall_ods.ods_user_info
    WHERE dt = '${biz_date}'
);

-- 2.4 插入今日无变化的老数据（关闭到前一天）
INSERT INTO tmp_dim_user_changed
SELECT
    id,
    login_name,
    nick_name,
    name,
    phone_num,
    email,
    head_img,
    user_level,
    birthday,
    gender,
    create_time,
    operate_time,
    status,
    start_date,
    '${add_months}')  -- 结束日期
FROM gmall_dim.dim_user
WHERE end_date = '9999-12-31'
AND start_date < '${biz_date}'
AND CONCAT(id, login_name, nick_name, name, phone_num, email, user_level, status) = (
    SELECT CONCAT(id, login_name, nick_name, name, phone_num, email, user_level, status)
    FROM gmall_ods.ods_user_info
    WHERE dt = '${biz_date}'
    AND id = dim_user.id
);

-- 2.5 插入今日变化的新数据（开启新记录）
INSERT INTO tmp_dim_user_changed
SELECT
    id,
    login_name,
    nick_name,
    name,
    phone_num,
    email,
    head_img,
    user_level,
    birthday,
    gender,
    create_time,
    operate_time,
    status,
    '${biz_date}' AS start_date,
    '9999-12-31' AS end_date
FROM gmall_ods.ods_user_info
WHERE dt = '${biz_date}'
AND CONCAT(id, login_name, nick_name, name, phone_num, email, user_level, status) != (
    SELECT CONCAT(id, login_name, nick_name, name, phone_num, email, user_level, status)
    FROM gmall_dim.dim_user
    WHERE end_date = '9999-12-31'
    AND id = ods_user_info.id
);

-- 2.6 插入今日新增的数据
INSERT INTO tmp_dim_user_changed
SELECT
    id,
    login_name,
    nick_name,
    name,
    phone_num,
    email,
    head_img,
    user_level,
    birthday,
    gender,
    create_time,
    operate_time,
    status,
    '${biz_date}' AS start_date,
    '9999-12-31' AS end_date
FROM gmall_ods.ods_user_info
WHERE dt = '${biz_date}'
AND id NOT IN (
    SELECT id
    FROM gmall_dim.dim_user
    WHERE end_date = '9999-12-31'
);

-- 2.7 重新写入 DIM 层
INSERT OVERWRITE TABLE gmall_dim.dim_user
PARTITION(dt = '${biz_date}')
SELECT * FROM tmp_dim_user_changed;

-- ============================================================================
-- 2. 商品SKU维度表
-- ============================================================================
INSERT OVERWRITE TABLE gmall_dim.dim_sku PARTITION(dt = '${biz_date}')
SELECT
    id,                      -- 商品ID
    spu_id,                  -- SPU ID
    sku_name,                -- SKU名称
    sku_desc,                -- 商品描述
    weight,                   -- 重量
    tm_id,                   -- 品牌ID
    tm_name,                 -- 品牌名称
    category1_id,            -- 一级分类ID
    category1_name,          -- 一级分类名称
    category2_id,            -- 二级分类ID
    category2_name,          -- 二级分类名称
    category3_id,            -- 三级分类ID
    category3_name,          -- 三级分类名称
    create_time,             -- 创建时间
    price,                   -- 价格
    ods.dt AS ods_dt         -- ODS分区
FROM gmall_ods.ods_sku_info ods
WHERE ods.dt = '${biz_date}';

-- ============================================================================
-- 3. 地区维度表
-- ============================================================================
INSERT OVERWRITE TABLE gmall_dim.dim_province PARTITION(dt = '${biz_date}')
SELECT
    id,                      -- 地区ID
    province_name,           -- 省份名称
    region_id,               -- 大区ID
    region_name,             -- 大区名称
    area_code,               -- 区域编码
    ods.dt AS ods_dt
FROM gmall_ods.ods_base_province ods
WHERE ods.dt = '${biz_date}';

-- ============================================================================
-- 4. 日期维度表（全量，年度首次执行即可）
-- ============================================================================
INSERT OVERWRITE TABLE gmall_dim.dim_time PARTITION(dt = '${biz_date}')
SELECT
    date_id,                 -- 日期ID
    year_id,                 -- 年份
    year_name,               -- 年份名称
    month_id,                -- 月份ID
    month_name,              -- 月份名称
    month_english,           -- 月份英文
    day_id,                  -- 日ID
    day_english,             -- 星期英文
    day_name_cn,             -- 星期中文
    week_id,                 -- 周ID
    week_of_year,            -- 年第几周
    quarter_id,              -- 季度ID
    quarter_name,             -- 季度名称
    is_workday,              -- 是否工作日
    is_holiday,              -- 是否节假日
    festival_name,           -- 节日名称
    season_id,               -- 季节ID
    season_name              -- 季节名称
FROM gmall_ods.ods_dim_time
WHERE dt = '${biz_date}';

-- ============================================================================
-- 5. 品牌维度表
-- ============================================================================
INSERT OVERWRITE TABLE gmall_dim.dim_trademark PARTITION(dt = '${biz_date}')
SELECT
    tm_id,                   -- 品牌ID
    tm_name,                 -- 品牌名称
    logo_url,                -- Logo URL
    ods.dt AS ods_dt
FROM gmall_ods.ods_base_trademark ods
WHERE ods.dt = '${biz_date}';

-- ============================================================================
-- 6. 活动维度表
-- ============================================================================
INSERT OVERWRITE TABLE gmall_dim.dim_activity PARTITION(dt = '${biz_date}')
SELECT
    activity_id,             -- 活动ID
    activity_name,           -- 活动名称
    activity_type_id,        -- 活动类型ID
    activity_type_name,      -- 活动类型名称
    start_time,              -- 开始时间
    end_time,                -- 结束时间
    create_time,             -- 创建时间
    ods.dt AS ods_dt
FROM gmall_ods.ods_activity_info ods
WHERE ods.dt = '${biz_date}';

-- ============================================================================
-- 7. 优惠券维度表
-- ============================================================================
INSERT OVERWRITE TABLE gmall_dim.dim_coupon PARTITION(dt = '${biz_date}')
SELECT
    coupon_id,               -- 优惠券ID
    coupon_name,             -- 优惠券名称
    coupon_type_id,          -- 优惠券类型ID
    coupon_type_name,        -- 优惠券类型名称
    coupon_amount,           -- 优惠券金额
    condition_amount,         -- 使用条件金额
    start_time,              -- 开始时间
    end_time,                -- 结束时间
    create_time,             -- 创建时间
    ods.dt AS ods_dt
FROM gmall_ods.ods_coupon_info ods
WHERE ods.dt = '${biz_date}';

-- ============================================================================
-- 清理临时表
-- ============================================================================
DROP TABLE IF EXISTS tmp_dim_user_changed;

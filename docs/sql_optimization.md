# Hive 深度优化指南

## 一、分区裁剪优化

### 1.1 分区裁剪原理

分区裁剪是 Hive 查询优化的基础，通过限制查询的分区范围，减少扫描的数据量。

### 1.2 分区裁剪最佳实践

```sql
-- ❌ 错误：WHERE条件在子查询中，无法进行分区裁剪
SELECT * FROM (
    SELECT * FROM dwd_order_detail WHERE dt >= '2024-01-01'
) t WHERE t.order_status = 'paid';

-- ✅ 正确：WHERE条件在最外层，支持分区裁剪
SELECT * FROM dwd_order_detail 
WHERE dt >= '2024-01-01' AND dt <= '2024-01-31'
  AND order_status = 'paid';

-- ✅ 使用动态分区裁剪
SET hive.exec.dynamic.partition=true;
SET hive.exec.dynamic.partition.mode=nonstrict;

-- ✅ 多分区字段裁剪
SELECT * FROM dwd_order_detail
WHERE dt = '2024-01-01'
  AND province_id = '110000';
```

### 1.3 分区裁剪配置

```sql
-- 启用分区裁剪优化
SET hive.optimize.pruner=true;

-- 启用Map端分区裁剪
SET hive.optimize.map.partition.pruner=true;

-- 启用谓词下推
SET hive.optimize.ppd=true;

-- 启用分区谓词下推
SET hive.optimize.ppd.storage=true;
```

---

## 二、索引优化

### 2.1 Hive 索引类型

| 索引类型 | 适用场景 | 特点 |
|---------|---------|------|
| **布隆索引** | 等值查询 | 快速判断值是否存在 |
| **位图索引** | 低基数列 | 适合性别、状态等列 |
| **复合索引** | 多列查询 | 提高多条件查询性能 |

### 2.2 创建索引示例

```sql
-- 创建布隆索引（适合高基数列）
CREATE INDEX idx_order_detail_sku_id
ON TABLE dwd_order_detail(sku_id)
AS 'org.apache.hadoop.hive.ql.index.compact.CompactIndexHandler'
WITH DEFERRED REBUILD
IN TABLE idx_order_detail_sku_id_table;

-- 创建位图索引（适合低基数列）
CREATE INDEX idx_order_detail_status
ON TABLE dwd_order_detail(order_status)
AS 'BITMAP'
WITH DEFERRED REBUILD;

-- 重建索引
ALTER INDEX idx_order_detail_sku_id ON dwd_order_detail REBUILD;

-- 删除索引
DROP INDEX idx_order_detail_sku_id ON dwd_order_detail;
```

### 2.3 索引使用建议

```sql
-- 查看表索引信息
SHOW INDEXES ON dwd_order_detail;

-- 强制使用索引
SELECT /*+ INDEX(dwd_order_detail idx_order_detail_sku_id) */ *
FROM dwd_order_detail 
WHERE sku_id = '1001';

-- 禁用索引
SET hive.optimize.index.filter=false;
```

---

## 三、大表 Join 优化

### 3.1 MapJoin 优化

MapJoin 将小表全部加载到内存中，在 Map 端完成 Join，避免 Shuffle。

```sql
-- ✅ 自动 MapJoin（Hive 自动检测小表）
SET hive.auto.convert.join=true;
SET hive.mapjoin.smalltable.filesize=25000000;  -- 25MB以下自动MapJoin

-- ✅ 强制 MapJoin
SELECT /*+ MAPJOIN(dim_sku) */ 
    od.*, s.sku_name, s.price
FROM dwd_order_detail od
JOIN dim_sku s ON od.sku_id = s.id
WHERE od.dt = '2024-01-01';

-- ✅ 多表 MapJoin
SELECT /*+ MAPJOIN(dim_sku, dim_user) */
    od.*, s.sku_name, u.nick_name
FROM dwd_order_detail od
JOIN dim_sku s ON od.sku_id = s.id
JOIN dim_user_scd2 u ON od.user_id = u.id
WHERE od.dt = '2024-01-01';
```

### 3.2 BucketJoin 优化

BucketJoin 通过预分区，减少 Shuffle 数据量。

```sql
-- 创建分桶表
CREATE TABLE dwd_order_detail_bucketed(
    id STRING,
    order_id STRING,
    user_id STRING,
    sku_id STRING,
    sku_num BIGINT,
    final_amount DECIMAL(16,2)
)
CLUSTERED BY (user_id) INTO 100 BUCKETS
STORED AS ORC;

-- 查询时启用 BucketJoin
SET hive.optimize.bucketmapjoin=true;
SET hive.optimize.bucketmapjoin.sortedmerge=true;

SELECT /*+ BUCKETMAPJOIN(dwd_order_detail_bucketed) */
    u.id, u.nick_name, COUNT(od.order_id) AS order_count
FROM dim_user_scd2 u
JOIN dwd_order_detail_bucketed od ON u.id = od.user_id
WHERE u.is_current = '1'
GROUP BY u.id, u.nick_name;
```

### 3.3 Sort-Merge Bucket Join (SMB Join)

```sql
-- 创建排序分桶表
CREATE TABLE dwd_order_detail_smb(
    id STRING,
    order_id STRING,
    user_id STRING,
    sku_id STRING,
    sku_num BIGINT,
    final_amount DECIMAL(16,2)
)
CLUSTERED BY (user_id) SORTED BY (user_id) INTO 100 BUCKETS
STORED AS ORC;

-- 启用 SMB Join
SET hive.optimize.bucketmapjoin.sortedmerge=true;
SET hive.auto.convert.sortmerge.join=true;
SET hive.sortmerge.join.bucket.mapjoin=false;

SELECT 
    u.id, u.nick_name, SUM(od.final_amount) AS total_amount
FROM dim_user_scd2 u
JOIN dwd_order_detail_smb od ON u.id = od.user_id
WHERE u.is_current = '1'
GROUP BY u.id, u.nick_name;
```

### 3.4 Skew Join 优化

处理数据倾斜问题。

```sql
-- 启用数据倾斜优化
SET hive.optimize.skewjoin=true;
SET hive.skewjoin.key=100000;  -- 超过此阈值视为倾斜
SET hive.skewjoin.mapjoin.map.tasks=10000;

-- 处理倾斜的查询
SELECT /*+ SKEWJOIN(od) */
    u.id, u.nick_name, COUNT(od.order_id) AS order_count
FROM dim_user_scd2 u
JOIN dwd_order_detail od ON u.id = od.user_id
WHERE u.is_current = '1'
GROUP BY u.id, u.nick_name;

-- 拆分倾斜数据处理
WITH skewed_data AS (
    SELECT * FROM dwd_order_detail 
    WHERE user_id IN ('user_001', 'user_002', 'user_003')  -- 倾斜key
),
normal_data AS (
    SELECT * FROM dwd_order_detail 
    WHERE user_id NOT IN ('user_001', 'user_002', 'user_003')
)
SELECT u.id, COUNT(order_id) 
FROM dim_user_scd2 u
JOIN skewed_data od ON u.id = od.user_id
WHERE u.is_current = '1'
GROUP BY u.id
UNION ALL
SELECT u.id, COUNT(order_id) 
FROM dim_user_scd2 u
JOIN normal_data od ON u.id = od.user_id
WHERE u.is_current = '1'
GROUP BY u.id;
```

---

## 四、查询语句优化

### 4.1 谓词下推优化

```sql
-- ❌ 子查询无法谓词下推
SELECT * FROM (
    SELECT * FROM dwd_order_detail WHERE dt = '2024-01-01'
) t WHERE t.sku_num > 1;

-- ✅ 谓词下推到数据源
SELECT * FROM dwd_order_detail 
WHERE dt = '2024-01-01' AND sku_num > 1;

-- 启用谓词下推
SET hive.optimize.ppd=true;
SET hive.optimize.ppd.storage=true;
```

### 4.2 聚合优化

```sql
-- ✅ 使用 GROUPING SETS 替代多次 UNION
SELECT 
    date_id, province_id, 
    SUM(order_amount) AS total_amount
FROM dws_order_day
GROUP BY date_id, province_id
GROUPING SETS (
    (date_id),
    (date_id, province_id)
);

-- ✅ 使用 CUBE 进行多维度聚合
SELECT 
    date_id, province_id, category_id,
    SUM(order_amount) AS total_amount
FROM dws_sku_day
GROUP BY date_id, province_id, category_id
WITH CUBE;

-- ✅ 使用 ROLLUP 进行层级聚合
SELECT 
    year, month, day,
    SUM(order_amount) AS total_amount
FROM dws_order_day
GROUP BY year, month, day WITH ROLLUP;
```

### 4.3 窗口函数优化

```sql
-- ✅ 使用 PARTITION BY 减少数据量
SELECT 
    user_id, order_id, final_amount,
    ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY create_time) AS rn
FROM dwd_order_detail
WHERE dt = '2024-01-01';

-- ✅ 避免全局排序
SELECT 
    user_id, order_amount,
    PERCENT_RANK() OVER(PARTITION BY user_id ORDER BY order_amount) AS rank
FROM dws_user_day;
```

### 4.4 子查询优化

```sql
-- ❌ 相关子查询效率低
SELECT * FROM dwd_order_detail od
WHERE EXISTS (
    SELECT 1 FROM dim_user_scd2 u 
    WHERE u.id = od.user_id AND u.is_current = '1'
);

-- ✅ 使用 JOIN 替代
SELECT od.* FROM dwd_order_detail od
JOIN dim_user_scd2 u ON od.user_id = u.id
WHERE u.is_current = '1';

-- ✅ 使用 EXISTS 替代 IN（大数据量）
SELECT * FROM dwd_order_detail od
WHERE EXISTS (
    SELECT 1 FROM dim_sku s WHERE s.id = od.sku_id
);
```

---

## 五、数据生命周期管理

### 5.1 分区级数据生命周期

```sql
-- 设置表的生命周期属性
ALTER TABLE ods_user_info SET TBLPROPERTIES (
    'retention.days' = '90',
    'retention.policy' = 'delete'
);

-- 手动清理过期分区
ALTER TABLE ods_user_info DROP IF EXISTS PARTITION(dt < '2024-01-01');

-- 批量清理脚本
SET hive.exec.dynamic.partition.mode=nonstrict;

INSERT OVERWRITE TABLE ods_user_info 
PARTITION(dt)
SELECT * FROM ods_user_info 
WHERE dt >= date_sub(current_date(), 90);
```

### 5.2 冷热数据分离

```sql
-- 热数据表（最近7天）
CREATE TABLE dwd_order_detail_hot(
    id STRING, order_id STRING, user_id STRING, sku_id STRING,
    sku_num BIGINT, final_amount DECIMAL(16,2)
)
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/hot/dwd_order_detail';

-- 温数据表（7-30天）
CREATE TABLE dwd_order_detail_warm(
    id STRING, order_id STRING, user_id STRING, sku_id STRING,
    sku_num BIGINT, final_amount DECIMAL(16,2)
)
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/warm/dwd_order_detail';

-- 冷数据表（30天以上）
CREATE TABLE dwd_order_detail_cold(
    id STRING, order_id STRING, user_id STRING, sku_id STRING,
    sku_num BIGINT, final_amount DECIMAL(16,2)
)
PARTITIONED BY (dt STRING)
STORED AS ORC
LOCATION '/warehouse/gmall/cold/dwd_order_detail';

-- 冷热数据迁移脚本
INSERT OVERWRITE TABLE dwd_order_detail_warm PARTITION(dt)
SELECT * FROM dwd_order_detail_hot 
WHERE dt >= date_sub(current_date(), 30) AND dt < date_sub(current_date(), 7);

INSERT OVERWRITE TABLE dwd_order_detail_cold PARTITION(dt)
SELECT * FROM dwd_order_detail_warm 
WHERE dt < date_sub(current_date(), 30);
```

### 5.3 数据归档策略

```sql
-- 创建归档表
CREATE TABLE dwd_order_detail_archive(
    id STRING, order_id STRING, user_id STRING, sku_id STRING,
    sku_num BIGINT, final_amount DECIMAL(16,2),
    archive_date STRING
)
STORED AS ORC
LOCATION '/warehouse/gmall/archive/dwd_order_detail';

-- 归档脚本
INSERT OVERWRITE TABLE dwd_order_detail_archive
SELECT *, current_date() AS archive_date
FROM dwd_order_detail_cold;

-- 删除已归档数据
ALTER TABLE dwd_order_detail_cold DROP PARTITION(dt < '2024-01-01');
```

---

## 六、执行引擎优化

### 6.1 Tez 引擎优化

```sql
-- 启用 Tez 引擎
SET hive.execution.engine=tez;
SET tez.container.size=4096;
SET tez.task.resource.memory.mb=4096;
SET tez.java.opts=-Xmx3072m;

-- Tez 并行度配置
SET tez.grouping.min-size=16777216;  -- 16MB
SET tez.grouping.max-size=134217728;  -- 128MB
```

### 6.2 Spark 引擎优化

```sql
-- 启用 Spark 引擎
SET hive.execution.engine=spark;
SET spark.executor.memory=4g;
SET spark.executor.cores=2;
SET spark.driver.memory=2g;

-- Spark 并行度配置
SET spark.default.parallelism=100;
SET spark.sql.shuffle.partitions=100;
```

### 6.3 内存优化

```sql
-- Map 端内存配置
SET hive.map.aggr=true;
SET hive.groupby.skewindata=true;

-- Reduce 端内存配置
SET hive.exec.reducers.bytes.per.reducer=256000000;  -- 256MB
SET hive.exec.reducers.max=1009;

-- JVM 内存配置
SET mapreduce.map.java.opts=-Xmx1024m;
SET mapreduce.reduce.java.opts=-Xmx2048m;
```

---

## 七、优化配置汇总

### 7.1 生产环境推荐配置

```sql
-- 基础优化
SET hive.optimize.pruner=true;
SET hive.optimize.ppd=true;
SET hive.optimize.map.partition.pruner=true;

-- Join 优化
SET hive.auto.convert.join=true;
SET hive.mapjoin.smalltable.filesize=25000000;
SET hive.optimize.bucketmapjoin=true;
SET hive.optimize.bucketmapjoin.sortedmerge=true;
SET hive.optimize.skewjoin=true;
SET hive.skewjoin.key=100000;

-- 执行优化
SET hive.exec.dynamic.partition=true;
SET hive.exec.dynamic.partition.mode=nonstrict;
SET hive.exec.max.dynamic.partitions=1000;
SET hive.exec.max.dynamic.partitions.pernode=100;

-- 压缩优化
SET hive.exec.compress.output=true;
SET mapreduce.output.fileoutputformat.compress=true;
SET mapreduce.output.fileoutputformat.compress.codec=org.apache.hadoop.io.compress.SnappyCodec;

-- 统计信息
SET hive.stats.autogather=true;
SET hive.compute.query.using.stats=true;
```

### 7.2 性能调优检查表

| 检查项 | 优化目标 | 检查方法 |
|-------|---------|---------|
| 分区裁剪 | WHERE条件包含分区字段 | EXPLAIN查看 |
| 数据倾斜 | 任务进度长时间卡在99% | 查看任务日志 |
| 小表广播 | 小表加载到内存 | hive.auto.convert.join |
| 统计信息 | 表/分区统计信息完整 | ANALYZE TABLE |
| 压缩配置 | 输出数据压缩 | hive.exec.compress.output |

---

## 八、SQL 优化案例

### 8.1 案例1：复杂查询优化

**优化前**：
```sql
SELECT 
    u.id, u.nick_name,
    COUNT(DISTINCT od.order_id) AS order_count,
    SUM(od.final_amount) AS total_amount
FROM dwd_order_detail od
LEFT JOIN dim_user_scd2 u ON od.user_id = u.id
WHERE od.dt BETWEEN '2024-01-01' AND '2024-01-31'
  AND u.is_current = '1'
GROUP BY u.id, u.nick_name
ORDER BY total_amount DESC
LIMIT 100;
```

**优化后**：
```sql
-- 1. 先过滤分区，减少扫描数据
-- 2. 使用 MapJoin 加速维度表关联
-- 3. 避免 COUNT(DISTINCT)
WITH order_stats AS (
    SELECT /*+ MAPJOIN(u) */
        u.id, u.nick_name,
        od.order_id, od.final_amount
    FROM dwd_order_detail od
    JOIN dim_user_scd2 u ON od.user_id = u.id
    WHERE od.dt BETWEEN '2024-01-01' AND '2024-01-31'
      AND u.is_current = '1'
)
SELECT 
    id, nick_name,
    COUNT(order_id) AS order_count,
    SUM(final_amount) AS total_amount
FROM order_stats
GROUP BY id, nick_name
ORDER BY total_amount DESC
LIMIT 100;
```

### 8.2 案例2：数据倾斜优化

**问题**：某些用户订单量特别大，导致 Join 时数据倾斜。

**优化方案**：
```sql
SET hive.optimize.skewjoin=true;
SET hive.skewjoin.key=100000;

SELECT /*+ SKEWJOIN(od) */
    u.id, u.nick_name,
    COUNT(od.order_id) AS order_count
FROM dim_user_scd2 u
JOIN dwd_order_detail od ON u.id = od.user_id
WHERE u.is_current = '1'
GROUP BY u.id, u.nick_name;
```

---

## 九、监控与诊断

### 9.1 EXPLAIN 分析

```sql
-- 查看执行计划
EXPLAIN 
SELECT * FROM dwd_order_detail 
WHERE dt = '2024-01-01' AND sku_num > 1;

-- 查看详细执行计划
EXPLAIN EXTENDED
SELECT u.id, COUNT(od.order_id)
FROM dim_user_scd2 u
JOIN dwd_order_detail od ON u.id = od.user_id
WHERE u.is_current = '1'
GROUP BY u.id;
```

### 9.2 统计信息收集

```sql
-- 收集表统计信息
ANALYZE TABLE dwd_order_detail COMPUTE STATISTICS;

-- 收集分区统计信息
ANALYZE TABLE dwd_order_detail PARTITION(dt='2024-01-01') COMPUTE STATISTICS;

-- 查看统计信息
DESCRIBE EXTENDED dwd_order_detail;
```

### 9.3 Hive CLI 监控命令

```bash
# 查看当前配置
hive> SET;

# 查看特定配置
hive> SET hive.optimize.ppd;

# 查看表信息
hive> DESCRIBE FORMATTED dwd_order_detail;

# 查看分区信息
hive> SHOW PARTITIONS dwd_order_detail;
```
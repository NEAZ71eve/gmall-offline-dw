# SQL 优化指南

## 一、Hive SQL 优化原则

### 1.1 分区裁剪与谓词下推
- **原则**：WHERE 条件中优先使用分区字段
- **示例**：
  ```sql
  -- 优化前
  SELECT * FROM dwd_order_detail WHERE create_time >= '2024-01-01'
  
  -- 优化后
  SELECT * FROM dwd_order_detail WHERE dt = '2024-01-01'
  ```

### 1.2 MapJoin 优化
- **原则**：小表驱动大表，使用 MapJoin
- **示例**：
  ```sql
  SET hive.auto.convert.join=true;
  SET hive.mapjoin.smalltable.filesize=25000000;
  
  SELECT /*+ MAPJOIN(dim) */ 
      d.order_id, d.sku_id, dim.sku_name
  FROM dwd_order_detail d
  JOIN dim_sku dim ON d.sku_id = dim.sku_id;
  ```

### 1.3 合理设置并行度
```sql
SET mapreduce.job.reduces=10;
SET hive.exec.dynamic.partition=true;
SET hive.exec.dynamic.partition.mode=nonstrict;
```

## 二、ETL 性能优化

### 2.1 数据倾斜处理
- **方案1**：加盐处理
```sql
SELECT 
    CONCAT(user_id, '_', FLOOR(RAND() * 100)) AS user_id_salt,
    COUNT(*)
FROM dwd_order_info
GROUP BY CONCAT(user_id, '_', FLOOR(RAND() * 100));
```

- **方案2**：单独处理热点数据
```sql
-- 处理热点用户
INSERT INTO dws_user_stats_hot
SELECT user_id, COUNT(*) FROM dwd_order_info
WHERE user_id IN ('hot_user_1', 'hot_user_2')
GROUP BY user_id;

-- 处理普通用户
INSERT INTO dws_user_stats_normal
SELECT user_id, COUNT(*) FROM dwd_order_info
WHERE user_id NOT IN ('hot_user_1', 'hot_user_2')
GROUP BY user_id;
```

### 2.2 存储格式优化
- **推荐使用 ORC/Parquet 格式**
- **启用压缩**
```sql
SET hive.exec.compress.output=true;
SET mapreduce.output.fileoutputformat.compress.codec=org.apache.hadoop.io.compress.SnappyCodec;
```

## 三、索引优化

### 3.1 Hive 索引类型
| 索引类型 | 适用场景 | 注意事项 |
|---------|---------|---------|
| 普通索引 | 等值查询 | Hive 3.x 支持 |
| 位图索引 | 低基数列 | 适合性别、状态等 |
| Bloom 过滤 | 高基数列 | 加速 EXISTS 查询 |

### 3.2 创建索引示例
```sql
CREATE INDEX idx_user_id ON TABLE dwd_order_info(user_id)
AS 'org.apache.hadoop.hive.ql.index.compact.CompactIndexHandler'
WITH DEFERRED REBUILD;
```

## 四、执行计划分析

### 4.1 查看执行计划
```sql
EXPLAIN EXTENDED 
SELECT date_id, COUNT(*) as order_count
FROM dwd_order_info
WHERE dt = '2024-01-01'
GROUP BY date_id;
```

### 4.2 关键指标解读
| 指标 | 含义 | 优化方向 |
|-----|------|---------|
| Map Input Records | Map 端输入记录数 | 检查分区裁剪是否生效 |
| Reduce Shuffle Bytes | Shuffle 数据量 | 减少数据倾斜 |
| GC Time | 垃圾回收时间 | 调整 JVM 参数 |

## 五、最佳实践

### 5.1 数据分层原则
- ODS层：保持原始格式，快速写入
- DWD层：清洗后使用 ORC 格式
- DWS层：按主题聚合，适当预计算
- ADS层：面向报表，按需计算

### 5.2 分区策略
- **时间分区**：按天分区，支持增量更新
- **二级分区**：大表可按地区/渠道二级分区
- **分区粒度**：避免过多小分区

### 5.3 数据生命周期管理
```sql
-- 清理30天前的 ODS 数据
ALTER TABLE ods_user_info DROP IF EXISTS PARTITION (dt < '2024-01-01');

-- 设置表的 TTL
ALTER TABLE dwd_order_detail SET TBLPROPERTIES ('transient_lastDdlTime'='20240101');
```
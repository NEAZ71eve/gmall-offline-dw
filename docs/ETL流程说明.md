# ETL 流程说明文档

## 一、ETL 流程概述

### 1.1 数据流向

```
┌─────────────────────────────────────────────────────────────────┐
│                      数据采集层                                │
│  MySQL (Binlog) ──► Maxwell ──► Kafka ──► Flume ──► HDFS     │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      ODS层（原始数据层）                        │
│  存储原始数据，不做任何加工，按天分区                            │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      DIM层（维度层）                           │
│  构建维度表：用户、商品、日期、品牌等（包含拉链表）              │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      DWD层（明细数据层）                        │
│  数据清洗、去重、脱敏、格式统一、维度关联                       │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      DWS层（汇总数据层）                        │
│  轻度聚合：GMV、用户行为、商品销售等主题汇总                    │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      ADS层（应用数据层）                        │
│  业务指标：日报表、留存分析、转化漏斗等                         │
└─────────────────────────────────────────────────────────────────┘
```

## 二、ETL 执行顺序

### 2.1 每日 ETL 执行顺序

```
Step 1: ODS -> DIM (维度表构建)
   │
   ├── etl_ods_to_dim.sql
   │   ├── dim_user (拉链表)
   │   ├── dim_sku
   │   ├── dim_province
   │   ├── dim_time
   │   ├── dim_trademark
   │   ├── dim_activity
   │   └── dim_coupon
   │
   ▼
Step 2: ODS -> DWD (明细数据清洗)
   │
   ├── etl_ods_to_dwd.sql
   │   ├── dwd_order_detail
   │   ├── dwd_order_info
   │   ├── dwd_payment_info
   │   ├── dwd_action
   │   ├── dwd_order_refund
   │   └── dwd_review_info
   │
   ▼
Step 3: DWD -> DWS (数据汇总)
   │
   ├── etl_dwd_to_dws.sql
   │   ├── dws_gmv_stats
   │   ├── dws_user_action_stats
   │   ├── dws_sku_stats
   │   ├── dws_user_stats
   │   ├── dws_province_stats
   │   ├── dws_trademark_stats
   │   └── dws_category_stats
   │
   ▼
Step 4: DWS -> ADS (指标计算)
   │
   ├── etl_dws_to_ads.sql
   │   ├── ads_gmv_day
   │   ├── ads_user_retention
   │   ├── ads_sku_sales_rank
   │   ├── ads_conversion_rate
   │   ├── ads_user_repurchase_rate
   │   ├── ads_user_activity
   │   ├── ads_category_sale_analysis
   │   └── ads_province_sale
   │
   ▼
Step 5: 数据质量校验
   │
   └── python utils/data_quality_validator.py
```

## 三、各层 ETL 详细说明

### 3.1 ODS 层（原始数据层）

**职责**：存储从业务系统直接同步过来的原始数据，不做任何加工。

**特点**：
- 保持原始格式
- 按天分区存储
- 数据不可更新

**同步方式**：
- **全量同步**：每天凌晨全量覆盖
- **增量同步**：Maxwell + Kafka 实时同步

### 3.2 DIM 层（维度层）

**职责**：构建维度表，为 DWD 层提供维度信息。

**核心维度表**：

| 表名 | 说明 | 更新方式 |
|------|------|---------|
| dim_user | 用户维度 | 拉链表 |
| dim_sku | 商品SKU维度 | 全量覆盖 |
| dim_province | 地区维度 | 全量覆盖 |
| dim_time | 日期维度 | 全量覆盖 |
| dim_trademark | 品牌维度 | 全量覆盖 |
| dim_activity | 活动维度 | 全量覆盖 |
| dim_coupon | 优惠券维度 | 全量覆盖 |

**拉链表实现（dim_user）**：

```sql
-- 拉链表核心字段
- start_date: 记录开始日期
- end_date: 记录结束日期（9999-12-31 表示当前有效）
- status: 数据状态

-- 更新逻辑
1. 新增数据：start_date = 当前日期, end_date = '9999-12-31'
2. 变化数据：关闭旧记录，start_date 不变，end_date = 当前日期-1
3. 变化数据：新增新记录，start_date = 当前日期, end_date = '9999-12-31'
```

### 3.3 DWD 层（明细数据层）

**职责**：数据清洗、标准化、维度关联。

**清洗规则**：
1. 空值过滤：id、user_id 等关键字段不能为空
2. 格式标准化：订单状态、支付方式等枚举值标准化
3. 数据脱敏：手机号、邮箱等敏感信息脱敏
4. 去重处理：基于主键去重
5. 维度关联：关联商品、用户、地区等维度

**核心事实表**：

| 表名 | 说明 | 更新方式 |
|------|------|---------|
| dwd_order_detail | 订单明细事实表 | 增量追加 |
| dwd_order_info | 订单信息事实表 | 增量追加 |
| dwd_payment_info | 支付信息事实表 | 增量追加 |
| dwd_action | 用户行为事实表 | 增量追加 |
| dwd_order_refund | 退单事实表 | 增量追加 |

### 3.4 DWS 层（汇总数据层）

**职责**：按主题轻度聚合，为 ADS 层提供基础汇总数据。

**汇总主题**：

| 主题 | 表名 | 聚合粒度 |
|------|------|---------|
| GMV统计 | dws_gmv_stats | 每日 |
| 用户行为 | dws_user_action_stats | 用户+商品+每日 |
| 商品销售 | dws_sku_stats | 商品+每日 |
| 用户统计 | dws_user_stats | 用户+每日 |
| 地区统计 | dws_province_stats | 地区+每日 |
| 品牌统计 | dws_trademark_stats | 品牌+每日 |
| 分类统计 | dws_category_stats | 分类+每日 |

### 3.5 ADS 层（应用数据层）

**职责**：计算最终业务指标，为报表和大屏提供数据。

**核心指标**：

| 指标 | 表名 | 说明 |
|------|------|------|
| GMV日报 | ads_gmv_day | 1天/7天/30天 |
| 用户留存 | ads_user_retention | 1日/7日/30日留存 |
| 商品排行 | ads_sku_sales_rank | 销售排行 |
| 转化率 | ads_conversion_rate | 漏斗转化分析 |
| 复购率 | ads_user_repurchase_rate | 用户复购分析 |
| 活跃度 | ads_user_activity | DAU/WAU/MAU |
| 品类分析 | ads_category_sale_analysis | 品类销售分析 |
| 地区销售 | ads_province_sale | 地区销售排行 |

## 四、ETL 参数说明

### 4.1 变量参数

```bash
# 业务日期（通常为前一天）
${biz_date}  # 例如：2024-01-08

# 时间函数
DATE_SUB('${biz_date}', 6)  # 7天前
DATE_SUB('${biz_date}', 29) # 30天前
```

### 4.2 执行示例

```bash
# 使用 Hive 执行单个 ETL 脚本
hive -hivevar biz_date=2024-01-08 -f etl_ods_to_dim.sql

# 使用参数化脚本执行
python run_etl.py --date 2024-01-08 --step all
```

## 五、数据质量保障

### 5.1 数据校验规则

```sql
-- 1. 非空校验
WHERE id IS NOT NULL AND id != ''

-- 2. 唯一性校验
GROUP BY id HAVING COUNT(*) > 1

-- 3. 业务规则校验
WHERE total_amount >= 0
WHERE sku_num > 0

-- 4. 参照完整性校验
WHERE user_id IN (SELECT id FROM dim_user)
```

### 5.2 数据质量检查脚本

```bash
# 执行数据质量校验
python utils/data_quality_validator.py

# 检查数据新鲜度
python utils/data_quality_check.py
```

## 六、异常处理

### 6.1 常见异常及解决方案

| 异常 | 原因 | 解决方案 |
|------|------|---------|
| 数据倾斜 | Key分布不均 | 加盐、单独处理热点 |
| 内存溢出 | 数据量过大 | 增加资源、减少并发 |
| 数据重复 | 幂等性未保证 | 去重处理 |
| 数据丢失 | 网络抖动 | 断点续传、补偿机制 |
| 任务超时 | SQL复杂度过高 | 优化SQL、调整超时时间 |

### 6.2 任务失败处理

```bash
# 1. 查看任务日志
cat /var/log/gmall/etl/etl_20240108.log

# 2. 手动重跑失败的步骤
hive -hivevar biz_date=2024-01-08 -f etl_dwd_to_dws.sql

# 3. 补数处理
# 从失败的步骤开始重新执行
```

## 七、性能优化

### 7.1 SQL 优化

```sql
-- 1. 分区裁剪
WHERE dt = '${biz_date}'

-- 2. 避免 SELECT *
SELECT id, name, ...

-- 3. 小表广播
/*+ MAPJOIN(dim) */

-- 4. 启用压缩
SET hive.exec.compress.output=true;
```

### 7.2 任务调度优化

- 利用依赖关系并行执行独立任务
- 错峰执行重量级任务
- 合理设置重试机制

## 八、监控告警

### 8.1 监控指标

- ETL 任务执行时间
- 数据处理量
- 数据质量合格率
- 服务健康状态

### 8.2 告警机制

```bash
# 执行服务监控
./monitor/service_monitor.sh all

# 配置钉钉告警
vim monitor/alert.sh
```

## 九、版本历史

| 版本 | 日期 | 修改内容 |
|------|------|---------|
| v1.0 | 2024-01-01 | 初始版本 |
| v1.1 | 2024-01-08 | 添加拉链表实现 |
| v1.2 | 2024-01-15 | 完善数据质量校验 |

---

**文档版本**：v1.2
**最后更新**：2024-01-15
**维护人员**：电商数仓团队

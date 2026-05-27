
# 电商离线数仓项目

基于尚硅谷电商数仓项目的标准离线数仓架构，包含完整的分层设计、ETL流程和指标开发。

## 一、项目架构

### 1.1 整体架构（数据流）
```
用户/业务系统 → 数据源 → 采集 → 数仓分层 → 调度 → 报表/可视化
```

### 1.2 标准五层架构
| 层次 | 说明 | 存储格式 | 表前缀 |
|------|------|---------|--------|
| ODS | 原始数据层，直接同步业务库与日志，不清洗、不加工 | Text | ods_* |
| DIM | 公共维度层，用户、商品、店铺、时间等维度表 | ORC | dim_* |
| DWD | 明细数据层，清洗、脱敏、去重、统一规范 | ORC | dwd_* |
| DWS | 汇总数据层，按主题轻度聚合（用户、订单、商品等） | ORC | dws_* |
| ADS | 应用数据层，指标报表、大屏、接口输出 | ORC | ads_* |

### 1.3 技术栈
- **采集**：Flume（日志）、DataX/Maxwell（业务库）
- **存储**：HDFS、Hive
- **计算**：Hive SQL / Spark SQL
- **调度**：Azkaban / DolphinScheduler
- **可视化**：Superset / DataV

## 二、项目目录结构

```
dw/
├── README.md                    # 项目说明文档
├── ods/                         # ODS层
│   └── ods_init.sql            # ODS层建表脚本
├── dim/                         # DIM层
│   └── dim_init.sql            # DIM层建表脚本
├── dwd/                         # DWD层
│   └── dwd_init.sql            # DWD层建表脚本
├── dws/                         # DWS层
│   └── dws_init.sql            # DWS层建表脚本
├── ads/                         # ADS层
│   └── ads_init.sql            # ADS层建表脚本
├── etl/                         # ETL脚本
│   ├── ods_to_dim_user.sql
│   ├── ods_to_dwd_order_detail.sql
│   ├── dwd_to_dws_trade_user_sku_order.sql
│   └── dws_to_ads_trade_stats.sql
├── datax/                       # DataX配置
│   └── mysql_to_hdfs_user_info.json
├── scripts/                     # 脚本目录
│   └── (待补充)
└── docs/                        # 文档目录
    └── (待补充)
```

## 三、数据模型设计

### 3.1 总线矩阵
| 主题域 | 用户 | 商品 | 订单 | 支付 | 流量 |
|--------|------|------|------|------|------|
| ODS | ✓ | ✓ | ✓ | ✓ | ✓ |
| DWD | ✓ | ✓ | ✓ | ✓ | ✓ |
| DWS | ✓ | ✓ | ✓ | ✓ | ✓ |
| ADS | ✓ | ✓ | ✓ | ✓ | ✓ |

### 3.2 维度表
- 用户维度表（拉链表）
- 商品维度表
- 地区维度表
- 日期维度表
- 优惠券维度表
- 活动维度表

### 3.3 事实表
- 订单明细表（事务型事实表）
- 支付明细表（事务型事实表）
- 退单明细表（事务型事实表）
- 页面日志表（事务型事实表）
- 启动日志表（事务型事实表）
- 加购明细表（事务型事实表）
- 收藏明细表（事务型事实表）
- 评论明细表（事务型事实表）

## 四、核心指标

### 4.1 交易统计
- 订单数
- 下单人数
- 下单原始金额
- 下单活动减免金额
- 下单优惠券减免金额
- 下单最终金额
- GMV

### 4.2 用户统计
- 新增用户数
- 活跃用户数
- 留存用户数
- 流失用户数
- 回流用户数
- 复购率

### 4.3 流量统计
- 页面浏览次数
- 独立访客数
- 页面停留时长
- 跳出率

## 五、使用说明

### 5.1 初始化数仓
```bash
# 1. 创建ODS层表
hive -f dw/ods/ods_init.sql

# 2. 创建DIM层表
hive -f dw/dim/dim_init.sql

# 3. 创建DWD层表
hive -f dw/dwd/dwd_init.sql

# 4. 创建DWS层表
hive -f dw/dws/dws_init.sql

# 5. 创建ADS层表
hive -f dw/ads/ads_init.sql
```

### 5.2 运行ETL
```bash
# 示例：运行ODS到DIM层的ETL
hive -f dw/etl/ods_to_dim_user.sql -hivevar dt=2020-06-14

# 示例：运行ODS到DWD层的ETL
hive -f dw/etl/ods_to_dwd_order_detail.sql -hivevar dt=2020-06-14

# 示例：运行DWD到DWS层的ETL
hive -f dw/etl/dwd_to_dws_trade_user_sku_order.sql -hivevar dt=2020-06-14

# 示例：运行DWS到ADS层的ETL
hive -f dw/etl/dws_to_ads_trade_stats.sql -hivevar dt=2020-06-14
```

## 六、常见问题

### 6.1 零点漂移
使用时间分区时，需注意数据生成时间和分区时间的一致性。

### 6.2 小文件问题
定期合并小文件，使用`CombineHiveInputFormat`。

### 6.3 数据倾斜
- 过滤空值
- 增加Reduce数量
- 数据重分区

### 6.4 缓慢变化维
使用拉链表（Start Date和End Date）记录维度变化。

## 七、参考资料

- 尚硅谷电商数仓项目视频（BV1UN411j79o）
- Apache Hive官方文档
- DataX官方文档
- Apache Flume官方文档

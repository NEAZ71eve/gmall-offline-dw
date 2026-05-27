# 尚硅谷电商数仓项目

基于 Hadoop + Hive 的离线数据仓库项目，实现电商业务数据的采集、清洗、转换和汇总分析。

## 技术栈

| 技术组件 | 版本 | 职责 |
|---------|------|------|
| **Linux + JDK** | Ubuntu 22.04 / JDK 8 | 集群基础运行环境 |
| **MySQL** | 8.0 | 业务数据库，存储模拟电商原始数据 |
| **Zookeeper** | 3.8.x | 集群服务协调、节点管理 |
| **Hadoop HDFS** | 3.3.5 | 分布式文件存储 |
| **Kafka** | 3.9.x | 消息队列，实时数据中转 |
| **Maxwell** | 1.49.0 | MySQL 增量日志采集 |
| **Flume** | 1.11.0 | 日志采集，数据管道 |
| **DataX** | 202310 | 多数据源全量/增量同步 |
| **Hive** | 3.1.3 | 离线数仓核心引擎 |
| **DolphinScheduler** | 3.2.x | 任务工作流编排、定时调度 |
| **Apache Superset** | 2.1.x | 可视化报表与数据大屏 |

## 数据仓库架构

```
┌─────────────────────────────────────────────────────────────────┐
│                      数据采集层                                │
│  Flume ──► Kafka ──► Maxwell(MySQL Binlog) ──► DataX          │
└───────────────────────────┬─────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      数据存储层                                │
│                    HDFS / Hive                                │
└───────────────────────────┬─────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      数仓分层架构                              │
│  ODS ──► DIM ──► DWD ──► DWS ──► ADS                          │
└───────────────────────────┬─────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      数据应用层                                │
│               Apache Superset (可视化报表/数据大屏)             │
└─────────────────────────────────────────────────────────────────┘
```

### 各层说明

| 层级 | 名称 | 职责 | 存储格式 |
|------|------|------|---------|
| **ODS** | 原始数据层 | 直接同步业务库与日志，不清洗、不加工 | Text |
| **DIM** | 公共维度层 | 用户、商品、店铺、时间等维度表（拉链表） | ORC |
| **DWD** | 明细数据层 | 清洗、脱敏、去重、统一规范 | ORC |
| **DWS** | 汇总数据层 | 按主题轻度聚合（用户、订单、商品等） | ORC |
| **ADS** | 应用数据层 | 指标报表、大屏、接口输出 | ORC |

## 项目结构

```
.
├── sql/                          # MySQL 业务库建表脚本
│   └── gmall_schema.sql          # 电商业务表结构
├── gmall-dw/                     # 数据仓库核心
│   ├── hive/                     # Hive 建表脚本
│   │   ├── create_ods.sql        # ODS层建表
│   │   ├── create_dim.sql        # DIM层建表
│   │   ├── create_dwd.sql        # DWD层建表
│   │   ├── create_dws.sql        # DWS层建表
│   │   └── create_ads.sql        # ADS层建表
│   └── docs/                     # 设计文档
│       ├── 分层设计.md            # 数仓分层设计
│       └── 指标字典.md            # 指标定义
├── kafka-conf/                   # Kafka 配置
│   ├── server.properties         # Kafka 服务配置
│   └── create_topics.sh          # Topic 创建脚本
├── maxwell/                      # Maxwell 配置
│   ├── config.properties         # Maxwell 配置文件
│   └── maxwell_init.sql          # Maxwell 初始化SQL
├── flume-conf/                   # Flume 配置
│   ├── ecommerce.conf            # 电商日志采集
│   └── kafka_to_hdfs.conf        # Kafka到HDFS采集
├── datax/                        # DataX 任务配置
│   ├── ods_user_info.json        # 用户数据同步
│   ├── ods_order_info.json       # 订单数据同步
│   ├── ods_order_detail.json     # 订单明细同步
│   └── run_datax.sh              # DataX 启动脚本
├── dolphinscheduler/             # DolphinScheduler 配置
│   ├── workflow.json             # ETL工作流定义
│   └── submit_workflow.sh        # 工作流提交脚本
├── superset/                     # Superset 配置
│   ├── superset_config.py        # Superset 配置
│   └── hive_connection.py        # Hive 连接配置
├── utils/                        # 工具脚本
│   └── data_masking.py           # 数据脱敏工具
├── docs/                         # 项目文档
│   └── sql_optimization.md       # SQL优化指南
├── *.py                          # ETL Python脚本
│   ├── setup_gmall_mysql_wsl.py  # MySQL数据初始化
│   ├── ods_data_loader.py        # ODS层数据加载
│   ├── dim_data_processor.py     # DIM层数据处理
│   ├── dwd_data_processor.py     # DWD层数据清洗
│   └── dws_data_processor.py     # DWS层数据汇总
├── start_all.sh                  # 启动所有服务
├── start_kafka.sh                # 启动Kafka生态
├── start_flume.sh                # 启动Flume采集
├── init_hive.sh                  # 初始化Hive
└── README.md                     # 项目说明文档
```

## 核心功能

### 1. 数据采集
- **实时采集**：Maxwell 监听 MySQL Binlog，实时同步增量数据到 Kafka
- **批量采集**：DataX 实现多数据源全量/增量同步
- **日志采集**：Flume 采集业务日志，写入 HDFS

### 2. 维度建模
- **拉链表**：用户维度表实现 SCD Type 2 缓慢变化维
- **日期维度**：预计算 2020-2026 年日期数据
- **商品维度**：关联品牌、分类等多层级维度

### 3. ETL 流程
- **数据清洗**：去重、过滤脏数据、格式统一
- **数据脱敏**：手机号、邮箱、身份证等敏感信息脱敏
- **指标计算**：GMV、订单量、用户留存等核心指标

### 4. 任务调度
- **DolphinScheduler**：工作流编排、依赖管理、定时调度
- **监控告警**：任务失败重试、邮件/短信告警

### 5. 数据可视化
- **Superset 报表**：GMV日报、转化率分析、商品销售排行
- **数据大屏**：实时业务监控

## 快速开始

### 1. 环境要求

- Linux (WSL2 或物理机)
- JDK 8+
- Hadoop 3.3.5
- MySQL 8.0
- Hive 3.1.3
- Kafka 3.9.x
- Python 3.x

### 2. 启动服务

```bash
# 启动基础服务 (MySQL + Hadoop)
./start_all.sh

# 启动 Kafka 生态 (Zookeeper + Kafka + Maxwell)
./start_kafka.sh

# 启动 Flume 采集
./start_flume.sh

# 初始化 Hive
./init_hive.sh
```

### 3. 执行 ETL 流程

```bash
# 方式1：使用 Python 脚本
python3 ods_data_loader.py
python3 dim_data_processor.py
python3 dwd_data_processor.py
python3 dws_data_processor.py

# 方式2：使用 DataX
./datax/run_datax.sh

# 方式3：使用 DolphinScheduler（推荐）
./dolphinscheduler/submit_workflow.sh
```

### 4. 查看数据

```bash
# 查看 HDFS 目录结构
hdfs dfs -ls -R /warehouse/gmall/

# 查看 GMV 统计
hdfs dfs -cat /warehouse/gmall/dws/dws_gmv_stats
```

## 数据说明

### MySQL 业务表 (gmall 数据库)

| 表名 | 说明 |
|------|------|
| user_info | 用户信息表 |
| order_info | 订单表 |
| order_detail | 订单明细表 |
| sku_info | 商品SKU表 |
| spu_info | 商品SPU表 |
| base_trademark | 品牌表 |
| base_category1/2/3 | 分类表 |
| payment_info | 支付表 |

### Hive 数仓表

| 层级 | 表名 | 说明 |
|------|------|------|
| ODS | ods_user_info | 用户原始数据 |
| ODS | ods_order_info | 订单原始数据 |
| ODS | ods_order_detail | 订单明细原始数据 |
| DIM | dim_user | 用户维度表（拉链表） |
| DIM | dim_sku | 商品SKU维度表 |
| DIM | dim_time | 日期维度表 |
| DWD | dwd_order_detail | 清洗后的订单明细 |
| DWD | dwd_order_info | 清洗后的订单 |
| DWS | dws_gmv_stats | GMV统计汇总 |
| DWS | dws_user_stats | 用户统计汇总 |
| ADS | ads_gmv_day | GMV日报表 |
| ADS | ads_user_retention | 用户留存表 |

## 学习价值

通过本项目，您可以掌握：

- ✅ Hadoop HDFS 分布式文件系统使用
- ✅ Kafka + Maxwell 增量数据采集
- ✅ Flume 日志采集与数据管道
- ✅ DataX 多数据源同步
- ✅ 数据仓库分层架构设计 (ODS → DIM → DWD → DWS → ADS)
- ✅ 维度建模与拉链表实现
- ✅ ETL 流程开发与优化
- ✅ DolphinScheduler 任务调度
- ✅ Apache Superset 数据可视化
- ✅ 数据脱敏与 SQL 优化

## 文档

- [gmall-dw/docs/分层设计.md](gmall-dw/docs/分层设计.md) - 数仓分层设计
- [docs/sql_optimization.md](docs/sql_optimization.md) - SQL优化指南
- [README.md](README.md) - 项目说明文档

## 许可证

MIT License
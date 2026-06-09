# 尚硅谷电商数仓项目

基于 Hadoop + Hive 的离线数据仓库项目，实现电商业务数据的采集、清洗、转换和汇总分析。

**GitHub**: https://github.com/NEAZ71eve/gmall-offline-dw

---

## 技术栈

| 技术组件 | 版本 | 职责 | 配置位置 |
|---------|------|------|---------|
| **Linux + JDK** | Ubuntu 22.04 / JDK 8 | 集群基础运行环境 | - |
| **MySQL** | 8.0 | 业务数据库，存储模拟电商原始数据 | `sql/` |
| **Zookeeper** | 3.8.x | 集群服务协调、节点管理 | `zookeeper/zoo.cfg` |
| **Hadoop HDFS** | 3.3.5 | 分布式文件存储 | `start_all.sh` |
| **DataX** | 202310 | 多数据源全量/增量同步 | `datax/` |
| **Hive** | 3.1.3 | 离线数仓核心引擎 | `gmall-dw/hive/` |
| **DolphinScheduler** | 3.2.x | 任务工作流编排、定时调度 | `dolphinscheduler/` |
| **Apache Superset** | 2.1.x | 可视化报表与数据大屏 | `superset/` |

---

## 快速启动

### 1. 环境要求

- Linux (WSL2 或物理机)
- JDK 8+
- Hadoop 3.3.5
- MySQL 8.0
- Hive 3.1.3
- Python 3.x

### 2. 一键启动所有服务

```bash
# 启动基础服务 (MySQL + Hadoop + Zookeeper)
./start_all.sh

# 停止所有服务
./stop_all.sh
```

### 3. 执行 ETL 流程

```bash
# 方式1：使用 Python 脚本（演示模式）
python3 demo_etl_flow.py

# 方式2：使用 DataX 同步数据
./datax/run_datax.sh

# 方式3：使用 DolphinScheduler（推荐生产环境）
./dolphinscheduler/submit_workflow.sh
```

---

## 项目结构

```
/workspace/
├── sql/                                    # MySQL 业务库脚本
│   └── gmall_schema.sql                    # 电商业务表结构
│
├── gmall-dw/                               # 数据仓库核心
│   ├── hive/                               # Hive 建表脚本
│   │   ├── create_ods.sql                 # ODS层建表
│   │   ├── create_dim.sql                 # DIM层建表（含拉链表）
│   │   ├── create_dwd.sql                 # DWD层建表
│   │   ├── create_dws.sql                 # DWS层建表
│   │   ├── create_ads.sql                # ADS层建表
│   │   └── etl_*.sql                      # ETL转换脚本
│   └── docs/                               # 设计文档
│       ├── 分层设计.md                     # 数仓分层设计
│       ├── 指标字典.md                     # 指标定义
│       └── 架构图.md                       # 架构说明
│
├── zookeeper/                              # Zookeeper 配置
│   └── zoo.cfg                            # Zookeeper 配置文件
│
├── datax/                                  # DataX 任务配置
│   ├── ods_user_info.json                 # 用户数据同步
│   ├── ods_order_info.json                # 订单数据同步
│   ├── ods_order_detail.json              # 订单明细同步
│   └── run_datax.sh                       # DataX 启动脚本
│
├── dolphinscheduler/                       # DolphinScheduler 配置
│   ├── workflow.json                      # ETL工作流定义
│   ├── workflow_full.yaml                 # 完整工作流配置
│   ├── submit_workflow.sh                 # 工作流提交脚本
│   └── README.md                          # DolphinScheduler 使用指南
│
├── superset/                              # Apache Superset 配置
│   ├── superset_config.py                 # Superset 配置文件
│   ├── hive_connection.py                # Hive 连接配置
│   ├── create_datasets.py                 # 自动创建数据集脚本
│   ├── chart_queries.py                   # 预置图表SQL查询
│   ├── dashboard_config.yaml              # 仪表盘配置
│   ├── install_superset.sh               # 安装部署脚本
│   └── README.md                          # Superset 使用指南
│
├── utils/                                 # 工具脚本
│   ├── data_masking.py                   # 数据脱敏工具
│   ├── data_quality_check.py             # 数据质量监控脚本
│   └── data_quality_validator.py         # 数据质量校验器
│
├── monitor/                               # 监控告警
│   ├── alert.sh                          # 告警脚本
│   └── service_monitor.sh                # 服务监控脚本
│
├── docs/                                  # 项目文档
│   ├── ETL流程说明.md                     # ETL流程说明
│   ├── sql_optimization.md               # SQL优化指南
│   └── 运维手册.md                        # 运维手册
│
├── *.py                                   # ETL Python 脚本
│   ├── setup_gmall_mysql_wsl.py         # MySQL 数据初始化
│   ├── ods_data_loader.py               # ODS层数据加载
│   ├── dim_data_processor.py            # DIM层数据处理
│   ├── dwd_data_processor.py            # DWD层数据清洗
│   ├── dws_data_processor.py            # DWS层数据汇总
│   └── demo_etl_flow.py                # ETL 演示脚本
│
├── *.sh                                   # 启动脚本
│   ├── start_all.sh                      # 启动所有基础服务
│   ├── stop_all.sh                       # 停止所有服务
│   ├── init_hive.sh                      # Hive初始化脚本
│   └── setup_hadoop_and_create_dirs.sh   # Hadoop环境配置
│
├── README.md                             # 项目说明文档
├── 项目完成报告.md                        # 项目完成报告
└── 验收报告.md                           # 项目验收报告
```

---

## 数据仓库架构

```
┌─────────────────────────────────────────────────────────────────┐
│                      数据采集层                                │
│                DataX (全量/增量同步)                            │
└───────────────────────────┬─────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      数据存储层                                │
│                    HDFS / Hive (离线批处理)                    │
└───────────────────────────┬─────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      数仓分层架构                              │
│  ODS ──► DIM ──► DWD ──► DWS ──► ADS                          │
│  (雪花模型 + SCD1/SCD2/SCD3 + 拉链表/快照表)                   │
└───────────────────────────┬─────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      数据应用层                                │
│    Apache Superset (可视化报表/日报/周报/月报)                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 核心功能

### 1. 数据采集
- **批量采集**：DataX 实现多数据源全量/增量同步
- **离线批处理**：纯离线数据同步，每日定时执行

### 2. 维度建模
- **雪花模型**：多层级维度关联，如商品→品类→品牌
- **SCD缓慢变化维**：支持 SCD1（覆盖更新）、SCD2（拉链表）、SCD3（多版本列）三种模式
- **多类型维度表**：普通维度、分层维度、拉链表、快照表、累计快照表

### 3. ETL 流程
- **数据清洗**：去重、过滤脏数据、格式统一
- **数据脱敏**：手机号、邮箱、身份证等敏感信息脱敏
- **指标计算**：GMV、订单量、用户留存等核心指标

### 4. 指标体系
- **原子指标**：基础度量指标
- **衍生指标**：基于原子指标计算
- **复合指标**：多指标组合计算
- **指标血缘**：完整的指标依赖链路

### 5. 任务调度与运维
- **DolphinScheduler**：复杂工作流编排、跨周期依赖、批量任务运维
- **监控告警**：任务超时告警、失败自愈、批量重跑机制

### 6. Hive 深度优化
- **分区裁剪**：高效的数据过滤
- **索引优化**：提升查询性能
- **大表Join优化**：MapJoin、BucketJoin等优化策略
- **数据生命周期管理**：冷热数据分离

### 7. 数据可视化
- **Superset 报表**：GMV日报、周报、月报，转化率分析、商品销售排行
- **自助报表**：支持业务人员自主查询分析

---

## 数据说明

### MySQL 业务表 (gmall 数据库)

| 表名 | 说明 | 记录数 |
|------|------|--------|
| user_info | 用户信息表 | ~5条 |
| order_info | 订单表 | ~10条 |
| order_detail | 订单明细表 | ~5条 |
| sku_info | 商品SKU表 | ~4条 |

### Hive 数仓表

| 层级 | 表名 | 说明 |
|------|------|------|
| **ODS** | ods_user_info | 用户原始数据 |
| **ODS** | ods_order_info | 订单原始数据 |
| **ODS** | ods_order_detail | 订单明细原始数据 |
| **DIM** | dim_user | 用户维度表（拉链表） |
| **DIM** | dim_sku | 商品SKU维度表 |
| **DIM** | dim_time | 日期维度表 |
| **DWD** | dwd_order_detail | 清洗后的订单明细 |
| **DWD** | dwd_order_info | 清洗后的订单 |
| **DWS** | dws_gmv_stats | GMV统计汇总 |
| **DWS** | dws_user_stats | 用户统计汇总 |
| **ADS** | ads_gmv_day | GMV日报表 |
| **ADS** | ads_user_retention | 用户留存表 |

---

## Superset 可视化

详细配置请参考 [superset/README.md](superset/README.md)

### 快速开始

```bash
# 1. 部署 Superset
cd superset
chmod +x install_superset.sh
./install_superset.sh

# 2. 访问 Superset
# 地址: http://localhost:8088
# 用户名: admin
# 密码: admin123

# 3. 配置数据源
python create_datasets.py

# 4. 创建图表
# 使用 chart_queries.py 中的 SQL 查询创建可视化图表
```

### 预置报表

| 报表名称 | SQL查询位置 | 说明 |
|---------|------------|------|
| GMV日报 | chart_queries.py:13 | 每日GMV统计 |
| GMV趋势 | chart_queries.py:23 | GMV趋势折线图 |
| 商品销售排行 | chart_queries.py:48 | Top商品销售排行 |
| 用户留存 | chart_queries.py:86 | 用户留存漏斗 |
| 转化率分析 | chart_queries.py:128 | 转化率分析 |

---

## DolphinScheduler 调度

详细配置请参考 [dolphinscheduler/README.md](dolphinscheduler/README.md)

### 工作流任务

```
datax_user_info ──► datax_order_info ──► datax_order_detail
                                                │
                    ┌───────────────────────────┘
                    ▼
              hive_dim ──► hive_dwd ──► hive_dws ──► hive_ads
```

### 定时调度

```bash
# Cron 表达式: 0 0 2 * * ?
# 含义: 每天凌晨2点执行
```

---

## 学习价值

通过本项目，您可以掌握：

- ✅ Hadoop HDFS 分布式文件系统使用
- ✅ DataX 多数据源同步
- ✅ 数据仓库分层架构设计 (ODS → DIM → DWD → DWS → ADS)
- ✅ 雪花模型维度建模
- ✅ SCD缓慢变化维（SCD1/SCD2/SCD3）实现
- ✅ 拉链表、快照表、累计快照表设计
- ✅ 指标体系搭建（原子/衍生/复合指标）
- ✅ ETL 流程开发与优化
- ✅ Hive 性能优化（分区裁剪、索引、大表Join）
- ✅ 数据生命周期管理与冷热数据分离
- ✅ 数据脱敏与安全治理
- ✅ SQL 优化技巧
- ✅ DolphinScheduler 复杂工作流编排
- ✅ Apache Superset 数据可视化与报表开发
- ✅ 数据质量监控与告警机制

---

## 文档

- [README.md](README.md) - 项目说明文档（本文档）
- [验收报告.md](验收报告.md) - 项目验收报告
- [superset/README.md](superset/README.md) - Superset 使用指南
- [dolphinscheduler/README.md](dolphinscheduler/README.md) - DolphinScheduler 使用指南
- [docs/sql_optimization.md](docs/sql_optimization.md) - SQL优化指南
- [gmall-dw/docs/分层设计.md](gmall-dw/docs/分层设计.md) - 数仓分层设计

---

## 许可证

MIT License

---

**项目地址**: https://github.com/NEAZ71eve/gmall-offline-dw

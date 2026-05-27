# 尚硅谷电商数仓项目

基于 Hadoop + Hive 的离线数据仓库项目，实现电商业务数据的采集、清洗、转换和汇总分析。

## 项目概述

本项目构建了一个完整的电商数仓系统，包含从数据采集、清洗、转换到汇总的完整 ETL 流程。

## 技术栈

- **Hadoop 3.3.5** - 分布式文件系统 (HDFS)
- **Hive 3.1.3** - 数据仓库工具
- **MySQL 8.0** - 业务数据库
- **Python 3.x** - ETL 脚本开发

## 数据仓库架构

```
ODS (原始数据层) → DIM (维度层) → DWD (明细事实层) → DWS (汇总层) → ADS (应用层)
```

### 各层说明

- **ODS 层**: 原始数据层，存储业务系统的原始数据
- **DIM 层**: 维度层，存储维度表（用户、商品、日期等）
- **DWD 层**: 明细事实层，存储经过清洗的事实表
- **DWS 层**: 汇总层，存储轻度汇总的指标数据
- **ADS 层**: 应用层，存储面向业务的报表数据

## 项目结构

```
.
├── sql/                          # SQL 脚本
│   └── gmall_schema.sql          # MySQL 建表脚本
├── gmall-dw/                     # 数据仓库相关
│   └── hive/                     # Hive 相关
│       └── ods_schema.md         # ODS 层表结构定义
├── scripts/                      # 启动脚本
│   ├── start_all.sh              # 启动所有服务
│   ├── init_hive.sh              # 初始化 Hive
│   └── create_gmall_db.sh        # 创建数据库
├── *.py                          # ETL 脚本
│   ├── ods_data_loader.py        # ODS 层数据加载
│   ├── dim_data_processor.py     # DIM 层数据处理
│   ├── dwd_data_processor.py     # DWD 层数据清洗
│   ├── dws_data_processor.py     # DWS 层数据汇总
│   └── setup_gmall_mysql_wsl.py # MySQL 数据初始化
├── README.md                      # 项目说明文档
├── 项目完成报告.md                # 项目完成报告
└── 实施计划.md                    # 项目实施计划
```

## 快速开始

### 1. 环境要求

- Linux (WSL) 环境
- Hadoop 3.3.5
- MySQL 8.0
- Hive 3.1.3
- Python 3.x

### 2. 启动服务

```bash
cd /mnt/d/s/作业
./start_all.sh
```

### 3. 执行 ETL 流程

```bash
# ODS 层数据加载
python3 ods_data_loader.py

# DIM 层数据处理
python3 dim_data_processor.py

# DWD 层数据处理
python3 dwd_data_processor.py

# DWS 层数据汇总
python3 dws_data_processor.py
```

### 4. 查看数据

```bash
# 查看 HDFS 目录结构
/usr/local/hadoop/bin/hdfs dfs -ls -R /warehouse/gmall/

# 查看 ODS 层数据
/usr/local/hadoop/bin/hdfs dfs -cat /warehouse/gmall/ods/user_info

# 查看 GMV 统计
/usr/local/hadoop/bin/hdfs dfs -cat /warehouse/gmall/dws/dws_gmv_stats
```

## 数据说明

### MySQL 业务表 (gmall 数据库)

| 表名 | 记录数 | 说明 |
|------|--------|------|
| user_info | 20 | 用户信息表 |
| order_info | 50 | 订单表 |
| order_detail | 102 | 订单明细表 |
| sku_info | 4 | 商品SKU表 |
| spu_info | 3 | 商品SPU表 |
| base_trademark | 5 | 品牌表 |
| base_category1 | 4 | 一级分类表 |
| base_category2 | 6 | 二级分类表 |
| base_category3 | 8 | 三级分类表 |
| payment_info | 0 | 支付表 |

### HDFS 数据文件

| 层级 | 文件 | 说明 |
|------|------|------|
| ODS | user_info | 用户原始数据 |
| ODS | order_info | 订单原始数据 |
| ODS | order_detail | 订单明细原始数据 |
| ODS | sku_info | 商品原始数据 |
| ODS | base_* | 基础维度原始数据 |
| DIM | dim_date | 日期维度表 (2020-2026) |
| DIM | dim_user | 用户维度表 (拉链表) |
| DIM | dim_sku | 商品SKU维度表 |
| DWD | dwd_order_detail | 清洗后的订单明细 |
| DWD | dwd_order_info | 清洗后的订单 |
| DWS | dws_gmv_stats | GMV 统计汇总 |
| DWS | dws_user_stats | 用户统计汇总 |

## 核心功能

1. **数据采集**: 从 MySQL 业务库抽取数据到 HDFS
2. **维度建模**: 构建用户、商品、日期等维度表
3. **数据清洗**: 清洗和转换订单、支付等事实表
4. **指标汇总**: 统计 GMV、订单量、用户行为等指标
5. **自动化 ETL**: Python 脚本实现全流程自动化

## 学习价值

通过本项目，您可以掌握：

- ✅ Hadoop HDFS 分布式文件系统使用
- ✅ 数据仓库分层架构设计 (ODS → DIM → DWD → DWS → ADS)
- ✅ ETL 流程开发与优化
- ✅ 维度建模与事实表设计
- ✅ Python 数据处理技术
- ✅ MySQL 业务数据库管理

## 文档

- [项目完成报告.md](项目完成报告.md) - 完整项目报告
- [README.md](README.md) - 项目说明文档
- [gmall-dw/hive/ods_schema.md](gmall-dw/hive/ods_schema.md) - ODS 层表结构定义

## 注意事项

1. **服务启动顺序**: MySQL → Hadoop (NameNode → DataNode)
2. **端口占用**: MySQL (3307), Hadoop NameNode (9000)
3. **目录权限**: 确保 WSL 用户有权限访问相关目录

## 作者

基于尚硅谷电商数仓项目教程开发

## 许可证

MIT License

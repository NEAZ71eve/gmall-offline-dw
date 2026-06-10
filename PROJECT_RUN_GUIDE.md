# 尚硅谷电商数仓项目 - 运行指南

## 项目概述

这是一个基于 Hadoop + Hive 的离线数据仓库项目，实现电商业务数据的采集、清洗、转换和汇总分析。

## 环境要求

### 已安装的组件（WSL2 Ubuntu 24.04）

| 组件 | 版本 | 路径 | 状态 |
|------|------|------|------|
| JDK | 1.8.0_482 | 系统自带 | ✅ 可用 |
| MySQL | 8.0.45 | /usr/sbin/mysqld | ✅ 可用 |
| Hadoop | 3.3.5 | /opt/hadoop-3.3.5 | ⚠️ 需要配置 |
| Hive | 3.1.3 | /opt/apache-hive-3.1.3-bin | ⚠️ 需要配置 |
| Kafka | 3.9.2 | /opt/kafka | ⚠️ 需要配置 |
| Flume | 1.11.0 | /opt/apache-flume-1.11.0-bin | ⚠️ 需要配置 |

## 启动流程

### 1. 启动基础服务

```bash
# 进入WSL
wsl -d Ubuntu

# 进入项目目录
cd /mnt/d/s/作业

# 启动Hadoop（修复后的脚本）
bash start_hadoop.sh

# 启动MySQL并初始化数据
bash start_mysql_and_init.sh

# 或者使用简化的MySQL初始化
bash init_mysql_data.sh
```

**预期输出：**
```
=== 启动所有服务 ===
1. 启动 MySQL...
MySQL 启动成功
2. 启动 Hadoop...
Hadoop 启动成功
3. 创建 ODS 层目录...
=== 所有服务启动完成 ===
```

**验证服务状态：**
```bash
# 检查MySQL
mysql -h 127.0.0.1 -u root -P 3307 -e "SHOW DATABASES;"

# 检查Hadoop进程
jps
# 应该看到: NameNode, DataNode
```

### 2. 初始化MySQL数据库

```bash
# 初始化业务数据库
bash init_mysql_data.sh
```

**预期输出：**
```
=== Initializing MySQL Database ===
tbl_name        cnt
Users           25
Orders          53
Order Details   106
SKU Info        8
=== Database initialization completed ===
```

### 3. 创建Hive数据库和表

```bash
# 进入Hive目录
cd /opt/apache-hive-3.1.3-bin

# 启动Hive Beeline或创建数据库
bin/hive -e "CREATE DATABASE IF NOT EXISTS gmall_ods;"
bin/hive -e "CREATE DATABASE IF NOT EXISTS gmall_dim;"
bin/hive -e "CREATE DATABASE IF NOT EXISTS gmall_dwd;"
bin/hive -e "CREATE DATABASE IF NOT EXISTS gmall_dws;"
bin/hive -e "CREATE DATABASE IF NOT EXISTS gmall_ads;"
```

### 4. 执行建表脚本

```bash
# 返回项目目录
cd /mnt/d/s/作业

# 执行建表脚本（按顺序）
cd gmall-dw/hive

# ODS层建表
bin/hive -f create_ods.sql

# DIM层建表
bin/hive -f create_dim.sql

# DWD层建表
bin/hive -f create_dwd.sql

# DWS层建表
bin/hive -f create_dws.sql

# ADS层建表
bin/hive -f create_ads.sql
```

### 5. 执行ETL流程

#### 5.1 ODS层数据同步

使用DataX将MySQL数据同步到HDFS：

```bash
cd /mnt/d/s/作业/datax

# 运行DataX同步任务
bash run_datax.sh
```

#### 5.2 ETL处理

```bash
cd /mnt/d/s/作业/gmall-dw/hive

# ODS -> DIM (维度表构建)
bin/hive -f etl_ods_to_dim.sql

# ODS -> DWD (明细数据清洗)
bin/hive -f etl_ods_to_dwd.sql

# DWD -> DWS (数据汇总)
bin/hive -f etl_dwd_to_dws.sql

# DWS -> ADS (指标计算)
bin/hive -f etl_dws_to_ads.sql
```

## 数据流向图

```
┌─────────────────────────────────────────┐
│         MySQL 业务数据库                 │
│  (user_info, order_info, order_detail)   │
└──────────────────┬──────────────────────┘
                   │
                   ▼ DataX / Maxwell
┌─────────────────────────────────────────┐
│        HDFS 分布式文件系统               │
└──────────────────┬──────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│              ODS层 (原始数据)            │
│  ods_user_info, ods_order_info,         │
│  ods_order_detail                       │
└──────────────────┬──────────────────────┘
                   │
                   ▼ ETL
┌─────────────────────────────────────────┐
│              DIM层 (维度表)             │
│  dim_user (拉链表), dim_sku, dim_time   │
└──────────────────┬──────────────────────┘
                   │
                   ▼ ETL
┌─────────────────────────────────────────┐
│              DWD层 (明细数据)            │
│  dwd_order_info, dwd_order_detail       │
└──────────────────┬──────────────────────┘
                   │
                   ▼ ETL
┌─────────────────────────────────────────┐
│              DWS层 (汇总数据)            │
│  dws_gmv_stats, dws_user_action_stats   │
└──────────────────┬──────────────────────┘
                   │
                   ▼ ETL
┌─────────────────────────────────────────┐
│              ADS层 (应用数据)            │
│  ads_gmv_day, ads_user_retention        │
└─────────────────────────────────────────┘
```

## 常用命令

### MySQL操作

```bash
# 连接MySQL
mysql -h 127.0.0.1 -u root -P 3307

# 查看数据库
mysql -h 127.0.0.1 -u root -P 3307 -e "SHOW DATABASES;"

# 查看表
mysql -h 127.0.0.1 -u root -P 3307 gmall -e "SHOW TABLES;"

# 查询数据
mysql -h 127.0.0.1 -u root -P 3307 gmall -e "SELECT COUNT(*) FROM user_info;"
```

### HDFS操作

```bash
# 查看目录
hdfs dfs -ls /warehouse/gmall/

# 查看文件
hdfs dfs -cat /warehouse/gmall/ods/ods_user_info/dt=2024-01-15/*

# 创建目录
hdfs dfs -mkdir -p /warehouse/gmall/ods

# 上传文件
hdfs dfs -put local_file.txt /warehouse/gmall/ods/
```

### Hive操作

```bash
# 启动Hive
hive

# 执行SQL
hive -e "SELECT * FROM gmall_ods.ods_user_info LIMIT 10;"

# 执行脚本
hive -f script.sql
```

## 已知问题

### 1. Hadoop在WSL2中启动问题

**症状：** Hadoop进程启动后很快退出，jps看不到NameNode和DataNode

**可能原因：**
- WSL2环境的网络和文件系统限制
- Hadoop配置不适合WSL2环境
- 端口冲突或权限问题

**解决方案：**
- 使用原生Linux或虚拟机运行Hadoop
- 检查$HADOOP_HOME/logs目录的日志文件
- 确保core-site.xml和hdfs-site.xml配置正确

### 2. MySQL连接问题

**症状：** ERROR 2003 (HY000): Can't connect to MySQL server

**解决方案：**
```bash
# 检查MySQL进程
ps aux | grep mysql

# 检查端口监听
netstat -tlnp | grep 3307

# 查看MySQL日志
tail -f /var/log/mysql/error.log
```

## 学习建议

### 第一阶段：理解架构（1-2天）
1. 阅读README.md和docs/ETL流程说明.md
2. 理解五层数据仓库架构
3. 查看SQL脚本，理解每层的职责

### 第二阶段：环境搭建（2-3天）
1. 安装配置Hadoop集群
2. 安装配置Hive
3. 启动服务并验证

### 第三阶段：实战演练（3-5天）
1. 执行完整的建表流程
2. 运行DataX同步任务
3. 执行ETL流程
4. 查询验证结果

### 第四阶段：深入理解（持续）
1. 学习SQL优化技巧
2. 理解任务调度原理
3. 学习数据质量监控

## 项目文件结构

```
d:\s\作业/
├── sql/                    # MySQL建表脚本
├── gmall-dw/              # 数据仓库核心
│   └── hive/             # Hive建表和ETL脚本
├── datax/                # DataX同步配置
├── flume-conf/           # Flume采集配置
├── kafka-conf/           # Kafka配置
├── dolphinscheduler/     # 调度系统配置
├── superset/            # 可视化配置
├── docs/                # 项目文档
└── *.sh                 # 启动脚本
```

## 下一步

1. **完善环境配置**：解决Hadoop启动问题
2. **执行完整流程**：运行所有建表和ETL脚本
3. **学习核心代码**：理解每个SQL的逻辑
4. **扩展功能**：添加数据质量监控、告警机制等

---

**最后更新：** 2026-05-29
**维护者：** 数据仓库团队

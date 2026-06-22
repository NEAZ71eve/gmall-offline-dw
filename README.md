# gmall 电商大数据全链路系统 · 基于 Docker + Shell 自动化

《Linux系统开发》期末大作业 — Shell 自动化驱动的电商离线大数据全链路平台。

**覆盖标准大数据工程流程**: 环境初始化 → 数据模拟/采集 → 分布式存储 → 离线计算 → 结果入库 → 数据可视化 → 集群自动化运维。

## 技术栈

| 组件 | 版本 | 角色 |
|---|---|---|
| **Hadoop (HDFS/YARN)** | 3.2.1 | 分布式存储 + 资源调度 |
| **Zookeeper** | 3.8 | 分布式协调 |
| **Hive** | 2.3.2 (pg metastore) | 离线数仓 5 层计算 (ODS→DIM→DWD→DWS→ADS) |
| **Spark** | 3.5 (standalone) | 离线批分析 (热门商品/转化漏斗/用户画像) |
| **MySQL** | 8.0 | 业务源库 + ADS 结果库 + Superset 元库 |
| **Superset** | 3.1 | 数据可视化平台 |
| **Docker Compose** | 3.8 | 容器化编排 (14 个容器) |
| **Bash** | 5.x | 全流程 Shell 自动化 |

## 快速启动

```bash
# 0. 确保 Docker 可用 (WSL / Linux)
docker --version

# 1. 启动全部服务
./scripts/cluster.sh start

# 2. 一键环境初始化
./scripts/cluster.sh init

# 3. 执行离线 ETL 全链路
./scripts/cluster.sh etl

# 4. 查看集群状态
./scripts/cluster.sh status

# 5. 打开 Superset
# 浏览器访问 http://localhost:8089 (admin / admin2024)
```

## 目录结构

```
作业/
├── docker-compose.yml              # 全组件 Docker 编排
├── .env                            # 环境变量 (密码/端口/版本)
├── conf/
│   ├── hadoop.env                  # Hadoop 集群配置
│   ├── hadoop-hive.env             # Hive 配置 (metastore+HDFS)
│   └── mysql/
│       ├── init.sql                # 业务库 schema + 60+条模拟数据
│       └── my.cnf
├── gmall-dw/hive/                  # Hive 数仓 SQL (5层完整)
│   ├── create_ods.sql / create_dim.sql / create_dwd.sql / create_dws.sql / create_ads.sql
│   └── etl_*.sql                   # ETL 加工脚本 (ODS→DIM→DWD→DWS→ADS)
├── spark/analytics.py              # PySpark 离线分析作业
├── scripts/                        # ★ Shell 自动化脚本集 (核心)
│   ├── cluster.sh                  # 总控 (start/stop/status/init/recover/cleanup/etl)
│   ├── start_all.sh                # 启动全部 14 个容器
│   ├── stop_all.sh                 # 停止全部容器
│   ├── cluster_init.sh             # 一键环境初始化
│   ├── status.sh                   # 集群健康巡检
│   ├── fault_recover.sh            # 故障自愈
│   ├── log_cleanup.sh              # 日志清理
│   ├── schedule_etl.sh             # 定时调度 + 全链路执行
│   ├── ingest_mysql_to_hdfs.sh     # 数据采集 (MySQL→HDFS)
│   ├── run_offline_etl.sh          # 离线 ETL (Hive 5 层)
│   ├── run_spark_job.sh            # Spark 分析提交
│   ├── export_ads_to_mysql.sh      # 结果入库 (Hive→MySQL)
│   └── superset_setup.sh           # Superset 初始化
├── superset/
│   ├── superset_config.py          # Superset 配置
│   └── init_superset.py            # 数据源自动创建
├── sql/                            # MySQL schema
├── ref-code/                       # Shell 电商分析器 (额外 Shell 能力佐证)
├── docs/                           # 设计报告 + 部署运维手册 + 架构图
└── README.md
```

## 数据流

```
conf/mysql/init.sql ──写入──▶ MySQL (gmall: user_info, order_info, order_detail, sku_info)
                                   │
                    ingest_mysql_to_hdfs.sh (mysql --batch | hdfs dfs -put)
                                   │
                                   ▼
                            HDFS /origin_data/gmall/db/{table}/dt=YYYY-MM-DD/
                                   │
                    run_offline_etl.sh (beeline -f, hive var biz_date)
                                   │
                    ┌──────────────┼──────────────┐
                    ▼              ▼              ▼              ▼              ▼
                  ODS ─────▶ DIM ─────▶ DWD ─────▶ DWS ─────▶ ADS
               (原始数据)    (维度表)   (明细事实)  (汇总宽表)  (应用报表)
                                                          │
                                    ┌─────────────────────┤
                                    │                     │
                        export_ads_to_mysql.sh    run_spark_job.sh
                                    │                     │
                                    ▼                     ▼
                            MySQL ads_* 表      Spark 补充指标输出
                                    │
                                    ▼
                        Superset 可视化平台
                    ┌─────────────────────────┐
                    │ 离线看板:                │
                    │  · GMV 趋势图            │
                    │  · 热门商品 Top10        │
                    │  · 转化漏斗              │
                    │  · 用户留存              │
                    │  · 支付方式分布          │
                    └─────────────────────────┘
```

## Shell 自动化清单 (符合考核核心强制要求)

| 能力 | 脚本 | 说明 |
|---|---|---|
| **集群部署** | `cluster.sh start` | `docker compose up -d` 全部容器 |
| **服务启停** | `start_all.sh / stop_all.sh` | 带健康检查等待与端口验证 |
| **环境初始化** | `cluster.sh init` | HDFS目录 + Hive 5层库 + MySQL schema |
| **任务调度** | `schedule_etl.sh --run-now` | 一键执行 5 步全链路 ETL |
| **定时调度** | `schedule_etl.sh --cron` | 输出 crontab 注册示例 |
| **故障自愈** | `cluster.sh recover` | 检测宕机容器并重启 |
| **日志清理** | `log_cleanup.sh` | 容器日志截断 + HDFS 旧分区回收 |
| **集群巡检** | `cluster.sh status` | 容器/HDFS/Hive/MySQL/Spark/Superset 全检查 |
| **数据采集** | `ingest_mysql_to_hdfs.sh` | MySQL → HDFS 流式采集 |
| **离线计算** | `run_offline_etl.sh` | ODS→DIM→DWD→DWS→ADS 逐层执行 |
| **结果入库** | `export_ads_to_mysql.sh` | Hive ADS → MySQL 结果表 |
| **可视化初始化** | `superset_setup.sh` | 建管理员+初始化DB+安装驱动+添加数据源 |

## 容器化编排

```bash
# 查看所有容器
docker compose ps

# 关键端口
HDFS NameNode:  http://localhost:9870
YARN RM:        http://localhost:8088
Spark Master:   http://localhost:18080
Superset:       http://localhost:8089
Hive Server2:   jdbc:hive2://localhost:10000 (beeline)
MySQL:          localhost:3306 (gmall / gmall123)
```

## 环境要求

- **Docker** (Docker Desktop + WSL2 或原生 Linux)
- **内存** ≥ 12GB (建议 16GB+)
- **磁盘** ≥ 10GB 空闲 (Docker 镜像 + 数据卷)
- **Shell** Bash 5.x (WSL 或 Linux)

## 运维常用命令

```bash
# 健康巡检
./scripts/cluster.sh status

# 查看某容器日志
docker logs -f hive-server
docker logs -f namenode

# 手动进入 Hive
docker exec -it hive-server beeline -u jdbc:hive2://localhost:10000

# 手动查 HDFS
docker exec -it namenode hdfs dfs -ls -R /warehouse/gmall

# 手动查 MySQL
docker exec -it mysql mysql -u gmall -pgmall123 gmall

# 重启单个服务
docker compose restart hive-server

# 彻底清理 (删除数据!)
docker compose down -v
```

## 许可证

MIT License

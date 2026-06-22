# 基于 Docker 的电商(gmall)大数据全链路系统 — 设计文档

- 日期: 2026-06-22
- 课题: 《Linux系统开发》期末大作业 — Shell 自动化驱动的电商离线大数据全链路系统
- 适用考核点: 环境初始化 → 数据模拟/采集 → 分布式存储 → 离线计算 → 结果入库 → 数据可视化 → 集群自动化运维；容器化与版本控制；Shell 脚本自动化

## 1. 目标与范围

在 Linux(WSL Ubuntu) 上用 Docker Compose 搭建一套电商大数据环境,覆盖 Hadoop(HDFS/YARN)、Zookeeper、Hive、Spark、MySQL、Superset 六类组件,通过 **Shell 脚本最大化自动化**实现"环境初始化 → 数据模拟 → 采集入 HDFS → Hive 分层离线计算 → 结果入库 MySQL → Superset 可视化 → 集群运维(启停/健康巡检/故障自愈/日志清理/定时调度)"标准流程。

**范围(确定项):**
- 离线计算全链路为主链路,必须跑通并验证。
- 实时计算(Flink/Kafka)与 HBase **不在本期范围**,仅在设计报告与运维手册中作为扩展方向文字说明,不实现、不部署。
- 数据域: 电商 gmall(用户 user_info、商品 sku_info、订单 order_info、订单明细 order_detail)。
- 全部交付物落在仓库内;mp4 答辩录屏由学生本人录制,不在工程交付范围。

**成功标准(可验证):**
1. `docker compose up -d` 全部容器健康(running/healthy),`status.sh` 全绿。
2. `cluster_init.sh` 一键完成: HDFS 目录、Hive 库(5 层)、MySQL 业务库与 mock 数据。
3. `ingest_mysql_to_hdfs.sh` 将业务源数据放入 HDFS `/origin_data`。
4. `run_offline_etl.sh` 跑通 ODS→DIM→DWD→DWS→ADS,各层表行数 > 0。
5. `run_spark_job.sh` 产出至少 1 个补充指标(如热门 SKU Top10)。
6. `export_ads_to_mysql.sh` 将 ADS 关键报表导出到 MySQL。
7. `superset_setup.sh` 建好 Hive 与 MySQL 数据源、导入看板;浏览器打开 http://localhost:8089 可见离线看板。
8. `fault_recover.sh`、`log_cleanup.sh`、`schedule_etl.sh` 均可运行并产出可观测结果。

## 2. 组件栈

统一 `docker-compose.yml`(置于仓库根),所有服务在同一用户定义网络 `gmall-net`。

| 组件 | 镜像 | 容器(端口) | 角色 |
|---|---|---|---|
| HDFS NameNode | bde2020/hadoop-namenode:2.0.0-hadoop3.2.1-java8 | namenode(9870,9000) | HDFS 主节点 |
| HDFS DataNode | bde2020/hadoop-datanode:2.0.0-hadoop3.2.1-java8 | datanode1/2(9864/9865) | 数据节点(2 副本即可) |
| YARN ResourceManager | bde2020/hadoop-resourcemanager | resourcemanager(8088) | YARN 调度主 |
| YARN NodeManager | bde2020/hadoop-nodemanager | nodemanager(8042) | YARN 计算 |
| HistoryServer | bde2020/hadoop-historyserver | historyserver(8188) | 作业历史 |
| Zookeeper | bitnami/zookeeper:3.8 | zookeeper(2181) | 协调(为 Hive/Spark HA 预留) |
| Hive Metastore | bde2020/hive:2.3.2-postgresql-metastore | hive-metastore(9083) | 元数据 |
| Hive Server2 | bde2020/hive:2.3.2-postgresql-metastore | hive-server(10000) | beeline 入口 |
| Hive PG | bde2020/hive-metastore-postgresql:2.3.0 | hive-metastore-postgresql | metastore 库 |
| MySQL | mysql:8.0 | mysql(3306) | 业务源库 gmall + ADS 结果库 + Superset 元库 |
| Spark Master | bitnami/spark:3.5 | spark-master(7077,8080) | 离线批算子 |
| Spark Worker | bitnami/spark:3.5 | spark-worker(8081) | Spark 计算 |
| Superset | apache/superset:3.1 | superset(8089) | 可视化 |

容器约 13 个。`.env` 集中管理版本、端口、口令。各服务设 `mem_limit`,datanode 降为 2 个以控内存。

> 选型理由: bde2020 hadoop/hive 栈与 WSL 内已存在的 `~/docker-hadoop-spark/` 同源,镜像可用性高;Spark 用 standalone(非 on YARN),规避与 Hadoop3.2.1/java8 的版本耦合,降低风险;Zookeeper 为后续 HA 与可能的实时扩展预留,本期亦供 Spark master standby 语义。

## 3. 数据流

```
gen_mock_data.sh ──写──▶ MySQL(gmall 业务表)
                              │ ingest_mysql_to_hdfs.sh (mysql --batch -B | hdfs dfs -put)
                              ▼
                       HDFS /origin_data/gmall/db/{user_info,order_info,order_detail,sku_info}/dt=...
                              │ run_offline_etl.sh (beeline -f, ${biz_date} 替换)
                              ▼
   ODS ─▶ DIM ─▶ DWD ─▶ DWS ─▶ ADS  (Hive 5 层, ORC/分区分桶)
                              │ run_spark_job.sh (读 ADS/DWS, 算热门SKU等补充指标)
                              ▼
                       Hive ADS 表 + MySQL ads 结果表
                              │ export_ads_to_mysql.sh (beeline 导出 → mysql 导入)
                              ▼
                       MySQL ads.* 表 ──▶ Superset(看板)
                              ▲
   Superset 同时直连 Hive(ODS~ADS)与 MySQL(ads) 两类数据源
```

数据时间分区键 `dt`(业务日期,默认取 mock 数据覆盖的日期区间)。ETL 脚本通过 `-hivevar dt=YYYY-MM-DD` 与 `--hivevar biz_date=...` 参数化。

## 4. Shell 自动化脚本集(核心强制要求)

全部置于 `scripts/`,统一 `cluster.sh` 总控 + 各专项脚本,采用 `set -euo pipefail`、函数化、带日志与颜色输出。

| 脚本 | 功能 |
|---|---|
| `cluster.sh` | 总控: `start\|stop\|restart\|status\|init\|recover\|logs\|cleanup\|etl` 分发到子脚本 |
| `start_all.sh` | `docker compose up -d`,等待健康,并校验关键端口 |
| `stop_all.sh` | `docker compose down`(保留卷) |
| `cluster_init.sh` | HDFS 建目录、Hive 建 5 库 + 跑 create_*.sql、MySQL 建库 + 初始化 |
| `status.sh` | 容器状态 + HDFS 健康 + Hive/MySQL 连通性巡检,输出表 |
| `fault_recover.sh` | 周期/触发检测宕机容器,`docker compose up -d <svc>` 自愈并告警日志 |
| `log_cleanup.sh` | 清理 HDFS 旧分区(>N 天)、容器日志、YARN 临时,可被 `schedule_etl.sh` cron 调用 |
| `schedule_etl.sh` | Shell 定时调度每日 ETL(含 `cluster_init→ingest→etl→spark→export` 全链),可注册 cron |
| `gen_mock_data.sh` | 生成电商业务数据写 MySQL(基于既有 setup_gmall_mysql_wsl 逻辑改为 Shell+SQL) |
| `ingest_mysql_to_hdfs.sh` | MySQL → HDFS(流式导出 + put,按 dt 分区目录) |
| `run_offline_etl.sh` | beeline 执行 gmall-dw/hive 下 create_*.sql + etl_*.sql,带 biz_date 参数与行数校验 |
| `run_spark_job.sh` | spark-submit 提交 PySpark/Scala 作业算补充指标 |
| `export_ads_to_mysql.sh` | beeline 导出 ADS → 临时文件 → mysql LOAD/INSERT |
| `superset_setup.sh` | 初始化 Superset: 建管理员、数据源(Hive+MySQL)、导入看板 JSON |

## 5. 仓库结构

```
docker-compose.yml          # 全组件编排
.env                        # 版本/端口/口令集中
conf/
  hadoop.env                # Hadoop 环境变量
  hive/hive-site.xml        # Hive 配置(指向 metastore/HDFS)
  mysql/init.sql            # 业务库 + ads 库 + 实时表(预留) schema
  spark/                    # spark-defaults.conf 等
gmall-dw/hive/              # 既有 5 层数仓 SQL(保留,仅按需微调)
sql/                        # MySQL schema(业务源 + ads 结果)
spark/                      # Spark 作业源码(PySpark) + 打包说明
scripts/                    # 全部 Shell 自动化(见上表)
superset/
  superset_config.py        # Superset 配置
  dashboards/*.json         # 看板导入文件
  setup_superset.sh         # (= scripts/superset_setup.sh 的实际实现或链接)
docs/
  设计报告.md               # 可贴入 docx 模板
  部署运维手册.md
  架构图.md
README.md
```

既有但不再需要的主机直装脚本(`start_all.sh` 老版、`setup_hadoop_and_create_dirs.sh`、`setup_gmall_mysql_wsl.py`、`create_gmall_db.sh`、`start_mysql_and_init.sh`)将被仓库内 Docker 版脚本取代;处理方式见第 8 节"迁移与清理"。

## 6. 验证计划(实际执行并报告数字)

按顺序执行,每步记录输出与行数,失败即停并排查:
1. `docker compose up -d` → `status.sh` 全绿(13 容器 healthy)。
2. `cluster_init.sh` → `hdfs dfs -ls /warehouse/gmall/*` 各层目录存在;Hive `show databases` 含 5 库;MySQL `use gmall; select count(*)` 业务表有数据。
3. `gen_mock_data.sh` → 业务表行数 > 阈值(给出具体数字)。
4. `ingest_mysql_to_hdfs.sh` → HDFS `/origin_data/.../dt=...` 各表文件存在且非空。
5. `run_offline_etl.sh` → DIM/DWD/DWS/ADS 各 `select count(*)` > 0(给数字);GMV 等指标非空。
6. `run_spark_job.sh` → 输出热门 SKU Top10 到 MySQL/控制台。
7. `export_ads_to_mysql.sh` → MySQL `ads.*` 表行数与 Hive ADS 一致。
8. `superset_setup.sh` → http://localhost:8089 可登录,看板含至少 4 张图表(GMV 趋势、订单数、热门商品、用户活跃)。
9. 运维演示: 手动 `docker stop datanode1` → `fault_recover.sh` 恢复; `log_cleanup.sh` 执行后报告清理量; `schedule_etl.sh --dry-run` 打印调度计划。

未通过或受环境限制(如内存不足降配)的步骤,在报告与提交说明中**明确标注**,不谎报。

## 7. 错误处理与降级

- 容器依赖用 `SERVICE_PRECONDITION` + `healthcheck`,`start_all.sh` 轮询等待而非固定 sleep。
- ETL 脚本对每层做行数断言,异常退出码非 0 并输出日志路径。
- 若 WSL 内存不足: 降 datanode→2、Spark worker→1、Superset 给 `mem_limit`,必要时分阶段启停(ETL 期间停 Superset,演示期间停 Spark)。
- 口令统一 `.env`,不硬编码;`start_mysql_and_init.sh` 老脚本中的明文 sudo 口令不再使用。

## 8. 迁移与清理(对现有仓库的处理)

- 删除/替换: 主机直装版 `start_all.sh`、`start_mysql_and_init.sh`、`setup_hadoop_and_create_dirs.sh`、`create_gmall_db.sh`、`setup_gmall_mysql_wsl.py`(内容并入 Docker 版脚本与 `conf/mysql/init.sql`)。
- 保留: `gmall-dw/hive/*`(数仓 SQL)、`gmall-dw/docs/*`、`gmall-conf/*`(改为容器配置引用)、`ref-code/*`(Shell 分析器,作为 Shell 编程能力的额外佐证保留,文档中说明)、`sql/*`、`superset/superset_config.py`。
- 删除无关文件: `derby.log`、`venv/`(若仅本地用,加入 .gitignore)。
- `README.md` 重写为 Docker 全链路说明。

## 9. 交付材料对应

- 设计报告(电子档): `docs/设计报告.md`(可粘入附件2 docx 模板)。
- 源代码与重要配置: `docker-compose.yml`、`conf/`、`gmall-dw/hive/`、`sql/`、`spark/`、`scripts/`、`superset/`。
- 部署运维手册: `docs/部署运维手册.md`。
- 答辩录屏: 学生本人录制(不在工程内)。
- 命名打包按考核要求 `学号-姓名-Linux系统开发-大作业源代码.zip`,学号/姓名待学生填入(报告封面留占位)。

## 10. 风险

- **内存**: ~13 容器对 WSL 内存压力大 → 已设 mem_limit 与降配预案。
- **bde2020 镜像可用性**: 该栈久未更新,需联网拉取;若某镜像失效,用 `bigdataendeavour/hive-metastore` 等替代并记录。
- **时间**: 6/26 截止 → 优先保证离线主链路跑通与 Superset 看板,运维脚本次之,报告最后补。

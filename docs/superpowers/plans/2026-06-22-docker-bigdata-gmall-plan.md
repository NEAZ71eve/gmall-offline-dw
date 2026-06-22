# Docker电商大数据全链路系统 实施计划

**目标:** 基于Docker+Shell搭建电商(gmall)离线大数据全链路，覆盖Hadoop/ZK/Hive/Spark/MySQL/Superset，Shell自动化运维，满足考核标准。

**架构:** Docker Compose统一编排13个容器 → Shell脚本全链路自动化(环境初始化→数据模拟→采集入HDFS→Hive五层ETL→Spark补充计算→结果入MySQL→Superset可视化→集群运维)。

**核心交付物:**
1. `docker-compose.yml` + `.env` + `conf/` — 全组件编排
2. `scripts/` — 15个Shell自动化脚本(满足核心强制要求)
3. `gmall-dw/hive/` — 5层数仓SQL(已有,微调)
4. `sql/` — MySQL schema(业务+ads)
5. `spark/` — PySpark作业
6. `superset/` — 配置+看板导入+setup脚本
7. `docs/` — 设计报告+部署运维手册+架构图
8. `README.md` — 重写为Docker全链路说明

## 任务顺序(8个Phase,按依赖串行)

### Phase 1: 仓库准备与清理

### Phase 2: Docker Compose + 配置文件

### Phase 3: Shell自动化脚本(核心)

### Phase 4: 数据模拟与MySQL初始化

### Phase 5: Hive数仓SQL微调

### Phase 6: Spark离线计算作业

### Phase 7: Superset可视化

### Phase 8: 文档+README+验证

---

### Task 1.1: 清理旧文件,搭建目录结构

**操作:**
- 删除旧的主机安装脚本
- 创建新目录: scripts/ conf/hive conf/mysql conf/spark spark/ sql/
- 更新 .gitignore

### Task 1.2: 重写 README.md

**操作:** 用Docker全链路说明替换当前README

---

### Task 2.1: 编写 .env + hadoop.env + hive-site.xml

### Task 2.2: 编写 docker-compose.yml (核心编排文件)

### Task 2.3: 编写 conf/mysql/init.sql (业务库+ADS库)

---

### Task 3.1-3.12: Shell脚本集(每个脚本独立)

1. `cluster.sh` — 总控
2. `start_all.sh` — 启动全部服务
3. `stop_all.sh` — 停止全部服务
4. `cluster_init.sh` — 一键环境初始化(HDFS目录+Hive库+MySQL库)
5. `status.sh` — 集群健康巡检
6. `fault_recover.sh` — 故障自愈
7. `log_cleanup.sh` — 日志清理
8. `schedule_etl.sh` — 定时调度
9. `gen_mock_data.sh` — 数据模拟
10. `ingest_mysql_to_hdfs.sh` — 数据采集
11. `run_offline_etl.sh` — 离线ETL
12. `run_spark_job.sh` — Spark作业提交
13. `export_ads_to_mysql.sh` — 结果入库
14. `superset_setup.sh` — Superset初始化

---

### Task 4.1: MySQL init SQL (业务源表schema + mock数据)

### Task 5.1: Hive SQL调整(biz_date参数化统一)

### Task 6.1: PySpark作业(热门商品+转化漏斗指标)

### Task 7.1: Superset config + 看板JSON + setup脚本

### Task 8.1: 设计报告.md + 部署运维手册.md + 架构图.md

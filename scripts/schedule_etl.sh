#!/bin/bash
# ============================================================
# schedule_etl.sh - Shell 定时调度每日 ETL 全链路
# 用法: ./schedule_etl.sh [--run-now] [--date YYYY-MM-DD] [--cron]
#   --run-now : 立即执行一次
#   --date     : 指定业务日期(默认昨天)
#   --cron     : 输出 crontab 注册提示
# ============================================================
set -euo pipefail

RUN_NOW=false; BIZ_DATE=""; SHOW_CRON=false

while [ $# -gt 0 ]; do
    case "$1" in
        --run-now) RUN_NOW=true; shift;;
        --date)    BIZ_DATE="$2"; shift 2;;
        --cron)    SHOW_CRON=true; shift;;
        *) shift;;
    esac
done

if [ -z "$BIZ_DATE" ]; then
    BIZ_DATE=$(date -d 'yesterday' '+%Y-%m-%d' 2>/dev/null || date '+%Y-%m-%d')
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
info() { echo -e "${GREEN}[INFO]${NC}  $*"; }
step() { echo -e "\n${BLUE}════════════════════════════════════════════════${NC}"; echo -e "${BLUE}  $*${NC}"; }

if $SHOW_CRON; then
    echo ""
    echo "# ===== gmall 定时调度 - crontab 注册示例 ====="
    echo ""
    echo "# 每日凌晨2点执行离线ETL全链路"
    echo "0 2 * * * cd $(pwd) && bash $SCRIPT_DIR/schedule_etl.sh --run-now >> /tmp/gmall_etl.log 2>&1"
    echo ""
    echo "# 每周日凌晨3点日志清理"
    echo "0 3 * * 0 cd $(pwd) && bash $SCRIPT_DIR/log_cleanup.sh >> /tmp/gmall_cleanup.log 2>&1"
    echo ""
    echo "# 每小时健康巡检"
    echo "0 * * * * cd $(pwd) && bash $SCRIPT_DIR/status.sh >> /tmp/gmall_status.log 2>&1"
    echo ""
    echo "# 注册方式: crontab -e  粘贴以上行"
    echo ""
    exit 0
fi

if $RUN_NOW; then
    info "执行离线 ETL 全链路 - 日期: $BIZ_DATE"
    START_TIME=$(date +%s)

    # 1. 环境初始化
    step "1/5 环境初始化"
    bash "$SCRIPT_DIR/cluster_init.sh"

    # 2. 数据采集 MySQL → HDFS
    step "2/5 数据采集"
    bash "$SCRIPT_DIR/ingest_mysql_to_hdfs.sh" "$BIZ_DATE"

    # 3. Hive 离线 ETL (ODS→DIM→DWD→DWS→ADS)
    step "3/5 离线 ETL (Hive 5层)"
    bash "$SCRIPT_DIR/run_offline_etl.sh" "$BIZ_DATE"

    # 4. Spark 补充计算
    step "4/5 Spark 离线分析"
    bash "$SCRIPT_DIR/run_spark_job.sh" "$BIZ_DATE" || \
        echo "  (Spark 作业异常,不影响主链路)"

    # 5. 结果入库 Hive → MySQL
    step "5/5 结果入库 (ADS → MySQL)"
    bash "$SCRIPT_DIR/export_ads_to_mysql.sh" "$BIZ_DATE"

    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))

    echo ""
    info "========================================="
    info "  ETL 全链路完成! 耗时: ${ELAPSED} 秒"
    info "========================================="
else
    info "用法: $0 --run-now [--date YYYY-MM-DD]"
    info "      $0 --cron  # 查看 crontab 示例"
fi

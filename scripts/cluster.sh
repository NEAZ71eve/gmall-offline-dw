#!/bin/bash
# ============================================================
# cluster.sh - gmall 集群总控脚本
# 用法: ./cluster.sh {start|stop|restart|status|init|recover|logs|cleanup|etl}
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# 颜色
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
step()  { echo -e "${BLUE}[STEP]${NC} $*"; }

usage() {
    echo "用法: $0 {start|stop|restart|status|init|recover|logs|cleanup|etl}"
    echo "  start    - 启动全部容器"
    echo "  stop     - 停止全部容器"
    echo "  restart  - 重启全部容器"
    echo "  status   - 集群健康巡检"
    echo "  init     - 一键环境初始化(HDFS目录+Hive库+MySQL验证)"
    echo "  recover  - 故障自愈(检测宕机容器并重启)"
    echo "  logs     - 显示关键服务日志摘要"
    echo "  cleanup  - 清理临时日志与旧分区"
    echo "  etl      - 执行完整离线ETL链路(含Spark)"
}

case "${1:-}" in
    start)
        shift; bash "$SCRIPT_DIR/start_all.sh" "$@";;
    stop)
        shift; bash "$SCRIPT_DIR/stop_all.sh" "$@";;
    restart)
        shift; bash "$SCRIPT_DIR/stop_all.sh" "$@"
        bash "$SCRIPT_DIR/start_all.sh" "$@";;
    status)
        shift; bash "$SCRIPT_DIR/status.sh" "$@";;
    init)
        shift; bash "$SCRIPT_DIR/cluster_init.sh" "$@";;
    recover)
        shift; bash "$SCRIPT_DIR/fault_recover.sh" "$@";;
    logs)
        shift; bash "$SCRIPT_DIR/log_cleanup.sh" --show-logs "$@";;
    cleanup)
        shift; bash "$SCRIPT_DIR/log_cleanup.sh" "$@";;
    etl)
        shift; bash "$SCRIPT_DIR/schedule_etl.sh" --run-now "$@";;
    *)
        usage; exit 1;;
esac

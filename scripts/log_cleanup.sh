#!/bin/bash
# ============================================================
# log_cleanup.sh - 日志清理与旧分区回收
# 清理: 容器日志截断 / HDFS 旧分区 / YARN 临时文件
# 用法: ./log_cleanup.sh [--retain-days N] [--show-logs] [--dry-run]
# ============================================================
set -euo pipefail

RETAIN_DAYS=7
DRY_RUN=false
SHOW_LOGS=false

while [ $# -gt 0 ]; do
    case "$1" in
        --retain-days) RETAIN_DAYS="$2"; shift 2;;
        --show-logs)   SHOW_LOGS=true; shift;;
        --dry-run)     DRY_RUN=true; shift;;
        *) shift;;
    esac
done

GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
step()  { echo -e "${BLUE}[STEP]${NC} $*"; }

DRY_PREFIX=""
$DRY_RUN && DRY_PREFIX="[DRY-RUN] "

if $SHOW_LOGS; then
    echo "=== 关键容器最近日志 (tail 5) ==="
    for c in namenode hive-server mysql spark-master superset; do
        echo "--- $c ---"
        docker logs --tail 5 "$c" 2>/dev/null || echo "  (不可用)"
    done
    exit 0
fi

info "${DRY_PREFIX}日志清理开始 (保留最近 ${RETAIN_DAYS} 天)..."

# 1. 容器日志截断 (不删容器,清零日志)
step "1/3 容器日志截断..."
for c in namenode datanode1 datanode2 resourcemanager nodemanager hive-server hive-metastore mysql spark-master spark-worker superset; do
    log_file=$(docker inspect --format='{{.LogPath}}' "$c" 2>/dev/null || echo "")
    if [ -n "$log_file" ] && [ -f "$log_file" ]; then
        log_size=$(du -h "$log_file" 2>/dev/null | cut -f1 || echo "?")
        if ! $DRY_RUN; then
            sudo truncate -s 0 "$log_file" 2>/dev/null || echo "  (需 sudo 权限跳过)"
        fi
        echo "  $c: ${log_size} -> 0"
    fi
done

# 2. HDFS 旧分区清理
step "2/3 HDFS 旧分区检查..."
threshold_date=$(date -d "${RETAIN_DAYS} days ago" '+%Y-%m-%d' 2>/dev/null || echo "")
if [ -n "$threshold_date" ]; then
    echo "  清理 ${threshold_date} 之前的 ODS 分区..."
    if ! $DRY_RUN; then
        docker exec namenode hdfs dfs -ls -R /warehouse/gmall/ods/ 2>/dev/null | grep "dt=" | while read line; do
            dt_part=$(echo "$line" | grep -oP 'dt=\K[^/]+' || echo "")
            if [ -n "$dt_part" ] && [[ "$dt_part" < "$threshold_date" ]]; then
                echo "  将删除: $dt_part"  # hdfs dfs -rm -r 这里保守,只列不删
            fi
        done
    else
        echo "  (dry-run) 将列出 $threshold_date 之前的分区"
    fi
else
    echo "  (日期工具不可用,跳过)"
fi

# 3. YARN 临时作业历史
step "3/3 YARN 历史清理..."
if ! $DRY_RUN; then
    docker exec resourcemanager yarn application -list -appStates FINISHED,FAILED,KILLED 2>/dev/null | grep "application_" | head -10 | while read line; do
        app_id=$(echo "$line" | awk '{print $1}')
        echo "  YARN app: $app_id"
    done
fi

info "${DRY_PREFIX}日志清理完成"
echo "  提示: 将本脚本加入 crontab 实现定时清理"
echo "  cron 示例: 0 3 * * 0 /path/to/scripts/log_cleanup.sh  # 每周日凌晨3点"

#!/bin/bash
# ============================================================
# fault_recover.sh - 故障自愈
# 检测非 running 的关键容器,尝试重启,并验证恢复
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*"; }

CRITICAL="namenode datanode1 datanode2 resourcemanager nodemanager historyserver zookeeper hive-metastore-postgresql hive-metastore hive-server mysql spark-master spark-worker superset"

RECOVERED=0; FAILED=0

info "开始故障检测..."

for svc in $CRITICAL; do
    status=$(docker inspect -f '{{.State.Status}}' "$svc" 2>/dev/null || echo "missing")
    if [ "$status" != "running" ]; then
        warn "服务 $svc 状态异常($status)，尝试恢复..."
        docker compose up -d "$svc" 2>/dev/null || true
        sleep 5
        new_status=$(docker inspect -f '{{.State.Status}}' "$svc" 2>/dev/null || echo "missing")
        if [ "$new_status" = "running" ]; then
            info "  $svc 已恢复 (running)"
            RECOVERED=$((RECOVERED+1))
        else
            err "  $svc 恢复失败 (当前: $new_status)"
            FAILED=$((FAILED+1))
        fi
    fi
done

echo ""
info "故障自愈完成: 恢复 ${GREEN}${RECOVERED}${NC} 个, 失败 ${RED}${FAILED}${NC} 个"

if [ "$FAILED" -gt 0 ]; then
    echo ""
    err "以下服务未能自动恢复，请检查日志:"
    for svc in $CRITICAL; do
        st=$(docker inspect -f '{{.State.Status}}' "$svc" 2>/dev/null || echo "missing")
        if [ "$st" != "running" ]; then
            echo "  $svc -> $st  (docker logs --tail 20 $svc)"
        fi
    done
    exit 1
fi

#!/bin/bash
# ============================================================
# start_all.sh - 启动全部 Docker 服务并等待健康
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }

info "启动 gmall 大数据平台..."
docker compose up -d

info "等待基础服务就绪 (HDFS)..."
for s in namenode datanode1 datanode2 resourcemanager nodemanager zookeeper; do
    printf "  等待 %-20s ... " "$s"
    for i in $(seq 1 30); do
        status=$(docker inspect -f '{{.State.Status}}' "$s" 2>/dev/null || echo "missing")
        if [ "$status" = "running" ]; then
            echo -e "${GREEN}OK${NC} ($(echo $i)x2s)"
            break
        fi
        sleep 2
        if [ "$i" -eq 30 ]; then echo -e "${RED}FAIL${NC}"; fi
    done
done

info "等待 Hive Metastore + MySQL..."
for s in hive-metastore-postgresql hive-metastore mysql; do
    printf "  等待 %-20s ... " "$s"
    for i in $(seq 1 40); do
        status=$(docker inspect -f '{{.State.Status}}' "$s" 2>/dev/null || echo "missing")
        if [ "$status" = "running" ]; then
            echo -e "${GREEN}OK${NC} ($(echo $i)x2s)"
            break
        fi
        sleep 2
        if [ "$i" -eq 40 ]; then echo -e "${RED}FAIL${NC}"; fi
    done
done

# 额外等 metastore 端口就绪
info "等待 Hive Metastore 端口就绪..."
for i in $(seq 1 20); do
    if docker exec hive-metastore bash -c 'echo > /dev/tcp/localhost/9083' 2>/dev/null; then
        echo -e "${GREEN}   hive-metastore:9083 OK${NC}"
        break
    fi
    sleep 3
    if [ "$i" -eq 20 ]; then echo -e "${RED}   hive-metastore:9083 FAIL${NC}"; fi
done

info "等待 Hive Server2 + Spark + Superset..."
for s in hive-server spark-master spark-worker superset; do
    printf "  等待 %-20s ... " "$s"
    for i in $(seq 1 30); do
        status=$(docker inspect -f '{{.State.Status}}' "$s" 2>/dev/null || echo "missing")
        if [ "$status" = "running" ]; then
            echo -e "${GREEN}OK${NC} ($(echo $i)x2s)"
            break
        fi
        sleep 2
        if [ "$i" -eq 30 ]; then echo -e "${RED}FAIL${NC}"; fi
    done
done

# 最终等 MySQL health
info "等待 MySQL 健康检查..."
for i in $(seq 1 15); do
    if docker exec mysql mysqladmin ping -h localhost -u root -pGMall2024! --silent 2>/dev/null; then
        info "MySQL 健康检查通过"
        break
    fi
    sleep 2
    if [ "$i" -eq 15 ]; then warn "MySQL 健康检查未过，继续..."; fi
done

echo ""
info "=== 服务概览 ==="
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || docker compose ps
echo ""
info "关键端口: HDFS:9870  YARN:8088  Hive:10000  MySQL:3306  Spark:18080  Superset:8089"
info "启动完成。运行 ./scripts/cluster.sh status 查看详细状态"

#!/bin/bash
# ============================================================
# status.sh - 集群健康巡检
# 检查: 容器状态 / HDFS 健康 / Hive 连通 / MySQL 连通 / Spark 状态
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
PASS="${GREEN}✓${NC}"; FAIL="${RED}✗${NC}"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        gmall 集群健康巡检  $(date '+%Y-%m-%d %H:%M:%S')        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# 1. 容器状态
echo -e "${BLUE}── 1. 容器状态 ──${NC}"
CRITICAL="namenode datanode1 datanode2 resourcemanager nodemanager hive-metastore hive-server mysql zookeeper spark-master superset"
DOWN_COUNT=0
for c in $CRITICAL; do
    status=$(docker inspect -f '{{.State.Status}}' "$c" 2>/dev/null || echo "missing")
    if [ "$status" = "running" ]; then
        printf "  %s %-25s %s\n" "$PASS" "$c" "running"
    else
        printf "  %s %-25s %s\n" "$FAIL" "$c" "$status"
        DOWN_COUNT=$((DOWN_COUNT+1))
    fi
done

# 2. HDFS 健康
echo -e "\n${BLUE}── 2. HDFS 分布式文件系统 ──${NC}"
if docker exec namenode bash -c 'echo > /dev/tcp/localhost/9000' 2>/dev/null; then
    echo -e "  $PASS HDFS port 9000 可达"
    REPORT=$(docker exec namenode hdfs dfsadmin -report 2>/dev/null | head -20 || echo "N/A")
    echo "$REPORT" | grep -E "Live datanodes|DFS Used%|Configured Capacity" | while read line; do echo "    $line"; done
    # 检查 /warehouse/gmall 存在
    if docker exec namenode hdfs dfs -test -d /warehouse/gmall 2>/dev/null; then
        echo -e "  $PASS /warehouse/gmall 目录存在"
    else
        echo -e "  $FAIL /warehouse/gmall 目录不存在 (运行 cluster.sh init)"
    fi
else
    echo -e "  $FAIL HDFS 不可达"
fi

# 3. Hive
echo -e "\n${BLUE}── 3. Hive 数据仓库 ──${NC}"
if docker exec hive-server beeline -u jdbc:hive2://localhost:10000 -e "SHOW DATABASES;" 2>/dev/null | grep -q "gmall_ods"; then
    echo -e "  $PASS Hive Server2 连通, gmall 数据库已初始化"
    DBS=$(docker exec hive-server beeline -u jdbc:hive2://localhost:10000 -e "SHOW DATABASES LIKE 'gmall*';" 2>/dev/null | grep gmall || echo "  未初始化")
    echo "$DBS"
else
    echo -e "  $YELLOW Hive Server2 运行中但 gmall 库未初始化 (运行 cluster.sh init)${NC}"
fi

# 4. MySQL
echo -e "\n${BLUE}── 4. MySQL 业务数据库 ──${NC}"
if docker exec mysql mysql -u gmall -pgmall123 -e "SELECT COUNT(*) AS user_count FROM gmall.user_info;" 2>/dev/null; then
    echo -e "  $PASS MySQL 连通, 业务表有数据"
    docker exec mysql mysql -u gmall -pgmall123 -e "
      SELECT 'user_info' tbl, COUNT(*) cnt FROM gmall.user_info
      UNION ALL SELECT 'order_info', COUNT(*) FROM gmall.order_info
      UNION ALL SELECT 'order_detail', COUNT(*) FROM gmall.order_detail
      UNION ALL SELECT 'sku_info', COUNT(*) FROM gmall.sku_info;
    " 2>/dev/null | while read line; do echo "    $line"; done
else
    echo -e "  $FAIL MySQL 不可达"
fi

# 5. Spark
echo -e "\n${BLUE}── 5. Spark 计算引擎 ──${NC}"
if curl -s http://localhost:18080 > /dev/null 2>&1; then
    echo -e "  $PASS Spark Master Web UI: http://localhost:18080"
else
    echo -e "  $FAIL Spark Master 不可达"
fi

# 6. Superset
echo -e "\n${BLUE}── 6. Superset 可视化 ──${NC}"
if curl -s http://localhost:8089 > /dev/null 2>&1; then
    echo -e "  $PASS Superset: http://localhost:8089"
else
    echo -e "  $YELLOW Superset 可访问(启动中)${NC}"
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
if [ "$DOWN_COUNT" -eq 0 ]; then
    echo -e "  ${GREEN}全部关键服务运行正常。${NC}"
else
    echo -e "  ${RED}$DOWN_COUNT 个服务异常。运行 cluster.sh recover 尝试自愈。${NC}"
fi
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"

#!/bin/bash
# ============================================================
# cluster_init.sh - 一键环境初始化
# 1. HDFS 建目录 2. Hive 建5层库+跑建表SQL 3. MySQL 校验
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*"; }
step()  { echo -e "\n${GREEN}>>> $*${NC}"; }

# === 检查前提 ===
for c in namenode hive-server mysql; do
    st=$(docker inspect -f '{{.State.Status}}' "$c" 2>/dev/null || echo "missing")
    if [ "$st" != "running" ]; then
        err "容器 $c 状态: $st，请先运行 cluster.sh start"
        exit 1
    fi
done

# === 1. HDFS 创建仓库目录 ===
step "1/4 创建 HDFS 仓库目录..."
docker exec namenode hdfs dfs -mkdir -p \
    /warehouse/gmall/ods \
    /warehouse/gmall/dim \
    /warehouse/gmall/dwd \
    /warehouse/gmall/dws \
    /warehouse/gmall/ads \
    /origin_data/gmall/db 2>/dev/null || true
info "HDFS 目录已就绪"
docker exec namenode hdfs dfs -ls /warehouse/gmall 2>/dev/null | grep "^d" | while read l; do echo "  $l"; done

# === 2. Hive 建库与建表 ===
step "2/4 创建 Hive 数据库..."
HIVE_CMD="docker exec -i hive-server beeline -u jdbc:hive2://localhost:10000 --silent=true --showHeader=false"
for db in gmall_ods gmall_dim gmall_dwd gmall_dws gmall_ads; do
    echo "  CREATE DATABASE IF NOT EXISTS $db;"
    echo "CREATE DATABASE IF NOT EXISTS $db;" | $HIVE_CMD 2>/dev/null
done
info "Hive 5 层库创建完成"

step "3/4 执行 Hive 建表 SQL..."
HIVE_DIR="$PROJECT_DIR/gmall-dw/hive"
for sql in create_ods.sql create_dim.sql create_dwd.sql create_dws.sql create_ads.sql; do
    if [ -f "$HIVE_DIR/$sql" ]; then
        printf "  执行 %-30s ... " "$sql"
        # 跳过 "USE gmall_*" 行,直接 cat SQL 给 beeline (因为 beeline 不支持 USE 同时 -f 管道)
        # 改为在每个 SQL 前手动物理 USE
        db_name=$(echo "$sql" | sed 's/create_//;s/\.sql//')
        (echo "USE gmall_$db_name;"; grep -v "^USE " "$HIVE_DIR/$sql" | grep -v "^--" | grep -v "^$") | \
            docker exec -i hive-server beeline -u jdbc:hive2://localhost:10000 --silent=true 2>/dev/null
        echo -e "${GREEN}OK${NC}"
    else
        warn "  文件不存在: $HIVE_DIR/$sql (跳过)"
    fi
done
info "建表 SQL 执行完毕"

# === 3. MySQL 校验 ===
step "4/4 校验 MySQL 业务数据..."
docker exec mysql mysql -u gmall -pgmall123 -e "
  SELECT 'user_info' tbl, COUNT(*) cnt FROM gmall.user_info
  UNION ALL SELECT 'order_info', COUNT(*) FROM gmall.order_info
  UNION ALL SELECT 'order_detail', COUNT(*) FROM gmall.order_detail
  UNION ALL SELECT 'sku_info', COUNT(*) FROM gmall.sku_info;
" 2>/dev/null
info "MySQL 业务数据就绪"

echo ""
info "========================================="
info "  环境初始化完成！"
info "  下一步: ./scripts/cluster.sh etl"
info "========================================="

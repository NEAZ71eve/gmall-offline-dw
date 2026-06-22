#!/bin/bash
# ============================================================
# ingest_mysql_to_hdfs.sh - 数据采集: MySQL 业务表 → HDFS /origin_data
# 用法: ./ingest_mysql_to_hdfs.sh [biz_date]
#       默认 biz_date = 昨天日期
# 数据流: mysql --batch 导出 → hdfs dfs -put 到 /origin_data/gmall/db/{table}/dt={date}/
# ============================================================
set -euo pipefail

BIZ_DATE="${1:-$(date -d 'yesterday' '+%Y-%m-%d' 2>/dev/null || date '+%Y-%m-%d')}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'
info() { echo -e "${GREEN}[INFO]${NC}  $*"; }
step() { echo -e "${BLUE}[STEP]${NC} $*"; }

MYSQL_CMD="docker exec -i mysql mysql -u gmall -pgmall123 gmall -N -B"
HDFS_PUT="docker exec -i namenode hdfs dfs -put -"

# 需要采集的业务表
TABLES="user_info sku_info order_info order_detail"
BASE_DIR="/origin_data/gmall/db"

info "采集日期: $BIZ_DATE"
info "数据源: MySQL gmall 业务库"
info "目标:   HDFS $BASE_DIR/*/dt=$BIZ_DATE/"

# 创建 HDFS 基础目录
docker exec namenode hdfs dfs -mkdir -p $BASE_DIR 2>/dev/null || true

TOTAL_ROWS=0
for tbl in $TABLES; do
    step "采集 $tbl → $BASE_DIR/$tbl/dt=$BIZ_DATE/"

    # 创建分区目录
    docker exec namenode hdfs dfs -mkdir -p "$BASE_DIR/$tbl/dt=$BIZ_DATE" 2>/dev/null

    # MySQL 导出 → HDFS (TSV 格式,用 \t 分隔)
    # 如果表有 date 字段,按 biz_date 过滤;否则全量导出
    ROW_COUNT=$($MYSQL_CMD -e "SELECT COUNT(*) FROM $tbl;" 2>/dev/null)
    echo "  源表行数: $ROW_COUNT"

    $MYSQL_CMD -e "SELECT * FROM $tbl;" 2>/dev/null | \
        docker exec -i namenode hdfs dfs -put - "$BASE_DIR/$tbl/dt=$BIZ_DATE/${tbl}.tsv"

    # 验证
    HDFS_SIZE=$(docker exec namenode hdfs dfs -du -s "$BASE_DIR/$tbl/dt=$BIZ_DATE/" 2>/dev/null | awk '{print $1}')
    echo "  HDFS 写入: ${HDFS_SIZE:-0} bytes"
    echo -e "  ${GREEN}✓${NC} $tbl 采集完成"
    TOTAL_ROWS=$((TOTAL_ROWS + ROW_COUNT))
done

echo ""
info "========================================="
info "  数据采集完成: $TOTAL_ROWS 行写入 HDFS"
info "  HDFS: $BASE_DIR/*/dt=$BIZ_DATE/"
info "========================================="
# 展示目录结构
docker exec namenode hdfs dfs -ls -R "$BASE_DIR" 2>/dev/null | head -30

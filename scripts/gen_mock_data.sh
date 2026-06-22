#!/bin/bash
# ============================================================
# gen_mock_data.sh - 数据模拟/校验
# MySQL init.sql 已在容器首次启动时自动载入模拟数据
# 本脚本提供: 校验已有数据 + 按需生成额外区间数据
# ============================================================
set -euo pipefail

GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
info() { echo -e "${GREEN}[INFO]${NC}  $*"; }
step() { echo -e "${BLUE}[STEP]${NC} $*"; }

MYSQL="docker exec -i mysql mysql -u gmall -pgmall123 gmall -N -B"

step "校验 MySQL 业务数据..."

echo "  表名                  行数"
echo "  ----                  ----"
for tbl in user_info sku_info order_info order_detail; do
    cnt=$($MYSQL -e "SELECT COUNT(*) FROM $tbl;" 2>/dev/null || echo "0")
    printf "  %-20s %s\n" "$tbl" "$cnt"
done

info "数据校验完成。模拟数据已由 conf/mysql/init.sql 在 MySQL 容器首次启动时自动载入。"
info "如需重新初始化数据: docker compose down -v mysql && docker compose up -d mysql"

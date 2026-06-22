#!/bin/bash
# ============================================================
# export_ads_to_mysql.sh - 结果入库: Hive ADS → MySQL
# 用法: ./export_ads_to_mysql.sh [biz_date]
# ============================================================
set -euo pipefail

BIZ_DATE="${1:-$(date -d 'yesterday' '+%Y-%m-%d' 2>/dev/null || date '+%Y-%m-%d')}"

GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
info() { echo -e "${GREEN}[INFO]${NC}  $*"; }
step() { echo -e "${BLUE}[STEP]${NC} $*"; }

BEELINE="docker exec -i hive-server beeline -u jdbc:hive2://localhost:10000 --outputformat=dsv --silent=true --showHeader=false"
MYSQL="docker exec -i mysql mysql -u gmall -pgmall123 gmall"

info "导出 ADS 报表到 MySQL - 日期: $BIZ_DATE"

# === GMV 日报 ===
step "1/5 导出 GMV 日报..."
echo "TRUNCATE TABLE ads_gmv_day;" | $MYSQL 2>/dev/null
echo "USE gmall_ads; SELECT dt, recent_days, gmv, order_count, order_user_count, payment_amount, avg_order_amount FROM ads_gmv_day WHERE dt='${BIZ_DATE}' OR 1=1 LIMIT 30;" | \
    $BEELINE 2>/dev/null | while IFS='|' read -r dt recent gmv ocount ousers pay avg; do
    [ -z "$dt" ] && continue
    echo "INSERT INTO ads_gmv_day VALUES ('${dt// /}',${recent// /},${gmv// /},${ocount// /},${ousers// /},${pay// /},${avg// /});" | $MYSQL 2>/dev/null || true
done
info "  ads_gmv_day 导入完成"

# === 热门商品 ===
step "2/5 导出热门商品 Top10..."
echo "TRUNCATE TABLE ads_hot_sku;" | $MYSQL 2>/dev/null
echo "USE gmall_ads; SELECT dt, sku_id, sku_name, order_count, total_gmv FROM ads_hot_sku ORDER BY total_gmv DESC LIMIT 10;" | \
    $BEELINE 2>/dev/null | while IFS='|' read -r dt sid sname cnt gmv; do
    [ -z "$dt" ] && continue
    echo "INSERT INTO ads_hot_sku VALUES ('${dt// /}','${sid// /}','${sname// /}',${cnt// /},${gmv// /});" | $MYSQL 2>/dev/null || true
done
info "  ads_hot_sku 导入完成"

# === 用户留存 ===
step "3/5 导出用户留存..."
echo "TRUNCATE TABLE ads_user_retention;" | $MYSQL 2>/dev/null
echo "USE gmall_ads; SELECT dt, new_user_count, day1_retain, day7_retain, retention_rate_d1, retention_rate_d7 FROM ads_user_retention WHERE dt='${BIZ_DATE}' OR 1=1 LIMIT 10;" | \
    $BEELINE 2>/dev/null | while IFS='|' read -r dt new d1 d7 r1 r7; do
    [ -z "$dt" ] && continue
    echo "INSERT INTO ads_user_retention VALUES ('${dt// /}',${new// /},${d1// /},${d7// /},${r1// /},${r7// /});" | $MYSQL 2>/dev/null || true
done
info "  ads_user_retention 导入完成"

# === 转化漏斗 ===
step "4/5 导出转化漏斗..."
echo "TRUNCATE TABLE ads_conversion_funnel;" | $MYSQL 2>/dev/null
echo "USE gmall_ads; SELECT dt, step_view, step_add_cart, step_order, step_pay, view_to_cart_rate, cart_to_order_rate, order_to_pay_rate FROM ads_conversion_funnel WHERE dt='${BIZ_DATE}' OR 1=1 LIMIT 10;" | \
    $BEELINE 2>/dev/null | while IFS='|' read -r dt svw scart sorder spay r1 r2 r3; do
    [ -z "$dt" ] && continue
    echo "INSERT INTO ads_conversion_funnel VALUES ('${dt// /}',${svw// /},${scart// /},${sorder// /},${spay// /},${r1// /},${r2// /},${r3// /});" | $MYSQL 2>/dev/null || true
done
info "  ads_conversion_funnel 导入完成"

# === 验证 ===
step "5/5 验证 MySQL ADS 表..."
docker exec mysql mysql -u gmall -pgmall123 -e "
  SELECT 'ads_gmv_day' tbl, COUNT(*) cnt FROM gmall.ads_gmv_day
  UNION ALL SELECT 'ads_hot_sku', COUNT(*) FROM gmall.ads_hot_sku
  UNION ALL SELECT 'ads_user_retention', COUNT(*) FROM gmall.ads_user_retention
  UNION ALL SELECT 'ads_conversion_funnel', COUNT(*) FROM gmall.ads_conversion_funnel;
" 2>/dev/null

echo ""
info "========================================="
info "  结果入库完成 (日期: $BIZ_DATE)"
info "  下一步: superset_setup.sh 配置可视化"
info "========================================="

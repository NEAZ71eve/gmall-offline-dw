#!/bin/bash
# ============================================================
# run_offline_etl.sh - 离线 ETL: ODS→DIM→DWD→DWS→ADS
# 用法: ./run_offline_etl.sh [biz_date]
# 默认 biz_date = 昨天
# ============================================================
set -euo pipefail

BIZ_DATE="${1:-$(date -d 'yesterday' '+%Y-%m-%d' 2>/dev/null || date '+%Y-%m-%d')}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
HIVE_DIR="$PROJECT_DIR/gmall-dw/hive"

GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
step()  { echo -e "\n${BLUE}[STEP]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*"; }

BEELINE="docker exec -i hive-server beeline -u jdbc:hive2://localhost:10000 --silent=true"

info "离线 ETL 开始 - 业务日期: $BIZ_DATE"

# ============ Step 1: ODS 层 (装载原始数据) ============
step "1/6 ODS 层: 装载外部表数据"
ODS_SQLS="
USE gmall_ods;
ALTER TABLE ods_user_info ADD IF NOT EXISTS PARTITION(dt='${BIZ_DATE}') LOCATION '/origin_data/gmall/db/user_info/dt=${BIZ_DATE}';
ALTER TABLE ods_sku_info ADD IF NOT EXISTS PARTITION(dt='${BIZ_DATE}') LOCATION '/origin_data/gmall/db/sku_info/dt=${BIZ_DATE}';
ALTER TABLE ods_order_info ADD IF NOT EXISTS PARTITION(dt='${BIZ_DATE}') LOCATION '/origin_data/gmall/db/order_info/dt=${BIZ_DATE}';
ALTER TABLE ods_order_detail ADD IF NOT EXISTS PARTITION(dt='${BIZ_DATE}') LOCATION '/origin_data/gmall/db/order_detail/dt=${BIZ_DATE}';
"

echo "$ODS_SQLS" | $BEELINE 2>/dev/null

# 验证 ODS
echo "  ODS 表行数:"
for tbl in ods_user_info ods_order_info ods_order_detail ods_sku_info; do
    cnt=$(echo "USE gmall_ods; SELECT COUNT(*) FROM $tbl WHERE dt='${BIZ_DATE}';" | $BEELINE 2>/dev/null | tail -2 | head -1 | tr -d ' |\r\n')
    echo "    $tbl: ${cnt:-?} 行"
done

# ============ Step 2: DIM 层 ============
step "2/6 DIM 层: 维度表加工"
if [ -f "$HIVE_DIR/etl_ods_to_dim.sql" ]; then
    sed "s/\${biz_date}/${BIZ_DATE}/g; s/\${dt}/${BIZ_DATE}/g" "$HIVE_DIR/etl_ods_to_dim.sql" | $BEELINE 2>/dev/null
    cnt=$(echo "USE gmall_dim; SELECT COUNT(*) FROM dim_user_info;" | $BEELINE 2>/dev/null | tail -2 | head -1 | tr -d ' |\r\n')
    echo "  dim_user_info: ${cnt:-?} 行"
fi

# ============ Step 3: DWD 层 ============
step "3/6 DWD 层: 明细数据加工"
if [ -f "$HIVE_DIR/etl_ods_to_dwd.sql" ]; then
    sed "s/\${biz_date}/${BIZ_DATE}/g; s/\${dt}/${BIZ_DATE}/g" "$HIVE_DIR/etl_ods_to_dwd.sql" | $BEELINE 2>/dev/null
    cnt=$(echo "USE gmall_dwd; SELECT COUNT(*) FROM dwd_order_detail;" | $BEELINE 2>/dev/null | tail -2 | head -1 | tr -d ' |\r\n')
    echo "  dwd_order_detail: ${cnt:-?} 行"
fi

# ============ Step 4: DWS 层 ============
step "4/6 DWS 层: 汇总宽表加工"
if [ -f "$HIVE_DIR/etl_dwd_to_dws.sql" ]; then
    sed "s/\${biz_date}/${BIZ_DATE}/g; s/\${dt}/${BIZ_DATE}/g" "$HIVE_DIR/etl_dwd_to_dws.sql" | $BEELINE 2>/dev/null
    echo "  DWS 层加工完成"
fi

# ============ Step 5: ADS 层 ============
step "5/6 ADS 层: 应用报表生成"
if [ -f "$HIVE_DIR/etl_dws_to_ads.sql" ]; then
    sed "s/\${biz_date}/${BIZ_DATE}/g; s/\${dt}/${BIZ_DATE}/g" "$HIVE_DIR/etl_dws_to_ads.sql" | $BEELINE 2>/dev/null
fi
if [ -f "$HIVE_DIR/etl_dws_to_ads_supplement.sql" ]; then
    echo "  执行补充 ADS ..."
    sed "s/\${biz_date}/${BIZ_DATE}/g; s/\${dt}/${BIZ_DATE}/g" "$HIVE_DIR/etl_dws_to_ads_supplement.sql" | $BEELINE 2>/dev/null
fi

# ============ 验证 ADS ============
step "6/6 ADS 报表验证"
echo "  ADS 关键指标:"
for tbl in ads_gmv_day ads_order_stats ads_hot_sku ads_user_retention; do
    echo "USE gmall_ads; SELECT '${tbl}' tbl, COUNT(*) rows FROM ${tbl};" | $BEELINE 2>/dev/null | tail -2 | head -1
done 2>/dev/null

# 尝试获取 GMV
echo ""
echo "USE gmall_ads; SELECT * FROM ads_gmv_day ORDER BY dt DESC LIMIT 3;" | $BEELINE 2>/dev/null | tail -8

echo ""
info "========================================="
info "  离线 ETL 完成 (日期: $BIZ_DATE)"
info "  下一步: ./scripts/run_spark_job.sh $BIZ_DATE"
info "         ./scripts/export_ads_to_mysql.sh $BIZ_DATE"
info "========================================="

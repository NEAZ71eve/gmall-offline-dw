#!/bin/bash
# Python-based ETL pipeline for GMall Data Warehouse
# This replaces Hive-MapReduce execution (since no YARN)
set -e

BDATE="${1:-2024-01-15}"
HDFS="hdfs://traffic-hdfs-namenode:9000"
BASE="/warehouse/gmall"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "============================================"
echo "GMall Data Warehouse ETL Pipeline (Python)"
echo "Business Date: ${BDATE}"
echo "============================================"

# Run Python ETL script
docker run --rm --name gmall-etl \
  --network traffic-prod-net \
  -e BDATE="${BDATE}" \
  -e HDFS_URL="${HDFS}" \
  -e BASE_PATH="${BASE}" \
  -v "${SCRIPT_DIR}/sql:/sql" \
  -v "${SCRIPT_DIR}/gmall-dw/hive:/hive_scripts" \
  -v "${SCRIPT_DIR}/utils:/utils" \
  --entrypoint /bin/bash \
  apache/hive:4.0.0 \
  -c '
set -e
BDATE=${BDATE:-2024-01-15}
HDFS_URL=${HDFS_URL:-hdfs://traffic-hdfs-namenode:9000}
BASE=${BASE_PATH:-/warehouse/gmall}

echo "=== Step 1: DIM Layer - Build dim_time ==="
mkdir -p /tmp/etl/dim
python3 -c "
import datetime
bd = datetime.date(2024, 1, 1)
lines = []
for i in range(365):
    d = bd + datetime.timedelta(days=i)
    date_id = d.strftime(\"%Y%m%d\")
    year = d.strftime(\"%Y\")
    month = d.strftime(\"%m\")
    day = d.strftime(\"%d\")
    quarter = str((int(month)-1)//3 + 1)
    week = f\"W{d.strftime(\"%W\")}\"
    weekday = d.strftime(\"%A\")
    lines.append(f\"{date_id}\\t{d}\\t{year}\\t{month}\\t{day}\\t{quarter}\\t{week}\\t{weekday}\")
with open(\"/tmp/etl/dim/dim_time.tsv\", \"w\") as f:
    f.write(\"\\n\".join(lines))
print(f\"Created dim_time with {len(lines)} rows\")
"

hdfs dfs -D fs.defaultFS=${HDFS_URL} -mkdir -p ${BASE}/dim/dim_time 2>/dev/null || true
hdfs dfs -D fs.defaultFS=${HDFS_URL} -put -f /tmp/etl/dim/dim_time.tsv ${BASE}/dim/dim_time/
echo "dim_time data uploaded to HDFS"

echo ""
echo "=== Step 2: DIM Layer - Build dim_sku ==="
# Read ods_sku_info and enrich with category/trademark info
hdfs dfs -D fs.defaultFS=${HDFS_URL} -cat ${BASE}/ods/ods_sku_info/dt=${BDATE}/ods_sku_info.tsv 2>/dev/null > /tmp/etl/dim/ods_sku.tsv
cat /tmp/etl/dim/ods_sku.tsv | awk -F\"\t\" '\''{print $1"\t"$4"\t"$2"\t"$3"\t"$5"\t"$7"\t"$8}'\'' > /tmp/etl/dim/dim_sku.tsv
hdfs dfs -D fs.defaultFS=${HDFS_URL} -mkdir -p ${BASE}/dim/dim_sku 2>/dev/null || true
hdfs dfs -D fs.defaultFS=${HDFS_URL} -put -f /tmp/etl/dim/dim_sku.tsv ${BASE}/dim/dim_sku/
lines=$(wc -l < /tmp/etl/dim/dim_sku.tsv)
echo "dim_sku created with ${lines} rows"

echo ""
echo "=== Step 3: DIM Layer - Build dim_user (SCD Type 2 snapshot) ==="
hdfs dfs -D fs.defaultFS=${HDFS_URL} -cat ${BASE}/ods/ods_user_info/dt=${BDATE}/ods_user_info.tsv 2>/dev/null > /tmp/etl/dim/ods_user.tsv
cat /tmp/etl/dim/ods_user.tsv | awk -F\"\t\" '\''{print $1"\t"$2"\t"$3"\t"$4"\t"$9"\t"$10"\t"$12"\t"$8"\t"$11}'\'' > /tmp/etl/dim/dim_user.tsv
hdfs dfs -D fs.defaultFS=${HDFS_URL} -mkdir -p ${BASE}/dim/dim_user 2>/dev/null || true
hdfs dfs -D fs.defaultFS=${HDFS_URL} -put -f /tmp/etl/dim/dim_user.tsv ${BASE}/dim/dim_user/
lines=$(wc -l < /tmp/etl/dim/dim_user.tsv)
echo "dim_user created with ${lines} rows"

echo ""
echo "=== Step 4: DWD Layer - Clean order details ==="
mkdir -p /tmp/etl/dwd
hdfs dfs -D fs.defaultFS=${HDFS_URL} -cat ${BASE}/ods/ods_order_info/dt=${BDATE}/ods_order_info.tsv 2>/dev/null > /tmp/etl/dwd/ods_order.tsv
hdfs dfs -D fs.defaultFS=${HDFS_URL} -cat ${BASE}/ods/ods_order_detail/dt=${BDATE}/ods_order_detail.tsv 2>/dev/null > /tmp/etl/dwd/ods_detail.tsv

# Generate DWD - clean, mask sensitive fields, join order + detail
python3 -c "
import csv
orders = {}
with open(\"/tmp/etl/dwd/ods_order.tsv\") as f:
    for line in f:
        cols = line.strip().split(chr(9))
        if len(cols) >= 14:
            oid = cols[0]
            orders[oid] = {
                \"user_id\": cols[5], \"status\": cols[4],
                \"amount\": cols[3], \"province\": cols[13],
                \"create_time\": cols[11], \"pay_method\": cols[6]
            }

with open(\"/tmp/etl/dwd/ods_detail.tsv\") as f:
    lines_out = []
    for line in f:
        cols = line.strip().split(chr(9))
        if len(cols) >= 10:
            detail_id = cols[0]
            order_id = cols[1]
            sku_id = cols[2]
            sku_name = cols[3]
            price = cols[5]
            num = cols[6]
            create_time = cols[7]
            source = cols[8]
            # Mask sku_name (data masking)
            if len(sku_name) > 2:
                masked_name = sku_name[:1] + \"***\" + sku_name[-1:]
            else:
                masked_name = sku_name
            order_info = orders.get(order_id, {})
            user_id = order_info.get(\"user_id\", \"\")
            province = order_info.get(\"province\", \"\")
            amount = order_info.get(\"amount\", \"0\")
            lines_out.append(f\"{detail_id}\\t{order_id}\\t{user_id}\\t{sku_id}\\t{masked_name}\\t{price}\\t{num}\\t{amount}\\t{create_time}\\t{source}\\t{province}\\t{order_info.get(chr(34)+status+chr(34), '')}\")

with open(\"/tmp/etl/dwd/dwd_order_detail.tsv\", \"w\") as f:
    f.write(chr(10).join(lines_out))
print(f\"DWD order detail: {len(lines_out)} rows\")
"

hdfs dfs -D fs.defaultFS=${HDFS_URL} -mkdir -p ${BASE}/dwd/dwd_order_detail/dt=${BDATE} 2>/dev/null || true
hdfs dfs -D fs.defaultFS=${HDFS_URL} -put -f /tmp/etl/dwd/dwd_order_detail.tsv ${BASE}/dwd/dwd_order_detail/dt=${BDATE}/
echo "DWD order_detail uploaded"

echo ""
echo "=== Step 5: DWS Layer - Daily aggregation ==="
mkdir -p /tmp/etl/dws
python3 -c "
# Read DWD data
details = []
with open(\"/tmp/etl/dwd/dwd_order_detail.tsv\") as f:
    for line in f:
        cols = line.strip().split(chr(9))
        if len(cols) >= 8:
            try:
                price = float(cols[5]) if cols[5] else 0
                num = int(cols[6]) if cols[6] else 0
                details.append((price, num))
            except ValueError:
                continue

total_gmv = sum(p * n for p, n in details)
total_items = sum(n for _, n in details)
total_orders = len(set([l.split(chr(9))[1] for l in open(\"/tmp/etl/dwd/dwd_order_detail.tsv\") if l.strip()]))

# DWS: GMV stats
with open(\"/tmp/etl/dws/dws_gmv_stats.tsv\", \"w\") as f:
    f.write(f\"{chr(36)+chr(36)+str(total_gmv)+chr(36)+chr(36)}\\t2024-01-15\\t{total_orders}\\t{total_items}\\t{total_gmv/total_orders if total_orders > 0 else 0}\\n\")
print(f\"DWS GMV Stats: {chr(36)+chr(36)}{total_gmv:.2f}, Orders: {total_orders}, Items: {total_items}\")
"

hdfs dfs -D fs.defaultFS=${HDFS_URL} -mkdir -p ${BASE}/dws/dws_gmv_stats/dt=${BDATE} 2>/dev/null || true
hdfs dfs -D fs.defaultFS=${HDFS_URL} -put -f /tmp/etl/dws/dws_gmv_stats.tsv ${BASE}/dws/dws_gmv_stats/dt=${BDATE}/
echo "DWS GMV stats uploaded"

echo ""
echo "=== Step 6: ADS Layer - Final metrics ==="
mkdir -p /tmp/etl/ads

# ADS: GMV daily report
python3 -c "
gmv = 0; orders = 0; items = 0; users = set()
with open(\"/tmp/etl/dwd/dwd_order_detail.tsv\") as f:
    for line in f:
        cols = line.strip().split(chr(9))
        if len(cols) >= 8:
            try:
                gmv += float(cols[5]) * int(cols[6])
                items += int(cols[6])
                orders += 1
                if len(cols) > 2 and cols[2]:
                    users.add(cols[2])
            except: pass

user_cnt = len(users)
avg_price = gmv / items if items > 0 else 0
with open(\"/tmp/etl/ads/ads_gmv_day.tsv\", \"w\") as f:
    f.write(f\"2024-01-15\\t{gmv:.2f}\\t{orders}\\t{items}\\t{user_cnt}\\t{avg_price:.2f}\\n\")
print(f\"ADS GMV Day: GMV={gmv:.2f}, Orders={orders}, Users={user_cnt}\")
"

hdfs dfs -D fs.defaultFS=${HDFS_URL} -mkdir -p ${BASE}/ads/ads_gmv_day 2>/dev/null || true
hdfs dfs -D fs.defaultFS=${HDFS_URL} -put -f /tmp/etl/ads/ads_gmv_day.tsv ${BASE}/ads/ads_gmv_day/
echo "ADS GMV Day uploaded"

# ADS: User retention
python3 -c "
import datetime
bd = datetime.date(2024, 1, 15)
users_new = set()
users_active = set()

# Simulate retention: users who registered before 2024-01-15 and have orders on 2024-01-15
with open(\"/tmp/etl/dwd/ods_user.tsv\") as f:
    for line in f:
        cols = line.strip().split(chr(9))
        if len(cols) >= 11:
            create_date = cols[10][:10] if len(cols[10]) >= 10 else \"\"
            if create_date and create_date < \"2024-01-15\":
                users_new.add(cols[0])

with open(\"/tmp/etl/dwd/dwd_order_detail.tsv\") as f:
    for line in f:
        cols = line.strip().split(chr(9))
        if len(cols) > 2 and cols[2]:
            users_active.add(cols[2])

retained = users_new & users_active
total_new = len(users_new)
retention_rate = len(retained) / total_new * 100 if total_new > 0 else 0
with open(\"/tmp/etl/ads/ads_user_retention.tsv\", \"w\") as f:
    f.write(f\"2024-01-15\\t1_day\\t{total_new}\\t{len(retained)}\\t{retention_rate:.2f}%\\n\")
print(f\"ADS User Retention: New={total_new}, Retained={len(retained)}, Rate={retention_rate:.2f}%\")
"

hdfs dfs -D fs.defaultFS=${HDFS_URL} -mkdir -p ${BASE}/ads/ads_user_retention 2>/dev/null || true
hdfs dfs -D fs.defaultFS=${HDFS_URL} -put -f /tmp/etl/ads/ads_user_retention.tsv ${BASE}/ads/ads_user_retention/
echo "ADS User Retention uploaded"

# ADS: SKU sales ranking
python3 -c "
from collections import Counter
sku_sales = Counter()
with open(\"/tmp/etl/dwd/dwd_order_detail.tsv\") as f:
    for line in f:
        cols = line.strip().split(chr(9))
        if len(cols) >= 5:
            sku_id = cols[3]
            try:
                num = int(cols[6])
                price = float(cols[5])
                sku_sales[sku_id] += num
            except: pass

with open(\"/tmp/etl/ads/ads_sku_sales_rank.tsv\", \"w\") as f:
    for rank, (sku_id, qty) in enumerate(sku_sales.most_common(), 1):
        f.write(f\"2024-01-15\\t{rank}\\t{sku_id}\\t{qty}\\n\")
print(f\"ADS SKU Sales: {len(sku_sales)} SKUs ranked\")
"

hdfs dfs -D fs.defaultFS=${HDFS_URL} -put -f /tmp/etl/ads/ads_sku_sales_rank.tsv ${BASE}/ads/ads_sku_sales_rank/ 2>/dev/null || true
echo "ADS SKU Sales uploaded"

echo ""
echo "=== Step 7: Register in Hive ==="
# Register all tables in Hive Metastore via beeline
/opt/hive/bin/beeline -u \"jdbc:hive2://gmall-hiveserver2:10000\" -e \"
-- DIM
DROP TABLE IF EXISTS gmall_dim.dim_time;
CREATE EXTERNAL TABLE gmall_dim.dim_time (date_id STRING, date_val STRING, year STRING, month STRING, day STRING, quarter STRING, week STRING, weekday STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY \'\\\\t\' STORED AS TEXTFILE LOCATION \\\"${BASE}/dim/dim_time\\\";
SELECT COUNT(*) FROM gmall_dim.dim_time;

DROP TABLE IF EXISTS gmall_dim.dim_sku;
CREATE EXTERNAL TABLE gmall_dim.dim_sku (sku_id STRING, sku_name STRING, spu_id STRING, price DECIMAL(16,2), sku_desc STRING, tm_id STRING, category3_id STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY \'\\\\t\' STORED AS TEXTFILE LOCATION \\\"${BASE}/dim/dim_sku\\\";
SELECT COUNT(*) FROM gmall_dim.dim_sku;

DROP TABLE IF EXISTS gmall_dim.dim_user;
CREATE EXTERNAL TABLE gmall_dim.dim_user (user_id STRING, login_name STRING, nick_name STRING, name STRING, birthday STRING, gender STRING, operate_time STRING, user_level STRING, create_time STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY \'\\\\t\' STORED AS TEXTFILE LOCATION \\\"${BASE}/dim/dim_user\\\";
SELECT COUNT(*) FROM gmall_dim.dim_user;

-- DWD
DROP TABLE IF EXISTS gmall_dwd.dwd_order_detail;
CREATE EXTERNAL TABLE gmall_dwd.dwd_order_detail (detail_id STRING, order_id STRING, user_id STRING, sku_id STRING, sku_name STRING, price DECIMAL(16,2), num INT, amount DECIMAL(16,2), create_time STRING, source_type STRING, province_id STRING, order_status STRING)
PARTITIONED BY (dt STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY \'\\\\t\' STORED AS TEXTFILE LOCATION \\\"${BASE}/dwd/dwd_order_detail\\\";
ALTER TABLE gmall_dwd.dwd_order_detail ADD PARTITION (dt=\\\"${BDATE}\\\");
SELECT COUNT(*) FROM gmall_dwd.dwd_order_detail WHERE dt=\\\"${BDATE}\\\";

-- DWS
DROP TABLE IF EXISTS gmall_dws.dws_gmv_stats;
CREATE EXTERNAL TABLE gmall_dws.dws_gmv_stats (gmv STRING, dt STRING, order_count INT, item_count INT, avg_order_value DOUBLE)
PARTITIONED BY (biz_date STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY \'\\\\t\' STORED AS TEXTFILE LOCATION \\\"${BASE}/dws/dws_gmv_stats\\\";
ALTER TABLE gmall_dws.dws_gmv_stats ADD PARTITION (biz_date=\\\"${BDATE}\\\");
SELECT COUNT(*) FROM gmall_dws.dws_gmv_stats WHERE biz_date=\\\"${BDATE}\\\";

-- ADS
DROP TABLE IF EXISTS gmall_ads.ads_gmv_day;
CREATE EXTERNAL TABLE gmall_ads.ads_gmv_day (dt STRING, gmv DECIMAL(16,2), order_count INT, item_count INT, user_count INT, avg_price DECIMAL(16,2))
ROW FORMAT DELIMITED FIELDS TERMINATED BY \'\\\\t\' STORED AS TEXTFILE LOCATION \\\"${BASE}/ads/ads_gmv_day\\\";
SELECT * FROM gmall_ads.ads_gmv_day;

DROP TABLE IF EXISTS gmall_ads.ads_user_retention;
CREATE EXTERNAL TABLE gmall_ads.ads_user_retention (dt STRING, retention_type STRING, new_user_count INT, retained_user_count INT, retention_rate STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY \'\\\\t\' STORED AS TEXTFILE LOCATION \\\"${BASE}/ads/ads_user_retention\\\";
SELECT * FROM gmall_ads.ads_user_retention;

DROP TABLE IF EXISTS gmall_ads.ads_sku_sales_rank;
CREATE EXTERNAL TABLE gmall_ads.ads_sku_sales_rank (dt STRING, rank INT, sku_id STRING, sales_qty INT)
ROW FORMAT DELIMITED FIELDS TERMINATED BY \'\\\\t\' STORED AS TEXTFILE LOCATION \\\"${BASE}/ads/ads_sku_sales_rank\\\";
SELECT * FROM gmall_ads.ads_sku_sales_rank;
\" 2>&1 | grep -v SLF4J | grep -E \"^|\"

echo ""
echo \"=== ETL Pipeline Complete! ===\"
'

echo ""
echo "=== Hive layer verification ==="
for layer in dim dwd dws ads; do
  echo "--- ${layer} ---"
  docker exec gmall-hiveserver2 /opt/hive/bin/beeline -u "jdbc:hive2://localhost:10000" \
    -e "SHOW TABLES IN gmall_${layer};" 2>&1 | grep "^|" | grep -v "tab_name"
done

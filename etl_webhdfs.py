#!/usr/bin/env python3
"""
GMall DW ETL Pipeline using WebHDFS API
"""
import os, sys, json, io, csv
from collections import Counter
from datetime import datetime, date, timedelta
import requests

BDATE = "2024-01-15"
NAMENODE = "http://traffic-hdfs-namenode:9870"
BASE = "/warehouse/gmall"
HIVE_JDBC = "jdbc:hive2://gmall-hiveserver2:10000"


def webhdfs_list(path):
    r = requests.get(f"{NAMENODE}/webhdfs/v1{path}?op=LISTSTATUS")
    if r.status_code == 200:
        return r.json().get("FileStatuses", {}).get("FileStatus", [])
    return []


def webhdfs_read(path):
    """Read file content via WebHDFS"""
    # Step 1: Get redirect to DataNode
    r = requests.get(f"{NAMENODE}/webhdfs/v1{path}?op=OPEN", allow_redirects=False)
    if r.status_code == 307:
        url = r.headers.get("Location")
        if url:
            r2 = requests.get(url)
            if r2.status_code == 200:
                return r2.text
    elif r.status_code == 200:
        return r.text
    return None


def webhdfs_write(path, content):
    """Write content to HDFS via WebHDFS"""
    # Step 1: Create file (redirect to DataNode)
    r = requests.put(f"{NAMENODE}/webhdfs/v1{path}?op=CREATE&overwrite=true",
                     allow_redirects=False)
    if r.status_code == 307:
        url = r.headers.get("Location")
        if url:
            r2 = requests.put(url, data=content.encode("utf-8"))
            return r2.status_code in (200, 201)
    elif r.status_code == 201:
        return True
    print(f"  WebHDFS write error: {r.status_code} - {r.text[:100]}")
    return False


def webhdfs_mkdir(path):
    r = requests.put(f"{NAMENODE}/webhdfs/v1{path}?op=MKDIRS")
    return r.status_code == 200


def run_beeline(sql):
    """Run Hive SQL"""
    import subprocess
    cmd = ["/opt/hive/bin/beeline", "-u", HIVE_JDBC, "-e", sql]
    result = subprocess.run(cmd, capture_output=True, text=True)
    for line in result.stdout.split("\n"):
        if "|" in line and "SLF4J" not in line and line.strip():
            print(f"  {line.strip()}")
    return result.returncode == 0


# ===== Steps =====

def step_dim_time():
    print("\n[DIM] dim_time...")
    lines = []
    d = date(2024, 1, 1)
    for i in range(366):
        date_id = d.strftime("%Y%m%d")
        q = (d.month - 1) // 3 + 1
        w = f"W{d.strftime('%W')}"
        lines.append(f"{date_id}\t{d}\t{d.year}\t{d.month:02d}\t{d.day:02d}\t{q}\t{w}\t{d.strftime('%A')}")
        d += timedelta(days=1)
    content = "\n".join(lines)
    webhdfs_mkdir(f"{BASE}/dim/dim_time")
    webhdfs_write(f"{BASE}/dim/dim_time/data.tsv", content)
    print(f"  {len(lines)} rows")


def read_tsv(hdfs_path):
    """Read TSV from HDFS and return list of column lists"""
    content = webhdfs_read(hdfs_path)
    if content:
        return [line.split("\t") for line in content.strip().split("\n") if line.strip()]
    return []


def write_tsv(hdfs_path, rows):
    """Write list of rows as TSV to HDFS"""
    content = "\n".join(["\t".join(str(c) for c in row) for row in rows])
    webhdfs_mkdir(os.path.dirname(hdfs_path))
    webhdfs_write(hdfs_path, content)


def step_dim_sku():
    print("\n[DIM] dim_sku...")
    rows = read_tsv(f"{BASE}/ods/ods_sku_info/dt={BDATE}/ods_sku_info.tsv")
    dim_rows = []
    for cols in rows:
        if len(cols) >= 8:
            dim_rows.append([cols[0], cols[3], cols[1], cols[2], cols[4], cols[6], cols[7]])
    write_tsv(f"{BASE}/dim/dim_sku/data.tsv", dim_rows)
    print(f"  {len(dim_rows)} rows")


def step_dim_user():
    print("\n[DIM] dim_user...")
    rows = read_tsv(f"{BASE}/ods/ods_user_info/dt={BDATE}/ods_user_info.tsv")
    dim_rows = []
    for cols in rows:
        if len(cols) >= 11:
            dim_rows.append([cols[0], cols[1], cols[2], cols[3], cols[8], cols[9], cols[11], cols[6], cols[10]])
    write_tsv(f"{BASE}/dim/dim_user/data.tsv", dim_rows)
    print(f"  {len(dim_rows)} rows")


def step_dwd():
    print("\n[DWD] dwd_order_detail...")
    orders_rows = read_tsv(f"{BASE}/ods/ods_order_info/dt={BDATE}/ods_order_info.tsv")
    detail_rows = read_tsv(f"{BASE}/ods/ods_order_detail/dt={BDATE}/ods_order_detail.tsv")

    orders = {}
    for cols in orders_rows:
        if len(cols) >= 14:
            orders[cols[0]] = {"user": cols[5], "status": cols[4], "amount": cols[3], "province": cols[13]}

    dwd_rows = []
    for cols in detail_rows:
        if len(cols) >= 10:
            detail_id, order_id, sku_id, sku_name = cols[0], cols[1], cols[2], cols[3]
            price, num, ctime, source = cols[5], cols[6], cols[7], cols[8]
            o = orders.get(order_id, {})
            user_id = o.get("user", "UNKNOWN")
            province = o.get("province", "UNKNOWN")
            amount = o.get("amount", "0")
            status = o.get("status", "UNKNOWN")

            # Data masking
            masked = sku_name[:1] + "***" + sku_name[-1:] if len(sku_name) > 2 else sku_name

            dwd_rows.append([detail_id, order_id, user_id, sku_id, masked, price, num, amount, ctime, source, province, status])

    webhdfs_mkdir(f"{BASE}/dwd/dwd_order_detail/dt={BDATE}")
    write_tsv(f"{BASE}/dwd/dwd_order_detail/dt={BDATE}/data.tsv", dwd_rows)
    print(f"  {len(dwd_rows)} rows")


def step_dws():
    print("\n[DWS] dws_gmv_stats...")
    detail_rows = read_tsv(f"{BASE}/dwd/dwd_order_detail/dt={BDATE}/data.tsv")

    total_gmv = 0.0
    total_items = 0
    order_ids = set()

    for cols in detail_rows:
        if len(cols) >= 8:
            try:
                price = float(cols[5])
                num = int(cols[6])
                total_gmv += price * num
                total_items += num
                order_ids.add(cols[1])
            except:
                pass

    total_orders = len(order_ids)
    avg_val = total_gmv / total_orders if total_orders else 0
    webhdfs_mkdir(f"{BASE}/dws/dws_gmv_stats/dt={BDATE}")
    write_tsv(f"{BASE}/dws/dws_gmv_stats/dt={BDATE}/data.tsv",
              [["TOTAL", BDATE, str(total_orders), str(total_items), f"{avg_val:.2f}"]])
    print(f"  GMV={total_gmv:.2f}, Orders={total_orders}")


def step_ads():
    print("\n[ADS] ads tables...")
    detail_rows = read_tsv(f"{BASE}/dwd/dwd_order_detail/dt={BDATE}/data.tsv")

    total_gmv = 0.0
    total_items = 0
    total_orders = 0
    users = set()
    sku_sales = Counter()

    for cols in detail_rows:
        if len(cols) >= 8:
            try:
                price = float(cols[5])
                num = int(cols[6])
                total_gmv += price * num
                total_items += num
                total_orders += 1
                if cols[2] and cols[2] != "UNKNOWN":
                    users.add(cols[2])
                sku_sales[cols[3]] += num
            except:
                pass

    # ads_gmv_day
    avg_price = total_gmv / total_items if total_items else 0
    write_tsv(f"{BASE}/ads/ads_gmv_day/data.tsv",
              [[BDATE, f"{total_gmv:.2f}", str(total_orders), str(total_items), str(len(users)), f"{avg_price:.2f}"]])
    print(f"  ads_gmv_day: GMV={total_gmv:.2f}, Orders={total_orders}")

    # ads_sku_sales_rank
    rank_rows = []
    for rank, (sku_id, qty) in enumerate(sku_sales.most_common(), 1):
        rank_rows.append([BDATE, str(rank), sku_id, str(qty)])
    write_tsv(f"{BASE}/ads/ads_sku_sales_rank/data.tsv", rank_rows)
    print(f"  ads_sku_sales_rank: {len(rank_rows)} SKUs")

    # ads_user_retention
    user_rows = read_tsv(f"{BASE}/ods/ods_user_info/dt={BDATE}/ods_user_info.tsv")
    new_users = set()
    for cols in user_rows:
        if len(cols) >= 11 and cols[10][:10] < BDATE:
            new_users.add(cols[0])
    retained = new_users & users
    rate = len(retained) / len(new_users) * 100 if new_users else 0
    write_tsv(f"{BASE}/ads/ads_user_retention/data.tsv",
              [[BDATE, "1_day", str(len(new_users)), str(len(retained)), f"{rate:.2f}%"]])
    print(f"  ads_user_retention: {len(retained)}/{len(new_users)} retained ({rate:.2f}%)")


def register_hive():
    """Register tables in Hive via beeline"""
    print("\n[HIVE] Registering tables...")

    # Read the template SQL and replace variables
    sqls = f"""
USE gmall_dim;
DROP TABLE IF EXISTS dim_time;
CREATE EXTERNAL TABLE dim_time (date_id STRING, date_val STRING, year STRING, month STRING, day STRING, quarter STRING, week STRING, weekday STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\\t' STORED AS TEXTFILE LOCATION '{BASE}/dim/dim_time';

DROP TABLE IF EXISTS dim_sku;
CREATE EXTERNAL TABLE dim_sku (sku_id STRING, sku_name STRING, spu_id STRING, price DECIMAL(16,2), sku_desc STRING, tm_id STRING, category3_id STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\\t' STORED AS TEXTFILE LOCATION '{BASE}/dim/dim_sku';

DROP TABLE IF EXISTS dim_user;
CREATE EXTERNAL TABLE dim_user (user_id STRING, login_name STRING, nick_name STRING, name STRING, birthday STRING, gender STRING, operate_time STRING, user_level STRING, create_time STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\\t' STORED AS TEXTFILE LOCATION '{BASE}/dim/dim_user';

USE gmall_dwd;
DROP TABLE IF EXISTS dwd_order_detail;
CREATE EXTERNAL TABLE dwd_order_detail (detail_id STRING, order_id STRING, user_id STRING, sku_id STRING, sku_name STRING, price DECIMAL(16,2), num INT, amount DECIMAL(16,2), create_time STRING, source_type STRING, province_id STRING, order_status STRING) PARTITIONED BY (dt STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\\t' STORED AS TEXTFILE LOCATION '{BASE}/dwd/dwd_order_detail';
ALTER TABLE gmall_dwd.dwd_order_detail ADD PARTITION (dt='{BDATE}');

USE gmall_dws;
DROP TABLE IF EXISTS dws_gmv_stats;
CREATE EXTERNAL TABLE dws_gmv_stats (gmv_label STRING, dt STRING, order_count INT, item_count INT, avg_order_value DOUBLE) PARTITIONED BY (biz_date STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\\t' STORED AS TEXTFILE LOCATION '{BASE}/dws/dws_gmv_stats';
ALTER TABLE gmall_dws.dws_gmv_stats ADD PARTITION (biz_date='{BDATE}');

USE gmall_ads;
DROP TABLE IF EXISTS ads_gmv_day;
CREATE EXTERNAL TABLE ads_gmv_day (dt STRING, gmv DECIMAL(16,2), order_count INT, item_count INT, user_count INT, avg_price DECIMAL(16,2)) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\\t' STORED AS TEXTFILE LOCATION '{BASE}/ads/ads_gmv_day';

DROP TABLE IF EXISTS ads_user_retention;
CREATE EXTERNAL TABLE ads_user_retention (dt STRING, retention_type STRING, new_user_count INT, retained_user_count INT, retention_rate STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\\t' STORED AS TEXTFILE LOCATION '{BASE}/ads/ads_user_retention';

DROP TABLE IF EXISTS ads_sku_sales_rank;
CREATE EXTERNAL TABLE ads_sku_sales_rank (dt STRING, rank INT, sku_id STRING, sales_qty INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\\t' STORED AS TEXTFILE LOCATION '{BASE}/ads/ads_sku_sales_rank';

-- Verification
SELECT '=== Layer Verification ===' as msg;
SELECT 'dim_time', COUNT(*) FROM gmall_dim.dim_time;
SELECT 'dim_sku', COUNT(*) FROM gmall_dim.dim_sku;
SELECT 'dim_user', COUNT(*) FROM gmall_dim.dim_user;
SELECT COUNT(*) as dwd_count FROM gmall_dwd.dwd_order_detail WHERE dt='{BDATE}';
SELECT COUNT(*) as dws_count FROM gmall_dws.dws_gmv_stats WHERE biz_date='{BDATE}';
SELECT dt, gmv, order_count, user_count FROM gmall_ads.ads_gmv_day;
SELECT * FROM gmall_ads.ads_sku_sales_rank ORDER BY rank LIMIT 10;
SELECT * FROM gmall_ads.ads_user_retention;
"""
    run_beeline(sqls)


def main():
    print("=" * 55)
    print("  GMall Data Warehouse ETL Pipeline")
    print(f"  Date: {BDATE}  |  HDFS: {NAMENODE}")
    print("=" * 55)

    step_dim_time()
    step_dim_sku()
    step_dim_user()
    step_dwd()
    step_dws()
    step_ads()
    register_hive()

    print("\n" + "=" * 55)
    print("  ETL Pipeline Completed Successfully!")
    print("  All 5 layers: ODS -> DIM -> DWD -> DWS -> ADS")
    print("=" * 55)


if __name__ == "__main__":
    main()

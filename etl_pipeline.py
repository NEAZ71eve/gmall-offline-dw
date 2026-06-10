#!/usr/bin/env python3
"""
GMall Offline Data Warehouse ETL Pipeline
Process data from ODS through DIM/DWD/DWS to ADS layer
"""
import os
import subprocess
import sys
import csv
import io
from collections import Counter, defaultdict

BDATE = os.environ.get("BDATE", "2024-01-15")
HDFS_URL = os.environ.get("HDFS_URL", "hdfs://traffic-hdfs-namenode:9000")
BASE = os.environ.get("BASE_PATH", "/warehouse/gmall")
HDFS_CMD = ["hdfs", "dfs", "-D", f"fs.defaultFS={HDFS_URL}"]
BEELINE = ["/opt/hive/bin/beeline", "-u", "jdbc:hive2://gmall-hiveserver2:10000"]


def hdfs_cmd(*args):
    """Run HDFS command and return output"""
    cmd = HDFS_CMD + list(args)
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"  HDFS Error: {result.stderr.strip()}")
        return None
    return result.stdout.strip()


def hdfs_upload(local_path, hdfs_path):
    """Upload file to HDFS"""
    hdfs_cmd("mkdir", "-p", os.path.dirname(hdfs_path))
    return hdfs_cmd("put", "-f", local_path, hdfs_path)


def hdfs_download(hdfs_path, local_path):
    """Download file from HDFS"""
    result = subprocess.run(HDFS_CMD + ["cat", hdfs_path], capture_output=True, text=True)
    if result.returncode == 0 and result.stdout.strip():
        with open(local_path, "w", encoding="utf-8") as f:
            f.write(result.stdout)
        return True
    return False


def run_beeline(sql):
    """Run Hive SQL via beeline"""
    cmd = BEELINE + ["-e", sql]
    result = subprocess.run(cmd, capture_output=True, text=True)
    for line in result.stdout.split("\n"):
        if "|" in line and not "SLF4J" in line:
            print(f"  Hive: {line.strip()}")
    return result.returncode == 0


def step_dim_time():
    """Build date dimension for 2024"""
    print("\n[DIM] Building dim_time...")
    import datetime
    lines = []
    d = datetime.date(2024, 1, 1)
    for i in range(366):
        date_id = d.strftime("%Y%m%d")
        year = d.year
        month = d.month
        day = d.day
        quarter = (month - 1) // 3 + 1
        week = f"W{d.strftime("%W")}"
        weekday = d.strftime("%A")
        lines.append(f"{date_id}\t{d}\t{year}\t{month:02d}\t{day:02d}\t{quarter}\t{week}\t{weekday}")
        d += datetime.timedelta(days=1)

    local_path = "/tmp/dim_time.tsv"
    with open(local_path, "w") as f:
        f.write("\n".join(lines))

    hdfs_upload(local_path, f"{BASE}/dim/dim_time/dim_time.tsv")
    print(f"  dim_time: {len(lines)} rows")


def step_dim_sku():
    """Build SKU dimension from ODS"""
    print("\n[DIM] Building dim_sku...")
    local_ods = "/tmp/ods_sku.tsv"
    local_dim = "/tmp/dim_sku.tsv"

    if hdfs_download(f"{BASE}/ods/ods_sku_info/dt={BDATE}/ods_sku_info.tsv", local_ods):
        with open(local_ods) as f_in, open(local_dim, "w") as f_out:
            for line in f_in:
                cols = line.strip().split("\t")
                if len(cols) >= 8:
                    f_out.write(f"{cols[0]}\t{cols[3]}\t{cols[1]}\t{cols[2]}\t{cols[4]}\t{cols[6]}\t{cols[7]}\n")

        hdfs_upload(local_dim, f"{BASE}/dim/dim_sku/dim_sku.tsv")
        count = sum(1 for _ in open(local_dim))
        print(f"  dim_sku: {count} rows")
    else:
        print("  SKIP: No ODS SKU data found")


def step_dim_user():
    """Build user dimension from ODS"""
    print("\n[DIM] Building dim_user...")
    local_ods = "/tmp/ods_user.tsv"
    local_dim = "/tmp/dim_user.tsv"

    if hdfs_download(f"{BASE}/ods/ods_user_info/dt={BDATE}/ods_user_info.tsv", local_ods):
        with open(local_ods) as f_in, open(local_dim, "w") as f_out:
            for line in f_in:
                cols = line.strip().split("\t")
                if len(cols) >= 11:
                    f_out.write(f"{cols[0]}\t{cols[1]}\t{cols[2]}\t{cols[3]}\t{cols[8]}\t{cols[9]}\t{cols[11]}\t{cols[6]}\t{cols[10]}\n")

        hdfs_upload(local_dim, f"{BASE}/dim/dim_user/dim_user.tsv")
        count = sum(1 for _ in open(local_dim))
        print(f"  dim_user: {count} rows")
    else:
        print("  SKIP: No ODS User data found")


def step_dwd_order_detail():
    """Build DWD order detail with data cleaning"""
    print("\n[DWD] Building dwd_order_detail...")
    local_order = "/tmp/ods_order.tsv"
    local_detail = "/tmp/ods_detail.tsv"
    local_dwd = "/tmp/dwd_order_detail.tsv"

    has_order = hdfs_download(f"{BASE}/ods/ods_order_info/dt={BDATE}/ods_order_info.tsv", local_order)
    has_detail = hdfs_download(f"{BASE}/ods/ods_order_detail/dt={BDATE}/ods_order_detail.tsv", local_detail)

    if not has_detail:
        print("  SKIP: No ODS Detail data found")
        return

    # Load orders into dict
    orders = {}
    if has_order:
        with open(local_order) as f:
            for line in f:
                cols = line.strip().split("\t")
                if len(cols) >= 14:
                    orders[cols[0]] = {
                        "user_id": cols[5], "status": cols[4],
                        "amount": cols[3], "province": cols[13],
                        "pay_method": cols[6]
                    }

    # Process details with data cleaning
    lines_out = []
    with open(local_detail) as f:
        for line in f:
            cols = line.strip().split("\t")
            if len(cols) >= 10:
                detail_id, order_id, sku_id, sku_name = cols[0], cols[1], cols[2], cols[3]
                price, num, create_time, source = cols[5], cols[6], cols[7], cols[8]

                # Data masking: mask sku name
                if len(sku_name) > 2:
                    masked_name = sku_name[:1] + "***" + sku_name[-1:]
                else:
                    masked_name = sku_name

                order_info = orders.get(order_id, {})
                user_id = order_info.get("user_id", "UNKNOWN")
                province = order_info.get("province", "UNKNOWN")
                amount = order_info.get("amount", "0")
                status = order_info.get("status", "UNKNOWN")

                lines_out.append(f"{detail_id}\t{order_id}\t{user_id}\t{sku_id}\t{masked_name}\t{price}\t{num}\t{amount}\t{create_time}\t{source}\t{province}\t{status}")

    with open(local_dwd, "w") as f:
        f.write("\n".join(lines_out))

    hdfs_cmd("mkdir", "-p", f"{BASE}/dwd/dwd_order_detail/dt={BDATE}")
    hdfs_upload(local_dwd, f"{BASE}/dwd/dwd_order_detail/dt={BDATE}/data.tsv")
    print(f"  dwd_order_detail: {len(lines_out)} rows")


def step_dws_gmv_stats():
    """Build DWS daily GMV stats"""
    print("\n[DWS] Building dws_gmv_stats...")
    local_dwd = "/tmp/dwd_order_detail.tsv"

    if not os.path.exists(local_dwd):
        hdfs_download(f"{BASE}/dwd/dwd_order_detail/dt={BDATE}/data.tsv", local_dwd)

    if not os.path.exists(local_dwd):
        print("  SKIP: No DWD data found")
        return

    total_gmv = 0.0
    total_items = 0
    order_ids = set()

    with open(local_dwd) as f:
        for line in f:
            cols = line.strip().split("\t")
            if len(cols) >= 8:
                try:
                    price = float(cols[5])
                    num = int(cols[6])
                    total_gmv += price * num
                    total_items += num
                    order_ids.add(cols[1])
                except ValueError:
                    continue

    total_orders = len(order_ids)
    avg_value = total_gmv / total_orders if total_orders > 0 else 0

    local_out = "/tmp/dws_gmv_stats.tsv"
    with open(local_out, "w") as f:
        f.write(f"TOTAL\t{BDATE}\t{total_orders}\t{total_items}\t{avg_value:.2f}\n")

    hdfs_cmd("mkdir", "-p", f"{BASE}/dws/dws_gmv_stats/dt={BDATE}")
    hdfs_upload(local_out, f"{BASE}/dws/dws_gmv_stats/dt={BDATE}/data.tsv")
    print(f"  GMV: {total_gmv:.2f}, Orders: {total_orders}, Items: {total_items}")


def step_ads_gmv_day():
    """Build ADS daily GMV report"""
    print("\n[ADS] Building ads_gmv_day...")
    local_dwd = "/tmp/dwd_order_detail.tsv"

    total_gmv = 0.0
    total_items = 0
    total_orders = 0
    users = set()

    with open(local_dwd) as f:
        for line in f:
            cols = line.strip().split("\t")
            if len(cols) >= 8:
                try:
                    price = float(cols[5])
                    num = int(cols[6])
                    total_gmv += price * num
                    total_items += num
                    total_orders += 1
                    if cols[2] and cols[2] != "UNKNOWN":
                        users.add(cols[2])
                except ValueError:
                    continue

    avg_price = total_gmv / total_items if total_items > 0 else 0

    local_out = "/tmp/ads_gmv_day.tsv"
    with open(local_out, "w") as f:
        f.write(f"{BDATE}\t{total_gmv:.2f}\t{total_orders}\t{total_items}\t{len(users)}\t{avg_price:.2f}\n")

    hdfs_upload(local_out, f"{BASE}/ads/ads_gmv_day/data.tsv")
    print(f"  GMV: {total_gmv:.2f}, Orders: {total_orders}, Users: {len(users)}")


def step_ads_sku_rank():
    """Build ADS SKU sales ranking"""
    print("\n[ADS] Building ads_sku_sales_rank...")
    local_dwd = "/tmp/dwd_order_detail.tsv"

    sku_sales = Counter()
    with open(local_dwd) as f:
        for line in f:
            cols = line.strip().split("\t")
            if len(cols) >= 7:
                try:
                    sku_id = cols[3]
                    num = int(cols[6])
                    sku_sales[sku_id] += num
                except ValueError:
                    continue

    local_out = "/tmp/ads_sku_sales_rank.tsv"
    with open(local_out, "w") as f:
        for rank, (sku_id, qty) in enumerate(sku_sales.most_common(), 1):
            f.write(f"{BDATE}\t{rank}\t{sku_id}\t{qty}\n")

    hdfs_upload(local_out, f"{BASE}/ads/ads_sku_sales_rank/data.tsv")
    print(f"  {len(sku_sales)} SKUs ranked")


def step_ads_user_retention():
    """Build ADS user retention"""
    print("\n[ADS] Building ads_user_retention...")
    local_user = "/tmp/ods_user.tsv"

    if not hdfs_download(f"{BASE}/ods/ods_user_info/dt={BDATE}/ods_user_info.tsv", local_user):
        print("  SKIP: No user data")
        return

    users_new = set()
    with open(local_user) as f:
        for line in f:
            cols = line.strip().split("\t")
            if len(cols) >= 11:
                create_date = cols[10][:10] if len(cols[10]) >= 10 else ""
                if create_date and create_date < BDATE:
                    users_new.add(cols[0])

    users_active = set()
    local_dwd = "/tmp/dwd_order_detail.tsv"
    with open(local_dwd) as f:
        for line in f:
            cols = line.strip().split("\t")
            if len(cols) > 2 and cols[2] != "UNKNOWN":
                users_active.add(cols[2])

    retained = users_new & users_active
    total_new = len(users_new)
    retention_rate = len(retained) / total_new * 100 if total_new > 0 else 0

    local_out = "/tmp/ads_user_retention.tsv"
    with open(local_out, "w") as f:
        f.write(f"{BDATE}\t1_day\t{total_new}\t{len(retained)}\t{retention_rate:.2f}%\n")

    hdfs_upload(local_out, f"{BASE}/ads/ads_user_retention/data.tsv")
    print(f"  New: {total_new}, Retained: {len(retained)}, Rate: {retention_rate:.2f}%")


def register_hive_tables():
    """Register all ETL results as Hive external tables"""
    print("\n[HIVE] Registering tables in Hive Metastore...")

    sqls = [
        f"USE gmall_dim;",
        f"DROP TABLE IF EXISTS dim_time;",
        f"CREATE EXTERNAL TABLE dim_time (date_id STRING, date_val STRING, year STRING, month STRING, day STRING, quarter STRING, week STRING, weekday STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\\\\t' STORED AS TEXTFILE LOCATION '{BASE}/dim/dim_time';",
        f"DROP TABLE IF EXISTS dim_sku;",
        f"CREATE EXTERNAL TABLE dim_sku (sku_id STRING, sku_name STRING, spu_id STRING, price DECIMAL(16,2), sku_desc STRING, tm_id STRING, category3_id STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\\\\t' STORED AS TEXTFILE LOCATION '{BASE}/dim/dim_sku';",
        f"DROP TABLE IF EXISTS dim_user;",
        f"CREATE EXTERNAL TABLE dim_user (user_id STRING, login_name STRING, nick_name STRING, name STRING, birthday STRING, gender STRING, operate_time STRING, user_level STRING, create_time STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\\\\t' STORED AS TEXTFILE LOCATION '{BASE}/dim/dim_user';",
        f"USE gmall_dwd;",
        f"DROP TABLE IF EXISTS dwd_order_detail;",
        f"CREATE EXTERNAL TABLE dwd_order_detail (detail_id STRING, order_id STRING, user_id STRING, sku_id STRING, sku_name STRING, price DECIMAL(16,2), num INT, amount DECIMAL(16,2), create_time STRING, source_type STRING, province_id STRING, order_status STRING) PARTITIONED BY (dt STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\\\\t' STORED AS TEXTFILE LOCATION '{BASE}/dwd/dwd_order_detail';",
        f"ALTER TABLE gmall_dwd.dwd_order_detail ADD PARTITION (dt='{BDATE}');",
        f"USE gmall_dws;",
        f"DROP TABLE IF EXISTS dws_gmv_stats;",
        f"CREATE EXTERNAL TABLE dws_gmv_stats (gmv_label STRING, dt STRING, order_count INT, item_count INT, avg_order_value DOUBLE) PARTITIONED BY (biz_date STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\\\\t' STORED AS TEXTFILE LOCATION '{BASE}/dws/dws_gmv_stats';",
        f"ALTER TABLE gmall_dws.dws_gmv_stats ADD PARTITION (biz_date='{BDATE}');",
        f"USE gmall_ads;",
        f"DROP TABLE IF EXISTS ads_gmv_day;",
        f"CREATE EXTERNAL TABLE ads_gmv_day (dt STRING, gmv DECIMAL(16,2), order_count INT, item_count INT, user_count INT, avg_price DECIMAL(16,2)) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\\\\t' STORED AS TEXTFILE LOCATION '{BASE}/ads/ads_gmv_day';",
        f"DROP TABLE IF EXISTS ads_user_retention;",
        f"CREATE EXTERNAL TABLE ads_user_retention (dt STRING, retention_type STRING, new_user_count INT, retained_user_count INT, retention_rate STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\\\\t' STORED AS TEXTFILE LOCATION '{BASE}/ads/ads_user_retention';",
        f"DROP TABLE IF EXISTS ads_sku_sales_rank;",
        f"CREATE EXTERNAL TABLE ads_sku_sales_rank (dt STRING, rank INT, sku_id STRING, sales_qty INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\\\\t' STORED AS TEXTFILE LOCATION '{BASE}/ads/ads_sku_sales_rank';",
    ]

    for sql in sqls:
        run_beeline(sql)

    # Verify
    print("\n  Verification:")
    run_beeline(f"SELECT 'ods_user_info',COUNT(*) FROM gmall_ods.ods_user_info WHERE dt='{BDATE}'")
    run_beeline(f"SELECT COUNT(*) as dim_time FROM gmall_dim.dim_time")
    run_beeline(f"SELECT COUNT(*) as dim_sku FROM gmall_dim.dim_sku")
    run_beeline(f"SELECT COUNT(*) as dim_user FROM gmall_dim.dim_user")
    run_beeline(f"SELECT * FROM gmall_ads.ads_gmv_day")


def main():
    print("=" * 50)
    print(f"GMall Data Warehouse ETL Pipeline")
    print(f"Business Date: {BDATE}")
    print("=" * 50)

    step_dim_time()
    step_dim_sku()
    step_dim_user()
    step_dwd_order_detail()
    step_dws_gmv_stats()
    step_ads_gmv_day()
    step_ads_sku_rank()
    step_ads_user_retention()
    register_hive_tables()

    print("\n" + "=" * 50)
    print("ETL Pipeline Completed Successfully!")
    print("=" * 50)


if __name__ == "__main__":
    main()

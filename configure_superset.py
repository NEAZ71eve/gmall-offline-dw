#!/usr/bin/env python3
"""Configure Superset with Hive database connection"""
import requests
import json

SUPERSET_URL = "http://gmall-superset:8088"
ADMIN_USER = "admin"
ADMIN_PASS = "54088Cnm,"

# Create session for cookie handling
session = requests.Session()

# Step 1: Login
print("=== Login to Superset ===")
r = session.post(f"{SUPERSET_URL}/api/v1/security/login", json={
    "username": ADMIN_USER, "password": ADMIN_PASS, "provider": "db"
})
token = r.json()["access_token"]
session.headers.update({"Authorization": f"Bearer {token}", "Content-Type": "application/json"})
print(f"Token obtained: {token[:20]}...")

# Get CSRF token
r_csrf = session.get(f"{SUPERSET_URL}/api/v1/security/csrf_token/")
csrf = r_csrf.json().get("result", "")
session.headers["X-CSRFToken"] = csrf
session.headers["Referer"] = f"{SUPERSET_URL}/"
print(f"CSRF token obtained")

# Step 2: Add Hive database
print("\n=== Adding Hive Database ===")
db_config = {
    "database_name": "Hive GMall",
    "sqlalchemy_uri": "hive://hive@gmall-hiveserver2:10000",
    "expose_in_sqllab": True,
    "allow_dml": False,
    "extra": json.dumps({
        "engine_params": {
            "connect_args": {"auth": "NONE"}
        },
        "metadata_params": {},
        "engine_information": {}
    })
}
r = session.post(f"{SUPERSET_URL}/api/v1/database/", json=db_config)
print(f"Status: {r.status_code}")
if r.status_code in (200, 201):
    db_id = r.json().get("id")
    print(f"Database created with ID: {db_id}")
else:
    print(f"Response: {r.text[:300]}")
    # Maybe it already exists - try getting it
    r2 = session.get(f"{SUPERSET_URL}/api/v1/database/")
    dbs = r2.json().get("result", [])
    for db in dbs:
        print(f"  Existing: {db['database_name']} (ID: {db['id']})")
    db_id = dbs[0]["id"] if dbs else None

# Step 3: Add datasets
if db_id:
    print(f"\n=== Adding datasets to database {db_id} ===")
    datasets = [
        # ADS layer
        {"table_name": "ads_gmv_day", "database_id": db_id, "schema": "gmall_ads",
         "sql": "SELECT dt, gmv, order_count, item_count, user_count, avg_price FROM gmall_ads.ads_gmv_day"},
        {"table_name": "ads_user_retention", "database_id": db_id, "schema": "gmall_ads",
         "sql": "SELECT dt, retention_type, new_user_count, retained_user_count, retention_rate FROM gmall_ads.ads_user_retention"},
        {"table_name": "ads_sku_sales_rank", "database_id": db_id, "schema": "gmall_ads",
         "sql": "SELECT dt, rank, sku_id, sales_qty FROM gmall_ads.ads_sku_sales_rank ORDER BY rank"},
        # DIM layer
        {"table_name": "dim_time", "database_id": db_id, "schema": "gmall_dim"},
        {"table_name": "dim_sku", "database_id": db_id, "schema": "gmall_dim"},
        {"table_name": "dim_user", "database_id": db_id, "schema": "gmall_dim"},
        # DWD layer
        {"table_name": "dwd_order_detail", "database_id": db_id, "schema": "gmall_dwd"},
        # DWS layer
        {"table_name": "dws_gmv_stats", "database_id": db_id, "schema": "gmall_dws"},
    ]
    for ds in datasets:
        r = session.post(f"{SUPERSET_URL}/api/v1/dataset/", json=ds)
        if r.status_code in (200, 201):
            print(f"  ✅ {ds['table_name']}")
        elif r.status_code == 422:
            print(f"  ⚠️  {ds['table_name']} already exists")
        else:
            print(f"  ❌ {ds['table_name']}: {r.status_code} {r.text[:100]}")

# Step 4: Verify
print("\n=== Verification ===")
r = session.get(f"{SUPERSET_URL}/api/v1/dataset/")
datasets = r.json().get("result", [])
print(f"Total datasets: {len(datasets)}")
for ds in datasets:
    print(f"  - {ds.get('table_name', ds.get('name', '?'))} (schema: {ds.get('schema', '-')})")

print("\n✅ Superset configuration complete!")

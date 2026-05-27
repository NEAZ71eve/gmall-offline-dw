#!/usr/bin/env python3
"""
Superset Hive数据库连接配置脚本
用于在Superset中注册Hive数据源
"""

import requests
import json
from datetime import datetime

SUPERSET_BASE_URL = "http://localhost:8088"
USERNAME = "admin"
PASSWORD = "admin"

def get_auth_token():
    """获取Superset认证令牌"""
    response = requests.post(
        f"{SUPERSET_BASE_URL}/api/v1/security/login",
        json={
            "username": USERNAME,
            "password": PASSWORD,
            "provider": "db",
            "refresh": True
        }
    )
    if response.status_code == 200:
        return response.json().get("access_token")
    else:
        print(f"认证失败: {response.status_code}")
        return None

def create_database(connection_uri, database_name):
    """创建数据库连接"""
    headers = {
        "Authorization": f"Bearer {get_auth_token()}",
        "Content-Type": "application/json"
    }

    payload = {
        "database_name": database_name,
        "sqlalchemy_uri": connection_uri,
        "cache_timeout": 3600,
        "expose_in_sqllab": True,
        "allow_run_async": True,
        "allow_ctas": True,
        "allow_cvas": True,
        "allow_file_upload": True,
        "extra": json.dumps({
            "metadata_params": {},
            "engine_params": {
                "connect_args": {
                    "auth": "CUSTOM"
                }
            },
            "schemas_allowed_for_file_upload": ["gmall_ods", "gmall_dim", "gmall_dwd", "gmall_dws", "gmall_ads"]
        })
    }

    response = requests.post(
        f"{SUPERSET_BASE_URL}/api/v1/database/",
        headers=headers,
        json=payload
    )

    if response.status_code == 201:
        print(f"✓ 数据库 '{database_name}' 创建成功")
        return response.json().get("id")
    else:
        print(f"✗ 数据库 '{database_name}' 创建失败: {response.status_code}")
        print(response.text)
        return None

def create_dataset(database_id, schema, table_name):
    """创建数据集"""
    headers = {
        "Authorization": f"Bearer {get_auth_token()}",
        "Content-Type": "application/json"
    }

    payload = {
        "database": database_id,
        "schema": schema,
        "table_name": table_name,
        "sql": f"SELECT * FROM {schema}.{table_name} LIMIT 100"
    }

    response = requests.post(
        f"{SUPERSET_BASE_URL}/api/v1/dataset/",
        headers=headers,
        json=payload
    )

    if response.status_code == 201:
        print(f"  ✓ 数据集 '{schema}.{table_name}' 创建成功")
        return response.json().get("id")
    else:
        print(f"  ✗ 数据集 '{schema}.{table_name}' 创建失败: {response.status_code}")
        return None

def main():
    print("=" * 80)
    print("Superset Hive数据源配置".center(80))
    print("=" * 80)
    print()

    # Step 1: 创建Hive数据库连接
    print("【步骤1】创建Hive数据库连接")
    print("-" * 80)

    hive_connection = "hive://hadoop:@localhost:10000/gmall"
    database_id = create_database(hive_connection, "Hive_Gmall_Data")

    if not database_id:
        print("数据库连接创建失败，退出")
        return

    print()

    # Step 2: 创建数据集
    print("【步骤2】创建数据集")
    print("-" * 80)

    datasets = [
        ("gmall_ads", "ads_gmv_day"),
        ("gmall_ads", "ads_sku_sales_rank"),
        ("gmall_ads", "ads_user_retention"),
        ("gmall_ads", "ads_conversion_rate"),
        ("gmall_dws", "dws_gmv_stats"),
        ("gmall_dws", "dws_user_stats"),
        ("gmall_dws", "dws_sku_stats"),
        ("gmall_dwd", "dwd_order_detail"),
        ("gmall_dwd", "dwd_order_info"),
        ("gmall_dim", "dim_user"),
        ("gmall_dim", "dim_sku"),
        ("gmall_dim", "dim_time"),
        ("gmall_ods", "ods_user_info"),
        ("gmall_ods", "ods_order_info"),
        ("gmall_ods", "ods_order_detail"),
    ]

    for schema, table in datasets:
        create_dataset(database_id, schema, table)

    print()
    print("=" * 80)
    print("数据源配置完成！".center(80))
    print("=" * 80)
    print()
    print("请访问 Superset 平台查看配置的数据源")
    print(f"地址: {SUPERSET_BASE_URL}")
    print(f"用户名: {USERNAME}")
    print(f"密码: {PASSWORD}")

if __name__ == '__main__':
    main()

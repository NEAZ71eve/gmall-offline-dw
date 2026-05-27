#!/usr/bin/env python3
"""
ODS 层数据加载脚本
直接从 MySQL 读取业务数据，生成文本文件并上传到 HDFS
"""

import pymysql
import os
from datetime import datetime

# MySQL 配置
mysql_config = {
    'host': 'localhost',
    'port': 3307,
    'user': 'testuser',
    'password': 'testpass',
    'database': 'gmall',
    'charset': 'utf8mb4'
}

# HDFS 命令
hdfs_cmd = '/usr/local/hadoop/bin/hdfs dfs'

def read_table(table_name):
    """从 MySQL 读取表数据"""
    conn = pymysql.connect(**mysql_config)
    try:
        with conn.cursor(pymysql.cursors.DictCursor) as cursor:
            cursor.execute(f"SELECT * FROM {table_name}")
            return cursor.fetchall()
    finally:
        conn.close()

def format_value(value, field_type='varchar'):
    """格式化字段值"""
    if value is None:
        return '\\N'
    if isinstance(value, datetime):
        return value.strftime('%Y-%m-%d %H:%M:%S')
    if isinstance(value, (int, float)):
        return str(value)
    return str(value).replace('\t', ' ').replace('\n', ' ').replace('\r', ' ')

def write_to_hdfs(table_name, data):
    """生成数据文件并上传到 HDFS"""
    if not data:
        print(f"表 {table_name} 无数据")
        return

    # 获取字段名
    fields = data[0].keys()
    field_count = len(fields)

    # 生成本地文件
    local_file = f'/tmp/{table_name}.txt'
    with open(local_file, 'w', encoding='utf-8') as f:
        for row in data:
            values = [format_value(row[field]) for field in fields]
            f.write('\t'.join(values) + '\n')

    print(f"已生成 {table_name}.txt，共 {len(data)} 条记录")

    # 上传到 HDFS
    hdfs_dir = '/warehouse/gmall/ods'
    hdfs_file = f'{hdfs_dir}/{table_name}'

    # 删除 HDFS 上的旧文件
    os.system(f'{hdfs_cmd} -rm -r {hdfs_file} 2>/dev/null')

    # 上传新文件
    result = os.system(f'{hdfs_cmd} -mkdir -p {hdfs_dir}')
    result = os.system(f'{hdfs_cmd} -put {local_file} {hdfs_file}')

    # 验证
    os.system(f'{hdfs_cmd} -ls {hdfs_dir} | grep {table_name}')

def main():
    print("=== ODS 层数据加载 ===")
    print(f"时间: {datetime.now()}")
    print()

    # 业务表列表
    tables = [
        'user_info',
        'sku_info',
        'spu_info',
        'base_trademark',
        'base_category1',
        'base_category2',
        'base_category3',
        'order_info',
        'order_detail',
        'payment_info'
    ]

    for table in tables:
        try:
            print(f"处理表: {table}...")
            data = read_table(table)
            write_to_hdfs(table, data)
            print()
        except Exception as e:
            print(f"处理表 {table} 时出错: {e}")
            print()

    print("=== ODS 层数据加载完成 ===")

    # 验证 ODS 层数据
    print("\n验证 ODS 层数据:")
    os.system(f'{hdfs_cmd} -ls -R /warehouse/gmall/ods/')

if __name__ == '__main__':
    main()

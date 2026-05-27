#!/usr/bin/env python3
"""
DIM 层数据处理脚本
从 ODS 层读取数据，进行维度建模处理
"""

import os
import subprocess
from datetime import datetime

# HDFS 命令
hdfs_cmd = '/usr/local/hadoop/bin/hdfs dfs'

def read_ods_table(table_name):
    """从 ODS 层读取表数据"""
    ods_file = f'/warehouse/gmall/ods/{table_name}'
    local_file = f'/tmp/dim_{table_name}.txt'

    # 从 HDFS 下载文件
    os.system(f'{hdfs_cmd} -get {ods_file} {local_file} 2>/dev/null')

    # 读取数据
    data = []
    if os.path.exists(local_file):
        with open(local_file, 'r', encoding='utf-8') as f:
            for line in f:
                fields = line.strip().split('\t')
                data.append(fields)

    return data

def create_dim_date():
    """创建日期维度表"""
    print("创建日期维度表...")

    dim_date_file = '/tmp/dim_date.txt'
    with open(dim_date_file, 'w', encoding='utf-8') as f:
        # 生成 2020-2026 年的日期数据
        for year in range(2020, 2027):
            for month in range(1, 13):
                for day in range(1, 32):
                    try:
                        date_str = f'{year}-{month:02d}-{day:02d}'
                        date_obj = datetime.strptime(date_str, '%Y-%m-%d')

                        # 计算星期（周一=1，周日=7）
                        weekday = date_obj.weekday() + 1

                        # 星期名称
                        weekday_name = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][weekday - 1]

                        # 是否周末
                        is_weekend = '1' if weekday in [6, 7] else '0'

                        # 月份名称
                        month_name = f'{month}月'

                        # 季度
                        quarter = (month - 1) // 3 + 1

                        # 年月
                        year_month = f'{year}{month:02d}'

                        # 写入数据
                        f.write(f"{date_str}\t{year}\t{month}\t{day}\t{year_month}\t{quarter}\t{weekday}\t{weekday_name}\t{is_weekend}\t{month_name}\n")

                    except ValueError:
                        # 无效日期（如 2月30日）
                        continue

    # 上传到 HDFS
    os.system(f'{hdfs_cmd} -mkdir -p /warehouse/gmall/dim')
    os.system(f'{hdfs_cmd} -rm -r /warehouse/gmall/dim/dim_date 2>/dev/null')
    os.system(f'{hdfs_cmd} -put {dim_date_file} /warehouse/gmall/dim/dim_date')

    print(f"日期维度表已创建，共 {os.path.getsize(dim_date_file)} 字节数据")

def create_dim_user():
    """创建用户维度表（拉链表）"""
    print("创建用户维度表...")

    try:
        data = read_ods_table('user_info')

        if not data:
            print("无用户数据")
            return

        dim_user_file = '/tmp/dim_user.txt'
        with open(dim_user_file, 'w', encoding='utf-8') as f:
            for row in data:
                if len(row) >= 13:
                    user_id = row[0]
                    login_name = row[1] if len(row) > 1 else '\\N'
                    nick_name = row[2] if len(row) > 2 else '\\N'
                    user_name = row[3] if len(row) > 3 else '\\N'
                    phone_num = row[4] if len(row) > 4 else '\\N'
                    email = row[5] if len(row) > 5 else '\\N'
                    user_level = row[7] if len(row) > 7 else '\\N'
                    birthday = row[8] if len(row) > 8 else '\\N'
                    gender = row[9] if len(row) > 9 else '\\N'
                    create_time = row[10] if len(row) > 10 else '\\N'
                    operate_time = row[11] if len(row) > 11 else '\\N'
                    status = row[12] if len(row) > 12 else '\\N'

                    # 拉链属性（模拟）
                    start_date = '2020-01-01'
                    end_date = '9999-12-31'

                    f.write(f"{user_id}\t{login_name}\t{nick_name}\t{user_name}\t{phone_num}\t{email}\t{user_level}\t{birthday}\t{gender}\t{create_time}\t{operate_time}\t{status}\t{start_date}\t{end_date}\n")

        # 上传到 HDFS
        os.system(f'{hdfs_cmd} -rm -r /warehouse/gmall/dim/dim_user 2>/dev/null')
        os.system(f'{hdfs_cmd} -put {dim_user_file} /warehouse/gmall/dim/dim_user')

        print(f"用户维度表已创建，共 {len(data)} 条记录")

    except Exception as e:
        print(f"创建用户维度表时出错: {e}")

def create_dim_sku():
    """创建商品SKU维度表"""
    print("创建商品SKU维度表...")

    try:
        # 读取 SKU 信息
        sku_data = read_ods_table('sku_info')

        # 读取品牌信息
        tm_data = read_ods_table('base_trademark')
        tm_dict = {row[0]: row[1] for row in tm_data if len(row) >= 2}

        # 读取分类信息
        cat1_data = read_ods_table('base_category1')
        cat1_dict = {row[0]: row[1] for row in cat1_data if len(row) >= 2}

        cat2_data = read_ods_table('base_category2')
        cat2_dict = {row[0]: {'name': row[1], 'cat1_id': row[2]} for row in cat2_data if len(row) >= 3}

        cat3_data = read_ods_table('base_category3')
        cat3_dict = {row[0]: {'name': row[1], 'cat2_id': row[2]} for row in cat3_data if len(row) >= 3}

        dim_sku_file = '/tmp/dim_sku.txt'
        with open(dim_sku_file, 'w', encoding='utf-8') as f:
            for row in sku_data:
                if len(row) >= 9:
                    sku_id = row[0]
                    spu_id = row[1]
                    price = row[2] if len(row) > 2 else '\\N'
                    sku_name = row[3] if len(row) > 3 else '\\N'
                    sku_desc = row[4] if len(row) > 4 else '\\N'
                    weight = row[5] if len(row) > 5 else '\\N'
                    tm_id = row[6] if len(row) > 6 else '\\N'
                    category3_id = row[7] if len(row) > 7 else '\\N'
                    create_time = row[8] if len(row) > 8 else '\\N'

                    # 维度属性
                    tm_name = tm_dict.get(tm_id, '\\N')

                    # 获取分类路径
                    cat3_name = cat3_dict.get(category3_id, {}).get('name', '\\N')
                    cat2_id = cat3_dict.get(category3_id, {}).get('cat2_id', '\\N')
                    cat2_name = cat2_dict.get(cat2_id, {}).get('name', '\\N')
                    cat1_id = cat2_dict.get(cat2_id, {}).get('cat1_id', '\\N')
                    cat1_name = cat1_dict.get(cat1_id, '\\N')

                    # 分类路径
                    category_path = f"{cat1_name}/{cat2_name}/{cat3_name}"

                    f.write(f"{sku_id}\t{spu_id}\t{sku_name}\t{sku_desc}\t{price}\t{weight}\t{tm_id}\t{tm_name}\t{category3_id}\t{cat3_name}\t{cat2_id}\t{cat2_name}\t{cat1_id}\t{cat1_name}\t{category_path}\t{create_time}\n")

        # 上传到 HDFS
        os.system(f'{hdfs_cmd} -rm -r /warehouse/gmall/dim/dim_sku 2>/dev/null')
        os.system(f'{hdfs_cmd} -put {dim_sku_file} /warehouse/gmall/dim/dim_sku')

        print(f"商品SKU维度表已创建，共 {len(sku_data)} 条记录")

    except Exception as e:
        print(f"创建商品SKU维度表时出错: {e}")

def main():
    print("=== DIM 层数据处理 ===")
    print(f"时间: {datetime.now()}")
    print()

    # 创建日期维度表
    create_dim_date()
    print()

    # 创建用户维度表
    create_dim_user()
    print()

    # 创建商品SKU维度表
    create_dim_sku()
    print()

    print("=== DIM 层数据处理完成 ===")

    # 验证 DIM 层数据
    print("\n验证 DIM 层数据:")
    os.system(f'{hdfs_cmd} -ls -R /warehouse/gmall/dim/')

if __name__ == '__main__':
    main()

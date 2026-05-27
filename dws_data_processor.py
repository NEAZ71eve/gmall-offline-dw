#!/usr/bin/env python3
"""
DWS 层数据处理脚本
从 DWD 层读取数据，进行轻度汇总，生成汇总表
"""

import os
from datetime import datetime
from collections import defaultdict

# HDFS 命令
hdfs_cmd = '/usr/local/hadoop/bin/hdfs dfs'

def read_dwd_table(table_name):
    """从 DWD 层读取表数据"""
    dwd_file = f'/warehouse/gmall/dwd/{table_name}'
    local_file = f'/tmp/dws_{table_name}.txt'

    # 从 HDFS 下载文件
    os.system(f'{hdfs_cmd} -get {dwd_file} {local_file} 2>/dev/null')

    # 读取数据
    data = []
    if os.path.exists(local_file):
        with open(local_file, 'r', encoding='utf-8') as f:
            for line in f:
                fields = line.strip().split('\t')
                data.append(fields)

    return data

def aggregate_order_stats():
    """汇总订单统计表"""
    print("汇总订单统计表...")

    try:
        data = read_dwd_table('dwd_order_detail')

        if not data:
            print("无订单明细数据")
            return

        # 按日期和用户汇总
        stats = defaultdict(lambda: {
            'order_count': 0,
            'sku_count': 0,
            'total_amount': 0.0
        })

        for row in data:
            if len(row) >= 9:
                create_time = row[8] if len(row) > 8 else '\\N'
                sku_num = row[6] if len(row) > 6 else '\\N'
                order_price = row[5] if len(row) > 5 else '\\N'

                # 提取日期
                if create_time and create_time != '\\N' and ' ' in create_time:
                    date_id = create_time.split()[0]
                else:
                    date_id = 'unknown'

                # 汇总
                stats[date_id]['order_count'] += 1

                if sku_num and sku_num != '\\N':
                    try:
                        stats[date_id]['sku_count'] += int(sku_num)
                    except:
                        pass

                if order_price and order_price != '\\N':
                    try:
                        stats[date_id]['total_amount'] += float(order_price)
                    except:
                        pass

        # 写入汇总数据
        dws_file = '/tmp/dws_order_stats.txt'
        with open(dws_file, 'w', encoding='utf-8') as f:
            for date_id in sorted(stats.keys()):
                order_count = stats[date_id]['order_count']
                sku_count = stats[date_id]['sku_count']
                total_amount = f"{stats[date_id]['total_amount']:.2f}"

                f.write(f"{date_id}\t{order_count}\t{sku_count}\t{total_amount}\n")

        # 上传到 HDFS
        os.system(f'{hdfs_cmd} -mkdir -p /warehouse/gmall/dws')
        os.system(f'{hdfs_cmd} -rm -r /warehouse/gmall/dws/dws_order_stats 2>/dev/null')
        os.system(f'{hdfs_cmd} -put {dws_file} /warehouse/gmall/dws/dws_order_stats')

        print(f"订单统计表已创建，共 {len(stats)} 天")

    except Exception as e:
        print(f"汇总订单统计表时出错: {e}")

def aggregate_user_stats():
    """汇总用户统计表"""
    print("汇总用户统计表...")

    try:
        data = read_dwd_table('dwd_order_info')

        if not data:
            print("无订单数据")
            return

        # 按用户汇总
        stats = defaultdict(lambda: {
            'order_count': 0,
            'total_amount': 0.0,
            'first_order_date': None,
            'last_order_date': None
        })

        for row in data:
            if len(row) >= 12:
                user_id = row[5] if len(row) > 5 else '\\N'
                total_amount = row[3] if len(row) > 3 else '\\N'
                create_time = row[11] if len(row) > 11 else '\\N'

                # 过滤无效用户
                if not user_id or user_id == '\\N':
                    continue

                # 汇总
                stats[user_id]['order_count'] += 1

                if total_amount and total_amount != '\\N':
                    try:
                        stats[user_id]['total_amount'] += float(total_amount)
                    except:
                        pass

                # 记录订单日期
                if create_time and create_time != '\\N':
                    date_str = create_time.split()[0] if ' ' in create_time else create_time
                    if not stats[user_id]['first_order_date'] or date_str < stats[user_id]['first_order_date']:
                        stats[user_id]['first_order_date'] = date_str
                    if not stats[user_id]['last_order_date'] or date_str > stats[user_id]['last_order_date']:
                        stats[user_id]['last_order_date'] = date_str

        # 写入汇总数据
        dws_file = '/tmp/dws_user_stats.txt'
        with open(dws_file, 'w', encoding='utf-8') as f:
            for user_id in sorted(stats.keys()):
                order_count = stats[user_id]['order_count']
                total_amount = f"{stats[user_id]['total_amount']:.2f}"
                first_order_date = stats[user_id]['first_order_date'] or '\\N'
                last_order_date = stats[user_id]['last_order_date'] or '\\N'

                # 计算平均订单金额
                if order_count > 0:
                    avg_order_amount = f"{stats[user_id]['total_amount'] / order_count:.2f}"
                else:
                    avg_order_amount = '0.00'

                f.write(f"{user_id}\t{order_count}\t{total_amount}\t{avg_order_amount}\t{first_order_date}\t{last_order_date}\n")

        # 上传到 HDFS
        os.system(f'{hdfs_cmd} -rm -r /warehouse/gmall/dws/dws_user_stats 2>/dev/null')
        os.system(f'{hdfs_cmd} -put {dws_file} /warehouse/gmall/dws/dws_user_stats')

        print(f"用户统计表已创建，共 {len(stats)} 个用户")

    except Exception as e:
        print(f"汇总用户统计表时出错: {e}")

def aggregate_sku_stats():
    """汇总商品统计表"""
    print("汇总商品统计表...")

    try:
        data = read_dwd_table('dwd_order_detail')

        if not data:
            print("无订单明细数据")
            return

        # 按商品汇总
        stats = defaultdict(lambda: {
            'order_count': 0,
            'total_num': 0,
            'total_amount': 0.0
        })

        for row in data:
            if len(row) >= 9:
                sku_id = row[2] if len(row) > 2 else '\\N'
                sku_num = row[6] if len(row) > 6 else '\\N'
                order_price = row[5] if len(row) > 5 else '\\N'
                order_amount = row[7] if len(row) > 7 else '\\N'

                # 过滤无效商品
                if not sku_id or sku_id == '\\N':
                    continue

                # 汇总
                stats[sku_id]['order_count'] += 1

                if sku_num and sku_num != '\\N':
                    try:
                        stats[sku_id]['total_num'] += int(sku_num)
                    except:
                        pass

                # 使用订单金额（sku_num * order_price）
                if order_amount and order_amount != '\\N':
                    try:
                        stats[sku_id]['total_amount'] += float(order_amount)
                    except:
                        pass

        # 写入汇总数据
        dws_file = '/tmp/dws_sku_stats.txt'
        with open(dws_file, 'w', encoding='utf-8') as f:
            for sku_id in sorted(stats.keys()):
                order_count = stats[sku_id]['order_count']
                total_num = stats[sku_id]['total_num']
                total_amount = f"{stats[sku_id]['total_amount']:.2f}"

                # 计算平均订单数量
                if order_count > 0:
                    avg_num = f"{stats[sku_id]['total_num'] / order_count:.2f}"
                    avg_amount = f"{stats[sku_id]['total_amount'] / order_count:.2f}"
                else:
                    avg_num = '0.00'
                    avg_amount = '0.00'

                f.write(f"{sku_id}\t{order_count}\t{total_num}\t{avg_num}\t{total_amount}\t{avg_amount}\n")

        # 上传到 HDFS
        os.system(f'{hdfs_cmd} -rm -r /warehouse/gmall/dws/dws_sku_stats 2>/dev/null')
        os.system(f'{hdfs_cmd} -put {dws_file} /warehouse/gmall/dws/dws_sku_stats')

        print(f"商品统计表已创建，共 {len(stats)} 个商品")

    except Exception as e:
        print(f"汇总商品统计表时出错: {e}")

def aggregate_gmv():
    """汇总 GMV 指标"""
    print("汇总 GMV 指标...")

    try:
        data = read_dwd_table('dwd_order_info')

        if not data:
            print("无订单数据")
            return

        # 按日期汇总 GMV
        gmv_stats = defaultdict(lambda: {
            'gmv': 0.0,
            'order_count': 0,
            'user_count': set()
        })

        for row in data:
            if len(row) >= 12:
                create_time = row[11] if len(row) > 11 else '\\N'
                total_amount = row[3] if len(row) > 3 else '\\N'
                user_id = row[5] if len(row) > 5 else '\\N'

                # 提取日期
                if create_time and create_time != '\\N' and ' ' in create_time:
                    date_id = create_time.split()[0]
                else:
                    date_id = 'unknown'

                # 汇总 GMV
                if total_amount and total_amount != '\\N':
                    try:
                        gmv_stats[date_id]['gmv'] += float(total_amount)
                        gmv_stats[date_id]['order_count'] += 1
                        if user_id and user_id != '\\N':
                            gmv_stats[date_id]['user_count'].add(user_id)
                    except:
                        pass

        # 写入汇总数据
        dws_file = '/tmp/dws_gmv_stats.txt'
        with open(dws_file, 'w', encoding='utf-8') as f:
            for date_id in sorted(gmv_stats.keys()):
                gmv = f"{gmv_stats[date_id]['gmv']:.2f}"
                order_count = gmv_stats[date_id]['order_count']
                user_count = len(gmv_stats[date_id]['user_count'])

                # 计算客单价
                if order_count > 0:
                    avg_order_amount = f"{gmv_stats[date_id]['gmv'] / order_count:.2f}"
                else:
                    avg_order_amount = '0.00'

                # 计算人均消费
                if user_count > 0:
                    avg_user_amount = f"{gmv_stats[date_id]['gmv'] / user_count:.2f}"
                else:
                    avg_user_amount = '0.00'

                f.write(f"{date_id}\t{gmv}\t{order_count}\t{user_count}\t{avg_order_amount}\t{avg_user_amount}\n")

        # 上传到 HDFS
        os.system(f'{hdfs_cmd} -rm -r /warehouse/gmall/dws/dws_gmv_stats 2>/dev/null')
        os.system(f'{hdfs_cmd} -put {dws_file} /warehouse/gmall/dws/dws_gmv_stats')

        print(f"GMV 统计表已创建，共 {len(gmv_stats)} 天")

    except Exception as e:
        print(f"汇总 GMV 指标时出错: {e}")

def main():
    print("=== DWS 层数据汇总 ===")
    print(f"时间: {datetime.now()}")
    print()

    # 汇总订单统计
    aggregate_order_stats()
    print()

    # 汇总用户统计
    aggregate_user_stats()
    print()

    # 汇总商品统计
    aggregate_sku_stats()
    print()

    # 汇总 GMV
    aggregate_gmv()
    print()

    print("=== DWS 层数据汇总完成 ===")

    # 验证 DWS 层数据
    print("\n验证 DWS 层数据:")
    os.system(f'{hdfs_cmd} -ls -R /warehouse/gmall/dws/')

if __name__ == '__main__':
    main()

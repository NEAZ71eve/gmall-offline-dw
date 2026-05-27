#!/usr/bin/env python3
"""
DWD 层数据处理脚本
从 ODS 层读取数据，进行数据清洗和转换，生成明细事实表
"""

import os
from datetime import datetime

# HDFS 命令
hdfs_cmd = '/usr/local/hadoop/bin/hdfs dfs'

def read_ods_table(table_name):
    """从 ODS 层读取表数据"""
    ods_file = f'/warehouse/gmall/ods/{table_name}'
    local_file = f'/tmp/dwd_{table_name}.txt'

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

def clean_order_detail():
    """清洗订单明细事实表"""
    print("清洗订单明细事实表...")

    try:
        data = read_ods_table('order_detail')

        if not data:
            print("无订单明细数据")
            return

        dwd_file = '/tmp/dwd_order_detail.txt'
        with open(dwd_file, 'w', encoding='utf-8') as f:
            for row in data:
                if len(row) >= 10:
                    detail_id = row[0]
                    order_id = row[1]
                    sku_id = row[2]
                    sku_name = row[3] if len(row) > 3 else '\\N'
                    img_url = row[4] if len(row) > 4 else '\\N'
                    order_price = row[5] if len(row) > 5 else '\\N'
                    sku_num = row[6] if len(row) > 6 else '\\N'
                    create_time = row[7] if len(row) > 7 else '\\N'
                    source_type = row[8] if len(row) > 8 else '\\N'
                    source_id = row[9] if len(row) > 9 else '\\N'

                    # 数据清洗
                    # 1. 过滤无效订单
                    if not order_id or order_id == '\\N':
                        continue

                    # 2. 清洗金额字段
                    if order_price and order_price != '\\N':
                        try:
                            order_price = f"{float(order_price):.2f}"
                        except:
                            order_price = '\\N'

                    # 3. 清洗数量字段
                    if sku_num and sku_num != '\\N':
                        try:
                            sku_num = str(int(float(sku_num)))
                        except:
                            sku_num = '\\N'

                    # 4. 计算订单金额
                    if order_price != '\\N' and sku_num != '\\N':
                        try:
                            total_amount = f"{float(order_price) * int(sku_num):.2f}"
                        except:
                            total_amount = '\\N'
                    else:
                        total_amount = '\\N'

                    # 5. 标准化来源类型
                    source_type_map = {'1': '购物车', '2': '直接购买', '3': '活动'}
                    source_type = source_type_map.get(source_type, source_type)

                    f.write(f"{detail_id}\t{order_id}\t{sku_id}\t{sku_name}\t{img_url}\t{order_price}\t{sku_num}\t{total_amount}\t{create_time}\t{source_type}\t{source_id}\n")

        # 上传到 HDFS
        os.system(f'{hdfs_cmd} -mkdir -p /warehouse/gmall/dwd')
        os.system(f'{hdfs_cmd} -rm -r /warehouse/gmall/dwd/dwd_order_detail 2>/dev/null')
        os.system(f'{hdfs_cmd} -put {dwd_file} /warehouse/gmall/dwd/dwd_order_detail')

        print(f"订单明细事实表已创建，共 {len(data)} 条记录")

    except Exception as e:
        print(f"清洗订单明细事实表时出错: {e}")

def clean_order_info():
    """清洗订单事实表"""
    print("清洗订单事实表...")

    try:
        data = read_ods_table('order_info')

        if not data:
            print("无订单数据")
            return

        dwd_file = '/tmp/dwd_order_info.txt'
        with open(dwd_file, 'w', encoding='utf-8') as f:
            for row in data:
                if len(row) >= 21:
                    order_id = row[0]
                    consignee = row[1] if len(row) > 1 else '\\N'
                    consignee_tel = row[2] if len(row) > 2 else '\\N'
                    total_amount = row[3] if len(row) > 3 else '\\N'
                    order_status = row[4] if len(row) > 4 else '\\N'
                    user_id = row[5] if len(row) > 5 else '\\N'
                    payment_way = row[6] if len(row) > 6 else '\\N'
                    delivery_address = row[7] if len(row) > 7 else '\\N'
                    order_comment = row[8] if len(row) > 8 else '\\N'
                    out_trade_no = row[9] if len(row) > 9 else '\\N'
                    trade_body = row[10] if len(row) > 10 else '\\N'
                    create_time = row[11] if len(row) > 11 else '\\N'
                    operate_time = row[12] if len(row) > 12 else '\\N'
                    expire_time = row[13] if len(row) > 13 else '\\N'
                    tracking_no = row[14] if len(row) > 14 else '\\N'
                    parent_order_id = row[15] if len(row) > 15 else '\\N'
                    img_url = row[16] if len(row) > 16 else '\\N'
                    province_id = row[17] if len(row) > 17 else '\\N'
                    benefit_reduce_amount = row[18] if len(row) > 18 else '\\N'
                    original_total_amount = row[19] if len(row) > 19 else '\\N'
                    feight_fee = row[20] if len(row) > 20 else '\\N'

                    # 数据清洗
                    # 1. 过滤无效订单
                    if not order_id or order_id == '\\N':
                        continue

                    # 2. 清洗金额字段
                    for idx in [3, 18, 19, 20]:
                        if idx < len(row) and row[idx] and row[idx] != '\\N':
                            try:
                                row[idx] = f"{float(row[idx]):.2f}"
                            except:
                                row[idx] = '\\N'

                    # 3. 标准化订单状态
                    order_status_map = {
                        '1001': '未支付',
                        '1002': '已支付',
                        '1003': '已发货',
                        '1004': '已完成',
                        '1005': '已取消'
                    }
                    order_status = order_status_map.get(order_status, order_status)

                    # 4. 标准化支付方式
                    payment_way_map = {
                        '1': '在线支付',
                        '2': '货到付款',
                        '3': '微信支付',
                        '4': '支付宝'
                    }
                    payment_way = payment_way_map.get(payment_way, payment_way)

                    # 5. 提取日期
                    if create_time and create_time != '\\N':
                        date_id = create_time.split()[0] if ' ' in create_time else create_time
                    else:
                        date_id = '\\N'

                    # 6. 提取省份
                    if province_id and province_id != '\\N':
                        province_id = province_id  # 保持原值
                    else:
                        province_id = '\\N'

                    f.write(f"{order_id}\t{consignee}\t{consignee_tel}\t{total_amount}\t{order_status}\t{user_id}\t{payment_way}\t{delivery_address}\t{order_comment}\t{out_trade_no}\t{trade_body}\t{create_time}\t{operate_time}\t{expire_time}\t{tracking_no}\t{parent_order_id}\t{img_url}\t{province_id}\t{benefit_reduce_amount}\t{original_total_amount}\t{feight_fee}\t{date_id}\n")

        # 上传到 HDFS
        os.system(f'{hdfs_cmd} -rm -r /warehouse/gmall/dwd/dwd_order_info 2>/dev/null')
        os.system(f'{hdfs_cmd} -put {dwd_file} /warehouse/gmall/dwd/dwd_order_info')

        print(f"订单事实表已创建，共 {len(data)} 条记录")

    except Exception as e:
        print(f"清洗订单事实表时出错: {e}")

def clean_payment_info():
    """清洗支付事实表"""
    print("清洗支付事实表...")

    try:
        data = read_ods_table('payment_info')

        if not data:
            print("无支付数据")
            return

        dwd_file = '/tmp/dwd_payment_info.txt'
        with open(dwd_file, 'w', encoding='utf-8') as f:
            for row in data:
                if len(row) >= 13:
                    payment_id = row[0]
                    out_trade_no = row[1] if len(row) > 1 else '\\N'
                    order_id = row[2] if len(row) > 2 else '\\N'
                    user_id = row[3] if len(row) > 3 else '\\N'
                    payment_type = row[4] if len(row) > 4 else '\\N'
                    trade_no = row[5] if len(row) > 5 else '\\N'
                    total_amount = row[6] if len(row) > 6 else '\\N'
                    subject = row[7] if len(row) > 7 else '\\N'
                    payment_status = row[8] if len(row) > 8 else '\\N'
                    create_time = row[9] if len(row) > 9 else '\\N'
                    callback_time = row[10] if len(row) > 10 else '\\N'
                    callback_content = row[11] if len(row) > 11 else '\\N'

                    # 数据清洗
                    # 1. 过滤无效记录
                    if not payment_id or payment_id == '\\N':
                        continue

                    # 2. 清洗金额字段
                    if total_amount and total_amount != '\\N':
                        try:
                            total_amount = f"{float(total_amount):.2f}"
                        except:
                            total_amount = '\\N'

                    # 3. 标准化支付状态
                    payment_status_map = {
                        'WAIT_BUYER_PAY': '等待支付',
                        'TRADE_CLOSED': '交易关闭',
                        'TRADE_SUCCESS': '支付成功',
                        'TRADE_FINISHED': '交易完成'
                    }
                    payment_status = payment_status_map.get(payment_status, payment_status)

                    # 4. 提取日期
                    if create_time and create_time != '\\N':
                        date_id = create_time.split()[0] if ' ' in create_time else create_time
                    else:
                        date_id = '\\N'

                    f.write(f"{payment_id}\t{out_trade_no}\t{order_id}\t{user_id}\t{payment_type}\t{trade_no}\t{total_amount}\t{subject}\t{payment_status}\t{create_time}\t{callback_time}\t{callback_content}\t{date_id}\n")

        # 上传到 HDFS
        os.system(f'{hdfs_cmd} -rm -r /warehouse/gmall/dwd/dwd_payment_info 2>/dev/null')
        os.system(f'{hdfs_cmd} -put {dwd_file} /warehouse/gmall/dwd/dwd_payment_info')

        print(f"支付事实表已创建，共 {len(data)} 条记录")

    except Exception as e:
        print(f"清洗支付事实表时出错: {e}")

def main():
    print("=== DWD 层数据处理 ===")
    print(f"时间: {datetime.now()}")
    print()

    # 清洗订单明细事实表
    clean_order_detail()
    print()

    # 清洗订单事实表
    clean_order_info()
    print()

    # 清洗支付事实表
    clean_payment_info()
    print()

    print("=== DWD 层数据处理完成 ===")

    # 验证 DWD 层数据
    print("\n验证 DWD 层数据:")
    os.system(f'{hdfs_cmd} -ls -R /warehouse/gmall/dwd/')

if __name__ == '__main__':
    main()

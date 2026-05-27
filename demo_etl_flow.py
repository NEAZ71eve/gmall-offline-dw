#!/usr/bin/env python3
import os
from datetime import datetime, timedelta
import random

print("="*80)
print("电商数仓项目 - ETL演示".center(80))
print("="*80)
print()

class ETLDemo:
    def __init__(self):
        self.dim_date_file = '/tmp/dim_date.txt'
        self.dim_user_file = '/tmp/dim_user.txt'
        self.ods_file = '/tmp/ods_data.txt'
        self.dwd_file = '/tmp/dwd_data.txt'
        self.dws_file = '/tmp/dws_data.txt'
        self.ads_file = '/tmp/ads_data.txt'

    def simulate_ods_layer(self):
        """ODS层：原始数据层 - 模拟业务数据"""
        print("【步骤1】ODS层 - 原始数据加载")
        print("-" * 80)
        print("职责：从MySQL业务库同步原始数据，不做任何加工")
        print("存储：Text格式，按天分区")
        print()

        users = [
            ("1", "user001", "张三", "13812340001", "zhangsan@example.com", "1990-01-15", "M", "2024-01-01 10:00:00"),
            ("2", "user002", "李四", "13812340002", "lisi@example.com", "1991-05-20", "F", "2024-01-02 11:30:00"),
            ("3", "user003", "王五", "13812340003", "wangwu@example.com", "1992-08-10", "M", "2024-01-03 09:15:00"),
            ("4", "user004", "赵六", "13812340004", "zhaoliu@example.com", "1993-03-25", "F", "2024-01-04 14:20:00"),
            ("5", "user005", "孙七", "13812340005", "sunqi@example.com", "1994-11-30", "M", "2024-01-05 16:45:00"),
        ]

        orders = [
            ("O001", "1", "2024-01-01 10:30:00", "2999.00", "1002"),
            ("O002", "1", "2024-01-01 15:20:00", "1599.00", "1002"),
            ("O003", "2", "2024-01-02 11:45:00", "3999.00", "1002"),
            ("O004", "3", "2024-01-03 09:30:00", "199.00", "1004"),
            ("O005", "3", "2024-01-03 14:00:00", "599.00", "1003"),
            ("O006", "4", "2024-01-04 16:30:00", "899.00", "1004"),
            ("O007", "5", "2024-01-05 20:15:00", "2599.00", "1002"),
            ("O008", "1", "2024-01-06 10:00:00", "1299.00", "1003"),
            ("O009", "2", "2024-01-07 11:30:00", "799.00", "1004"),
            ("O010", "4", "2024-01-08 14:45:00", "499.00", "1003"),
        ]

        print("[DATA] ODS层数据样本：")
        print()
        print("用户数据 (ods_user_info)：")
        print(f"{'ID':<5} {'登录名':<10} {'姓名':<8} {'手机号':<12} {'邮箱':<25} {'生日':<12} {'性别':<5} {'创建时间'}")
        for user in users:
            print(f"{user[0]:<5} {user[1]:<10} {user[2]:<8} {user[3]:<12} {user[4]:<25} {user[5]:<12} {user[6]:<5} {user[7]}")
        print()
        print(f"[OK] ODS层共加载 {len(users)} 条用户数据")

        print()
        print("订单数据 (ods_order_info)：")
        print(f"{'订单ID':<8} {'用户ID':<8} {'创建时间':<20} {'订单金额':<12} {'订单状态'}")
        for order in orders:
            status_map = {"1001": "未支付", "1002": "已支付", "1003": "已发货", "1004": "已完成", "1005": "已取消"}
            print(f"{order[0]:<8} {order[1]:<8} {order[2]:<20} {order[3]:<12} {status_map.get(order[4], order[4])}")
        print()
        print(f"[OK] ODS层共加载 {len(orders)} 条订单数据")

        return users, orders

    def simulate_dim_layer(self):
        """DIM层：维度层 - 拉链表实现"""
        print()
        print("="*80)
        print("【步骤2】DIM层 - 维度建模")
        print("-" * 80)
        print("职责：存储维度数据，处理缓慢变化维(SCD)，提供统一维度编码")
        print("存储：ORC压缩格式，支持拉链表")
        print()

        print("[DATA] 日期维度表 (dim_time)：")
        print(f"{'日期':<12} {'年':<6} {'月':<6} {'日':<6} {'季度':<6} {'星期':<8} {'是否工作日'}")
        for month in [1, 2, 3]:
            for day in [1, 2, 3]:
                date_str = f"2024-{month:02d}-{day:02d}"
                weekday = datetime(2024, month, day).weekday() + 1
                is_workday = "是" if weekday < 6 else "否"
                print(f"{date_str:<12} 2024   {month:<6} {day:<6} {(month-1)//3+1:<6} 周{weekday:<6} {is_workday}")
        print(f"[OK] 日期维度表已创建 (2020-2026年，共 {365*7} 天)")
        print()

        print("[DATA] 用户维度表 (dim_user) - 拉链表实现：")
        print("拉链：记录用户历史状态变化，start_date 和 end_date 确定有效时间范围")
        print()
        print(f"{'用户ID':<8} {'姓名':<8} {'手机号':<14} {'邮箱':<25} {'开始日期':<12} {'结束日期':<12} {'状态'}")
        print("-" * 100)

        users_scd = [
            ("1", "张三", "138****0001", "zh****@example.com", "2024-01-01", "9999-12-31", "有效"),
            ("2", "李四", "138****0002", "li****@example.com", "2024-01-02", "9999-12-31", "有效"),
            ("3", "王五", "138****0003", "wa****@example.com", "2024-01-03", "9999-12-31", "有效"),
            ("4", "赵六", "138****0004", "zh****@example.com", "2024-01-04", "2024-03-15", "失效"),
            ("5", "孙七", "138****0005", "su****@example.com", "2024-01-05", "9999-12-31", "有效"),
        ]

        for user in users_scd:
            print(f"{user[0]:<8} {user[1]:<8} {user[2]:<14} {user[3]:<25} {user[4]:<12} {user[5]:<12} {user[6]}")
        print()
        print("[INFO] 拉链表特点：")
        print("   * 用户4在2024-03-15失效，记录历史状态")
        print("   * 使用 start_date 和 end_date 确定数据有效范围")
        print("   * 支持历史数据查询和趋势分析")
        print(f"[OK] 用户维度表已创建 (拉链表，共 {len(users_scd)} 条)")
        print()

        print("[DATA] 商品维度表 (dim_sku)：")
        print(f"{'商品ID':<10} {'商品名称':<20} {'品牌':<10} {'一级分类':<10} {'二级分类':<10} {'三级分类':<10}")
        skus = [
            ("SKU001", "iPhone 15 128GB", "Apple", "数码产品", "手机", "智能手机"),
            ("SKU002", "MacBook Pro 14", "Apple", "数码产品", "电脑", "笔记本"),
            ("SKU003", "小米14 256GB", "小米", "数码产品", "手机", "智能手机"),
            ("SKU004", "AirPods Pro", "Apple", "数码产品", "配件", "耳机"),
        ]
        for sku in skus:
            print(f"{sku[0]:<10} {sku[1]:<20} {sku[2]:<10} {sku[3]:<10} {sku[4]:<10} {sku[5]:<10}")
        print(f"[OK] 商品维度表已创建 (共 {len(skus)} 条)")

    def simulate_dwd_layer(self):
        """DWD层：明细数据层 - 数据清洗"""
        print()
        print("="*80)
        print("【步骤3】DWD层 - 数据清洗与脱敏")
        print("-" * 80)
        print("职责：数据清洗(去重、过滤脏数据)、数据脱敏、格式统一")
        print("存储：ORC压缩格式事务表")
        print()

        print("[RULE] 清洗规则：")
        print("   1. 过滤无效订单（订单ID为空、金额异常）")
        print("   2. 标准化订单状态（1001->未支付，1002->已支付...）")
        print("   3. 标准化支付方式（1->在线支付，2->货到付款...）")
        print("   4. 手机号脱敏（138****0001）")
        print("   5. 邮箱脱敏（zh****@example.com）")
        print()

        print("[DATA] 清洗后的订单明细事实表 (dwd_order_detail)：")
        print(f"{'明细ID':<8} {'订单ID':<8} {'商品ID':<10} {'商品名称':<20} {'数量':<6} {'金额':<12} {'来源类型':<10}")
        details = [
            ("D001", "O001", "SKU001", "iPhone 15 128GB", "1", "2999.00", "购物车"),
            ("D002", "O002", "SKU004", "AirPods Pro", "1", "1599.00", "直接购买"),
            ("D003", "O003", "SKU002", "MacBook Pro 14", "1", "3999.00", "购物车"),
            ("D004", "O004", "SKU003", "小米14 256GB", "1", "199.00", "活动"),
            ("D005", "O005", "SKU001", "iPhone 15 128GB", "1", "599.00", "购物车"),
        ]
        for d in details:
            print(f"{d[0]:<8} {d[1]:<8} {d[2]:<10} {d[3]:<20} {d[4]:<6} {d[5]:<12} {d[6]:<10}")
        print(f"[OK] DWD层清洗完成 (共 {len(details)} 条有效明细)")

    def simulate_dws_layer(self):
        """DWS层：汇总数据层 - 轻度聚合"""
        print()
        print("="*80)
        print("【步骤4】DWS层 - 数据汇总")
        print("-" * 80)
        print("职责：按主题轻度聚合（用户、订单、商品等），提供跨主题关联")
        print("存储：ORC压缩格式，按天/周/月聚合")
        print()

        print("[DATA] GMV统计汇总表 (dws_gmv_stats)：")
        print(f"{'日期':<12} {'GMV':<15} {'订单数':<10} {'下单人数':<12} {'客单价':<12} {'人均消费':<12}")
        gmv_data = [
            ("2024-01-01", "4598.00", "2", "1", "2299.00", "4598.00"),
            ("2024-01-02", "3999.00", "1", "1", "3999.00", "3999.00"),
            ("2024-01-03", "798.00", "2", "1", "399.00", "798.00"),
            ("2024-01-04", "899.00", "1", "1", "899.00", "899.00"),
            ("2024-01-05", "2599.00", "1", "1", "2599.00", "2599.00"),
            ("2024-01-06", "1299.00", "1", "1", "1299.00", "1299.00"),
            ("2024-01-07", "799.00", "1", "1", "799.00", "799.00"),
        ]

        total_gmv = 0
        total_orders = 0
        total_users = set()

        for gmv in gmv_data:
            print(f"{gmv[0]:<12} {gmv[1]:<15} {gmv[2]:<10} {gmv[3]:<12} {gmv[4]:<12} {gmv[5]:<12}")
            total_gmv += float(gmv[1])
            total_orders += int(gmv[2])
            total_users.add(gmv[3])

        print()
        print("[DATA] 用户统计汇总表 (dws_user_stats)：")
        print(f"{'用户ID':<8} {'订单数':<10} {'消费总额':<12} {'平均订单金额':<15} {'首次购买':<12} {'最后购买':<12}")
        user_stats = [
            ("1", "3", "5897.00", "1965.67", "2024-01-01", "2024-01-06"),
            ("2", "2", "4798.00", "2399.00", "2024-01-02", "2024-01-07"),
            ("3", "2", "798.00", "399.00", "2024-01-03", "2024-01-03"),
            ("4", "2", "1398.00", "699.00", "2024-01-04", "2024-01-08"),
            ("5", "1", "2599.00", "2599.00", "2024-01-05", "2024-01-05"),
        ]
        for user in user_stats:
            print(f"{user[0]:<8} {user[1]:<10} {user[2]:<12} {user[3]:<15} {user[4]:<12} {user[5]:<12}")

        print()
        print("[STATS] 汇总统计：")
        print(f"   * 总GMV：{total_gmv:.2f} 元")
        print(f"   * 总订单数：{total_orders} 单")
        print(f"   * 活跃用户数：{len(total_users)} 人")
        print(f"   * 平均客单价：{total_gmv/total_orders:.2f} 元")
        print(f"[OK] DWS层汇总完成")

    def simulate_ads_layer(self):
        """ADS层：应用数据层 - 最终报表"""
        print()
        print("="*80)
        print("【步骤5】ADS层 - 应用报表生成")
        print("-" * 80)
        print("职责：计算最终指标，为报表和大屏提供数据")
        print("存储：ORC格式，面向业务指标")
        print()

        print("[DATA] GMV日报表 (ads_gmv_day)：")
        print(f"{'日期':<12} {'周期':<10} {'GMV':<15} {'订单数':<10} {'下单人数':<12} {'支付金额':<15} {'支付人数':<10}")
        ads_data = [
            ("2024-01-08", "1天", "15191.00", "10", "5", "14192.00", "4"),
            ("2024-01-08", "7天", "15191.00", "10", "5", "14192.00", "4"),
            ("2024-01-08", "30天", "15191.00", "10", "5", "14192.00", "4"),
        ]
        for ads in ads_data:
            print(f"{ads[0]:<12} {ads[1]:<10} {ads[2]:<15} {ads[3]:<10} {ads[4]:<12} {ads[5]:<15} {ads[6]:<10}")
        print()

        print("[DATA] 商品销售排行表 (ads_sku_sales_rank)：")
        print(f"{'排名':<6} {'商品ID':<10} {'商品名称':<20} {'销量':<8} {'销售额':<12}")
        sku_sales = [
            ("1", "SKU001", "iPhone 15 128GB", "2", "3598.00"),
            ("2", "SKU002", "MacBook Pro 14", "1", "3999.00"),
            ("3", "SKU004", "AirPods Pro", "1", "1599.00"),
            ("4", "SKU003", "小米14 256GB", "1", "199.00"),
        ]
        for sku in sku_sales:
            print(f"{sku[0]:<6} {sku[1]:<10} {sku[2]:<20} {sku[3]:<8} {sku[4]:<12}")
        print()

        print("[DATA] 用户留存表 (ads_user_retention)：")
        print(f"{'统计日期':<12} {'注册日期':<12} {'留存天数':<10} {'新增用户':<10} {'留存用户':<10} {'留存率'}")
        retention = [
            ("2024-01-08", "2024-01-01", "7天", "1", "1", "100%"),
            ("2024-01-08", "2024-01-02", "6天", "1", "1", "100%"),
            ("2024-01-08", "2024-01-03", "5天", "1", "1", "100%"),
            ("2024-01-08", "2024-01-04", "4天", "1", "0", "0%"),
            ("2024-01-08", "2024-01-05", "3天", "1", "1", "100%"),
        ]
        for r in retention:
            print(f"{r[0]:<12} {r[1]:<12} {r[2]:<10} {r[3]:<10} {r[4]:<10} {r[5]}")
        print()

        print("[DATA] 转化率分析表 (ads_conversion_rate)：")
        print(f"{'日期':<12} {'周期':<8} {'访问数':<10} {'加购数':<10} {'下单数':<10} {'支付数':<10} {'访问->加购':<12} {'加购->下单':<12} {'下单->支付'}")
        conversion = [
            ("2024-01-08", "1天", "1000", "300", "150", "120", "30.00%", "50.00%", "80.00%"),
            ("2024-01-08", "7天", "5000", "1500", "750", "600", "30.00%", "50.00%", "80.00%"),
        ]
        for c in conversion:
            print(f"{c[0]:<12} {c[1]:<8} {c[2]:<10} {c[3]:<10} {c[4]:<10} {c[5]:<10} {c[6]:<12} {c[7]:<12} {c[8]}")
        print()

        print(f"[OK] ADS层报表生成完成")
        print(f"[OK] 可对接 Apache Superset 进行可视化展示")

    def run_full_etl(self):
        """运行完整ETL流程"""
        print()
        print("="*80)
        print("开始运行电商数仓ETL流程".center(80))
        print("="*80)
        print()

        self.simulate_ods_layer()
        self.simulate_dim_layer()
        self.simulate_dwd_layer()
        self.simulate_dws_layer()
        self.simulate_ads_layer()

        print()
        print("="*80)
        print("ETL流程执行完成！".center(80))
        print("="*80)
        print()

        print("[FILES] 生成的数据文件：")
        print("   * ODS层：/warehouse/gmall/ods/")
        print("   * DIM层：/warehouse/gmall/dim/")
        print("   * DWD层：/warehouse/gmall/dwd/")
        print("   * DWS层：/warehouse/gmall/dws/")
        print("   * ADS层：/warehouse/gmall/ads/")
        print()
        print("[NEXT] 下一步：")
        print("   1. 使用 DolphinScheduler 配置定时调度任务")
        print("   2. 使用 Apache Superset 连接 Hive 创建可视化报表")
        print("   3. 使用 DataX 进行增量数据同步")
        print("   4. 使用 Maxwell + Kafka 实现实时数据采集")

if __name__ == '__main__':
    demo = ETLDemo()
    demo.run_full_etl()

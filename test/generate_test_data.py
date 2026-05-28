#!/usr/bin/env python3
"""
模拟电商数据生成脚本
生成测试用用户、订单、商品、支付等数据
"""

import random
import uuid
from datetime import datetime, timedelta
from typing import List, Dict
import csv
import os

class EcommerceDataGenerator:
    def __init__(self, output_dir: str = '/tmp/gmall_data'):
        self.output_dir = output_dir
        self.ensure_dir()

        # 初始化数据池
        self.users = []
        self.products = []
        self.categories = []

        # 省份数据
        self.provinces = [
            ('北京', '华北'), ('天津', '华北'), ('河北', '华北'), ('山西', '华北'), ('内蒙古', '华北'),
            ('辽宁', '东北'), ('吉林', '东北'), ('黑龙江', '东北'),
            ('上海', '华东'), ('江苏', '华东'), ('浙江', '华东'), ('安徽', '华东'), ('福建', '华东'), ('江西', '华东'), ('山东', '华东'),
            ('河南', '华中'), ('湖北', '华中'), ('湖南', '华中'),
            ('广东', '华南'), ('广西', '华南'), ('海南', '华南'),
            ('重庆', '西南'), ('四川', '西南'), ('贵州', '西南'), ('云南', '西南'), ('西藏', '西南'),
            ('陕西', '西北'), ('甘肃', '西北'), ('青海', '西北'), ('宁夏', '西北'), ('新疆', '西北'),
            ('台湾', '港澳台'), ('香港', '港澳台'), ('澳门', '港澳台')
        ]

        # 品牌数据
        self.brands = [
            ('B001', 'Apple'), ('B002', 'Samsung'), ('B003', 'Huawei'),
            ('B004', 'Xiaomi'), ('B005', 'OPPO'), ('B006', 'VIVO'),
            ('B007', 'Nike'), ('B008', 'Adidas'), ('B009', '安踏'),
            ('B010', '雅诗兰黛'), ('B011', '兰蔻'), ('B012', 'SK-II')
        ]

        # 商品分类
        self.category1_list = ['数码产品', '服装鞋帽', '美妆护肤', '食品饮料', '家居用品']
        self.category2 = {
            '数码产品': ['手机', '电脑', '平板', '耳机', '相机'],
            '服装鞋帽': ['男装', '女装', '童装', '运动鞋', '休闲鞋'],
            '美妆护肤': ['护肤品', '彩妆', '香水', '美容工具'],
            '食品饮料': ['零食', '饮料', '生鲜', '粮油'],
            '家居用品': ['家具', '家纺', '厨具', '卫浴']
        }

    def ensure_dir(self):
        """确保输出目录存在"""
        if not os.path.exists(self.output_dir):
            os.makedirs(self.output_dir)

    def generate_users(self, count: int = 1000) -> List[Dict]:
        """生成用户数据"""
        print(f"生成 {count} 条用户数据...")

        users = []
        for i in range(count):
            user_id = f'U{str(i+1).zfill(8)}'
            user = {
                'id': user_id,
                'login_name': f'user_{i+1}',
                'nick_name': f'用户{i+1}',
                'name': f'姓名{i+1}',
                'phone_num': f'138{random.randint(10000000, 99999999)}',
                'email': f'user{i+1}@example.com',
                'user_level': random.choice(['1', '2', '3', '4', '5']),
                'birthday': f'19{random.randint(70, 99)}-{random.randint(1,12):02d}-{random.randint(1,28):02d}',
                'gender': random.choice(['M', 'F']),
                'create_time': (datetime.now() - timedelta(days=random.randint(1, 365))).strftime('%Y-%m-%d %H:%M:%S'),
                'status': '1'
            }
            users.append(user)
            self.users.append(user)

        return users

    def generate_products(self, count: int = 500) -> List[Dict]:
        """生成商品数据"""
        print(f"生成 {count} 条商品数据...")

        products = []
        product_id = 1

        for brand_id, brand_name in self.brands:
            for category1 in self.category1_list:
                category2_list = self.category2.get(category1, [])

                for category2 in category2_list:
                    # 每个二级分类生成多个商品
                    num_products = random.randint(5, 15)

                    for _ in range(num_products):
                        sku_id = f'SKU{str(product_id).zfill(6)}'
                        price = round(random.uniform(9.9, 9999.9), 2)

                        product = {
                            'id': sku_id,
                            'spu_id': f'SPU{str(product_id // 3).zfill(6)}',
                            'sku_name': f'{brand_name} {category2} 商品{product_id}',
                            'price': price,
                            'tm_id': brand_id,
                            'tm_name': brand_name,
                            'category1_id': f'C1{random.randint(1, len(self.category1_list))}',
                            'category1_name': category1,
                            'category2_id': f'C2{random.randint(1, 20)}',
                            'category2_name': category2,
                            'category3_id': f'C3{random.randint(1, 100)}',
                            'category3_name': f'{category2}子类',
                            'create_time': (datetime.now() - timedelta(days=random.randint(1, 180))).strftime('%Y-%m-%d %H:%M:%S')
                        }
                        products.append(product)
                        self.products.append(product)
                        product_id += 1

        return products

    def generate_orders(self, users: List[Dict], products: List[Dict], count: int = 5000) -> List[Dict]:
        """生成订单数据"""
        print(f"生成 {count} 条订单数据...")

        orders = []
        order_statuses = ['1001', '1002', '1003', '1004', '1005']  # 未支付、已支付、已发货、已完成、已取消
        payment_ways = ['1', '2', '3']  # 在线支付、货到付款、优惠券

        province_id = 1
        for i in range(count):
            order_id = f'O{str(i+1).zfill(10)}'
            user = random.choice(users)

            # 生成订单时间
            order_time = datetime.now() - timedelta(days=random.randint(0, 30), hours=random.randint(0, 23))
            province_id = (province_id % len(self.provinces)) + 1

            order = {
                'id': order_id,
                'user_id': user['id'],
                'order_id': order_id,
                'province_id': f'P{str(province_id).zfill(3)}',
                'order_status': random.choice(order_statuses),
                'payment_way': random.choice(payment_ways),
                'delivery_address': f'{self.provinces[province_id-1][0]}某市某区某街道',
                'total_amount': round(random.uniform(10, 5000), 2),
                'benefit_reduce_amount': round(random.uniform(0, 100), 2),
                'feight_fee': round(random.uniform(0, 20), 2),
                'create_time': order_time.strftime('%Y-%m-%d %H:%M:%S'),
                'operate_time': (order_time + timedelta(hours=random.randint(1, 48))).strftime('%Y-%m-%d %H:%M:%S')
            }
            orders.append(order)

        return orders

    def generate_order_details(self, orders: List[Dict], products: List[Dict], count: int = 10000) -> List[Dict]:
        """生成订单明细数据"""
        print(f"生成 {count} 条订单明细数据...")

        details = []
        detail_id = 1

        for order in orders[:min(len(orders), count // 2)]:  # 每单平均2个商品
            num_items = random.randint(1, 5)

            for _ in range(num_items):
                product = random.choice(products)
                sku_num = random.randint(1, 3)

                detail = {
                    'id': f'D{str(detail_id).zfill(10)}',
                    'order_id': order['order_id'],
                    'sku_id': product['id'],
                    'sku_name': product['sku_name'],
                    'img_url': f'/images/{product["id"]}.jpg',
                    'order_price': product['price'],
                    'sku_num': sku_num,
                    'create_time': order['create_time'],
                    'source_type': random.choice(['APP', 'PC', 'H5']),
                    'source_id': f'SRC{random.randint(1000, 9999)}'
                }
                details.append(detail)
                detail_id += 1

        return details

    def save_to_csv(self, data: List[Dict], filename: str):
        """保存数据到 CSV 文件"""
        if not data:
            return

        filepath = os.path.join(self.output_dir, filename)
        keys = data[0].keys()

        with open(filepath, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=keys)
            writer.writeheader()
            writer.writerows(data)

        print(f"  [OK] 已保存到 {filepath}（{len(data)} 条记录）")

    def run(self, num_users=1000, num_products=500, num_orders=5000):
        """运行数据生成"""
        print("="*80)
        print("              电商模拟数据生成工具")
        print("="*80)
        print(f"\n开始时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"输出目录: {self.output_dir}")

        # 生成各类数据
        users = self.generate_users(num_users)
        products = self.generate_products(num_products)
        orders = self.generate_orders(users, products, num_orders)
        order_details = self.generate_order_details(orders, products, num_orders * 2)

        # 保存数据
        print("\n保存数据文件：")
        self.save_to_csv(users, 'user_info.csv')
        self.save_to_csv(products, 'sku_info.csv')
        self.save_to_csv(orders, 'order_info.csv')
        self.save_to_csv(order_details, 'order_detail.csv')

        print("\n" + "="*80)
        print("                       数据生成完成！")
        print("="*80)
        print(f"\n结束时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"\n生成统计：")
        print(f"  - 用户数据: {len(users)} 条")
        print(f"  - 商品数据: {len(products)} 条")
        print(f"  - 订单数据: {len(orders)} 条")
        print(f"  - 订单明细: {len(order_details)} 条")
        print(f"\n数据文件位置: {self.output_dir}/")

if __name__ == '__main__':
    generator = EcommerceDataGenerator()
    generator.run(num_users=1000, num_products=500, num_orders=5000)

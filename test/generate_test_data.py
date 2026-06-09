#!/usr/bin/env python3
"""
电商模拟数据生成脚本 - 完整版
生成测试用用户、订单、商品、支付、退款、优惠券、活动等数据
支持输出到CSV或直接导入MySQL
"""

import random
import uuid
from datetime import datetime, timedelta
from typing import List, Dict
import csv
import os
import argparse

class EcommerceDataGenerator:
    def __init__(self, output_dir: str = '/tmp/gmall_data'):
        self.output_dir = output_dir
        self.ensure_dir()

        # 初始化数据池
        self.users = []
        self.products = []
        self.orders = []
        self.order_details = []

        # 省份数据
        self.provinces = [
            ('P001', '北京', '华北'), ('P002', '天津', '华北'), ('P003', '河北', '华北'), 
            ('P004', '山西', '华北'), ('P005', '内蒙古', '华北'),
            ('P006', '辽宁', '东北'), ('P007', '吉林', '东北'), ('P008', '黑龙江', '东北'),
            ('P009', '上海', '华东'), ('P010', '江苏', '华东'), ('P011', '浙江', '华东'), 
            ('P012', '安徽', '华东'), ('P013', '福建', '华东'), ('P014', '江西', '华东'), ('P015', '山东', '华东'),
            ('P016', '河南', '华中'), ('P017', '湖北', '华中'), ('P018', '湖南', '华中'),
            ('P019', '广东', '华南'), ('P020', '广西', '华南'), ('P021', '海南', '华南'),
            ('P022', '重庆', '西南'), ('P023', '四川', '西南'), ('P024', '贵州', '西南'), 
            ('P025', '云南', '西南'), ('P026', '西藏', '西南'),
            ('P027', '陕西', '西北'), ('P028', '甘肃', '西北'), ('P029', '青海', '西北'), 
            ('P030', '宁夏', '西北'), ('P031', '新疆', '西北'),
            ('P032', '台湾', '港澳台'), ('P033', '香港', '港澳台'), ('P034', '澳门', '港澳台')
        ]

        # 品牌数据
        self.brands = [
            ('TM001', 'Apple'), ('TM002', 'Samsung'), ('TM003', 'Huawei'),
            ('TM004', 'Xiaomi'), ('TM005', 'OPPO'), ('TM006', 'VIVO'),
            ('TM007', 'Nike'), ('TM008', 'Adidas'), ('TM009', '安踏'),
            ('TM010', '雅诗兰黛'), ('TM011', '兰蔻'), ('TM012', 'SK-II'),
            ('TM013', '海尔'), ('TM014', '美的'), ('TM015', '格力'),
            ('TM016', '蒙牛'), ('TM017', '伊利'), ('TM018', '农夫山泉')
        ]

        # 商品分类
        self.category1_list = ['数码产品', '服装鞋帽', '美妆护肤', '食品饮料', '家居用品']
        self.category2 = {
            '数码产品': ['手机', '电脑', '平板', '耳机', '相机', '智能手表'],
            '服装鞋帽': ['男装', '女装', '童装', '运动鞋', '休闲鞋', '包包'],
            '美妆护肤': ['护肤品', '彩妆', '香水', '美容工具', '身体护理'],
            '食品饮料': ['零食', '饮料', '生鲜', '粮油', '酒水'],
            '家居用品': ['家具', '家纺', '厨具', '卫浴', '家电']
        }

        # 支付方式
        self.payment_types = [('1', '支付宝'), ('2', '微信支付'), ('3', '银行卡'), ('4', '货到付款')]

        # 订单状态
        self.order_statuses = [
            ('1001', '未支付'), ('1002', '已支付'), ('1003', '已发货'), 
            ('1004', '已完成'), ('1005', '已取消'), ('1006', '已退款')
        ]

        # 退款类型
        self.refund_types = [('1', '退货退款'), ('2', '仅退款'), ('3', '换货')]

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
            phone_prefix = random.choice(['138', '139', '158', '159', '188', '189'])
            user = {
                'id': user_id,
                'login_name': f'user_{user_id}',
                'nick_name': f'快乐购物{i+1}',
                'name': f'用户{i+1}',
                'phone_num': f'{phone_prefix}{random.randint(10000000, 99999999)}',
                'email': f'user{i+1}@gmall.com',
                'head_img': f'http://img.gmall.com/{user_id}.jpg',
                'user_level': str(random.randint(1, 5)),
                'birthday': f'{1980 + random.randint(0, 40)}-{random.randint(1,12):02d}-{random.randint(1,28):02d}',
                'gender': random.choice(['M', 'F']),
                'create_time': (datetime.now() - timedelta(days=random.randint(1, 365))).strftime('%Y-%m-%d %H:%M:%S'),
                'operate_time': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
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
                    num_products = random.randint(3, 10)

                    for _ in range(num_products):
                        sku_id = f'SKU{str(product_id).zfill(6)}'
                        spu_id = f'SPU{str((product_id - 1) // 3 + 1).zfill(6)}'
                        price = round(random.uniform(9.9, 9999.9), 2)
                        c1_id = f'C1{str(self.category1_list.index(category1) + 1).zfill(2)}'
                        c2_id = f'C2{str(self.category1_list.index(category1) * 10 + category2_list.index(category2) + 1).zfill(3)}'
                        c3_id = f'C3{str(product_id).zfill(4)}'

                        product = {
                            'id': sku_id,
                            'spu_id': spu_id,
                            'sku_name': f'{brand_name} {category1} {category2} 商品{product_id}',
                            'sku_desc': f'{brand_name} {category2}，品质保证',
                            'price': price,
                            'weight': round(random.uniform(0.1, 10), 2),
                            'tm_id': brand_id,
                            'tm_name': brand_name,
                            'category1_id': c1_id,
                            'category1_name': category1,
                            'category2_id': c2_id,
                            'category2_name': category2,
                            'category3_id': c3_id,
                            'category3_name': f'{category2}细分{random.randint(1, 10)}',
                            'create_time': (datetime.now() - timedelta(days=random.randint(1, 180))).strftime('%Y-%m-%d %H:%M:%S')
                        }
                        products.append(product)
                        self.products.append(product)
                        product_id += 1
                        if product_id > count:
                            return products

        return products

    def generate_orders(self, count: int = 5000) -> List[Dict]:
        """生成订单数据"""
        print(f"生成 {count} 条订单数据...")

        orders = []
        payment_ways = ['1', '2', '3']

        for i in range(count):
            order_id = f'O{str(i+1).zfill(10)}'
            user = random.choice(self.users)
            province = random.choice(self.provinces)
            status = random.choices(
                ['1001', '1002', '1003', '1004', '1005', '1006'],
                weights=[5, 30, 25, 30, 5, 5]
            )[0]
            
            order_time = datetime.now() - timedelta(days=random.randint(0, 30), hours=random.randint(0, 23))

            order = {
                'id': order_id,
                'consignee': f'{user["name"]}',
                'consignee_tel': user['phone_num'],
                'total_amount': round(random.uniform(10, 5000), 2),
                'order_status': status,
                'user_id': user['id'],
                'payment_way': random.choice(payment_ways),
                'delivery_address': f'{province[1]}省某市某区某街道{random.randint(1, 999)}号',
                'order_comment': random.choice(['', '尽快发货', '礼品包装', '周末配送']),
                'out_trade_no': f'T{str(random.randint(100000000000, 999999999999))}',
                'trade_body': '电商订单',
                'create_time': order_time.strftime('%Y-%m-%d %H:%M:%S'),
                'operate_time': (order_time + timedelta(hours=random.randint(1, 48))).strftime('%Y-%m-%d %H:%M:%S'),
                'expire_time': (order_time + timedelta(hours=24)).strftime('%Y-%m-%d %H:%M:%S'),
                'refund_time': (order_time + timedelta(hours=random.randint(2, 72))).strftime('%Y-%m-%d %H:%M:%S') if status in ['1005', '1006'] else '',
                'refund_status': '1' if status in ['1005', '1006'] else '0',
                'province_id': province[0]
            }
            orders.append(order)
            self.orders.append(order)

        return orders

    def generate_order_details(self, count: int = 10000) -> List[Dict]:
        """生成订单明细数据"""
        print(f"生成 {count} 条订单明细数据...")

        details = []
        detail_id = 1

        for order in self.orders[:min(len(self.orders), count // 2)]:
            num_items = random.randint(1, 5)

            for _ in range(num_items):
                product = random.choice(self.products)
                sku_num = random.randint(1, 3)
                original_amount = round(product['price'] * sku_num, 2)
                activity_reduce = round(random.uniform(0, original_amount * 0.3), 2)
                coupon_reduce = round(random.uniform(0, original_amount * 0.2), 2)
                final_amount = round(original_amount - activity_reduce - coupon_reduce, 2)

                detail = {
                    'id': f'D{str(detail_id).zfill(10)}',
                    'order_id': order['id'],
                    'sku_id': product['id'],
                    'sku_name': product['sku_name'],
                    'img_url': f'http://img.gmall.com/{product["id"]}.jpg',
                    'order_price': product['price'],
                    'sku_num': sku_num,
                    'original_amount': original_amount,
                    'activity_reduce': activity_reduce,
                    'coupon_reduce': coupon_reduce,
                    'final_amount': max(final_amount, 0),
                    'create_time': order['create_time'],
                    'source_type': random.choice(['APP', 'PC', 'H5', 'WAP']),
                    'source_id': f'SRC{random.randint(1000, 9999)}',
                    'user_id': order['user_id'],
                    'province_id': order['province_id']
                }
                details.append(detail)
                self.order_details.append(detail)
                detail_id += 1
                if detail_id > count:
                    return details

        return details

    def generate_payment_info(self, count: int = 3000) -> List[Dict]:
        """生成支付数据"""
        print(f"生成 {count} 条支付数据...")

        payments = []
        paid_orders = [o for o in self.orders if o['order_status'] in ['1002', '1003', '1004']]
        
        for i, order in enumerate(paid_orders[:count]):
            payment_id = f'P{str(i+1).zfill(10)}'
            payment = {
                'id': payment_id,
                'out_trade_no': order['out_trade_no'],
                'order_id': order['id'],
                'user_id': order['user_id'],
                'payment_type': order['payment_way'],
                'trade_no': f'TRN{str(random.randint(100000000000, 999999999999))}',
                'total_amount': order['total_amount'],
                'subject': '订单支付',
                'payment_status': '1',
                'create_time': order['create_time'],
                'callback_time': (datetime.strptime(order['create_time'], '%Y-%m-%d %H:%M:%S') + timedelta(minutes=random.randint(1, 10))).strftime('%Y-%m-%d %H:%M:%S')
            }
            payments.append(payment)

        return payments

    def generate_refund_info(self, count: int = 500) -> List[Dict]:
        """生成退款数据"""
        print(f"生成 {count} 条退款数据...")

        refunds = []
        refund_orders = [o for o in self.orders if o['order_status'] in ['1005', '1006']]
        
        for i, order in enumerate(refund_orders[:min(count, len(refund_orders))]):
            refund_id = f'R{str(i+1).zfill(10)}'
            details = [d for d in self.order_details if d['order_id'] == order['id']]
            sku = random.choice(details) if details else {'sku_id': 'SKU000001', 'sku_num': 1, 'final_amount': order['total_amount']}

            refund = {
                'id': refund_id,
                'order_id': order['id'],
                'sku_id': sku['sku_id'],
                'refund_type': random.choice(['1', '2', '3']),
                'refund_num': random.randint(1, sku.get('sku_num', 1)),
                'refund_amount': round(order['total_amount'] * random.uniform(0.5, 1), 2),
                'refund_reason_type': random.choice(['1', '2', '3', '4', '5']),
                'refund_reason_txt': random.choice([
                    '商品质量问题', '尺寸不合适', '颜色不符', '重复下单', '七天无理由退货'
                ]),
                'refund_status': '1',
                'create_time': order['refund_time'] or datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                'operate_time': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                'user_id': order['user_id']
            }
            refunds.append(refund)

        return refunds

    def generate_coupon_info(self, count: int = 100) -> List[Dict]:
        """生成优惠券数据"""
        print(f"生成 {count} 条优惠券数据...")

        coupons = []
        coupon_types = ['1', '2', '3']  # 满减券、折扣券、无门槛券

        for i in range(count):
            coupon_id = f'C{str(i+1).zfill(6)}'
            coupon_type = random.choice(coupon_types)
            
            if coupon_type == '1':  # 满减券
                discount_amount = round(random.uniform(10, 200), 2)
                threshold_amount = discount_amount * random.randint(3, 10)
            elif coupon_type == '2':  # 折扣券
                discount_amount = round(random.uniform(10, 100), 2)
                threshold_amount = round(random.uniform(50, 500), 2)
            else:  # 无门槛券
                discount_amount = round(random.uniform(5, 50), 2)
                threshold_amount = 0

            coupon = {
                'id': coupon_id,
                'coupon_name': f'优惠券{i+1}',
                'coupon_type': coupon_type,
                'coupon_desc': f'满{threshold_amount}减{discount_amount}',
                'discount_amount': discount_amount,
                'threshold_amount': threshold_amount,
                'start_time': (datetime.now() - timedelta(days=random.randint(0, 7))).strftime('%Y-%m-%d 00:00:00'),
                'end_time': (datetime.now() + timedelta(days=random.randint(7, 30))).strftime('%Y-%m-%d 23:59:59'),
                'create_time': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            }
            coupons.append(coupon)

        return coupons

    def generate_coupon_use(self, count: int = 500) -> List[Dict]:
        """生成优惠券使用数据"""
        print(f"生成 {count} 条优惠券使用数据...")

        uses = []
        coupon_ids = [f'C{str(i+1).zfill(6)}' for i in range(100)]

        for i in range(count):
            use_id = f'CU{str(i+1).zfill(10)}'
            coupon_id = random.choice(coupon_ids)
            user = random.choice(self.users)
            order = random.choice([o for o in self.orders if o['order_status'] not in ['1001', '1005']])

            use = {
                'id': use_id,
                'coupon_id': coupon_id,
                'user_id': user['id'],
                'order_id': order['id'] if random.random() > 0.3 else '',
                'coupon_status': random.choice(['1', '2', '3']),  # 未使用、已使用、已过期
                'create_time': (datetime.now() - timedelta(days=random.randint(0, 14))).strftime('%Y-%m-%d %H:%M:%S'),
                'used_time': order['create_time'] if random.random() > 0.5 else '',
                'expire_time': (datetime.now() + timedelta(days=random.randint(1, 30))).strftime('%Y-%m-%d %H:%M:%S')
            }
            uses.append(use)

        return uses

    def generate_activity_info(self, count: int = 20) -> List[Dict]:
        """生成活动数据"""
        print(f"生成 {count} 条活动数据...")

        activities = []
        activity_types = ['1', '2', '3', '4']  # 满减、折扣、秒杀、拼团

        for i in range(count):
            activity_id = f'A{str(i+1).zfill(6)}'
            activity_type = random.choice(activity_types)

            activity = {
                'id': activity_id,
                'activity_name': random.choice([
                    '双十一特惠', '618大促', '年货节', '会员日', 
                    '品牌日', '新品首发', '清仓特卖', '限时秒杀'
                ]),
                'activity_type': activity_type,
                'activity_desc': '限时优惠活动',
                'start_time': (datetime.now() - timedelta(days=random.randint(0, 7))).strftime('%Y-%m-%d 00:00:00'),
                'end_time': (datetime.now() + timedelta(days=random.randint(1, 14))).strftime('%Y-%m-%d 23:59:59'),
                'create_time': (datetime.now() - timedelta(days=random.randint(1, 7))).strftime('%Y-%m-%d %H:%M:%S')
            }
            activities.append(activity)

        return activities

    def generate_activity_order(self, count: int = 1000) -> List[Dict]:
        """生成活动订单关联数据"""
        print(f"生成 {count} 条活动订单关联数据...")

        activity_orders = []
        activity_ids = [f'A{str(i+1).zfill(6)}' for i in range(20)]

        for i in range(count):
            ao_id = f'AO{str(i+1).zfill(10)}'
            activity_id = random.choice(activity_ids)
            order = random.choice([o for o in self.orders if o['order_status'] not in ['1001', '1005']])

            activity_order = {
                'id': ao_id,
                'activity_id': activity_id,
                'order_id': order['id'],
                'create_time': order['create_time'],
                'user_id': order['user_id']
            }
            activity_orders.append(activity_order)

        return activity_orders

    def generate_comment_info(self, count: int = 1000) -> List[Dict]:
        """生成评论数据"""
        print(f"生成 {count} 条评论数据...")

        comments = []
        stars = ['1', '2', '3', '4', '5']

        for i in range(count):
            comment_id = f'CM{str(i+1).zfill(10)}'
            user = random.choice(self.users)
            product = random.choice(self.products)
            order = random.choice([o for o in self.orders if o['order_status'] == '1004'])

            comment = {
                'id': comment_id,
                'user_id': user['id'],
                'sku_id': product['id'],
                'order_id': order['id'],
                'appraisal_star': random.choices(stars, weights=[5, 5, 10, 30, 50])[0],
                'ip_opt': f'{random.randint(1, 255)}.{random.randint(0, 255)}.{random.randint(0, 255)}.{random.randint(1, 255)}',
                'create_time': (datetime.now() - timedelta(days=random.randint(1, 7))).strftime('%Y-%m-%d %H:%M:%S'),
                'appraise': random.choice([
                    '非常好！', '质量不错', '物有所值', '一般般', '不太满意',
                    '发货快，包装好', '商品与描述一致', '会回购'
                ])
            }
            comments.append(comment)

        return comments

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

    def run(self, num_users=1000, num_products=500, num_orders=5000, output_all=True):
        """运行数据生成"""
        print("="*80)
        print("              电商模拟数据生成工具 - 完整版")
        print("="*80)
        print(f"\n开始时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"输出目录: {self.output_dir}")

        # 生成各类数据
        users = self.generate_users(num_users)
        products = self.generate_products(num_products)
        orders = self.generate_orders(num_orders)
        order_details = self.generate_order_details(num_orders * 2)

        # 保存基础数据
        print("\n保存基础数据文件：")
        self.save_to_csv(users, 'user_info.csv')
        self.save_to_csv(products, 'sku_info.csv')
        self.save_to_csv(orders, 'order_info.csv')
        self.save_to_csv(order_details, 'order_detail.csv')

        # 如果需要生成所有数据
        if output_all:
            payments = self.generate_payment_info(int(num_orders * 0.6))
            refunds = self.generate_refund_info(int(num_orders * 0.1))
            coupons = self.generate_coupon_info(100)
            coupon_uses = self.generate_coupon_use(int(num_orders * 0.2))
            activities = self.generate_activity_info(20)
            activity_orders = self.generate_activity_order(int(num_orders * 0.3))
            comments = self.generate_comment_info(int(num_orders * 0.3))

            print("\n保存扩展数据文件：")
            self.save_to_csv(payments, 'payment_info.csv')
            self.save_to_csv(refunds, 'order_refund_info.csv')
            self.save_to_csv(coupons, 'coupon_info.csv')
            self.save_to_csv(coupon_uses, 'coupon_use.csv')
            self.save_to_csv(activities, 'activity_info.csv')
            self.save_to_csv(activity_orders, 'activity_order.csv')
            self.save_to_csv(comments, 'comment_info.csv')

        print("\n" + "="*80)
        print("                       数据生成完成！")
        print("="*80)
        print(f"\n结束时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"\n生成统计：")
        print(f"  - 用户数据: {len(self.users)} 条")
        print(f"  - 商品数据: {len(self.products)} 条")
        print(f"  - 订单数据: {len(self.orders)} 条")
        print(f"  - 订单明细: {len(self.order_details)} 条")
        if output_all:
            print(f"  - 支付数据: {len(payments)} 条")
            print(f"  - 退款数据: {len(refunds)} 条")
            print(f"  - 优惠券: {len(coupons)} 条")
            print(f"  - 优惠券使用: {len(coupon_uses)} 条")
            print(f"  - 活动数据: {len(activities)} 条")
            print(f"  - 活动订单: {len(activity_orders)} 条")
            print(f"  - 评论数据: {len(comments)} 条")
        print(f"\n数据文件位置: {self.output_dir}/")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='电商模拟数据生成工具')
    parser.add_argument('--output-dir', '-o', default='/tmp/gmall_data', help='输出目录')
    parser.add_argument('--users', '-u', type=int, default=1000, help='用户数量')
    parser.add_argument('--products', '-p', type=int, default=500, help='商品数量')
    parser.add_argument('--orders', '-r', type=int, default=5000, help='订单数量')
    parser.add_argument('--full', '-f', action='store_true', help='生成完整数据（包含支付、退款、优惠券等）')

    args = parser.parse_args()

    generator = EcommerceDataGenerator(output_dir=args.output_dir)
    generator.run(
        num_users=args.users,
        num_products=args.products,
        num_orders=args.orders,
        output_all=args.full
    )

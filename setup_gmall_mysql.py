#!/usr/bin/env python3
import pymysql
import random
from datetime import datetime, timedelta

# MySQL 连接配置
db_config = {
    'host': 'localhost',
    'port': 3307,
    'user': 'testuser',
    'password': 'testpass',
    'charset': 'utf8mb4'
}

def execute_sql_file(filename):
    """执行 SQL 文件"""
    conn = pymysql.connect(**db_config)
    try:
        with conn.cursor() as cursor:
            with open(filename, 'r', encoding='utf-8') as f:
                sql_content = f.read()
            
            # 分割 SQL 语句
            sql_statements = []
            current_stmt = []
            for line in sql_content.split('\n'):
                line = line.strip()
                if line and not line.startswith('--'):
                    current_stmt.append(line)
                    if line.endswith(';'):
                        sql_statements.append(' '.join(current_stmt))
                        current_stmt = []
            
            # 执行每个 SQL 语句
            for stmt in sql_statements:
                if stmt.strip():
                    try:
                        cursor.execute(stmt)
                        print(f"Executed: {stmt[:60]}...")
                    except Exception as e:
                        print(f"Warning: {e}")
            
            conn.commit()
            print("Database schema created successfully!")
            
    except Exception as e:
        print(f"Error: {e}")
    finally:
        conn.close()

def generate_mock_data():
    """生成模拟数据"""
    conn = pymysql.connect(**db_config)
    try:
        with conn.cursor() as cursor:
            cursor.execute("USE gmall")
            
            # 生成品牌数据
            brands = [
                ('1', 'Apple', 'https://example.com/apple.png'),
                ('2', 'Samsung', 'https://example.com/samsung.png'),
                ('3', 'Huawei', 'https://example.com/huawei.png'),
                ('4', 'Xiaomi', 'https://example.com/xiaomi.png'),
                ('5', 'Nike', 'https://example.com/nike.png')
            ]
            cursor.executemany("INSERT INTO base_trademark (id, tm_name, logo_url) VALUES (%s, %s, %s)", brands)
            
            # 生成分类数据
            category1 = [('1', '数码产品'), ('2', '服装'), ('3', '食品'), ('4', '家居')]
            cursor.executemany("INSERT INTO base_category1 (id, name) VALUES (%s, %s)", category1)
            
            category2 = [
                ('11', '手机', '1'), ('12', '电脑', '1'),
                ('21', '男装', '2'), ('22', '女装', '2'),
                ('31', '零食', '3'), ('32', '饮料', '3')
            ]
            cursor.executemany("INSERT INTO base_category2 (id, name, category1_id) VALUES (%s, %s, %s)", category2)
            
            category3 = [
                ('111', '智能手机', '11'), ('112', '老人机', '11'),
                ('121', '笔记本', '12'), ('122', '台式机', '12'),
                ('211', '衬衫', '21'), ('212', '裤子', '21'),
                ('311', '饼干', '31'), ('312', '糖果', '31')
            ]
            cursor.executemany("INSERT INTO base_category3 (id, name, category2_id) VALUES (%s, %s, %s)", category3)
            
            # 生成商品数据
            spu_data = [
                ('1', 'iPhone 15', '苹果最新手机', '111', '1'),
                ('2', 'MacBook Pro', '苹果笔记本电脑', '121', '1'),
                ('3', '小米14', '小米旗舰手机', '111', '4')
            ]
            cursor.executemany("INSERT INTO spu_info (id, spu_name, description, category3_id, tm_id) VALUES (%s, %s, %s, %s, %s)", spu_data)
            
            sku_data = [
                ('1', '1', 7999.00, 'iPhone 15 128GB', '黑色，128GB', 0.18, '1', '111', '2024-01-01 10:00:00'),
                ('2', '1', 8999.00, 'iPhone 15 256GB', '黑色，256GB', 0.18, '1', '111', '2024-01-01 10:00:00'),
                ('3', '2', 14999.00, 'MacBook Pro 14', 'M3芯片，16GB内存', 1.5, '1', '121', '2024-01-01 10:00:00'),
                ('4', '3', 3999.00, '小米14 256GB', '白色，256GB', 0.19, '4', '111', '2024-01-01 10:00:00')
            ]
            cursor.executemany("INSERT INTO sku_info (id, spu_id, price, sku_name, sku_desc, weight, tm_id, category3_id, create_time) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)", sku_data)
            
            # 生成用户数据
            user_data = []
            for i in range(1, 21):
                user_data.append((
                    str(i),
                    f'user{i}',
                    f'用户{i}',
                    f'姓名{i}',
                    f'138001380{str(i).zfill(2)}',
                    f'user{i}@example.com',
                    f'https://example.com/avatar{i}.jpg',
                    str(random.randint(1, 5)),
                    '1990-01-01',
                    'M' if i % 2 == 0 else 'F',
                    '2024-01-01 10:00:00',
                    '2024-01-01 10:00:00',
                    '1'
                ))
            cursor.executemany("INSERT INTO user_info (id, login_name, nick_name, name, phone_num, email, head_img, user_level, birthday, gender, create_time, operate_time, status) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)", user_data)
            
            # 生成订单和订单明细数据
            order_data = []
            order_detail_data = []
            base_date = datetime(2024, 6, 1)
            order_id = 1
            for i in range(1, 51):
                order_date = base_date + timedelta(days=random.randint(0, 14))
                user_id = str(random.randint(1, 20))
                total_amount = round(random.uniform(100, 10000), 2)
                
                order_data.append((
                    str(order_id),
                    f'收货人{order_id}',
                    f'138001380{str(order_id).zfill(2)}',
                    total_amount,
                    random.choice(['1001', '1002', '1003', '1004', '1005']),
                    user_id,
                    random.choice(['1', '2', '3']),
                    f'地址{order_id}',
                    f'备注{order_id}',
                    f'OT{order_id}',
                    f'订单{order_id}',
                    order_date.strftime('%Y-%m-%d %H:%M:%S'),
                    order_date.strftime('%Y-%m-%d %H:%M:%S'),
                    (order_date + timedelta(days=7)).strftime('%Y-%m-%d %H:%M:%S'),
                    f'LOG{order_id}',
                    '',
                    '',
                    '1',
                    round(total_amount * 0.1, 2),
                    total_amount,
                    10.0
                ))
                
                # 每个订单 1-3 个商品
                for j in range(random.randint(1, 3)):
                    sku_id = str(random.randint(1, 4))
                    sku_num = random.randint(1, 3)
                    order_price = round(random.uniform(100, 10000), 2)
                    order_detail_data.append((
                        str(order_id * 10 + j),
                        str(order_id),
                        sku_id,
                        f'商品{sku_id}',
                        f'https://example.com/img{sku_id}.jpg',
                        order_price,
                        sku_num,
                        order_date.strftime('%Y-%m-%d %H:%M:%S'),
                        '1',
                        ''
                    ))
                
                order_id += 1
            
            cursor.executemany("INSERT INTO order_info (id, consignee, consignee_tel, total_amount, order_status, user_id, payment_way, delivery_address, order_comment, out_trade_no, trade_body, create_time, operate_time, expire_time, tracking_no, parent_order_id, img_url, province_id, benefit_reduce_amount, original_total_amount, feight_fee) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)", order_data)
            
            cursor.executemany("INSERT INTO order_detail (id, order_id, sku_id, sku_name, img_url, order_price, sku_num, create_time, source_type, source_id) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)", order_detail_data)
            
            conn.commit()
            print("Mock data generated successfully!")
            
            # 验证数据
            print("\n--- Data verification ---")
            cursor.execute("SELECT COUNT(*) FROM user_info")
            print(f"Users: {cursor.fetchone()[0]}")
            cursor.execute("SELECT COUNT(*) FROM order_info")
            print(f"Orders: {cursor.fetchone()[0]}")
            cursor.execute("SELECT COUNT(*) FROM order_detail")
            print(f"Order details: {cursor.fetchone()[0]}")
            
    except Exception as e:
        print(f"Error: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    print("Creating gmall database and tables...")
    execute_sql_file('d:/s/作业/sql/gmall_schema.sql')
    print("\nGenerating mock data...")
    generate_mock_data()
    print("\nDone!")

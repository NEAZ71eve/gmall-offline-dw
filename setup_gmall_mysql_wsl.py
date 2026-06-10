#!/usr/bin/env python3
import mysql.connector
import sys

def setup_gmall_database():
    """Initialize gmall database with schema and sample data"""

    try:
        print("Connecting to MySQL...")
        conn = mysql.connector.connect(
            host='127.0.0.1',
            port=3307,
            user='root',
            password='',
            database='gmall'
        )
        cursor = conn.cursor()

        print("Creating tables...")

        # User Info Table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS user_info (
                id VARCHAR(255) PRIMARY KEY,
                login_name VARCHAR(255),
                nick_name VARCHAR(255),
                name VARCHAR(255),
                phone_num VARCHAR(255),
                email VARCHAR(255),
                head_img VARCHAR(255),
                user_level VARCHAR(255),
                birthday VARCHAR(255),
                gender VARCHAR(255),
                create_time VARCHAR(255),
                operate_time VARCHAR(255),
                status VARCHAR(255)
            )
        """)

        # SKU Info Table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS sku_info (
                id VARCHAR(255) PRIMARY KEY,
                spu_id VARCHAR(255),
                price DECIMAL(16,2),
                sku_name VARCHAR(255),
                sku_desc TEXT,
                weight DECIMAL(10,2),
                tm_id VARCHAR(255),
                category3_id VARCHAR(255),
                create_time VARCHAR(255)
            )
        """)

        # Order Info Table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS order_info (
                id VARCHAR(255) PRIMARY KEY,
                consignee VARCHAR(255),
                consignee_tel VARCHAR(255),
                total_amount DECIMAL(16,2),
                order_status VARCHAR(255),
                user_id VARCHAR(255),
                payment_way VARCHAR(255),
                delivery_address TEXT,
                order_comment TEXT,
                out_trade_no VARCHAR(255),
                trade_body VARCHAR(255),
                create_time VARCHAR(255),
                operate_time VARCHAR(255),
                expire_time VARCHAR(255),
                tracking_no VARCHAR(255),
                parent_order_id VARCHAR(255),
                img_url VARCHAR(255),
                province_id VARCHAR(255),
                benefit_reduce_amount DECIMAL(16,2),
                original_total_amount DECIMAL(16,2),
                feight_fee DECIMAL(10,2)
            )
        """)

        # Order Detail Table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS order_detail (
                id VARCHAR(255) PRIMARY KEY,
                order_id VARCHAR(255),
                sku_id VARCHAR(255),
                sku_name VARCHAR(255),
                img_url VARCHAR(255),
                order_price DECIMAL(16,2),
                sku_num BIGINT,
                create_time VARCHAR(255),
                source_type VARCHAR(255),
                source_id VARCHAR(255)
            )
        """)

        print("Inserting sample data...")

        # Insert sample users
        users = [
            ('1001', 'zhangsan', '张三', '张三', '13800138001', 'zhangsan@example.com',
             'https://example.com/avatar1.jpg', 'VIP', '1990-01-01', 'M',
             '2024-01-01 10:00:00', '2024-01-01 10:00:00', '1'),
            ('1002', 'lisi', '李四', '李四', '13800138002', 'lisi@example.com',
             'https://example.com/avatar2.jpg', '普通', '1991-02-02', 'F',
             '2024-01-02 11:00:00', '2024-01-02 11:00:00', '1'),
            ('1003', 'wangwu', '王五', '王五', '13800138003', 'wangwu@example.com',
             'https://example.com/avatar3.jpg', 'VIP', '1992-03-03', 'M',
             '2024-01-03 12:00:00', '2024-01-03 12:00:00', '1'),
            ('1004', 'zhaoliu', '赵六', '赵六', '13800138004', 'zhaoliu@example.com',
             'https://example.com/avatar4.jpg', '普通', '1993-04-04', 'F',
             '2024-01-04 13:00:00', '2024-01-04 13:00:00', '1'),
            ('1005', 'sunqi', '孙七', '孙七', '13800138005', 'sunqi@example.com',
             'https://example.com/avatar5.jpg', 'VIP', '1994-05-05', 'M',
             '2024-01-05 14:00:00', '2024-01-05 14:00:00', '1'),
        ]

        cursor.executemany("""
            INSERT IGNORE INTO user_info VALUES
            (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, [(u[0], u[1], u[2], u[3], u[4], u[5], u[6], u[7], u[8], u[9], u[10], u[11], u[12]) for u in users])

        # Insert sample SKU data
        skus = [
            ('2001', '1001', 1999.00, 'iPhone 15 Pro 256G', '苹果旗舰手机',
             0.187, 'T001', 'C1001', '2024-01-01 00:00:00'),
            ('2002', '1001', 2999.00, 'MacBook Air M2', '苹果笔记本电脑',
             1.24, 'T001', 'C1002', '2024-01-02 00:00:00'),
            ('2003', '1002', 499.00, '小米手环8', '智能运动手环',
             0.032, 'T002', 'C1003', '2024-01-03 00:00:00'),
            ('2004', '1002', 2999.00, '华为Mate60 Pro', '华为旗舰手机',
             0.225, 'T003', 'C1001', '2024-01-04 00:00:00'),
        ]

        cursor.executemany("""
            INSERT IGNORE INTO sku_info VALUES
            (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, skus)

        # Insert sample order data
        orders = [
            ('5001', '张三', '13800001111', 5998.00, 'PAID', '1001', 'ONLINE',
             '北京市朝阳区XX路XX号', '尽快发货', 'TRADE001', 'iPhone+MacBook',
             '2024-01-15 10:30:00', '2024-01-15 10:30:00', '2024-01-15 18:00:00',
             'SF123456789', '', '', '110000', 0.00, 5998.00, 0.00),
            ('5002', '李四', '13800002222', 2999.00, 'PAID', '1002', 'ONLINE',
             '上海市浦东新区XX路XX号', '', 'TRADE002', 'MacBook Air',
             '2024-01-15 11:00:00', '2024-01-15 11:00:00', '2024-01-15 18:00:00',
             'YTO987654321', '', '', '310000', 0.00, 2999.00, 0.00),
            ('5003', '王五', '13800003333', 499.00, 'PAID', '1003', 'ONLINE',
             '广州市天河区XX路XX号', '加急', 'TRADE003', '小米手环',
             '2024-01-15 14:00:00', '2024-01-15 14:00:00', '2024-01-15 18:00:00',
             'JD123456', '', '', '440000', 0.00, 499.00, 0.00),
        ]

        cursor.executemany("""
            INSERT IGNORE INTO order_info VALUES
            (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, orders)

        # Insert sample order details
        order_details = [
            ('6001', '5001', '2001', 'iPhone 15 Pro 256G',
             'https://example.com/iphone.jpg', 1999.00, 2, '2024-01-15 10:30:00', 'APP', '1001'),
            ('6002', '5001', '2002', 'MacBook Air M2',
             'https://example.com/macbook.jpg', 2999.00, 1, '2024-01-15 10:30:00', 'APP', '1002'),
            ('6003', '5002', '2002', 'MacBook Air M2',
             'https://example.com/macbook.jpg', 2999.00, 1, '2024-01-15 11:00:00', 'WEB', '1003'),
            ('6004', '5003', '2003', '小米手环8',
             'https://example.com/xiaomi.jpg', 499.00, 1, '2024-01-15 14:00:00', 'WEB', '1004'),
        ]

        cursor.executemany("""
            INSERT IGNORE INTO order_detail VALUES
            (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, order_details)

        conn.commit()

        print("\nVerifying data...")
        cursor.execute("SELECT COUNT(*) FROM user_info")
        user_count = cursor.fetchone()[0]
        print(f"Users: {user_count}")

        cursor.execute("SELECT COUNT(*) FROM order_info")
        order_count = cursor.fetchone()[0]
        print(f"Orders: {order_count}")

        cursor.execute("SELECT COUNT(*) FROM order_detail")
        detail_count = cursor.fetchone()[0]
        print(f"Order Details: {detail_count}")

        cursor.close()
        conn.close()

        print("\n✓ Database setup completed successfully!")
        return True

    except Exception as e:
        print(f"\n✗ Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return False

if __name__ == '__main__':
    if setup_gmall_database():
        sys.exit(0)
    else:
        sys.exit(1)

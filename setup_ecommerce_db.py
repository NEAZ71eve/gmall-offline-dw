
import pymysql
import sys

# 数据库连接配置
db_config = {
    'host': 'localhost',
    'port': 3307,
    'user': 'testuser',
    'password': 'testpass'
}

try:
    # 连接到 MySQL 服务器
    conn = pymysql.connect(**db_config)
    cursor = conn.cursor()
    
    print("Successfully connected to MySQL server")
    
    # 读取 SQL 文件
    with open('d:\\s\\作业\\sql\\schema.sql', 'r', encoding='utf-8') as f:
        sql_content = f.read()
    
    # 分割 SQL 语句（按分号）
    sql_statements = []
    current_statement = []
    
    for line in sql_content.split('\n'):
        line = line.strip()
        if line and not line.startswith('--'):
            current_statement.append(line)
            if line.endswith(';'):
                sql_statements.append(' '.join(current_statement))
                current_statement = []
    
    # 执行每个 SQL 语句
    for statement in sql_statements:
        if statement.strip():
            try:
                cursor.execute(statement)
                print(f"Executed: {statement[:50]}...")
            except Exception as e:
                print(f"Warning executing statement: {e}")
    
    # 提交更改
    conn.commit()
    print("\nDatabase setup completed successfully!")
    
    # 验证数据
    cursor.execute("USE ecommerce")
    cursor.execute("SELECT COUNT(*) FROM products")
    product_count = cursor.fetchone()[0]
    print(f"Products in database: {product_count}")
    
    cursor.execute("SELECT COUNT(*) FROM categories")
    category_count = cursor.fetchone()[0]
    print(f"Categories in database: {category_count}")
    
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
finally:
    if 'conn' in locals() and conn.open:
        cursor.close()
        conn.close()
        print("Database connection closed")


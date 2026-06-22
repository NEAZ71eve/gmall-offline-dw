#!/usr/bin/env python3
"""
Superset 初始化脚本 - 创建数据源与看板
在 superset 容器内执行: python3 /app/pythonpath/init_superset.py
"""
import sys, os
sys.path.insert(0, '/app/pythonpath')
from superset import create_app
from superset.extensions import db
from superset.models.core import Database

app = create_app()

with app.app_context():
    # --- MySQL 数据源 ---
    mysql_uri = 'mysql+mysqlconnector://gmall:gmall123@mysql:3306/gmall'
    existing = db.session.query(Database).filter_by(database_name='gmall_mysql').first()
    if not existing:
        db_mysql = Database(
            database_name='gmall_mysql',
            sqlalchemy_uri=mysql_uri,
            expose_in_sqllab=True,
            allow_ctas=True,
            allow_cvas=True,
        )
        db.session.add(db_mysql)
        db.session.commit()
        print("✓ MySQL 数据源已添加: gmall_mysql")
    else:
        print("  MySQL 数据源已存在")

    # --- Hive 数据源 (需要 pyhive 驱动) ---
    try:
        import pyhive
        hive_uri = 'hive://hive-server:10000/default?auth=NONE'
        existing2 = db.session.query(Database).filter_by(database_name='gmall_hive').first()
        if not existing2:
            db_hive = Database(
                database_name='gmall_hive',
                sqlalchemy_uri=hive_uri,
                expose_in_sqllab=True,
                allow_ctas=True,
            )
            db.session.add(db_hive)
            db.session.commit()
            print("✓ Hive 数据源已添加: gmall_hive")
        else:
            print("  Hive 数据源已存在")
    except ImportError:
        print("  ⚠ pyhive 未安装,Hive数据源跳过(MySQL数据源可用)")

    print("\n✓ Superset 初始化完成")
    print("  访问: http://localhost:8089  (admin / admin2024)")
    print("  下一步: 创建 Dataset → Chart → Dashboard")

db.session.close()

#!/usr/bin/env python3
"""
完整的 ETL 管道脚本
自动启动必要的服务，并执行 ODS -> DIM -> DWD -> DWS 层的数据处理
"""

import os
import sys
import time
import subprocess
from datetime import datetime

def run_command(cmd, check=True):
    """运行 shell 命令"""
    print(f"执行命令: {cmd}")
    result = os.system(cmd)
    if check and result != 0:
        print(f"命令执行失败: {cmd}")
        return False
    return True

def check_mysql():
    """检查并启动 MySQL"""
    print("检查 MySQL 服务...")

    # 检查 MySQL 是否运行
    result = subprocess.run(
        'mysql -h 127.0.0.1 -u root -P 3307 -e "SELECT 1" 2>/dev/null',
        shell=True,
        capture_output=True
    )

    if result.returncode == 0:
        print("MySQL 已运行")
        return True

    # 启动 MySQL
    print("启动 MySQL...")
    commands = [
        'sudo mkdir -p /var/run/mysqld',
        'sudo chown mysql:mysql /var/run/mysqld',
        'sudo mysqld --user=mysql --port=3307 --bind-address=127.0.0.1 > /tmp/mysql.log 2>&1 &'
    ]

    for cmd in commands:
        os.system(cmd)

    # 等待 MySQL 启动
    for i in range(20):
        time.sleep(1)
        result = subprocess.run(
            'mysql -h 127.0.0.1 -u root -P 3307 -e "SELECT 1" 2>/dev/null',
            shell=True,
            capture_output=True
        )
        if result.returncode == 0:
            print("MySQL 启动成功")
            return True

    print("MySQL 启动失败")
    return False

def check_hadoop():
    """检查并启动 Hadoop"""
    print("检查 Hadoop 服务...")

    # 检查 NameNode 和 DataNode
    result = subprocess.run('jps | grep -E "NameNode|DataNode"', shell=True, capture_output=True)

    if result.returncode == 0 and result.stdout:
        print("Hadoop 已运行")
        return True

    # 启动 Hadoop
    print("启动 Hadoop...")

    commands = [
        'mkdir -p /tmp/hadoop-jules/dfs/name /tmp/hadoop-jules/dfs/data',
    ]

    for cmd in commands:
        os.system(cmd)

    # 检查是否需要格式化
    if not os.path.exists('/tmp/hadoop-jules/dfs/name/current'):
        print("格式化 NameNode...")
        os.system('echo "Y" | /usr/local/hadoop/bin/hdfs namenode -format 2>/dev/null')

    # 启动 NameNode
    os.system('/usr/local/hadoop/bin/hdfs namenode > /tmp/namenode.log 2>&1 &')
    time.sleep(10)

    # 启动 DataNode
    os.system('/usr/local/hadoop/bin/hdfs datanode > /tmp/datanode.log 2>&1 &')
    time.sleep(10)

    # 验证
    result = subprocess.run('jps | grep -E "NameNode|DataNode"', shell=True, capture_output=True)

    if result.returncode == 0 and result.stdout:
        print("Hadoop 启动成功")
        return True

    print("Hadoop 启动失败")
    return False

def main():
    print("=" * 60)
    print("尚硅谷电商数仓项目 - ETL 管道")
    print("=" * 60)
    print(f"时间: {datetime.now()}")
    print()

    # 1. 检查并启动服务
    print("步骤 1: 检查并启动必要的服务...")
    if not check_mysql():
        print("MySQL 启动失败，退出")
        sys.exit(1)

    if not check_hadoop():
        print("Hadoop 启动失败，退出")
        sys.exit(1)

    print()

    # 2. 执行 ODS 层数据加载
    print("步骤 2: 执行 ODS 层数据加载...")
    os.chdir('/mnt/d/s/作业')
    os.system('python3 ods_data_loader.py')
    print()

    # 3. 执行 DIM 层数据处理
    print("步骤 3: 执行 DIM 层数据处理...")
    os.system('python3 dim_data_processor.py')
    print()

    # 4. 执行 DWD 层数据处理
    print("步骤 4: 执行 DWD 层数据处理...")
    os.system('python3 dwd_data_processor.py')
    print()

    # 5. 执行 DWS 层数据汇总
    print("步骤 5: 执行 DWS 层数据汇总...")
    os.system('python3 dws_data_processor.py')
    print()

    print("=" * 60)
    print("ETL 管道执行完成！")
    print("=" * 60)

    # 显示最终状态
    print("\n最终状态:")
    print("\nODS 层数据:")
    os.system('/usr/local/hadoop/bin/hdfs dfs -ls /warehouse/gmall/ods/')
    print("\nDIM 层数据:")
    os.system('/usr/local/hadoop/bin/hdfs dfs -ls /warehouse/gmall/dim/')
    print("\nDWD 层数据:")
    os.system('/usr/local/hadoop/bin/hdfs dfs -ls /warehouse/gmall/dwd/')
    print("\nDWS 层数据:")
    os.system('/usr/local/hadoop/bin/hdfs dfs -ls /warehouse/gmall/dws/')

if __name__ == '__main__':
    main()

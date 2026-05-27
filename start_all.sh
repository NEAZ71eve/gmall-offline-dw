#!/bin/bash
# 启动所有服务的完整脚本

echo "=== 启动所有服务 ==="

# 1. 启动 MySQL
echo "1. 启动 MySQL..."
echo '54088Cnm,' | sudo -S mkdir -p /var/run/mysqld
echo '54088Cnm,' | sudo -S chown mysql:mysql /var/run/mysqld
echo '54088Cnm,' | sudo -S mysqld --user=mysql --port=3307 --bind-address=127.0.0.1 > /tmp/mysql.log 2>&1 &
sleep 10

# 验证 MySQL
mysql -h 127.0.0.1 -u root -P 3307 -e "SELECT 1;" 2>/dev/null && echo "MySQL 启动成功" || echo "MySQL 启动失败"

# 2. 启动 Hadoop
echo "2. 启动 Hadoop..."
export HADOOP_HOME=/usr/local/hadoop
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH

# 创建必要目录
mkdir -p /tmp/hadoop-jules/dfs/name /tmp/hadoop-jules/dfs/data

# 检查是否需要格式化
if [ ! -d "/tmp/hadoop-jules/dfs/name/current" ]; then
    echo "格式化 NameNode..."
    echo "Y" | $HADOOP_HOME/bin/hdfs namenode -format -force > /dev/null 2>&1
fi

# 启动 NameNode
nohup $HADOOP_HOME/bin/hdfs namenode > /tmp/namenode.log 2>&1 &
sleep 10

# 启动 DataNode
nohup $HADOOP_HOME/bin/hdfs datanode > /tmp/datanode.log 2>&1 &
sleep 10

# 验证 HDFS
jps | grep -E 'NameNode|DataNode' && echo "Hadoop 启动成功" || echo "Hadoop 启动失败"

# 3. 创建 ODS 层目录
echo "3. 创建 ODS 层目录..."
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /warehouse/gmall/ods
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /warehouse/gmall/dim
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /warehouse/gmall/dwd
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /warehouse/gmall/dws
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /warehouse/gmall/dwd

echo "=== 所有服务启动完成 ==="

# 显示服务状态
echo ""
echo "服务状态:"
jps | grep -E 'NameNode|DataNode'
ss -tuln | grep -E '9000|3307'

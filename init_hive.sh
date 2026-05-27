#!/bin/bash

echo "=== Initializing Hive Environment ==="

# Set environment variables
export HADOOP_HOME=/usr/local/hadoop
export HIVE_HOME=/opt/hive
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin:$PATH

echo "1. Stopping existing Hadoop processes..."
$HADOOP_HOME/bin/hdfs --daemon stop namenode 2>/dev/null || true
$HADOOP_HOME/bin/hdfs --daemon stop datanode 2>/dev/null || true
sleep 2

echo "2. Formatting NameNode (if needed)..."
rm -rf /tmp/hadoop-jules/dfs/name/current 2>/dev/null || true
mkdir -p /tmp/hadoop-jules/dfs/name
$HADOOP_HOME/bin/hdfs namenode -format -force 2>&1 | tail -5

echo "3. Starting Hadoop..."
$HADOOP_HOME/bin/hdfs --daemon start namenode
sleep 8

echo "4. Starting DataNode..."
$HADOOP_HOME/bin/hdfs --daemon start datanode
sleep 10

echo "5. Checking HDFS status..."
jps

echo "6. Testing HDFS..."
$HADOOP_HOME/bin/hdfs dfs -ls / 2>&1 | head -10

echo "7. Creating Hive directories in HDFS..."
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /user/hive/warehouse
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /tmp/hive
$HADOOP_HOME/bin/hdfs dfs -chmod 777 /user/hive/warehouse
$HADOOP_HOME/bin/hdfs dfs -chmod 777 /tmp/hive

echo "8. Creating gmall databases..."
hive -e "CREATE DATABASE IF NOT EXISTS gmall_ods;"
hive -e "CREATE DATABASE IF NOT EXISTS gmall_dim;"
hive -e "CREATE DATABASE IF NOT EXISTS gmall_dwd;"
hive -e "CREATE DATABASE IF NOT EXISTS gmall_dws;"
hive -e "CREATE DATABASE IF NOT EXISTS gmall_ads;"

echo "9. Verifying databases..."
hive -e "SHOW DATABASES;"

echo "=== Hive initialization completed! ==="

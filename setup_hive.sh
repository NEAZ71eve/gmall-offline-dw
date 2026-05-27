#!/bin/bash
export HADOOP_HOME=/usr/local/hadoop
export HIVE_HOME=/usr/local/hive
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin:$PATH

# Start Hadoop
echo "Starting Hadoop..."
$HADOOP_HOME/bin/hdfs --daemon start namenode
sleep 5
$HADOOP_HOME/bin/hdfs --daemon start datanode
sleep 8

echo "Processes running:"
jps

# Create Hive databases
echo "Creating Hive databases..."
hive -e "CREATE DATABASE IF NOT EXISTS gmall_ods;" 2>&1
hive -e "CREATE DATABASE IF NOT EXISTS gmall_dim;" 2>&1
hive -e "CREATE DATABASE IF NOT EXISTS gmall_dwd;" 2>&1
hive -e "CREATE DATABASE IF NOT EXISTS gmall_dws;" 2>&1
hive -e "CREATE DATABASE IF NOT EXISTS gmall_ads;" 2>&1

echo "Hive databases created!"
hive -e "SHOW DATABASES;" 2>&1
echo "--- Done ---"

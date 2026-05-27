#!/bin/bash
export HADOOP_HOME=/usr/local/hadoop
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH

# Clean up any existing processes
pkill -f namenode 2>/dev/null
pkill -f datanode 2>/dev/null
sleep 2

# Clean up tmp directories and format NameNode
echo "Cleaning up old directories..."
rm -rf /tmp/hadoop-jules 2>/dev/null
mkdir -p /tmp/hadoop-jules/dfs/name
mkdir -p /tmp/hadoop-jules/dfs/data

# Format NameNode (only if needed)
echo "Formatting NameNode..."
echo "Y" | $HADOOP_HOME/bin/hdfs namenode -format 2>&1

# Start NameNode
echo "Starting NameNode..."
$HADOOP_HOME/bin/hdfs --daemon start namenode
sleep 8

# Start DataNode
echo "Starting DataNode..."
$HADOOP_HOME/bin/hdfs --daemon start datanode
sleep 10

# Check processes
echo "Processes running:"
jps

# Test and create directories
echo "Testing HDFS connection..."
sleep 5

echo "Creating warehouse directories..."
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /warehouse/gmall/ods
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /warehouse/gmall/dim
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /warehouse/gmall/dwd
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /warehouse/gmall/dws
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /warehouse/gmall/ads
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /origin_data/gmall/db

echo "HDFS directories created!"
$HADOOP_HOME/bin/hdfs dfs -ls -R /warehouse
echo "--- Done ---"

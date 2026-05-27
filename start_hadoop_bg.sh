#!/bin/bash
# Start Hadoop in background and keep it running

export HADOOP_HOME=/usr/local/hadoop
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH

# Create directories
mkdir -p /tmp/hadoop-jules/dfs/name /tmp/hadoop-jules/dfs/data

# Format if needed
if [ ! -d "/tmp/hadoop-jules/dfs/name/current" ]; then
    echo "Y" | $HADOOP_HOME/bin/hdfs namenode -format
fi

# Start NameNode in foreground mode with nohup
nohup $HADOOP_HOME/bin/hdfs namenode > /tmp/namenode.log 2>&1 &
sleep 10

# Start DataNode
nohup $HADOOP_HOME/bin/hdfs datanode > /tmp/datanode.log 2>&1 &
sleep 10

# Check status
jps
ss -tuln | grep 9000

# Create Hive directories
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /user/hive/warehouse
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /user/hive/warehouse/gmall_ods.db
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /user/hive/warehouse/gmall_dim.db
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /user/hive/warehouse/gmall_dwd.db
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /user/hive/warehouse/gmall_dws.db
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /user/hive/warehouse/gmall_ads.db

echo "Done!"
$HADOOP_HOME/bin/hdfs dfs -ls -R /user/hive/warehouse/
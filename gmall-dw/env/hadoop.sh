
#!/bin/bash

export HADOOP_HOME=/usr/local/hadoop
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH

start_hadoop() {
    echo "Starting Hadoop..."
    $HADOOP_HOME/sbin/start-dfs.sh
    $HADOOP_HOME/sbin/start-yarn.sh
}

stop_hadoop() {
    echo "Stopping Hadoop..."
    $HADOOP_HOME/sbin/stop-yarn.sh
    $HADOOP_HOME/sbin/stop-dfs.sh
}

create_warehouse() {
    echo "Creating warehouse directories..."
    hdfs dfs -mkdir -p /warehouse/gmall/ods
    hdfs dfs -mkdir -p /warehouse/gmall/dim
    hdfs dfs -mkdir -p /warehouse/gmall/dwd
    hdfs dfs -mkdir -p /warehouse/gmall/dws
    hdfs dfs -mkdir -p /warehouse/gmall/ads
    hdfs dfs -mkdir -p /origin_data/gmall/db
}

if [ "$1" == "start" ]; then
    start_hadoop
elif [ "$1" == "stop" ]; then
    stop_hadoop
elif [ "$1" == "init" ]; then
    create_warehouse
else
    echo "Usage: $0 {start|stop|init}"
fi

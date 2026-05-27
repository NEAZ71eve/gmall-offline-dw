#!/bin/bash
# Configure Hive to use Java 8

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH
export HADOOP_HOME=/usr/local/hadoop
export HIVE_HOME=/opt/hive
export HADOOP_CLASSPATH=$($HADOOP_HOME/bin/hadoop classpath)

# Verify Java version
echo "Java version:"
java -version

echo "Starting Hive..."

# Try to create databases using Hive
$HIVE_HOME/bin/hive -e "
    CREATE DATABASE IF NOT EXISTS gmall_ods;
    CREATE DATABASE IF NOT EXISTS gmall_dim;
    CREATE DATABASE IF NOT EXISTS gmall_dwd;
    CREATE DATABASE IF NOT EXISTS gmall_dws;
    CREATE DATABASE IF NOT EXISTS gmall_ads;
    SHOW DATABASES;
" 2>&1 | tail -30

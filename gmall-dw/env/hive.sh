
#!/bin/bash

export HIVE_HOME=/usr/local/hive
export HIVE_CONF_DIR=$HIVE_HOME/conf
export PATH=$HIVE_HOME/bin:$PATH
export HADOOP_HOME=/usr/local/hadoop

create_databases() {
    echo "Creating Hive databases..."
    hive -e "CREATE DATABASE IF NOT EXISTS gmall_ods;"
    hive -e "CREATE DATABASE IF NOT EXISTS gmall_dim;"
    hive -e "CREATE DATABASE IF NOT EXISTS gmall_dwd;"
    hive -e "CREATE DATABASE IF NOT EXISTS gmall_dws;"
    hive -e "CREATE DATABASE IF NOT EXISTS gmall_ads;"
}

execute_sql() {
    if [ -f "$1" ]; then
        echo "Executing SQL file: $1"
        hive -f "$1"
    else
        echo "File not found: $1"
        exit 1
    fi
}

run_etl() {
    echo "Running daily ETL..."
    hive -f hive/etl_daily.sql -hivevar dt="$1"
}

if [ "$1" == "init" ]; then
    create_databases
elif [ "$1" == "execute" ]; then
    execute_sql "$2"
elif [ "$1" == "etl" ]; then
    run_etl "$2"
else
    echo "Usage: $0 {init|execute <sql_file>|etl <date>}"
fi

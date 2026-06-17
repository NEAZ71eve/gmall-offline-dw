
#!/bin/bash

MYSQL_HOST="localhost"
MYSQL_PORT="3307"
MYSQL_USER="root"
MYSQL_PASS="000000"
MYSQL_DB="gmall"

create_db() {
    echo "Creating database $MYSQL_DB..."
    mysql -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER -p$MYSQL_PASS -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DB;"
}

execute_sql() {
    if [ -f "$1" ]; then
        echo "Executing SQL file: $1"
        mysql -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER -p$MYSQL_PASS $MYSQL_DB < "$1"
    else
        echo "File not found: $1"
        exit 1
    fi
}

query() {
    mysql -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER -p$MYSQL_PASS $MYSQL_DB -e "$1"
}

if [ "$1" == "init" ]; then
    create_db
elif [ "$1" == "execute" ]; then
    execute_sql "$2"
elif [ "$1" == "query" ]; then
    query "$2"
else
    echo "Usage: $0 {init|execute <sql_file>|query <sql>}"
fi

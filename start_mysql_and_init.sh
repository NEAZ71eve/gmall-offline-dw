#!/bin/bash
set -e

echo "Step 1: Creating necessary directories..."
echo '54088Cnm,' | sudo -S mkdir -p /var/run/mysqld
echo '54088Cnm,' | sudo -S chown mysql:mysql /var/run/mysqld

echo "Step 2: Stopping any existing MySQL processes..."
echo '54088Cnm,' | sudo -S killall -9 mysqld mysqld_safe 2>/dev/null || true
sleep 2

echo "Step 3: Starting MySQL..."
echo '54088Cnm,' | sudo -S mysqld --user=mysql --port=3307 --bind-address=127.0.0.1 &
MYSQL_PID=$!
echo "MySQL started with PID: $MYSQL_PID"

echo "Step 4: Waiting for MySQL to initialize..."
for i in {1..20}; do
    sleep 2
    if mysql -h 127.0.0.1 -u root -P 3307 -e 'SELECT 1' 2>/dev/null; then
        echo "MySQL is ready!"
        break
    fi
    echo "Waiting for MySQL... attempt $i"
done

echo "Step 5: Creating gmall database..."
mysql -h 127.0.0.1 -u root -P 3307 -e "
    CREATE DATABASE IF NOT EXISTS gmall CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    GRANT ALL ON gmall.* TO 'testuser'@'%';
    FLUSH PRIVILEGES;
"

echo "Step 6: Creating tables and data..."
cd /mnt/d/s/作业
python3 setup_gmall_mysql_wsl.py

echo "Done!"

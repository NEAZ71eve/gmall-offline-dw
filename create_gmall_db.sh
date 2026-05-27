#!/bin/bash
# Create gmall database and grant permissions

mysql -h localhost -u root -p000000 -P 3307 <<EOF
CREATE DATABASE IF NOT EXISTS gmall CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL ON gmall.* TO 'testuser'@'%';
FLUSH PRIVILEGES;
EOF

echo "Database gmall created and permissions granted!"

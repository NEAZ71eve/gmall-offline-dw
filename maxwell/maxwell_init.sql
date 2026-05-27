CREATE DATABASE IF NOT EXISTS maxwell;

CREATE USER 'maxwell'@'%' IDENTIFIED BY 'maxwell';
GRANT ALL ON maxwell.* TO 'maxwell'@'%';
GRANT SELECT, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'maxwell'@'%';
FLUSH PRIVILEGES;

USE maxwell;

CREATE TABLE IF NOT EXISTS positions (
    server_id VARCHAR(64) NOT NULL,
    gtid_set TEXT NULL,
    master_id INT NULL,
    master_pos TEXT NULL,
    last_heartbeat_read INT NULL,
    PRIMARY KEY (server_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS schema_store (
    id INT AUTO_INCREMENT PRIMARY KEY,
    database_name VARCHAR(255) NOT NULL,
    table_name VARCHAR(255) NOT NULL,
    schema_json TEXT NOT NULL,
    version INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_database_table (database_name, table_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
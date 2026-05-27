-- 创建 gmall 数据库
CREATE DATABASE IF NOT EXISTS gmall CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE gmall;

-- 用户表
CREATE TABLE IF NOT EXISTS user_info (
    id VARCHAR(255) PRIMARY KEY,
    login_name VARCHAR(255),
    nick_name VARCHAR(255),
    name VARCHAR(255),
    phone_num VARCHAR(255),
    email VARCHAR(255),
    head_img VARCHAR(255),
    user_level VARCHAR(255),
    birthday VARCHAR(255),
    gender VARCHAR(255),
    create_time VARCHAR(255),
    operate_time VARCHAR(255),
    status VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 商品SKU表
CREATE TABLE IF NOT EXISTS sku_info (
    id VARCHAR(255) PRIMARY KEY,
    spu_id VARCHAR(255),
    price DECIMAL(16,2),
    sku_name VARCHAR(255),
    sku_desc TEXT,
    weight DECIMAL(16,2),
    tm_id VARCHAR(255),
    category3_id VARCHAR(255),
    create_time VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 商品SPU表
CREATE TABLE IF NOT EXISTS spu_info (
    id VARCHAR(255) PRIMARY KEY,
    spu_name VARCHAR(255),
    description TEXT,
    category3_id VARCHAR(255),
    tm_id VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 品牌表
CREATE TABLE IF NOT EXISTS base_trademark (
    id VARCHAR(255) PRIMARY KEY,
    tm_name VARCHAR(255),
    logo_url VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 一级分类表
CREATE TABLE IF NOT EXISTS base_category1 (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 二级分类表
CREATE TABLE IF NOT EXISTS base_category2 (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255),
    category1_id VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 三级分类表
CREATE TABLE IF NOT EXISTS base_category3 (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255),
    category2_id VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 订单表
CREATE TABLE IF NOT EXISTS order_info (
    id VARCHAR(255) PRIMARY KEY,
    consignee VARCHAR(255),
    consignee_tel VARCHAR(255),
    total_amount DECIMAL(16,2),
    order_status VARCHAR(255),
    user_id VARCHAR(255),
    payment_way VARCHAR(255),
    delivery_address TEXT,
    order_comment TEXT,
    out_trade_no VARCHAR(255),
    trade_body VARCHAR(255),
    create_time VARCHAR(255),
    operate_time VARCHAR(255),
    expire_time VARCHAR(255),
    tracking_no VARCHAR(255),
    parent_order_id VARCHAR(255),
    img_url VARCHAR(255),
    province_id VARCHAR(255),
    benefit_reduce_amount DECIMAL(16,2),
    original_total_amount DECIMAL(16,2),
    feight_fee DECIMAL(16,2)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 订单明细表
CREATE TABLE IF NOT EXISTS order_detail (
    id VARCHAR(255) PRIMARY KEY,
    order_id VARCHAR(255),
    sku_id VARCHAR(255),
    sku_name VARCHAR(255),
    img_url VARCHAR(255),
    order_price DECIMAL(16,2),
    sku_num BIGINT,
    create_time VARCHAR(255),
    source_type VARCHAR(255),
    source_id VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 支付表
CREATE TABLE IF NOT EXISTS payment_info (
    id VARCHAR(255) PRIMARY KEY,
    out_trade_no VARCHAR(255),
    order_id VARCHAR(255),
    user_id VARCHAR(255),
    payment_type VARCHAR(255),
    trade_no VARCHAR(255),
    total_amount DECIMAL(16,2),
    subject VARCHAR(255),
    payment_status VARCHAR(255),
    create_time VARCHAR(255),
    callback_time VARCHAR(255),
    callback_content TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- 创建电商数据库
CREATE DATABASE IF NOT EXISTS ecommerce CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE ecommerce;

-- 分类表
CREATE TABLE IF NOT EXISTS categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 商品表
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    image_url VARCHAR(500),
    category_id INT,
    rating DECIMAL(3, 2) DEFAULT 0.00,
    stock INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
);

-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 购物车表
CREATE TABLE IF NOT EXISTS cart_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    product_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_product (user_id, product_id)
);

-- 订单表
CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    shipping_address TEXT NOT NULL,
    payment_method VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- 订单项目表
CREATE TABLE IF NOT EXISTS order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

-- 插入测试数据

-- 分类数据
INSERT INTO categories (name, description) VALUES
('电子产品', '手机、电脑、配件等'),
('服装', '男装、女装、童装'),
('家居用品', '家具、装饰、日用品'),
('图书', '小说、教材、参考书'),
('运动户外', '运动器材、户外装备');

-- 商品数据
INSERT INTO products (name, description, price, image_url, category_id, rating, stock) VALUES
('iPhone 15 Pro', '苹果最新款智能手机，A17芯片，钛金属边框', 8999.00, 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=400', 1, 4.8, 50),
('MacBook Pro 14', 'M3芯片，18小时续航，Liquid Retina XDR显示屏', 14999.00, 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=400', 1, 4.9, 30),
('AirPods Pro 2', '主动降噪，空间音频，无线充电', 1899.00, 'https://images.unsplash.com/photo-1572569511254-d8f925fe2cbb?w=400', 1, 4.7, 100),
('男士休闲衬衫', '纯棉材质，舒适透气，多色可选', 299.00, 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400', 2, 4.5, 200),
('女士连衣裙', '时尚设计，优雅气质，适合多种场合', 599.00, 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400', 2, 4.6, 150),
('北欧风格沙发', '简约设计，实木框架，超软坐垫', 3999.00, 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=400', 3, 4.8, 20),
('智能台灯', 'LED护眼，可调节亮度，USB充电', 199.00, 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=400', 3, 4.4, 100),
('《Python编程从入门到实践》', '畅销编程书籍，适合初学者', 89.00, 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=400', 4, 4.9, 300),
('耐克运动鞋', 'Air Max气垫，缓震舒适，时尚外观', 899.00, 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400', 5, 4.7, 80),
('瑜伽垫', 'TPE环保材质，防滑耐磨，附送收纳袋', 159.00, 'https://images.unsplash.com/photo-1601925260368-ae2f83cf8b7f?w=400', 5, 4.6, 150);

-- 测试用户
INSERT INTO users (username, email, password_hash, phone) VALUES
('testuser', 'test@example.com', '$2b$10$placeholder', '13800138000');


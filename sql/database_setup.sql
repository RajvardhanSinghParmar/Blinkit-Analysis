```sql
-- ============================================================
-- BLINKIT SQL ANALYSIS PROJECT
-- File: 01_database_setup.sql
-- Purpose: Create database and six project tables
-- Database: MySQL
-- ============================================================


-- ============================================================
-- 1. CREATE DATABASE
-- ============================================================

CREATE DATABASE IF NOT EXISTS blinkit_analytics;

USE blinkit_analytics;


-- ============================================================
-- 2. DROP TABLES IF THEY ALREADY EXIST
--    Drop child tables first because of foreign keys.
-- ============================================================

DROP TABLE IF EXISTS blinkit_customer_feedback;
DROP TABLE IF EXISTS blinkit_delivery_performance;
DROP TABLE IF EXISTS blinkit_order_items;
DROP TABLE IF EXISTS blinkit_orders;
DROP TABLE IF EXISTS blinkit_products;
DROP TABLE IF EXISTS blinkit_customers;


-- ============================================================
-- 3. CREATE CUSTOMERS TABLE
-- ============================================================

CREATE TABLE blinkit_customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    email VARCHAR(150),
    address VARCHAR(255),
    area VARCHAR(100),
    pincode VARCHAR(10),
    registration_date DATE,
    customer_segment VARCHAR(50),
    total_orders INT,
    avg_order_value DECIMAL(10,2)
);


-- ============================================================
-- 4. CREATE PRODUCTS TABLE
-- ============================================================

CREATE TABLE blinkit_products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(150),
    category VARCHAR(100),
    brand VARCHAR(100),
    price DECIMAL(10,2),
    mrp DECIMAL(10,2),
    margin_percentage DECIMAL(5,2),
    shelf_life_days INT,
    min_stock_level INT,
    max_stock_level INT
);


-- ============================================================
-- 5. CREATE ORDERS TABLE
-- ============================================================

CREATE TABLE blinkit_orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    promised_delivery_time DATETIME,
    actual_delivery_time DATETIME,
    delivery_status VARCHAR(50),
    order_total DECIMAL(10,2),
    payment_method VARCHAR(50),
    delivery_partner_id INT,
    store_id INT,

    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES blinkit_customers(customer_id)
);


-- ============================================================
-- 6. CREATE ORDER ITEMS TABLE
-- ============================================================

CREATE TABLE blinkit_order_items (
    order_id INT,
    product_id INT,
    quantity INT,
    unit_price DECIMAL(10,2),

    PRIMARY KEY (order_id, product_id),

    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES blinkit_orders(order_id),

    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES blinkit_products(product_id)
);


-- ============================================================
-- 7. CREATE DELIVERY PERFORMANCE TABLE
-- ============================================================

CREATE TABLE blinkit_delivery_performance (
    order_id INT,
    delivery_partner_id INT,
    promised_time DATETIME,
    actual_time DATETIME,
    delivery_time_minutes DECIMAL(10,2),
    distance_km DECIMAL(10,2),
    delivery_status VARCHAR(50),
    reasons_if_delayed VARCHAR(255),

    CONSTRAINT fk_delivery_order
        FOREIGN KEY (order_id)
        REFERENCES blinkit_orders(order_id)
);


-- ============================================================
-- 8. CREATE CUSTOMER FEEDBACK TABLE
-- ============================================================

CREATE TABLE blinkit_customer_feedback (
    feedback_id INT PRIMARY KEY,
    order_id INT,
    customer_id INT,
    rating DECIMAL(3,1),
    feedback_text TEXT,
    feedback_category VARCHAR(100),
    sentiment VARCHAR(50),
    feedback_date DATE,

    CONSTRAINT fk_feedback_order
        FOREIGN KEY (order_id)
        REFERENCES blinkit_orders(order_id),

    CONSTRAINT fk_feedback_customer
        FOREIGN KEY (customer_id)
        REFERENCES blinkit_customers(customer_id)
);


-- ============================================================
-- 9. OPTIONAL: CHECK CREATED TABLES
-- ============================================================

SHOW TABLES;


-- ============================================================
-- 10. OPTIONAL: CHECK TABLE STRUCTURES
-- ============================================================

DESCRIBE blinkit_customers;
DESCRIBE blinkit_products;
DESCRIBE blinkit_orders;
DESCRIBE blinkit_order_items;
DESCRIBE blinkit_delivery_performance;
DESCRIBE blinkit_customer_feedback;


-- ============================================================
-- END OF DATABASE SETUP
-- ============================================================
```

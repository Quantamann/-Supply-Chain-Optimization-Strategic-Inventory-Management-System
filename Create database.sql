CREATE DATABASE inventory_managements;
Use	inventory_managements;
Select database();
CREATE TABLE orders (
order_id INT AUTO_INCREMENT PRIMARY KEY,
order_date DATE NOT NULL,
sku_id VARCHAR(50) NOT NULL,
order_quantity DECIMAL(10, 2) NOT NULL,
order_status VARCHAR(50) DEFAULT 'COMPLETED',
customer_id VARCHAR(50),
created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
INDEX idx_sku (sku_id),
INDEX idx_date (order_date)
);
Show tables;
Create table inventory
(
sku_id varchar(50) PRIMARY KEY,
sku_description text,
product_category varchar(100),
current_ctock_quantity decimal(10,2) not null,
units varchar(20),
unit_price DECIMAL(10, 2) NOT NULL,
average_lead_time_days INT,
maximum_lead_time_days INT,
supplier_id VARCHAR(50),
warehouse_location VARCHAR(100),
last_received_date DATE,
last_issued_date DATE,
is_active BOOLEAN DEFAULT TRUE,
created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

Show tables;


Describe orders;

Select count(*) from orders;
Select count(*) from inventory;

select * from orders limit 15;
--Create a database
CREATE DATABASE ProfitLeakAnalysis;
GO

--use it
USE ProfitLeakAnalysis;
GO

--Verify that database is working or not
SELECT DB_NAME() AS CurrentDatabase;

--CREATE SQL STRUCTURE
CREATE SCHEMA stg;
GO

CREATE SCHEMA dim;
GO

CREATE SCHEMA fact;
GO

CREATE SCHEMA analytics;
GO

--Verify
SELECT name
FROM sys.schemas
WHERE name IN ('stg', 'dim', 'fact', 'analytics');

--Create the staging Tables (Dimension Tables)

--Create stg.customers
CREATE TABLE stg.Customers
(
    customer_id VARCHAR(20) NOT NULL,
    signup_date DATE NULL,
    acquisition_channel VARCHAR(50) NULL,
    customer_type VARCHAR(50) NULL,
    country VARCHAR(50) NULL,
    state VARCHAR(100) NULL,
    city VARCHAR(100) NULL,
    age_band VARCHAR(50) NULL,
    income_band VARCHAR(50) NULL,
    loyalty_tier VARCHAR(50) NULL
);
GO

--Create stg.products
CREATE TABLE stg.Products
(
    product_id VARCHAR(20) NOT NULL,
    product_name VARCHAR(200) NULL,
    category VARCHAR(100) NULL,
    subcategory VARCHAR(100) NULL,
    brand VARCHAR(100) NULL,
    supplier_id VARCHAR(20) NULL,
    list_price DECIMAL(18,2) NULL,
    standard_cost DECIMAL(18,2) NULL,
    launch_date DATE NULL,
    product_status VARCHAR(50) NULL
);
GO

--Create stg.stores
CREATE TABLE stg.Stores
(
    store_id VARCHAR(20) NOT NULL,
    store_name VARCHAR(200) NULL,
    region VARCHAR(100) NULL,
    state VARCHAR(100) NULL,
    city VARCHAR(100) NULL,
    store_type VARCHAR(50) NULL,
    store_size_sqft INT NULL,
    opened_date DATE NULL
);
GO

--Create stg.campaigns
CREATE TABLE stg.Campaigns
(
    campaign_id VARCHAR(20) NOT NULL,
    campaign_name VARCHAR(200) NULL,
    channel VARCHAR(100) NULL,
    campaign_type VARCHAR(50) NULL,
    objective VARCHAR(100) NULL,
    start_date DATE NULL,
    target_segment VARCHAR(100) NULL
);
GO

--Create stg.Date
CREATE TABLE stg.Date
(
    [date] DATE NOT NULL,
    [year] INT NOT NULL,
    [quarter] VARCHAR(10) NULL,
    [month] INT NOT NULL,
    [month_name] VARCHAR(20) NULL,
    [week] INT NOT NULL,
    [day_of_week] VARCHAR(20) NULL,
    [is_weekend] BIT NULL,
    [is_holiday] BIT NULL,
    [season] VARCHAR(30) NULL
);


--Create staging Tables (Fact Tables)

--Create stg.Orders
CREATE TABLE stg.Orders
(
    order_id VARCHAR(20) NOT NULL,
    customer_id VARCHAR(20) NOT NULL,
    order_date DATE NOT NULL,
    store_id VARCHAR(20) NULL,
    sales_channel VARCHAR(50) NULL,
    device_type VARCHAR(50) NULL,
    shipping_method VARCHAR(50) NULL,
    payment_method VARCHAR(50) NULL,
    coupon_code VARCHAR(50) NULL,
    discount_rate DECIMAL(5,4) NULL,
    order_status VARCHAR(30) NULL
);
GO

--Create stg.OrderItems
CREATE TABLE stg.OrderItems
(
    order_item_id VARCHAR(20) NOT NULL,
    order_id VARCHAR(20) NOT NULL,
    product_id VARCHAR(20) NOT NULL,
    quantity INT NOT NULL,
    unit_list_price DECIMAL(18,2) NOT NULL,
    unit_selling_price DECIMAL(18,2) NOT NULL,
    discount_amount DECIMAL(18,2) NOT NULL,
    unit_cost DECIMAL(18,2) NOT NULL,
    gross_revenue DECIMAL(18,2) NOT NULL,
    product_cost DECIMAL(18,2) NOT NULL
);
GO

--Create stg.Returns
CREATE TABLE stg.Returns
(
    return_id VARCHAR(20) NOT NULL,
    order_id VARCHAR(20) NOT NULL,
    order_item_id VARCHAR(20) NOT NULL,
    customer_id VARCHAR(20) NOT NULL,
    product_id VARCHAR(20) NOT NULL,
    return_date DATE NOT NULL,
    return_quantity INT NOT NULL,
    return_reason VARCHAR(100) NULL,
    refund_amount DECIMAL(18,2) NOT NULL,
    return_shipping_cost DECIMAL(18,2) NOT NULL,
    restocking_cost DECIMAL(18,2) NOT NULL
);
GO

--Create stg.shipments
CREATE TABLE stg.Shipments
(
    shipment_id VARCHAR(20) NOT NULL,
    order_id VARCHAR(20) NOT NULL,
    warehouse_id VARCHAR(20) NULL,
    ship_date DATE NOT NULL,
    promised_date DATE NOT NULL,
    delivery_date DATE NOT NULL,
    shipping_cost DECIMAL(18,2) NOT NULL,
    delivery_status VARCHAR(30) NULL
);
GO

--Create stg.MarketingDaily
CREATE TABLE stg.MarketingDaily
(
    [date] DATE NOT NULL,
    campaign_id VARCHAR(20) NOT NULL,
    impressions INT NOT NULL,
    clicks INT NULL,
    ad_spend DECIMAL(18,2) NOT NULL,
    new_customers INT NOT NULL,
    attributed_orders INT NOT NULL,
    attributed_revenue DECIMAL(18,2) NOT NULL
);
GO

--IMPORT CLEANED CSV FILES
SELECT @@SERVERNAME AS ServerName;

--check that all tables data load successfully 

Select * from stg.Customers
Select * from stg.Campaigns
Select * from stg.Products
Select * from stg.Stores
Select * from stg.Shipments
Select * from stg.OrderItems
Select * from stg.Orders
Select * from stg.Date
Select * from stg.MarketingDaily
Select * from stg.Returns

-- Check Table row counts
SELECT 'Customers' AS TableName, COUNT(*) AS [RowCount] FROM stg.Customers
UNION ALL
SELECT 'Products', COUNT(*) FROM stg.Products
UNION ALL
SELECT 'Stores', COUNT(*) FROM stg.Stores
UNION ALL
SELECT 'Campaigns', COUNT(*) FROM stg.Campaigns
UNION ALL
SELECT 'Date', COUNT(*) FROM stg.Date
UNION ALL
SELECT 'Orders', COUNT(*) FROM stg.Orders
UNION ALL
SELECT 'OrderItems', COUNT(*) FROM stg.OrderItems
UNION ALL
SELECT 'Returns', COUNT(*) FROM stg.Returns
UNION ALL
SELECT 'Shipments', COUNT(*) FROM stg.Shipments 
UNION ALL
SELECT 'MarketingDaily', COUNT(*) FROM stg.MarketingDaily;

--

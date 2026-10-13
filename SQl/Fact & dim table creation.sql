--Create customer dimension
CREATE TABLE dim.Customers
(
    customer_id VARCHAR(20) NOT NULL PRIMARY KEY,
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

--Populate
INSERT INTO dim.Customers
(
    customer_id,
    signup_date,
    acquisition_channel,
    customer_type,
    country,
    state,
    city,
    age_band,
    income_band,
    loyalty_tier
)
SELECT
    customer_id,
    signup_date,
    acquisition_channel,
    customer_type,
    country,
    state,
    city,
    age_band,
    income_band,
    loyalty_tier
FROM stg.Customers;
GO

--Verify
SELECT COUNT(*) AS CustomerCount
FROM dim.Customers;

--Product Dimension
CREATE TABLE dim.Products
(
    product_id VARCHAR(20) NOT NULL PRIMARY KEY,
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

--Populate
INSERT INTO dim.Products
SELECT *
FROM stg.Products;
GO

--Verify
SELECT COUNT(*) AS ProductCount
FROM dim.Products;

--Store Dimesnion Table
CREATE TABLE dim.Stores
(
    store_id VARCHAR(20) NOT NULL PRIMARY KEY,
    store_name VARCHAR(200) NULL,
    region VARCHAR(100) NULL,
    state VARCHAR(100) NULL,
    city VARCHAR(100) NULL,
    store_type VARCHAR(50) NULL,
    store_size_sqft INT NULL,
    opened_date DATE NULL
);
GO

--Populate
INSERT INTO dim.Stores
SELECT *
FROM stg.Stores;
GO

--Verify
SELECT COUNT (*) AS StoreTable_count
FROM dim.Stores;

--CAMPAIGN DIMENSION
CREATE TABLE dim.Campaigns
(
    campaign_id VARCHAR(20) NOT NULL PRIMARY KEY,
    campaign_name VARCHAR(200) NULL,
    channel VARCHAR(100) NULL,
    campaign_type VARCHAR(50) NULL,
    objective VARCHAR(100) NULL,
    start_date DATE NULL,
    target_segment VARCHAR(100) NULL
);
GO

--Populate
INSERT INTO dim.Campaigns
SELECT *
FROM stg.Campaigns;
GO

--Verfiy
SELECT COUNT (*) AS CampaignsTable_count
FROM dim.Campaigns;

--Date Dimension
CREATE TABLE dim.Date
(
    [date] DATE NOT NULL PRIMARY KEY,
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
GO

--Populate
INSERT INTO dim.Date
SELECT *
FROM stg.Date;
GO

--Verify
SELECT COUNT (*) AS Date_count
FROM dim.Date;

--Create Fact Table

--Fact Order
CREATE TABLE fact.Orders
(
    order_id VARCHAR(20) NOT NULL PRIMARY KEY,
    customer_id VARCHAR(20) NOT NULL,
    order_date DATE NOT NULL,
    store_id VARCHAR(20) NULL,
    sales_channel VARCHAR(50) NULL,
    device_type VARCHAR(50) NULL,
    shipping_method VARCHAR(50) NULL,
    payment_method VARCHAR(50) NULL,
    coupon_code VARCHAR(50) NULL,
    discount_rate DECIMAL(5,4) NULL,
    order_status VARCHAR(30) NULL,

    CONSTRAINT FK_Orders_Customer
        FOREIGN KEY (customer_id)
        REFERENCES dim.Customers(customer_id),

    CONSTRAINT FK_Orders_Store
        FOREIGN KEY (store_id)
        REFERENCES dim.Stores(store_id),

    CONSTRAINT FK_Orders_Date
        FOREIGN KEY (order_date)
        REFERENCES dim.Date([date])
);
GO

--Populate fact.Orders and safely handle empty or missing store_ids
INSERT INTO fact.Orders
(
    order_id,
    customer_id,
    order_date,
    store_id,
    sales_channel,
    device_type,
    shipping_method,
    payment_method,
    coupon_code,
    discount_rate,
    order_status
)
SELECT 
    o.order_id,
    o.customer_id,
    o.order_date,
    -- Convert empty strings, whitespace, or missing matches to NULL
    CASE 
        WHEN LTRIM(RTRIM(o.store_id)) = '' OR o.store_id IS NULL THEN NULL
        WHEN s.store_id IS NULL THEN NULL
        ELSE o.store_id 
    END AS store_id,
    o.sales_channel,
    o.device_type,
    o.shipping_method,
    o.payment_method,
    o.coupon_code,
    o.discount_rate,
    o.order_status
FROM stg.Orders o
LEFT JOIN dim.Stores s 
    ON o.store_id = s.store_id;
GO

--Verify row count
SELECT COUNT(*) AS TotalRows 
FROM fact.Orders;

--Fact Order_item Table
CREATE TABLE fact.OrderItems
(
    order_item_id VARCHAR(20) NOT NULL PRIMARY KEY,
    order_id VARCHAR(20) NOT NULL,
    product_id VARCHAR(20) NOT NULL,
    quantity INT NOT NULL,
    unit_list_price DECIMAL(18,2) NOT NULL,
    unit_selling_price DECIMAL(18,2) NOT NULL,
    discount_amount DECIMAL(18,2) NOT NULL,
    unit_cost DECIMAL(18,2) NOT NULL,
    gross_revenue DECIMAL(18,2) NOT NULL,
    product_cost DECIMAL(18,2) NOT NULL,

    CONSTRAINT FK_OrderItems_Order
        FOREIGN KEY (order_id)
        REFERENCES fact.Orders(order_id),

    CONSTRAINT FK_OrderItems_Product
        FOREIGN KEY (product_id)
        REFERENCES dim.Products(product_id)
);
GO

--Populate
INSERT INTO fact.OrderItems
SELECT *
FROM stg.OrderItems;
GO

--Row count
SELECT COUNT(*) AS TotalRows 
FROM fact.OrderItems;

--Fact Returns
CREATE TABLE fact.Returns
(
    return_id VARCHAR(20) NOT NULL PRIMARY KEY,
    order_id VARCHAR(20) NOT NULL,
    order_item_id VARCHAR(20) NOT NULL,
    customer_id VARCHAR(20) NOT NULL,
    product_id VARCHAR(20) NOT NULL,
    return_date DATE NOT NULL,
    return_quantity INT NOT NULL,
    return_reason VARCHAR(100) NULL,
    refund_amount DECIMAL(18,2) NOT NULL,
    return_shipping_cost DECIMAL(18,2) NOT NULL,
    restocking_cost DECIMAL(18,2) NOT NULL,

    CONSTRAINT FK_Returns_Order
        FOREIGN KEY (order_id)
        REFERENCES fact.Orders(order_id),

    CONSTRAINT FK_Returns_OrderItem
        FOREIGN KEY (order_item_id)
        REFERENCES fact.OrderItems(order_item_id),

    CONSTRAINT FK_Returns_Customer
        FOREIGN KEY (customer_id)
        REFERENCES dim.Customers(customer_id),

    CONSTRAINT FK_Returns_Product
        FOREIGN KEY (product_id)
        REFERENCES dim.Products(product_id)
);
GO

--Populate
INSERT INTO fact.Returns
SELECT *
FROM stg.Returns;
GO

--Verify row count
SELECT COUNT(*) AS TotalRows 
FROM fact.Returns;

--Fact Shipments
CREATE TABLE fact.Shipments
(
    shipment_id VARCHAR(20) NOT NULL PRIMARY KEY,
    order_id VARCHAR(20) NOT NULL,
    warehouse_id VARCHAR(20) NULL,
    ship_date DATE NOT NULL,
    promised_date DATE NOT NULL,
    delivery_date DATE NOT NULL,
    shipping_cost DECIMAL(18,2) NOT NULL,
    delivery_status VARCHAR(30) NULL,

    CONSTRAINT FK_Shipments_Order
        FOREIGN KEY (order_id)
        REFERENCES fact.Orders(order_id)
);
GO

--Populate
INSERT INTO fact.Shipments
SELECT *
FROM stg.Shipments;
GO

SELECT COUNT(*) AS TotalRows 
FROM fact.Shipments;

--Fact Marketing
CREATE TABLE fact.MarketingDaily
(
    [date] DATE NOT NULL,
    campaign_id VARCHAR(20) NOT NULL,
    impressions INT NOT NULL,
    clicks INT NULL,
    ad_spend DECIMAL(18,2) NOT NULL,
    new_customers INT NOT NULL,
    attributed_orders INT NOT NULL,
    attributed_revenue DECIMAL(18,2) NOT NULL,

    CONSTRAINT PK_MarketingDaily
        PRIMARY KEY ([date], campaign_id),

    CONSTRAINT FK_Marketing_Date
        FOREIGN KEY ([date])
        REFERENCES dim.Date([date]),

    CONSTRAINT FK_Marketing_Campaign
        FOREIGN KEY (campaign_id)
        REFERENCES dim.Campaigns(campaign_id)
);
GO

--Populate
INSERT INTO fact.MarketingDaily
SELECT *
FROM stg.MarketingDaily;
GO

SELECT COUNT(*) AS TotalRows 
FROM fact.MarketingDaily;

--Verify rows by Schema Name
SELECT
    SCHEMA_NAME(t.schema_id) AS SchemaName,
    t.name AS TableName,
    SUM(p.rows) AS [RowCount]
FROM sys.tables t
JOIN sys.partitions p
    ON t.object_id = p.object_id
WHERE p.index_id IN (0,1)
GROUP BY t.schema_id, t.name
ORDER BY SchemaName, TableName;







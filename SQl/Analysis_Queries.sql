--Check Customer ID's
SELECT COUNT(*) AS TotalRows,
       COUNT(DISTINCT customer_id) AS UniqueCustomerIDs
FROM stg.Customers;

--Check Product_Ids
Select Count(*) As TotalProducts,
Count(Distinct product_id) As UniqueProductIDS
From stg.Products

--Check Order_Ids
SELECT COUNT(*) AS TotalRows,
COUNT(DISTINCT order_id) AS UniqueOrderIDs
FROM stg.Orders;

--Check order_item Ids
SELECT COUNT(*) AS TotalRows,
COUNT(DISTINCT order_item_id) AS UniqueOrderItemIDs
FROM stg.OrderItems;


--CHECK THE RELTIONSHIP IN TABLES
SELECT COUNT(*) AS OrphanOrders
FROM stg.Orders o
LEFT JOIN stg.Customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT (*) AS OrphanOrder
FROM stg.OrderItems oi
LEFT JOIN stg.Orders o
ON oi.order_id=o.order_id
WHERE o.order_id IS NULL;

SELECT COUNT(*) AS OrphanOrder
FROM stg.OrderItems oi
LEFT JOIN stg.Products p
ON oi.product_id=p.product_id
WHERE p.product_id is NULL

SELECT COUNT(*) AS OrphanReturns
FROM stg.Returns r
LEFT JOIN stg.Orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT COUNT(*) AS OrphanReturnItems
FROM stg.Returns r
LEFT JOIN stg.OrderItems oi
    ON r.order_item_id = oi.order_item_id
WHERE oi.order_item_id IS NULL;

SELECT COUNT(*) AS OrphanShipments
FROM stg.Shipments s
LEFT JOIN stg.Orders o
    ON s.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT COUNT(*) AS OrphanMarketingRows
FROM stg.MarketingDaily m
LEFT JOIN stg.Campaigns c
    ON m.campaign_id = c.campaign_id
WHERE c.campaign_id IS NULL;

--Check clean marketing grain  (means we check is their any duplicate date + campaign combo )
SELECT
    [date],
    campaign_id,
    COUNT(*) AS [RowCount]
FROM stg.MarketingDaily
GROUP BY
    [date],
    campaign_id
HAVING COUNT(*) > 1;


--CHECK FINANCIAL LOGIC

--Spelling price check
SELECT COUNT(*) AS ERRORS
FROM stg.OrderItems
WHERE unit_selling_price > unit_list_price;

--Discount Check
SELECT COUNT(*) AS ERROR
FROM stg.OrderItems
WHERE ABS(
discount_amount - (unit_list_price-unit_selling_price)) > 0.01;

--Revenue check
SELECT COUNT(*) AS ERROR
FROM stg.OrderItems
WHERE ABS( gross_revenue - (quantity * unit_selling_price) ) > 0.01;

--Product cost check
SELECT COUNT(*) AS ERROR
FROM stg.OrderItems
WHERE ABS( product_cost - (quantity * unit_cost)) > 0.01;


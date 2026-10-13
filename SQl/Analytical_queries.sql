--Create Analytical view  (Our view should look like: Orders__OrderItems__Customers__Products)
CREATE OR ALTER VIEW analytics.OrderItemAnalysis
AS
SELECT
    oi.order_item_id,
    oi.order_id,
    o.order_date,
    o.customer_id,
    c.customer_type,
    c.loyalty_tier,
    c.acquisition_channel,

    o.sales_channel,
    o.device_type,
    o.shipping_method,
    o.coupon_code,
    o.discount_rate,
    o.order_status,

    oi.product_id,
    p.product_name,
    p.category,
    p.subcategory,
    p.brand,

    oi.quantity,
    oi.unit_list_price,
    oi.unit_selling_price,
    oi.discount_amount,
    oi.unit_cost,
    oi.gross_revenue,
    oi.product_cost,

    CAST(
        oi.gross_revenue - oi.product_cost
        AS DECIMAL(18,2)
    ) AS ProductMargin

FROM fact.OrderItems oi

INNER JOIN fact.Orders o
    ON oi.order_id = o.order_id

INNER JOIN dim.Customers c
    ON o.customer_id = c.customer_id

INNER JOIN dim.Products p
    ON oi.product_id = p.product_id;
GO

--Now we test it is it working
SELECT TOP 20 *
FROM analytics.OrderItemAnalysis;

--For profit calculation we have to perform analysis on Completed orders not on cancel and pending orders so we create a 
--compelete order view
CREATE OR ALTER VIEW analytics.CompletedOrderItems
AS
SELECT *
FROM analytics.OrderItemAnalysis
WHERE order_status = 'Completed';
GO

--Test it
SELECT COUNT(*) AS CompletedOrderItems
FROM analytics.CompletedOrderItems;

--NOW WE START OUR ACTUAL ANALYSIS that "REVENUE IS GROWING. SO WHY PROFIT ISN'T? "

--ANALYSIS 1:Total Revenue
SELECT SUM(gross_revenue) as TotalRevenue
FROM analytics.CompletedOrderItems

--ANALYSIS 2:Product cost
SELECT SUM(product_cost) as TotalProductCost
FROM analytics.CompletedOrderItems

--ANALYSIS 3:Product margin
SELECT
SUM(gross_revenue) as Revenue,
SUM(product_cost) as ProductCost,
SUM(gross_revenue - product_cost) as ProfitMargin
FROM analytics.CompletedOrderItems

--Analysis 4:Revenue by Year (Is revenue actually growing)
SELECT
YEAR(order_date) as SalesYear,
SUM(gross_revenue) as Revenue
FROM analytics.CompletedOrderItems
GROUP BY YEAR(order_date)
ORDER BY SalesYear

--Analysis 5: Margin by year
SELECT
    YEAR(order_date) AS SalesYear,

    SUM(gross_revenue) AS Revenue,

    SUM(product_cost) AS ProductCost,

    SUM(gross_revenue - product_cost) AS ProductMargin,

    CAST(
        100.0 *
        SUM(gross_revenue - product_cost)
        / NULLIF(SUM(gross_revenue), 0)
        AS DECIMAL(10,2)
    ) AS ProductMarginPct

FROM analytics.CompletedOrderItems

GROUP BY YEAR(order_date)

ORDER BY SalesYear;

--Analysis 6: Revenue by Month:
SELECT
Year(order_date) as SalesYear,
Month(order_date) as SalesMonth,
Sum(gross_revenue) as Revenue
FROM analytics.CompletedOrderItems
GROUP BY 
   Year(order_date),
   Month(order_date)
ORDER BY
    SalesYear,
    SalesMonth;

--Analysis 7:Margin by Category
SELECT
    category,

    SUM(gross_revenue) AS Revenue,

    SUM(product_cost) AS ProductCost,

    SUM(gross_revenue - product_cost) AS ProductMargin,

    CAST(
        100.0 *
        SUM(gross_revenue - product_cost)
        / NULLIF(SUM(gross_revenue), 0)
        AS DECIMAL(10,2)
    ) AS MarginPct

FROM analytics.CompletedOrderItems

GROUP BY category

ORDER BY Revenue DESC;

--Discount Analysis:
SELECT
    discount_rate,

    COUNT(DISTINCT order_id) AS Orders,

    SUM(gross_revenue) AS Revenue,

    SUM(discount_amount * quantity) AS DiscountValue,

    SUM(gross_revenue - product_cost) AS ProductMargin,

    CAST(
        100.0 *
        SUM(gross_revenue - product_cost)
        / NULLIF(SUM(gross_revenue), 0)
        AS DECIMAL(10,2)
    ) AS MarginPct

FROM analytics.CompletedOrderItems

GROUP BY discount_rate

ORDER BY discount_rate;

--Sales Channel profitability
SELECT
    sales_channel,

    COUNT(DISTINCT order_id) AS Orders,

    SUM(gross_revenue) AS Revenue,

    SUM(product_cost) AS ProductCost,

    SUM(gross_revenue - product_cost) AS ProductMargin,

    CAST(
        100.0 *
        SUM(gross_revenue - product_cost)
        / NULLIF(SUM(gross_revenue), 0)
        AS DECIMAL(10,2)
    ) AS MarginPct

FROM analytics.CompletedOrderItems

GROUP BY sales_channel

ORDER BY Revenue DESC;


--Analysis 10: Customer loyalty economics
SELECT
    loyalty_tier,

    COUNT(DISTINCT customer_id) AS Customers,

    COUNT(DISTINCT order_id) AS Orders,

    SUM(gross_revenue) AS Revenue,

    SUM(gross_revenue - product_cost) AS ProductMargin,

    CAST(
        100.0 *
        SUM(gross_revenue - product_cost)
        / NULLIF(SUM(gross_revenue), 0)
        AS DECIMAL(10,2)
    ) AS MarginPct

FROM analytics.CompletedOrderItems

GROUP BY loyalty_tier

ORDER BY Revenue DESC;

--Analysis 11:Customer type economics
SELECT
    customer_type,

    COUNT(DISTINCT customer_id) AS Customers,

    COUNT(DISTINCT order_id) AS Orders,

    SUM(gross_revenue) AS Revenue,

    SUM(gross_revenue - product_cost) AS ProductMargin,

    CAST(
        100.0 *
        SUM(gross_revenue - product_cost)
        / NULLIF(SUM(gross_revenue), 0)
        AS DECIMAL(10,2)
    ) AS MarginPct

FROM analytics.CompletedOrderItems

GROUP BY customer_type;

--Now RETURN ANALYSIS
SELECT
    COUNT(*) AS ReturnEvents,
    SUM(return_quantity) AS ReturnedUnits,
    SUM(refund_amount) AS RefundAmount,
    SUM(return_shipping_cost) AS ReturnShippingCost,
    SUM(restocking_cost) AS RestockingCost
FROM fact.Returns;

--Now we will check Return reasons
SELECT
    return_reason,

    COUNT(*) AS ReturnEvents,

    SUM(return_quantity) AS ReturnedUnits,

    SUM(refund_amount) AS RefundAmount,

    SUM(return_shipping_cost) AS ReturnShippingCost,

    SUM(restocking_cost) AS RestockingCost

FROM fact.Returns

GROUP BY return_reason

ORDER BY RefundAmount DESC;

--Returns by product category
SELECT
    p.category,

    SUM(r.return_quantity) AS ReturnedUnits,

    SUM(r.refund_amount) AS RefundAmount,

    SUM(r.return_shipping_cost) AS ReturnShippingCost,

    SUM(r.restocking_cost) AS RestockingCost

FROM fact.Returns r

INNER JOIN dim.Products p
    ON r.product_id = p.product_id

GROUP BY p.category

ORDER BY RefundAmount DESC;

--Fullfilment Analysis
SELECT
    delivery_status,

    COUNT(*) AS Shipments,

    SUM(shipping_cost) AS ShippingCost,

    AVG(shipping_cost) AS AvgShippingCost

FROM fact.Shipments

GROUP BY delivery_status;

--Shipping cost by year
SELECT
    YEAR(ship_date) AS ShippingYear,

    COUNT(*) AS Shipments,

    SUM(shipping_cost) AS ShippingCost

FROM fact.Shipments

GROUP BY YEAR(ship_date)

ORDER BY ShippingYear;

--Late delivery rate
SELECT
    CAST(
        100.0 *
        SUM(
            CASE
                WHEN delivery_status = 'Late' THEN 1
                ELSE 0
            END
        )
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS LateDeliveryPct

FROM fact.Shipments;

--CUSTOMER ECONOMICS

--Revenue per customer
SELECT
    customer_id,

    COUNT(DISTINCT order_id) AS Orders,

    SUM(gross_revenue) AS Revenue,

    SUM(gross_revenue - product_cost) AS ProductMargin

FROM analytics.CompletedOrderItems

GROUP BY customer_id

ORDER BY Revenue DESC;

--Repeat customer Analysis:
WITH CustomerOrders AS
(
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS OrderCount
    FROM analytics.CompletedOrderItems
    GROUP BY customer_id
)

SELECT
    CASE
        WHEN OrderCount = 1 THEN 'One-Time'
        WHEN OrderCount BETWEEN 2 AND 4 THEN 'Repeat'
        ELSE 'Highly Repeat'
    END AS CustomerSegment,

    COUNT(*) AS Customers

FROM CustomerOrders

GROUP BY
    CASE
        WHEN OrderCount = 1 THEN 'One-Time'
        WHEN OrderCount BETWEEN 2 AND 4 THEN 'Repeat'
        ELSE 'Highly Repeat'
    END

ORDER BY Customers DESC;

--Marketing Economics

--Campaign performance
SELECT
    c.campaign_id,
    c.campaign_name,
    c.channel,
    c.campaign_type,
    c.objective,
    c.target_segment,

    SUM(m.impressions) AS Impressions,

    SUM(m.clicks) AS Clicks,

    SUM(m.ad_spend) AS AdSpend,

    SUM(m.new_customers) AS NewCustomers,

    SUM(m.attributed_orders) AS AttributedOrders,

    SUM(m.attributed_revenue) AS AttributedRevenue

FROM fact.MarketingDaily m

INNER JOIN dim.Campaigns c
    ON m.campaign_id = c.campaign_id

GROUP BY
    c.campaign_id,
    c.campaign_name,
    c.channel,
    c.campaign_type,
    c.objective,
    c.target_segment

ORDER BY AttributedRevenue DESC;

--ROAS (Return on ADs)
SELECT
    c.channel,

    SUM(m.ad_spend) AS AdSpend,

    SUM(m.attributed_revenue) AS AttributedRevenue,

    CAST(
        SUM(m.attributed_revenue)
        / NULLIF(SUM(m.ad_spend), 0)
        AS DECIMAL(10,2)
    ) AS ROAS

FROM fact.MarketingDaily m

INNER JOIN dim.Campaigns c
    ON m.campaign_id = c.campaign_id

GROUP BY c.channel

ORDER BY ROAS DESC;


--NOW WE BUILD PROFITABILITY VIEW:
CREATE OR ALTER VIEW analytics.ProfitabilityBase
AS
WITH Sales AS
(
    SELECT
        o.order_id,
        o.customer_id,
        o.order_date,
        o.sales_channel,

        SUM(oi.gross_revenue) AS Revenue,
        SUM(oi.product_cost) AS ProductCost

    FROM fact.Orders o

    INNER JOIN fact.OrderItems oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'Completed'

    GROUP BY
        o.order_id,
        o.customer_id,
        o.order_date,
        o.sales_channel
),

Returns AS
(
    SELECT
        order_id,

        SUM(refund_amount) AS RefundAmount,

        SUM(return_shipping_cost) AS ReturnShippingCost,

        SUM(restocking_cost) AS RestockingCost

    FROM fact.Returns

    GROUP BY order_id
),

Shipping AS
(
    SELECT
        order_id,

        SUM(shipping_cost) AS ShippingCost

    FROM fact.Shipments

    GROUP BY order_id
)

SELECT
    s.order_id,
    s.customer_id,
    s.order_date,
    s.sales_channel,

    s.Revenue,
    s.ProductCost,

    ISNULL(r.RefundAmount, 0) AS RefundAmount,

    ISNULL(r.ReturnShippingCost, 0) AS ReturnShippingCost,

    ISNULL(r.RestockingCost, 0) AS RestockingCost,

    ISNULL(sh.ShippingCost, 0) AS ShippingCost,

    CAST(
        s.Revenue
        - s.ProductCost
        - ISNULL(r.RefundAmount, 0)
        - ISNULL(r.ReturnShippingCost, 0)
        - ISNULL(r.RestockingCost, 0)
        - ISNULL(sh.ShippingCost, 0)
        AS DECIMAL(18,2)
    ) AS ContributionProfit

FROM Sales s

LEFT JOIN Returns r
    ON s.order_id = r.order_id

LEFT JOIN Shipping sh
    ON s.order_id = sh.order_id;
GO

--Executive profitability results
SELECT
    SUM(Revenue) AS Revenue,

    SUM(ProductCost) AS ProductCost,

    SUM(RefundAmount) AS Refunds,

    SUM(ReturnShippingCost) AS ReturnShippingCost,

    SUM(RestockingCost) AS RestockingCost,

    SUM(ShippingCost) AS ShippingCost,

    SUM(ContributionProfit) AS ContributionProfit,

    CAST(
        100.0 *
        SUM(ContributionProfit)
        / NULLIF(SUM(Revenue), 0)
        AS DECIMAL(10,2)
    ) AS ContributionMarginPct

FROM analytics.ProfitabilityBase;

--Profitability by Year
SELECT
    YEAR(order_date) AS SalesYear,

    SUM(Revenue) AS Revenue,

    SUM(ProductCost) AS ProductCost,

    SUM(RefundAmount) AS Refunds,

    SUM(ReturnShippingCost) AS ReturnShippingCost,

    SUM(RestockingCost) AS RestockingCost,

    SUM(ShippingCost) AS ShippingCost,

    SUM(ContributionProfit) AS ContributionProfit,

    CAST(
        100.0 *
        SUM(ContributionProfit)
        / NULLIF(SUM(Revenue), 0)
        AS DECIMAL(10,2)
    ) AS ContributionMarginPct

FROM analytics.ProfitabilityBase

GROUP BY YEAR(order_date)

ORDER BY SalesYear;

--validation in returns (51 excess units found)

--first check the return table
SELECT Top 5 * FROM fact.Returns;

--Then
SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'fact'
  AND TABLE_NAME = 'Returns'
ORDER BY ORDINAL_POSITION;

--Create a validation view:
CREATE OR ALTER VIEW analytics.ValidatedReturns
AS

WITH ReturnBase AS
(
    SELECT
        r.return_id,
        r.order_id,
        r.order_item_id,
        r.customer_id,
        r.product_id,
        r.return_date,
        r.return_quantity,
        r.return_reason,
        r.refund_amount,
        r.return_shipping_cost,
        r.restocking_cost,

        oi.quantity AS purchased_quantity,

        SUM(r.return_quantity) OVER
        (
            PARTITION BY r.order_item_id
            ORDER BY r.return_date, r.return_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_return_quantity

    FROM fact.Returns r

    INNER JOIN fact.OrderItems oi
        ON r.order_item_id = oi.order_item_id
),

Validated AS
(
    SELECT
        *,

        CASE
            WHEN cumulative_return_quantity <= purchased_quantity
                THEN return_quantity

            WHEN cumulative_return_quantity - return_quantity >= purchased_quantity
                THEN 0

            ELSE purchased_quantity
                 - (cumulative_return_quantity - return_quantity)
        END AS valid_return_quantity

    FROM ReturnBase
)

SELECT
    return_id,
    order_id,
    order_item_id,
    customer_id,
    product_id,
    return_date,
    return_quantity,
    valid_return_quantity,
    purchased_quantity,
    return_reason,

    refund_amount,
    return_shipping_cost,
    restocking_cost,

    CASE
        WHEN valid_return_quantity < return_quantity
            THEN 'Over-return quantity'
        ELSE 'Valid'
    END AS return_quantity_issue,

    CAST(
        refund_amount
        * valid_return_quantity
        / NULLIF(return_quantity, 0)
        AS DECIMAL(18,2)
    ) AS valid_refund_amount,

    CAST(
        return_shipping_cost
        * valid_return_quantity
        / NULLIF(return_quantity, 0)
        AS DECIMAL(18,2)
    ) AS valid_return_shipping_cost,

    CAST(
        restocking_cost
        * valid_return_quantity
        / NULLIF(return_quantity, 0)
        AS DECIMAL(18,2)
    ) AS valid_restocking_cost

FROM Validated;
GO

--Validate that correction
SELECT
    COUNT(*) AS ReturnRecords,
    SUM(return_quantity) AS RawReturnedUnits,
    SUM(valid_return_quantity) AS ValidReturnedUnits,
    SUM(return_quantity - valid_return_quantity) AS ExcessUnits
FROM analytics.ValidatedReturns;


--Check the affected records
SELECT
    return_id,
    order_id,
    order_item_id,
    return_date,
    return_quantity,
    valid_return_quantity,
    purchased_quantity,
    return_quantity_issue
FROM analytics.ValidatedReturns
WHERE return_quantity_issue = 'Over-return quantity'
ORDER BY order_item_id, return_date, return_id;

--Validate final correction
SELECT
    SUM(refund_amount) AS RawRefunds,
    SUM(valid_refund_amount) AS ValidRefunds,

    SUM(return_shipping_cost) AS RawReturnShipping,
    SUM(valid_return_shipping_cost) AS ValidReturnShipping,

    SUM(restocking_cost) AS RawRestocking,
    SUM(valid_restocking_cost) AS ValidRestocking
FROM analytics.ValidatedReturns;

--Check that no item is still over-returned
SELECT
    order_item_id,
    purchased_quantity,
    SUM(valid_return_quantity) AS valid_returned_quantity
FROM analytics.ValidatedReturns
GROUP BY
    order_item_id,
    purchased_quantity
HAVING SUM(valid_return_quantity) > purchased_quantity;

--Check financial reconcilition (compare raw vs valid return cost)
SELECT

    SUM(refund_amount)
        - SUM(valid_refund_amount)
        AS RefundAdjustment,

    SUM(return_shipping_cost)
        - SUM(valid_return_shipping_cost)
        AS ShippingAdjustment,

    SUM(restocking_cost)
        - SUM(valid_restocking_cost)
        AS RestockingAdjustment,

    (
        SUM(refund_amount)
        - SUM(valid_refund_amount)
    )
    +
    (
        SUM(return_shipping_cost)
        - SUM(valid_return_shipping_cost)
    )
    +
    (
        SUM(restocking_cost)
        - SUM(valid_restocking_cost)
    )
    AS TotalAdjustment

FROM analytics.ValidatedReturns;


--Rebuild view: analytics.Profitability.Base
CREATE OR ALTER VIEW analytics.ProfitabilityBase
AS

WITH Sales AS
(
    SELECT
        oi.order_id,

        SUM(oi.gross_revenue) AS Revenue,

        SUM(oi.product_cost) AS ProductCost

    FROM fact.OrderItems oi

    INNER JOIN fact.Orders o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'Completed'

    GROUP BY
        oi.order_id
),

Returns AS
(
    SELECT
        order_id,

        SUM(valid_refund_amount) AS Refunds,

        SUM(valid_return_shipping_cost) AS ReturnShippingCost,

        SUM(valid_restocking_cost) AS RestockingCost

    FROM analytics.ValidatedReturns

    GROUP BY
        order_id
),

Shipping AS
(
    SELECT
        order_id,

        SUM(shipping_cost) AS ShippingCost

    FROM fact.Shipments

    GROUP BY
        order_id
)

SELECT

    s.order_id,

    s.Revenue,

    s.ProductCost,

    ISNULL(r.Refunds, 0) AS Refunds,

    ISNULL(r.ReturnShippingCost, 0)
        AS ReturnShippingCost,

    ISNULL(r.RestockingCost, 0)
        AS RestockingCost,

    ISNULL(sh.ShippingCost, 0)
        AS ShippingCost,

    s.Revenue
        - s.ProductCost
        - ISNULL(r.Refunds, 0)
        - ISNULL(r.ReturnShippingCost, 0)
        - ISNULL(r.RestockingCost, 0)
        - ISNULL(sh.ShippingCost, 0)
        AS ContributionProfit

FROM Sales s

LEFT JOIN Returns r
    ON s.order_id = r.order_id

LEFT JOIN Shipping sh
    ON s.order_id = sh.order_id;
GO

--Validate the final profitability dataset
SELECT
    COUNT(*) AS CompletedOrders,

    SUM(Revenue) AS Revenue,

    SUM(ProductCost) AS ProductCost,

    SUM(Refunds) AS Refunds,

    SUM(ReturnShippingCost) AS ReturnShippingCost,

    SUM(RestockingCost) AS RestockingCost,

    SUM(ShippingCost) AS ShippingCost,

    SUM(ContributionProfit) AS ContributionProfit,

    CAST(
        100.0 * SUM(ContributionProfit)
        / NULLIF(SUM(Revenue), 0)
        AS DECIMAL(10,2)
    ) AS ContributionMarginPct

FROM analytics.ProfitabilityBase;

--creating one powerful SQL analytical dataset
CREATE OR ALTER VIEW analytics.OrderProfitabilityDetail
AS

SELECT

    o.order_id,
    o.customer_id,
    o.order_date,
    o.sales_channel,
    o.device_type,
    o.shipping_method,
    o.coupon_code,
    o.discount_rate,

    p.product_id,
    p.product_name,
    p.category,
    p.subcategory,
    p.brand,

    oi.order_item_id,
    oi.quantity,
    oi.unit_list_price,
    oi.unit_selling_price,
    oi.discount_amount,
    oi.unit_cost,
    oi.gross_revenue,
    oi.product_cost,

    oi.gross_revenue - oi.product_cost
        AS ProductMargin

FROM fact.Orders o

INNER JOIN fact.OrderItems oi
    ON o.order_id = oi.order_id

INNER JOIN dim.Products p
    ON oi.product_id = p.product_id

WHERE o.order_status = 'Completed';
GO

--Creating other three views use in deep analysis

--First we verfiy that our validation returned layer exists or not
SELECT TOP 5 *
FROM analytics.ValidatedReturns;

SELECT
    SUM(valid_return_quantity) AS ValidReturnedUnits,
    SUM(valid_refund_amount) AS ValidRefunds,
    SUM(valid_return_shipping_cost) AS ValidReturnShipping,
    SUM(valid_restocking_cost) AS ValidRestocking
FROM analytics.ValidatedReturns;


--View 1: 'OrderProfitabilityDetail' (Already exists) so we just rechecked its data
SELECT TOP 1 *
FROM analytics.OrderProfitabilityDetail;

--View 2:Customer Economics
CREATE OR ALTER VIEW analytics.CustomerEconomics
AS

WITH OrderBase AS
(
    SELECT
        o.customer_id,
        o.order_id,
        o.order_date,

        SUM(oi.gross_revenue) AS Revenue,
        SUM(oi.product_cost) AS ProductCost

    FROM fact.Orders o

    INNER JOIN fact.OrderItems oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'Completed'

    GROUP BY
        o.customer_id,
        o.order_id,
        o.order_date
),

CustomerOrders AS
(
    SELECT
        customer_id,

        COUNT(*) AS CompletedOrders,

        SUM(Revenue) AS Revenue,

        SUM(ProductCost) AS ProductCost,

        MIN(order_date) AS FirstOrderDate,

        MAX(order_date) AS LastOrderDate

    FROM OrderBase

    GROUP BY customer_id
),

CustomerReturns AS
(
    SELECT
        customer_id,

        SUM(valid_return_quantity) AS ReturnedUnits,

        SUM(valid_refund_amount) AS Refunds,

        SUM(valid_return_shipping_cost)
            AS ReturnShippingCost,

        SUM(valid_restocking_cost)
            AS RestockingCost

    FROM analytics.ValidatedReturns

    GROUP BY customer_id
)

SELECT

    c.customer_id,

    c.signup_date,
    c.acquisition_channel,
    c.customer_type,
    c.country,
    c.state,
    c.city,
    c.age_band,
    c.income_band,
    c.loyalty_tier,

    ISNULL(o.CompletedOrders, 0)
        AS CompletedOrders,

    ISNULL(o.Revenue, 0)
        AS Revenue,

    ISNULL(o.ProductCost, 0)
        AS ProductCost,

    ISNULL(o.Revenue, 0)
        - ISNULL(o.ProductCost, 0)
        AS ProductMargin,

    ISNULL(r.ReturnedUnits, 0)
        AS ReturnedUnits,

    ISNULL(r.Refunds, 0)
        AS Refunds,

    ISNULL(r.ReturnShippingCost, 0)
        AS ReturnShippingCost,

    ISNULL(r.RestockingCost, 0)
        AS RestockingCost,

    ISNULL(o.Revenue, 0)
        - ISNULL(o.ProductCost, 0)
        - ISNULL(r.Refunds, 0)
        - ISNULL(r.ReturnShippingCost, 0)
        - ISNULL(r.RestockingCost, 0)
        AS ContributionBeforeOutboundShipping,

    o.FirstOrderDate,
    o.LastOrderDate,

    CASE
        WHEN ISNULL(o.CompletedOrders, 0) = 0
            THEN 'No Completed Orders'

        WHEN o.CompletedOrders = 1
            THEN 'One-Time'

        WHEN o.CompletedOrders BETWEEN 2 AND 4
            THEN 'Repeat'

        ELSE 'Highly Repeat'
    END AS CustomerSegment

FROM dim.Customers c

LEFT JOIN CustomerOrders o
    ON c.customer_id = o.customer_id

LEFT JOIN CustomerReturns r
    ON c.customer_id = r.customer_id;
GO

--Check the view (columns)
SELECT TOP 1 *
FROM analytics.CustomerEconomics;

--View 3:Fulfillment Analysis
CREATE OR ALTER VIEW analytics.FulfillmentAnalysis
AS

SELECT

    s.shipment_id,

    s.order_id,

    o.customer_id,

    o.order_date,

    o.sales_channel,

    o.shipping_method,

    s.warehouse_id,

    s.ship_date,

    s.promised_date,

    s.delivery_date,

    s.shipping_cost,

    s.delivery_status,

    DATEDIFF(
        DAY,
        s.ship_date,
        s.delivery_date
    ) AS DeliveryDays,

    DATEDIFF(
        DAY,
        s.ship_date,
        s.promised_date
    ) AS PromisedDeliveryDays,

    DATEDIFF(
        DAY,
        s.promised_date,
        s.delivery_date
    ) AS DaysVsPromise,

    CASE
        WHEN s.delivery_status = 'Late'
            THEN 1
        ELSE 0
    END AS IsLate,

    CASE
        WHEN s.delivery_date > s.promised_date
            THEN 1
        ELSE 0
    END AS DeliveryMiss,

    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM analytics.ValidatedReturns r
            WHERE r.order_id = s.order_id
              AND r.valid_return_quantity > 0
        )
        THEN 1
        ELSE 0
    END AS HasReturn

FROM fact.Shipments s

INNER JOIN fact.Orders o
    ON s.order_id = o.order_id

WHERE o.order_status = 'Completed';
GO

Select Top 1 * from analytics.FulfillmentAnalysis

--View 4:Marketing Economics
CREATE OR ALTER VIEW analytics.MarketingEconomics
AS

SELECT

    m.date,

    m.campaign_id,

    c.campaign_name,
    c.channel,
    c.campaign_type,
    c.objective,
    c.start_date,
    c.target_segment,

    m.impressions,
    m.clicks,
    m.ad_spend,
    m.new_customers,
    m.attributed_orders,
    m.attributed_revenue,

    CASE
        WHEN m.ad_spend > 0
            THEN m.attributed_revenue
                 / m.ad_spend
        ELSE NULL
    END AS AttributedROAS,

    CASE
        WHEN m.new_customers > 0
            THEN m.ad_spend
                 / m.new_customers
        ELSE NULL
    END AS CostPerNewCustomer,

    CASE
        WHEN m.impressions > 0
            THEN 100.0 * m.clicks
                 / m.impressions
        ELSE NULL
    END AS ClickThroughRatePct

FROM fact.MarketingDaily m

INNER JOIN dim.Campaigns c
    ON m.campaign_id = c.campaign_id;
GO


--Validate all four views
SELECT COUNT(*) AS Rows
FROM analytics.OrderProfitabilityDetail;

SELECT COUNT(*) AS Rows
FROM analytics.CustomerEconomics;

SELECT COUNT(*) AS Rows
FROM analytics.FulfillmentAnalysis;

SELECT COUNT(*) AS Rows
FROM analytics.MarketingEconomics;

--Check server name for python connection
SELECT @@SERVERNAME;
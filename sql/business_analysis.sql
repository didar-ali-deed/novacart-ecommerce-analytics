-- ============================================================
-- NovaCart E-commerce Analytics
-- Business Analysis with SQLite
-- ============================================================
-- Database: novacart.db
--
-- Tables:
-- customers
-- products
-- orders
-- order_items
-- returns
-- marketing
--
-- Run these queries in VS Code, DB Browser for SQLite,
-- DBeaver, or another SQLite-compatible client.
-- ============================================================


-- ------------------------------------------------------------
-- 1. EXECUTIVE KPI SUMMARY
-- ------------------------------------------------------------

SELECT
    ROUND(SUM(oi.Net_Sales), 2) AS Total_Revenue,
    ROUND(SUM(oi.Profit), 2) AS Total_Profit,
    ROUND(
        SUM(oi.Profit) * 100.0 / NULLIF(SUM(oi.Net_Sales), 0),
        2
    ) AS Profit_Margin_Pct,
    COUNT(DISTINCT o.Order_ID) AS Completed_Orders,
    COUNT(DISTINCT o.Customer_ID) AS Active_Customers,
    SUM(oi.Quantity) AS Units_Sold,
    ROUND(
        SUM(oi.Net_Sales) * 1.0 / COUNT(DISTINCT o.Order_ID),
        2
    ) AS Average_Order_Value
FROM orders o
JOIN order_items oi
    ON o.Order_ID = oi.Order_ID
WHERE o.Order_Status = 'Completed';


-- ------------------------------------------------------------
-- 2. MONTHLY REVENUE AND PROFIT
-- ------------------------------------------------------------

SELECT
    SUBSTR(o.Order_Date, 1, 7) AS Year_Month,
    ROUND(SUM(oi.Net_Sales), 2) AS Revenue,
    ROUND(SUM(oi.Profit), 2) AS Profit,
    COUNT(DISTINCT o.Order_ID) AS Orders,
    COUNT(DISTINCT o.Customer_ID) AS Customers
FROM orders o
JOIN order_items oi
    ON o.Order_ID = oi.Order_ID
WHERE o.Order_Status = 'Completed'
GROUP BY SUBSTR(o.Order_Date, 1, 7)
ORDER BY Year_Month;


-- ------------------------------------------------------------
-- 3. YEAR-OVER-YEAR PERFORMANCE
-- ------------------------------------------------------------

WITH yearly AS (
    SELECT
        CAST(SUBSTR(o.Order_Date, 1, 4) AS INTEGER) AS Year,
        SUM(oi.Net_Sales) AS Revenue,
        SUM(oi.Profit) AS Profit
    FROM orders o
    JOIN order_items oi
        ON o.Order_ID = oi.Order_ID
    WHERE o.Order_Status = 'Completed'
    GROUP BY CAST(SUBSTR(o.Order_Date, 1, 4) AS INTEGER)
)
SELECT
    Year,
    ROUND(Revenue, 2) AS Revenue,
    ROUND(Profit, 2) AS Profit,
    ROUND(
        (Revenue - LAG(Revenue) OVER (ORDER BY Year))
        * 100.0
        / NULLIF(LAG(Revenue) OVER (ORDER BY Year), 0),
        2
    ) AS Revenue_Growth_Pct,
    ROUND(
        (Profit - LAG(Profit) OVER (ORDER BY Year))
        * 100.0
        / NULLIF(LAG(Profit) OVER (ORDER BY Year), 0),
        2
    ) AS Profit_Growth_Pct
FROM yearly
ORDER BY Year;


-- ------------------------------------------------------------
-- 4. MONTH-OVER-MONTH REVENUE GROWTH
-- ------------------------------------------------------------

WITH monthly AS (
    SELECT
        SUBSTR(o.Order_Date, 1, 7) AS Year_Month,
        SUM(oi.Net_Sales) AS Revenue
    FROM orders o
    JOIN order_items oi
        ON o.Order_ID = oi.Order_ID
    WHERE o.Order_Status = 'Completed'
    GROUP BY SUBSTR(o.Order_Date, 1, 7)
)
SELECT
    Year_Month,
    ROUND(Revenue, 2) AS Revenue,
    ROUND(
        (Revenue - LAG(Revenue) OVER (ORDER BY Year_Month))
        * 100.0
        / NULLIF(LAG(Revenue) OVER (ORDER BY Year_Month), 0),
        2
    ) AS MoM_Growth_Pct
FROM monthly
ORDER BY Year_Month;


-- ------------------------------------------------------------
-- 5. RUNNING REVENUE TOTAL
-- ------------------------------------------------------------

WITH monthly AS (
    SELECT
        SUBSTR(o.Order_Date, 1, 7) AS Year_Month,
        SUM(oi.Net_Sales) AS Revenue
    FROM orders o
    JOIN order_items oi
        ON o.Order_ID = oi.Order_ID
    WHERE o.Order_Status = 'Completed'
    GROUP BY SUBSTR(o.Order_Date, 1, 7)
)
SELECT
    Year_Month,
    ROUND(Revenue, 2) AS Monthly_Revenue,
    ROUND(
        SUM(Revenue) OVER (
            ORDER BY Year_Month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS Running_Revenue
FROM monthly
ORDER BY Year_Month;


-- ------------------------------------------------------------
-- 6. CATEGORY PERFORMANCE
-- ------------------------------------------------------------

SELECT
    p.Category,
    ROUND(SUM(oi.Net_Sales), 2) AS Revenue,
    ROUND(SUM(oi.Profit), 2) AS Profit,
    ROUND(
        SUM(oi.Profit) * 100.0
        / NULLIF(SUM(oi.Net_Sales), 0),
        2
    ) AS Profit_Margin_Pct,
    SUM(oi.Quantity) AS Units_Sold,
    COUNT(DISTINCT o.Order_ID) AS Orders
FROM order_items oi
JOIN orders o
    ON oi.Order_ID = o.Order_ID
JOIN products p
    ON oi.Product_ID = p.Product_ID
WHERE o.Order_Status = 'Completed'
GROUP BY p.Category
ORDER BY Revenue DESC;


-- ------------------------------------------------------------
-- 7. TOP 10 PRODUCTS BY REVENUE
-- ------------------------------------------------------------

SELECT
    p.Product_ID,
    p.Product_Name,
    p.Category,
    ROUND(SUM(oi.Net_Sales), 2) AS Revenue,
    ROUND(SUM(oi.Profit), 2) AS Profit,
    SUM(oi.Quantity) AS Units_Sold
FROM order_items oi
JOIN orders o
    ON oi.Order_ID = o.Order_ID
JOIN products p
    ON oi.Product_ID = p.Product_ID
WHERE o.Order_Status = 'Completed'
GROUP BY
    p.Product_ID,
    p.Product_Name,
    p.Category
ORDER BY Revenue DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 8. TOP 3 PRODUCTS WITHIN EACH CATEGORY
-- Window function: DENSE_RANK
-- ------------------------------------------------------------

WITH product_sales AS (
    SELECT
        p.Category,
        p.Product_ID,
        p.Product_Name,
        SUM(oi.Net_Sales) AS Revenue,
        SUM(oi.Profit) AS Profit
    FROM order_items oi
    JOIN orders o
        ON oi.Order_ID = o.Order_ID
    JOIN products p
        ON oi.Product_ID = p.Product_ID
    WHERE o.Order_Status = 'Completed'
    GROUP BY
        p.Category,
        p.Product_ID,
        p.Product_Name
),
ranked AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY Category
            ORDER BY Revenue DESC
        ) AS Revenue_Rank
    FROM product_sales
)
SELECT
    Category,
    Product_ID,
    Product_Name,
    ROUND(Revenue, 2) AS Revenue,
    ROUND(Profit, 2) AS Profit,
    Revenue_Rank
FROM ranked
WHERE Revenue_Rank <= 3
ORDER BY Category, Revenue_Rank;


-- ------------------------------------------------------------
-- 9. HIGH-REVENUE, LOW-MARGIN PRODUCTS
-- ------------------------------------------------------------

WITH product_perf AS (
    SELECT
        p.Product_ID,
        p.Product_Name,
        p.Category,
        SUM(oi.Net_Sales) AS Revenue,
        SUM(oi.Profit) AS Profit,
        SUM(oi.Profit) * 1.0
            / NULLIF(SUM(oi.Net_Sales), 0) AS Margin
    FROM order_items oi
    JOIN orders o
        ON oi.Order_ID = o.Order_ID
    JOIN products p
        ON oi.Product_ID = p.Product_ID
    WHERE o.Order_Status = 'Completed'
    GROUP BY
        p.Product_ID,
        p.Product_Name,
        p.Category
),
thresholds AS (
    SELECT
        AVG(Revenue) AS Avg_Revenue,
        AVG(Margin) AS Avg_Margin
    FROM product_perf
)
SELECT
    pp.Product_ID,
    pp.Product_Name,
    pp.Category,
    ROUND(pp.Revenue, 2) AS Revenue,
    ROUND(pp.Profit, 2) AS Profit,
    ROUND(pp.Margin * 100, 2) AS Profit_Margin_Pct
FROM product_perf pp
CROSS JOIN thresholds t
WHERE pp.Revenue > t.Avg_Revenue
  AND pp.Margin < t.Avg_Margin
ORDER BY pp.Revenue DESC;


-- ------------------------------------------------------------
-- 10. CUSTOMER VALUE SUMMARY
-- ------------------------------------------------------------

SELECT
    c.Customer_ID,
    c.Customer_Name,
    c.Customer_Segment,
    COUNT(DISTINCT o.Order_ID) AS Orders,
    ROUND(SUM(oi.Net_Sales), 2) AS Revenue,
    ROUND(SUM(oi.Profit), 2) AS Profit,
    ROUND(
        SUM(oi.Net_Sales) * 1.0
        / COUNT(DISTINCT o.Order_ID),
        2
    ) AS Average_Order_Value,
    MIN(o.Order_Date) AS First_Order_Date,
    MAX(o.Order_Date) AS Last_Order_Date
FROM customers c
JOIN orders o
    ON c.Customer_ID = o.Customer_ID
JOIN order_items oi
    ON o.Order_ID = oi.Order_ID
WHERE o.Order_Status = 'Completed'
GROUP BY
    c.Customer_ID,
    c.Customer_Name,
    c.Customer_Segment
ORDER BY Revenue DESC;


-- ------------------------------------------------------------
-- 11. REPEAT CUSTOMER RATE
-- ------------------------------------------------------------

WITH customer_orders AS (
    SELECT
        Customer_ID,
        COUNT(DISTINCT Order_ID) AS Order_Count
    FROM orders
    WHERE Order_Status = 'Completed'
    GROUP BY Customer_ID
)
SELECT
    COUNT(*) AS Active_Customers,
    SUM(CASE WHEN Order_Count > 1 THEN 1 ELSE 0 END) AS Repeat_Customers,
    SUM(CASE WHEN Order_Count = 1 THEN 1 ELSE 0 END) AS One_Time_Customers,
    ROUND(
        SUM(CASE WHEN Order_Count > 1 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS Repeat_Customer_Rate_Pct
FROM customer_orders;


-- ------------------------------------------------------------
-- 12. REVENUE BY CUSTOMER SEGMENT
-- ------------------------------------------------------------

SELECT
    c.Customer_Segment,
    COUNT(DISTINCT c.Customer_ID) AS Customers,
    COUNT(DISTINCT o.Order_ID) AS Orders,
    ROUND(SUM(oi.Net_Sales), 2) AS Revenue,
    ROUND(SUM(oi.Profit), 2) AS Profit,
    ROUND(
        SUM(oi.Net_Sales) * 1.0
        / COUNT(DISTINCT c.Customer_ID),
        2
    ) AS Revenue_Per_Customer
FROM customers c
JOIN orders o
    ON c.Customer_ID = o.Customer_ID
JOIN order_items oi
    ON o.Order_ID = oi.Order_ID
WHERE o.Order_Status = 'Completed'
GROUP BY c.Customer_Segment
ORDER BY Revenue DESC;


-- ------------------------------------------------------------
-- 13. CUSTOMER REVENUE RANKING
-- ------------------------------------------------------------

WITH customer_revenue AS (
    SELECT
        c.Customer_ID,
        c.Customer_Name,
        c.Customer_Segment,
        SUM(oi.Net_Sales) AS Revenue
    FROM customers c
    JOIN orders o
        ON c.Customer_ID = o.Customer_ID
    JOIN order_items oi
        ON o.Order_ID = oi.Order_ID
    WHERE o.Order_Status = 'Completed'
    GROUP BY
        c.Customer_ID,
        c.Customer_Name,
        c.Customer_Segment
)
SELECT
    Customer_ID,
    Customer_Name,
    Customer_Segment,
    ROUND(Revenue, 2) AS Revenue,
    DENSE_RANK() OVER (
        ORDER BY Revenue DESC
    ) AS Revenue_Rank
FROM customer_revenue
ORDER BY Revenue_Rank
LIMIT 25;


-- ------------------------------------------------------------
-- 14. SALES BY ACQUISITION CHANNEL
-- ------------------------------------------------------------

SELECT
    o.Channel,
    COUNT(DISTINCT o.Order_ID) AS Orders,
    COUNT(DISTINCT o.Customer_ID) AS Customers,
    ROUND(SUM(oi.Net_Sales), 2) AS Revenue,
    ROUND(SUM(oi.Profit), 2) AS Profit,
    ROUND(
        SUM(oi.Profit) * 100.0
        / NULLIF(SUM(oi.Net_Sales), 0),
        2
    ) AS Profit_Margin_Pct,
    ROUND(
        SUM(oi.Net_Sales) * 1.0
        / COUNT(DISTINCT o.Order_ID),
        2
    ) AS Average_Order_Value
FROM orders o
JOIN order_items oi
    ON o.Order_ID = oi.Order_ID
WHERE o.Order_Status = 'Completed'
GROUP BY o.Channel
ORDER BY Revenue DESC;


-- ------------------------------------------------------------
-- 15. DISCOUNT BAND PROFITABILITY
-- ------------------------------------------------------------

SELECT
    CASE
        WHEN oi.Discount_Pct = 0 THEN '0%'
        WHEN oi.Discount_Pct <= 0.05 THEN '1-5%'
        WHEN oi.Discount_Pct <= 0.10 THEN '6-10%'
        WHEN oi.Discount_Pct <= 0.15 THEN '11-15%'
        WHEN oi.Discount_Pct <= 0.20 THEN '16-20%'
        ELSE '20%+'
    END AS Discount_Band,
    ROUND(SUM(oi.Net_Sales), 2) AS Revenue,
    ROUND(SUM(oi.Profit), 2) AS Profit,
    ROUND(
        SUM(oi.Profit) * 100.0
        / NULLIF(SUM(oi.Net_Sales), 0),
        2
    ) AS Profit_Margin_Pct,
    SUM(oi.Quantity) AS Units
FROM order_items oi
JOIN orders o
    ON oi.Order_ID = o.Order_ID
WHERE o.Order_Status = 'Completed'
GROUP BY Discount_Band
ORDER BY
    CASE Discount_Band
        WHEN '0%' THEN 1
        WHEN '1-5%' THEN 2
        WHEN '6-10%' THEN 3
        WHEN '11-15%' THEN 4
        WHEN '16-20%' THEN 5
        ELSE 6
    END;


-- ------------------------------------------------------------
-- 16. RETURN RATE BY CATEGORY
-- ------------------------------------------------------------

WITH sold AS (
    SELECT
        p.Category,
        COUNT(DISTINCT oi.Order_Item_ID) AS Sold_Items
    FROM order_items oi
    JOIN orders o
        ON oi.Order_ID = o.Order_ID
    JOIN products p
        ON oi.Product_ID = p.Product_ID
    WHERE o.Order_Status = 'Completed'
    GROUP BY p.Category
),
returned AS (
    SELECT
        p.Category,
        COUNT(DISTINCT r.Order_Item_ID) AS Returned_Items,
        SUM(r.Refund_Amount) AS Refund_Amount
    FROM returns r
    JOIN products p
        ON r.Product_ID = p.Product_ID
    GROUP BY p.Category
)
SELECT
    s.Category,
    s.Sold_Items,
    COALESCE(r.Returned_Items, 0) AS Returned_Items,
    ROUND(
        COALESCE(r.Returned_Items, 0)
        * 100.0 / NULLIF(s.Sold_Items, 0),
        2
    ) AS Return_Rate_Pct,
    ROUND(COALESCE(r.Refund_Amount, 0), 2) AS Refund_Amount
FROM sold s
LEFT JOIN returned r
    ON s.Category = r.Category
ORDER BY Return_Rate_Pct DESC;


-- ------------------------------------------------------------
-- 17. MOST COMMON RETURN REASONS
-- ------------------------------------------------------------

SELECT
    Return_Reason,
    COUNT(*) AS Return_Count,
    ROUND(SUM(Refund_Amount), 2) AS Refund_Amount
FROM returns
GROUP BY Return_Reason
ORDER BY Return_Count DESC;


-- ------------------------------------------------------------
-- 18. HIGH-VOLUME PRODUCTS WITH HIGH RETURN RATES
-- ------------------------------------------------------------

WITH sold AS (
    SELECT
        p.Product_ID,
        p.Product_Name,
        p.Category,
        COUNT(DISTINCT oi.Order_Item_ID) AS Sold_Items
    FROM order_items oi
    JOIN orders o
        ON oi.Order_ID = o.Order_ID
    JOIN products p
        ON oi.Product_ID = p.Product_ID
    WHERE o.Order_Status = 'Completed'
    GROUP BY
        p.Product_ID,
        p.Product_Name,
        p.Category
),
returned AS (
    SELECT
        Product_ID,
        COUNT(DISTINCT Order_Item_ID) AS Returned_Items
    FROM returns
    GROUP BY Product_ID
)
SELECT
    s.Product_ID,
    s.Product_Name,
    s.Category,
    s.Sold_Items,
    COALESCE(r.Returned_Items, 0) AS Returned_Items,
    ROUND(
        COALESCE(r.Returned_Items, 0)
        * 100.0 / NULLIF(s.Sold_Items, 0),
        2
    ) AS Return_Rate_Pct
FROM sold s
LEFT JOIN returned r
    ON s.Product_ID = r.Product_ID
WHERE s.Sold_Items >= 50
ORDER BY Return_Rate_Pct DESC, Sold_Items DESC
LIMIT 20;


-- ------------------------------------------------------------
-- 19. TOP CITIES BY REVENUE
-- ------------------------------------------------------------

SELECT
    c.City,
    c.State,
    COUNT(DISTINCT o.Order_ID) AS Orders,
    COUNT(DISTINCT c.Customer_ID) AS Customers,
    ROUND(SUM(oi.Net_Sales), 2) AS Revenue,
    ROUND(SUM(oi.Profit), 2) AS Profit
FROM customers c
JOIN orders o
    ON c.Customer_ID = o.Customer_ID
JOIN order_items oi
    ON o.Order_ID = oi.Order_ID
WHERE o.Order_Status = 'Completed'
GROUP BY
    c.City,
    c.State
ORDER BY Revenue DESC
LIMIT 20;


-- ------------------------------------------------------------
-- 20. SHIPPING PERFORMANCE
-- ------------------------------------------------------------

SELECT
    Shipping_Method,
    COUNT(*) AS Orders,
    ROUND(
        AVG(
            julianday(Ship_Date)
            - julianday(Order_Date)
        ),
        2
    ) AS Avg_Shipping_Days
FROM orders
WHERE Order_Status = 'Completed'
  AND Ship_Date IS NOT NULL
GROUP BY Shipping_Method
ORDER BY Avg_Shipping_Days;


-- ------------------------------------------------------------
-- 21. MARKETING CHANNEL PERFORMANCE
-- ------------------------------------------------------------

SELECT
    Channel,
    ROUND(SUM(Spend), 2) AS Spend,
    SUM(Impressions) AS Impressions,
    SUM(Clicks) AS Clicks,
    SUM(Attributed_Orders) AS Attributed_Orders,
    ROUND(
        SUM(Clicks) * 100.0
        / NULLIF(SUM(Impressions), 0),
        2
    ) AS CTR_Pct,
    ROUND(
        SUM(Attributed_Orders) * 100.0
        / NULLIF(SUM(Clicks), 0),
        2
    ) AS Conversion_Rate_Pct,
    ROUND(
        SUM(Spend) * 1.0
        / NULLIF(SUM(Clicks), 0),
        2
    ) AS Cost_Per_Click,
    ROUND(
        SUM(Spend) * 1.0
        / NULLIF(SUM(Attributed_Orders), 0),
        2
    ) AS Cost_Per_Attributed_Order
FROM marketing
GROUP BY Channel
ORDER BY Cost_Per_Attributed_Order;


-- ------------------------------------------------------------
-- 22. SALES REVENUE VS MARKETING SPEND
-- Directional comparison, not a strict causal attribution model.
-- ------------------------------------------------------------

WITH sales_channel AS (
    SELECT
        o.Channel,
        SUM(oi.Net_Sales) AS Revenue,
        SUM(oi.Profit) AS Profit
    FROM orders o
    JOIN order_items oi
        ON o.Order_ID = oi.Order_ID
    WHERE o.Order_Status = 'Completed'
    GROUP BY o.Channel
),
marketing_channel AS (
    SELECT
        Channel,
        SUM(Spend) AS Spend,
        SUM(Attributed_Orders) AS Attributed_Orders
    FROM marketing
    GROUP BY Channel
)
SELECT
    m.Channel,
    ROUND(m.Spend, 2) AS Spend,
    m.Attributed_Orders,
    ROUND(COALESCE(s.Revenue, 0), 2) AS Sales_Revenue,
    ROUND(COALESCE(s.Profit, 0), 2) AS Sales_Profit,
    ROUND(
        COALESCE(s.Revenue, 0)
        / NULLIF(m.Spend, 0),
        2
    ) AS Revenue_To_Spend_Ratio
FROM marketing_channel m
LEFT JOIN sales_channel s
    ON m.Channel = s.Channel
ORDER BY Revenue_To_Spend_Ratio DESC;


-- ------------------------------------------------------------
-- 23. NEW VS RETURNING CUSTOMER ORDERS
-- ------------------------------------------------------------

WITH first_order AS (
    SELECT
        Customer_ID,
        MIN(Order_Date) AS First_Order_Date
    FROM orders
    WHERE Order_Status = 'Completed'
    GROUP BY Customer_ID
)
SELECT
    SUBSTR(o.Order_Date, 1, 7) AS Year_Month,
    CASE
        WHEN o.Order_Date = f.First_Order_Date
            THEN 'New'
        ELSE 'Returning'
    END AS Customer_Type,
    COUNT(DISTINCT o.Customer_ID) AS Customers,
    COUNT(DISTINCT o.Order_ID) AS Orders,
    ROUND(SUM(oi.Net_Sales), 2) AS Revenue
FROM orders o
JOIN first_order f
    ON o.Customer_ID = f.Customer_ID
JOIN order_items oi
    ON o.Order_ID = oi.Order_ID
WHERE o.Order_Status = 'Completed'
GROUP BY
    SUBSTR(o.Order_Date, 1, 7),
    Customer_Type
ORDER BY
    Year_Month,
    Customer_Type;


-- ------------------------------------------------------------
-- 24. CUSTOMER RFM-STYLE SEGMENTATION
-- Recency is measured relative to the latest completed order date.
-- ------------------------------------------------------------

WITH max_date AS (
    SELECT MAX(Order_Date) AS Max_Order_Date
    FROM orders
    WHERE Order_Status = 'Completed'
),
customer_metrics AS (
    SELECT
        o.Customer_ID,
        CAST(
            julianday((SELECT Max_Order_Date FROM max_date))
            - julianday(MAX(o.Order_Date))
            AS INTEGER
        ) AS Recency_Days,
        COUNT(DISTINCT o.Order_ID) AS Frequency,
        SUM(oi.Net_Sales) AS Monetary
    FROM orders o
    JOIN order_items oi
        ON o.Order_ID = oi.Order_ID
    WHERE o.Order_Status = 'Completed'
    GROUP BY o.Customer_ID
),
segmented AS (
    SELECT
        *,
        CASE
            WHEN Frequency >= 6 AND Monetary >= 2500
                THEN 'VIP'
            WHEN Frequency >= 4 AND Monetary >= 1200
                THEN 'Loyal'
            WHEN Recency_Days <= 60 AND Frequency >= 2
                THEN 'Active'
            WHEN Recency_Days > 180
                THEN 'At Risk'
            ELSE 'Regular'
        END AS Customer_Segment_RFM
    FROM customer_metrics
)
SELECT
    Customer_Segment_RFM,
    COUNT(*) AS Customers,
    ROUND(AVG(Recency_Days), 1) AS Avg_Recency_Days,
    ROUND(AVG(Frequency), 2) AS Avg_Order_Frequency,
    ROUND(AVG(Monetary), 2) AS Avg_Customer_Revenue,
    ROUND(SUM(Monetary), 2) AS Segment_Revenue
FROM segmented
GROUP BY Customer_Segment_RFM
ORDER BY Segment_Revenue DESC;


-- ------------------------------------------------------------
-- 25. MONTHLY 3-MONTH MOVING AVERAGE
-- ------------------------------------------------------------

WITH monthly AS (
    SELECT
        SUBSTR(o.Order_Date, 1, 7) AS Year_Month,
        SUM(oi.Net_Sales) AS Revenue
    FROM orders o
    JOIN order_items oi
        ON o.Order_ID = oi.Order_ID
    WHERE o.Order_Status = 'Completed'
    GROUP BY SUBSTR(o.Order_Date, 1, 7)
)
SELECT
    Year_Month,
    ROUND(Revenue, 2) AS Revenue,
    ROUND(
        AVG(Revenue) OVER (
            ORDER BY Year_Month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS Revenue_3M_Moving_Avg
FROM monthly
ORDER BY Year_Month;

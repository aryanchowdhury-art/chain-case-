#Q1. Total Orders by Status   [Easy] 
#Write a query to count the number of orders for each Order Status. Order the results from 
#highest to lowest count. 
-- Q1: Count orders per status 
SELECT `Order Status`, 
       COUNT(*) AS total_orders 
FROM supply_chain 
GROUP BY `Order Status` 
ORDER BY total_orders DESC;

#Q2. Monthly Sales Trend   [Easy] 
#Calculate the total sales and total orders for each month-year. Show months with the highest 
#revenue at the top. 
-- Q2: Monthly sales trend 
SELECT 
    DATE_FORMAT(`Order Date`, '%Y-%m') AS order_month,
    COUNT(DISTINCT `Order Id`) AS total_orders,
    ROUND(SUM(Sales), 2) AS total_sales
FROM
    supply_chain
GROUP BY order_month
ORDER BY total_sales DESC;

#Q4. Customer Segment Analysis   [Easy] 
#Calculate average order value, total sales, and order count for each customer segment. 
-- Q4: Customer segment summary 
SELECT `Customer Segment`, 
       COUNT(DISTINCT `Order Id`) AS total_orders, 
       ROUND(SUM(Sales), 2) AS total_sales, 
       ROUND(AVG(Sales), 2) AS avg_order_value 
FROM supply_chain 
GROUP BY `Customer Segment` 
ORDER BY total_sales DESC;
#Q3. Top 10 Products by Revenue   [Easy] 
#Find the top 10 products by total sales revenue. Include the product category and total units 
#sold. 
-- Q3: Top 10 products by revenue 
SELECT `Product Name`, 
       `Category Name`, 
       SUM(`Order Item Quantity`) AS units_sold, 
       ROUND(SUM(Sales), 2) AS total_revenue 
FROM supply_chain 
GROUP BY `Product Name`, `Category Name` 
ORDER BY total_revenue DESC 
LIMIT 10; 

#Q5. Late Delivery Rate by Shipping Mode   [Medium] 
#Calculate the percentage of late deliveries for each shipping mode. Use the Late_delivery_risk 
#flag. Which shipping mode has the worst performance?
-- Q5: Late delivery rate by shipping mode 
SELECT `Shipping Mode`, 
       COUNT(*) AS total_shipments, 
       SUM(Late_delivery_risk) AS late_deliveries, 
       ROUND(100.0 * SUM(Late_delivery_risk) / COUNT(*), 2) AS late_rate_pct 
FROM supply_chain 
GROUP BY `Shipping Mode` 
ORDER BY late_rate_pct DESC;

#Q6. Average Lead Time per Category   [Medium] 
#Compute the average actual shipping days vs. scheduled shipping days for each product 
#category. Identify categories where actual time exceeds scheduled time the most. 
-- Q6: Lead time analysis by category 
SELECT `Category Name`, 
       ROUND(AVG(`Days for shipping (real)`), 2) AS avg_actual_days, 
       ROUND(AVG(`Days for shipment (scheduled)`), 2) AS avg_scheduled_days, 
       ROUND(AVG(`Days for shipping (real)`) - 
             AVG(`Days for shipment (scheduled)`), 2) AS avg_delay_days 
FROM supply_chain 
GROUP BY `Category Name` 
ORDER BY avg_delay_days DESC; 

#Q7. Order Fill Rate by Region   [Medium] 
#Find the fill rate (percentage of COMPLETE orders) for each Order Region. Rank the regions 
#from best to worst performance. 
-- Q7: Order fill rate by region 
SELECT `Order Region`, 
       COUNT(*) AS total_orders, 
       SUM(CASE WHEN `Order Status` = 'COMPLETE' THEN 1 ELSE 0 END) AS 
completed, 
       ROUND(100.0 * SUM(CASE WHEN `Order Status` = 'COMPLETE' THEN 1 ELSE 0 
END) 
             / COUNT(*), 2) AS fill_rate_pct 
FROM supply_chain 
GROUP BY `Order Region` 
ORDER BY fill_rate_pct DESC; 

#Q8. High-Discount Orders Impact   [Medium] 
#Identify orders where the discount is greater than 20%. Calculate the average profit ratio for 
#discounted vs. non-discounted orders. What pattern do you observe?
-- Q8: Discount impact on profit ratio 
SELECT 
  CASE WHEN `Order Item Discount` > 0.2 THEN 'High Discount (>20%)' 
       ELSE 'Normal Discount (<=20%)' END AS discount_group, 
  COUNT(*) AS total_orders, 
  ROUND(AVG(`Order Item Profit Ratio`) * 100, 2) AS avg_profit_pct, 
  ROUND(SUM(Sales), 2) AS total_sales 
FROM supply_chain 
GROUP BY discount_group; 

#Q9. Rolling 3-Month Revenue   [Hard] 
#Using a window function, calculate the 3-month rolling average of total revenue. This helps 
#identify seasonal trends. 
-- Q9: 3-month rolling average revenue (window function) 
WITH monthly_sales AS ( 
  SELECT DATE_FORMAT(`Order Date`, '%Y-%m') AS order_month, 
         ROUND(SUM(Sales), 2) AS monthly_revenue 
  FROM supply_chain 
  GROUP BY order_month 
) 
SELECT order_month, 
       monthly_revenue, 
       ROUND(AVG(monthly_revenue) OVER ( 
           ORDER BY order_month 
           ROWS BETWEEN 2 PRECEDING AND CURRENT ROW 
       ), 2) AS rolling_3mo_avg 
FROM monthly_sales 
ORDER BY order_month;

#Q10. Rank Products Within Each Category   [Hard] 
#Use RANK() or DENSE_RANK() to rank products by total sales within each category. Show only 
#the top 3 products per category. 
-- Q10: Top 3 products per category using window function 
WITH ranked_products AS ( 
  SELECT `Category Name`, 
         `Product Name`, 
         ROUND(SUM(Sales), 2) AS total_sales, 
         RANK() OVER ( 
             PARTITION BY `Category Name` 
             ORDER BY SUM(Sales) DESC 
         ) AS sales_rank 
  FROM supply_chain 
  GROUP BY `Category Name`, `Product Name` 
) 
SELECT `Category Name`, `Product Name`, total_sales, sales_rank 
FROM ranked_products 
WHERE sales_rank <= 3 
ORDER BY `Category Name`, sales_rank; 

#Q11. Identify Repeat Late-Delivery Regions   [Hard] 
#Using a subquery or CTE, find all regions where late delivery rate exceeds the global average 
#late delivery rate. Label them as underperforming regions.
-- Q11: Regions above average late delivery rate (subquery) 
WITH region_stats AS ( 
  SELECT `Order Region`, 
         COUNT(*) AS total_orders, 
         ROUND(100.0 * SUM(Late_delivery_risk) / COUNT(*), 2) AS late_rate 
  FROM supply_chain 
  GROUP BY `Order Region` 
), 
global_avg AS ( 
  SELECT ROUND(AVG(late_rate), 2) AS avg_late_rate FROM region_stats 
) 
SELECT r.`Order Region`, r.late_rate, 
       g.avg_late_rate, 
       'UNDERPERFORMING' AS status 
FROM region_stats r 
CROSS JOIN global_avg g 
WHERE r.late_rate > g.avg_late_rate 
ORDER BY r.late_rate DESC;

#Q12. Customer Lifetime Value (CLV)   [Hard] 
#Calculate the Customer Lifetime Value: total revenue, total orders, and average order value per 
#customer. Rank customers by CLV and return the top 20. 
-- Q12: Customer Lifetime Value ranking 
WITH customer_value AS ( 
  SELECT `Customer Id`, 
         `Customer Segment`, 
         `Order Country`, 
         COUNT(DISTINCT `Order Id`) AS total_orders, 
         ROUND(SUM(Sales), 2) AS lifetime_revenue, 
         ROUND(AVG(Sales), 2) AS avg_order_value 
  FROM supply_chain 
  GROUP BY `Customer Id`, `Customer Segment`, `Order Country` 
) 
SELECT `Customer Id`, `Customer Segment`, `Order Country`, 
       total_orders, lifetime_revenue, avg_order_value, 
       RANK() OVER (ORDER BY lifetime_revenue DESC) AS clv_rank 
FROM customer_value 
ORDER BY clv_rank 
LIMIT 20;

#Part D: Open-Ended Analysis Tasks 
#Q13. Supplier Performance Dashboard   [Hard] 
#Design a query that produces a supplier/department-level performance dashboard including: 
#total orders, total revenue, average late delivery rate, average profit ratio, and most popular 
#shipping mode per department. 
-- Q13: Supplier/Department Performance Dashboard
WITH shipping_mode_rank AS (
    SELECT 
        `Department Name`,
        `Shipping Mode`,
        COUNT(*) AS mode_count,
        RANK() OVER (
            PARTITION BY `Department Name`
            ORDER BY COUNT(*) DESC
        ) AS mode_rank
    FROM supply_chain
    GROUP BY `Department Name`, `Shipping Mode`
)
SELECT 
    sc.`Department Name`,
    COUNT(DISTINCT sc.`Order Id`) AS total_orders,
    ROUND(SUM(sc.Sales), 2) AS total_revenue,
    ROUND(AVG(sc.Late_delivery_risk) * 100, 2) AS avg_late_delivery_rate_pct,
    ROUND(AVG(sc.`Order Item Profit Ratio`) * 100, 2) AS avg_profit_pct,
    sm.`Shipping Mode` AS most_popular_shipping_mode
FROM supply_chain sc
LEFT JOIN shipping_mode_rank sm
    ON sc.`Department Name` = sm.`Department Name`
   AND sm.mode_rank = 1
GROUP BY sc.`Department Name`, sm.`Shipping Mode`
ORDER BY total_revenue DESC;

#Q14. Year-over-Year Sales Growth   [Hard] 
#Calculate the year-over-year percentage change in total sales for each product category. Identify 
#which categories are growing and which are declining.
-- Q14: Year-over-Year Sales Growth by Category
WITH category_year_sales AS (
    SELECT 
        `Category Name`,
        YEAR(`Order Date`) AS order_year,
        ROUND(SUM(Sales), 2) AS total_sales
    FROM supply_chain
    GROUP BY `Category Name`, YEAR(`Order Date`)
)
SELECT 
    `Category Name`,
    order_year,
    total_sales,
    LAG(total_sales) OVER (
        PARTITION BY `Category Name`
        ORDER BY order_year
    ) AS prev_year_sales,
    ROUND(
        CASE 
            WHEN LAG(total_sales) OVER (PARTITION BY `Category Name` ORDER BY order_year) IS NULL 
                 THEN NULL
            ELSE ( (total_sales - LAG(total_sales) OVER (PARTITION BY `Category Name` ORDER BY order_year)) 
                   / LAG(total_sales) OVER (PARTITION BY `Category Name` ORDER BY order_year) ) * 100
        END, 2
    ) AS yoy_growth_pct,
    CASE 
        WHEN LAG(total_sales) OVER (PARTITION BY `Category Name` ORDER BY order_year) IS NULL THEN 'N/A'
        WHEN total_sales > LAG(total_sales) OVER (PARTITION BY `Category Name` ORDER BY order_year) THEN 'Growing'
        WHEN total_sales < LAG(total_sales) OVER (PARTITION BY `Category Name` ORDER BY order_year) THEN 'Declining'
        ELSE 'Stable'
    END AS growth_status
FROM category_year_sales
ORDER BY `Category Name`, order_year;

#Q15. Order Anomaly Detection   [Hard] 
#Find orders where the actual shipping days exceed the scheduled days by more than 5 days 
#AND the order is marked COMPLETE. How many such anomalies exist, and which regions have 
#the most? 
-- Q15: Order Anomaly Detection
WITH anomalies AS (
    SELECT 
        `Order Id`,
        `Order Region`,
        `Days for shipping (real)` AS actual_days,
        `Days for shipment (scheduled)` AS scheduled_days
    FROM supply_chain
    WHERE `Order Status` = 'COMPLETE'
      AND (`Days for shipping (real)` - `Days for shipment (scheduled)`) > 5
)
SELECT 
    COUNT(*) AS total_anomalies,
    `Order Region`,
    COUNT(*) AS anomalies_in_region
FROM anomalies
GROUP BY `Order Region` WITH ROLLUP
ORDER BY anomalies_in_region DESC;

#Q16. Profitability by Geography   [Medium] 
#Write a query that shows total revenue, total profit (Sales * Order Item Profit Ratio), and profit 
#margin percentage by Order Country. Filter to countries with more than 500 orders.
-- Q16: Profitability by Geography
WITH country_stats AS (
    SELECT 
        `Order Country`,
        COUNT(DISTINCT `Order Id`) AS total_orders,
        ROUND(SUM(Sales), 2) AS total_revenue,
        ROUND(SUM(Sales * `Order Item Profit Ratio`), 2) AS total_profit
    FROM supply_chain
    GROUP BY `Order Country`
)
SELECT 
    `Order Country`,
    total_orders,
    total_revenue,
    total_profit,
    ROUND((total_profit / total_revenue) * 100, 2) AS profit_margin_pct
FROM country_stats
WHERE total_orders > 500
ORDER BY profit_margin_pct DESC;

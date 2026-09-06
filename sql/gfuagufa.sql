-- ============================================================
-- BLINKIT SALES & OPERATIONS ANALYSIS
-- SQL Analysis Project | MySQL
-- ============================================================


-- ============================================================
-- GROUP 1: SALES & ORDER PERFORMANCE
-- ============================================================


-- Q1. How did monthly order value change compared with the previous month?

WITH Monthly_Sales AS (
    SELECT 
        MONTHNAME(order_date) AS MONTH, 
        MONTH(order_date) AS Month_Number,
        SUM(order_total) AS Order_Value
    FROM blinkit_orders
    GROUP BY Month_Number, MONTH
),
Prev_month_value AS (
    SELECT 
        MONTH, 
        Order_Value, 
        LAG(Order_Value) OVER (ORDER BY Month_Number ASC) AS Previous_Month_Value
    FROM Monthly_Sales
)
SELECT 
    Month,
    Order_Value,
    Previous_Month_Value,
    ROUND(((Order_Value - Previous_Month_Value) / Previous_Month_Value) * 100, 2) AS MOM_Change_Pct,
    CASE 
        WHEN Previous_Month_Value IS NULL THEN 'First_Month'
        WHEN Order_Value > Previous_Month_Value THEN 'Increased'
        WHEN Order_Value < Previous_Month_Value THEN 'Decreased'
        ELSE 'No_Change'
    END AS Trend
FROM Prev_month_value;


-- ------------------------------------------------------------
-- Q2. What is the cumulative (running) order value over
--     each month?
-- ------------------------------------------------------------

WITH Monthly_Sales AS (
    SELECT 
        MONTHNAME(order_date) AS MONTH,
        MONTH(order_date) AS Month_Number,
        SUM(order_total) AS Monthly_Order_Value
    FROM blinkit_orders
    GROUP BY MONTH, Month_Number
)
SELECT 
    MONTH,
    Monthly_Order_Value,
    SUM(Monthly_Order_Value) OVER (ORDER BY Month_Number ASC) AS Running_Order_Value
FROM Monthly_Sales;


-- ------------------------------------------------------------
-- Q3. Which are the top 3 months based on total order value?
-- ------------------------------------------------------------

WITH Monthly_Sales AS (
    SELECT 
        MONTHNAME(order_date) AS MONTH,
        SUM(order_total) AS Monthly_Order_Value
    FROM blinkit_orders
    GROUP BY MONTH
),
Ranked_Months AS (
    SELECT 
        MONTH,
        Monthly_Order_Value,
        DENSE_RANK() OVER (ORDER BY Monthly_Order_Value DESC) AS rnk
    FROM Monthly_Sales
)
SELECT 
    MONTH,
    Monthly_Order_Value,
    rnk
FROM Ranked_Months
WHERE rnk <= 3;


-- ------------------------------------------------------------
-- Q4. Which months had the highest month-over-month increase
--     and the highest month-over-month decline in order value?
-- ------------------------------------------------------------

WITH Monthly_Sales AS (
    SELECT
        MONTHNAME(order_date) AS month,
        MONTH(order_date) AS month_number,
        SUM(order_total) AS order_value
    FROM blinkit_orders
    GROUP BY month_number, month
),
MoM AS (
    SELECT
        month,
        month_number,
        order_value,
        LAG(order_value) OVER (ORDER BY month_number) AS previous_month_value
    FROM Monthly_Sales
),
Ranked AS (
    SELECT *,
        ROUND((order_value - previous_month_value) / previous_month_value * 100, 2) AS mom_change,
        DENSE_RANK() OVER (ORDER BY (order_value - previous_month_value) / previous_month_value DESC) AS increase_rank,
        DENSE_RANK() OVER (ORDER BY (order_value - previous_month_value) / previous_month_value ASC) AS decline_rank
    FROM MoM
    WHERE previous_month_value IS NOT NULL
)
SELECT
    month,
    order_value,
    previous_month_value,
    mom_change,
    CASE
        WHEN increase_rank = 1 THEN 'Highest Increase'
        WHEN decline_rank = 1 THEN 'Highest Decline'
    END AS performance
FROM Ranked
WHERE increase_rank = 1 OR decline_rank = 1;



-- ============================================================
-- GROUP 2: CUSTOMER BEHAVIOR & SEGMENTATION
-- ============================================================


-- Q5. Who are the top 10 customers based on their total
--     recorded order value, and what percentage of overall
--     order value does each customer contribute?
-- ------------------------------------------------------------

WITH Customer_Sales AS (
    SELECT 
        bc.customer_id,
        bc.customer_name,
        SUM(bo.order_total) AS total_order_value
    FROM blinkit_customers bc
    JOIN blinkit_orders bo 
        ON bc.customer_id = bo.customer_id
    GROUP BY bc.customer_id, bc.customer_name
),
Customer_Ranking AS (
    SELECT 
        customer_id,
        customer_name,
        total_order_value,
        DENSE_RANK() OVER (ORDER BY total_order_value DESC) AS rnk,
        SUM(total_order_value) OVER () AS overall_order_value
    FROM Customer_Sales
)
SELECT 
    customer_id,
    customer_name,
    total_order_value,
    rnk,
    ROUND((total_order_value / overall_order_value) * 100,2) AS percentage_of_total
FROM Customer_Ranking
WHERE rnk <= 10;


-- ------------------------------------------------------------
-- Q6. Which customer segments generate higher sales per customer?
-- ------------------------------------------------------------

WITH Customer_Sales AS (
    SELECT
        bc.customer_id,
        bc.customer_segment,
        SUM(bo.order_total) AS total_customer_sales
    FROM blinkit_customers bc
    JOIN blinkit_orders bo
        ON bc.customer_id = bo.customer_id
    GROUP BY bc.customer_id, bc.customer_segment
)
SELECT
    customer_segment,
    COUNT(customer_id) AS customers,
    ROUND(AVG(total_customer_sales), 2) AS avg_customer_sales,
    ROUND(MIN(total_customer_sales), 2) AS min_customer_sales,
    ROUND(MAX(total_customer_sales), 2) AS max_customer_sales
FROM Customer_Sales
GROUP BY customer_segment
ORDER BY avg_customer_sales DESC;


-- ------------------------------------------------------------
-- Q7. How many days does each customer wait between
--     consecutive orders?
-- ------------------------------------------------------------

WITH Customer_Order_History AS (
    SELECT 
        bc.customer_id,
        bc.customer_name,
        bo.order_id,
        bo.order_date,
        LAG(bo.order_date) OVER (
            PARTITION BY bc.customer_id 
            ORDER BY bo.order_date ASC
        ) AS previous_order_date
    FROM blinkit_customers bc
    JOIN blinkit_orders bo 
        ON bc.customer_id = bo.customer_id
)
SELECT 
    customer_id,
    customer_name,
    order_id,
    order_date,
    previous_order_date,
    DATEDIFF(order_date, previous_order_date) AS days_since_previous_order
FROM Customer_Order_History
WHERE previous_order_date IS NOT NULL;


-- ------------------------------------------------------------
-- Q8. For each customer, did their order value increase or
--     decrease compared with their previous order?
-- ------------------------------------------------------------

WITH Customer_Order_History AS (
    SELECT 
        bc.customer_id,
        bc.customer_name,
        bo.order_id,
        bo.order_date,
        bo.order_total,
        LAG(bo.order_total) OVER (
            PARTITION BY bc.customer_id 
            ORDER BY bo.order_date ASC
        ) AS previous_order_value
    FROM blinkit_customers bc
    JOIN blinkit_orders bo 
        ON bc.customer_id = bo.customer_id
)
SELECT 
    customer_id,
    customer_name,
    order_id,
    order_date,
    order_total,
    previous_order_value,
    CASE 
        WHEN previous_order_value IS NULL THEN 'First Order'
        WHEN order_total > previous_order_value THEN 'Increased'
        WHEN order_total < previous_order_value THEN 'Decreased'
        ELSE 'No Change'
    END AS order_trend
FROM Customer_Order_History;


-- ------------------------------------------------------------
-- Q9. Which customers had a sequence of 3 consecutive orders
--     with increasing order values?
-- ------------------------------------------------------------

WITH Order_History AS (
    SELECT
        bc.customer_id,
        bc.customer_name,
        bo.order_id,
        bo.order_date,
        bo.order_total,
        LAG(bo.order_total, 1) OVER (
            PARTITION BY bc.customer_id 
            ORDER BY bo.order_date
        ) AS previous_order_value,
        LAG(bo.order_total, 2) OVER (
            PARTITION BY bc.customer_id 
            ORDER BY bo.order_date
        ) AS two_orders_back_value
    FROM blinkit_customers bc
    JOIN blinkit_orders bo
        ON bc.customer_id = bo.customer_id
),
Qualifying_Orders AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id 
            ORDER BY order_date DESC
        ) AS rn
    FROM Order_History
    WHERE order_total > previous_order_value
      AND previous_order_value > two_orders_back_value
)
SELECT
    customer_id,
    customer_name,
    order_id,
    order_date,
    order_total,
    previous_order_value,
    two_orders_back_value
FROM Qualifying_Orders
WHERE rn = 1;



-- ============================================================
-- GROUP 3: PRODUCT & CATEGORY PERFORMANCE
-- ============================================================


-- Q10. What are the top 3 products by sales value within
--      each product category?
-- ------------------------------------------------------------

WITH Product_Sales AS (
    SELECT 
        bp.product_id,
        bp.product_name,
        bp.category,
        SUM(bo.quantity * bo.unit_price) AS total_sales_value
    FROM blinkit_products bp
    JOIN blinkit_order_items bo 
        ON bp.product_id = bo.product_id
    GROUP BY bp.product_id, bp.product_name, bp.category
),
Product_Ranking AS (
    SELECT 
        product_id,
        product_name,
        category,
        total_sales_value,
        DENSE_RANK() OVER (
            PARTITION BY category 
            ORDER BY total_sales_value DESC
        ) AS product_rnk
    FROM Product_Sales
)
SELECT 
    product_id,
    product_name,
    category,
    total_sales_value,
    product_rnk
FROM Product_Ranking
WHERE product_rnk <= 3;


-- ------------------------------------------------------------
-- Q11. What percentage of each category's total sales value
--      is contributed by each product?
-- ------------------------------------------------------------

WITH Product_Sales AS (
    SELECT 
        bp.product_id,
        bp.product_name,
        bp.category,
        SUM(bo.quantity * bo.unit_price) AS total_sales_value
    FROM blinkit_products bp
    JOIN blinkit_order_items bo 
        ON bp.product_id = bo.product_id
    GROUP BY bp.product_id, bp.product_name, bp.category
),
Category_Sales AS (
    SELECT 
        product_id,
        product_name,
        category,
        total_sales_value,
        SUM(total_sales_value) OVER (
            PARTITION BY category
        ) AS category_overall_sales
    FROM Product_Sales
)
SELECT 
    product_id,
    product_name,
    category,
    total_sales_value,
    category_overall_sales,
    ROUND(
        (total_sales_value / category_overall_sales) * 100, 
        2
    ) AS category_sales_percentage
FROM Category_Sales;


-- ------------------------------------------------------------
-- Q12. Which products have sales value above the average
--      product sales value of their category?
-- ------------------------------------------------------------

WITH Product_Sales AS (
    SELECT 
        bp.product_id,
        bp.product_name,
        bp.category,
        SUM(bo.quantity * bo.unit_price) AS total_sales_value
    FROM blinkit_products bp
    JOIN blinkit_order_items bo 
        ON bp.product_id = bo.product_id
    GROUP BY bp.product_id, bp.product_name, bp.category
),
Category_Average_Sales AS (
    SELECT 
        product_id,
        product_name,
        category,
        total_sales_value,
        ROUND(
            AVG(total_sales_value) OVER (
                PARTITION BY category
            ),2
        ) AS category_average_sales
    FROM Product_Sales
)
SELECT *
FROM Category_Average_Sales
WHERE total_sales_value > category_average_sales;


-- ------------------------------------------------------------
-- Q13. For each category, what is the difference between the
--      top-selling product and the second-highest-selling product?
-- ------------------------------------------------------------

WITH Product_Sales AS (
    SELECT
        bp.product_id,
        bp.product_name,
        bp.category,
        SUM(bo.quantity * bo.unit_price) AS total_sales_value
    FROM blinkit_products bp
    JOIN blinkit_order_items bo
        ON bp.product_id = bo.product_id
    GROUP BY bp.product_id, bp.product_name, bp.category
),
Product_Ranking AS (
    SELECT *,
        DENSE_RANK() OVER (
            PARTITION BY category 
            ORDER BY total_sales_value DESC
        ) AS product_rank
    FROM Product_Sales
),
Category_Top_Sales AS (
    SELECT 
        category,
        MAX(CASE 
            WHEN product_rank = 1 THEN product_name 
        END) AS top_product_name,
        MAX(CASE 
            WHEN product_rank = 1 THEN total_sales_value 
        END) AS top_product_sales,
        MAX(CASE 
            WHEN product_rank = 2 THEN product_name 
        END) AS second_product_name,
        MAX(CASE 
            WHEN product_rank = 2 THEN total_sales_value 
        END) AS second_product_sales
    FROM Product_Ranking
    GROUP BY category
)
SELECT 
    category, 
    top_product_name, 
    top_product_sales, 
    second_product_name, 
    second_product_sales, 
    (top_product_sales - second_product_sales) AS sales_difference
FROM Category_Top_Sales;



-- ============================================================
-- GROUP 4: DELIVERY PERFORMANCE
-- ============================================================


-- Q14. What percentage of total orders were delivered On Time,
--      Slightly Delayed, and Significantly Delayed?
-- ------------------------------------------------------------

WITH Delivery_Status_Count AS (
    SELECT 
        delivery_status,
        COUNT(order_id) AS order_count
    FROM blinkit_delivery_performance
    GROUP BY delivery_status
),
Delivery_Status_Total AS (
    SELECT 
        delivery_status,
        order_count,
        SUM(order_count) OVER () AS total_order_count
    FROM Delivery_Status_Count
)
SELECT 
    delivery_status,
    order_count,
    total_order_count,
    ROUND((order_count / total_order_count) * 100,2) AS order_percentage
FROM Delivery_Status_Total;


-- ------------------------------------------------------------
-- Q15. Which deliveries perform better or worse than the
--      overall average delivery time?
-- ------------------------------------------------------------

WITH Delivery_Average AS (
    SELECT 
        order_id,
        delivery_time_minutes,
        ROUND(
            AVG(delivery_time_minutes) OVER (), 
            2
        ) AS overall_avg_delivery_time
    FROM blinkit_delivery_performance
),
Delivery_Comparison AS (
    SELECT 
        order_id,
        delivery_time_minutes,
        overall_avg_delivery_time,
        ROUND(
            delivery_time_minutes - overall_avg_delivery_time, 
            2
        ) AS difference
    FROM Delivery_Average
)
SELECT *,
    CASE 
        WHEN delivery_time_minutes > overall_avg_delivery_time THEN 'Slower'
        WHEN delivery_time_minutes < overall_avg_delivery_time THEN 'Faster'
        ELSE 'Same'
    END AS performance
FROM Delivery_Comparison;


-- ------------------------------------------------------------
-- Q16. Which customers experienced repeated delayed deliveries?
-- ------------------------------------------------------------

WITH Customer_Delays AS (
    SELECT 
        bc.customer_id,
        bc.customer_name,
        bo.order_id,
        bd.delivery_status
    FROM blinkit_customers bc
    JOIN blinkit_orders bo 
        ON bc.customer_id = bo.customer_id
    JOIN blinkit_delivery_performance bd 
        ON bo.order_id = bd.order_id
)
SELECT 
    customer_id,
    customer_name,
    COUNT(order_id) AS delayed_deliveries
FROM Customer_Delays
WHERE delivery_status IN (
    'Slightly Delayed', 
    'Significantly Delayed'
)
GROUP BY customer_id, customer_name
HAVING COUNT(order_id) >= 2
ORDER BY delayed_deliveries DESC;



-- ============================================================
-- GROUP 5: CUSTOMER SATISFACTION & ADVANCED INSIGHTS
-- ============================================================


-- Q17. Which feedback categories have the highest negative
--      sentiment rate?
-- ------------------------------------------------------------

WITH Category_Sentiment AS (
    SELECT 
        feedback_category,
        COUNT(order_id) AS total_feedback,
        COUNT(
            CASE 
                WHEN sentiment = 'Negative' THEN order_id 
            END
        ) AS negative_feedback
    FROM blinkit_customer_feedback
    GROUP BY feedback_category
)
SELECT 
    feedback_category, 
    total_feedback,
    negative_feedback,
    ROUND(
        (negative_feedback / total_feedback) * 100, 
        2
    ) AS negative_sentiment_rate
FROM Category_Sentiment
ORDER BY negative_sentiment_rate DESC;


-- ------------------------------------------------------------
-- Q18. Does delivery performance affect customer ratings
--      and sentiment?
-- ------------------------------------------------------------

WITH Delivery_Sentiment AS (
    SELECT 
        bd.delivery_status,
        COUNT(bc.feedback_id) AS total_feedback,
        ROUND(AVG(bc.rating), 2) AS avg_rating,
        COUNT(
            CASE 
                WHEN bc.sentiment = 'Positive' THEN 1 
            END
        ) AS positive_feedback,
        COUNT(
            CASE 
                WHEN bc.sentiment = 'Neutral' THEN 1 
            END
        ) AS neutral_feedback,
        COUNT(
            CASE 
                WHEN bc.sentiment = 'Negative' THEN 1 
            END
        ) AS negative_feedback
    FROM blinkit_delivery_performance bd
    JOIN blinkit_customer_feedback bc 
        ON bd.order_id = bc.order_id
    GROUP BY bd.delivery_status
)
SELECT *,
    ROUND(
        (negative_feedback / total_feedback) * 100, 
        2
    ) AS negative_sentiment_rate
FROM Delivery_Sentiment;


-- ------------------------------------------------------------
-- Q19. What percentage of total orders does each payment
--      method account for?
-- ------------------------------------------------------------

WITH Payment_Orders AS (
    SELECT
        payment_method,
        COUNT(order_id) AS total_orders
    FROM blinkit_orders
    GROUP BY payment_method
),
Overall_Orders AS (
    SELECT
        payment_method,
        total_orders,
        SUM(total_orders) OVER () AS overall_orders
    FROM Payment_Orders
)
SELECT
    payment_method,
    total_orders, 
    overall_orders,
    ROUND(
        (total_orders / overall_orders) * 100, 
        2
    ) AS order_percentage
FROM Overall_Orders
ORDER BY order_percentage DESC;


-- ------------------------------------------------------------
-- Q20. Which customer in each customer segment has generated
--      the highest total sales?
-- ------------------------------------------------------------

WITH Customer_Sales AS (
    SELECT 
        bc.customer_segment,
        bc.customer_id,
        bc.customer_name,
        SUM(bo.order_total) AS total_sales
    FROM blinkit_customers bc
    JOIN blinkit_orders bo 
        ON bc.customer_id = bo.customer_id
    GROUP BY bc.customer_id, bc.customer_name, bc.customer_segment
),
Customer_Ranking AS (
    SELECT *,
        DENSE_RANK() OVER (
            PARTITION BY customer_segment 
            ORDER BY total_sales DESC
        ) AS segment_rank
    FROM Customer_Sales
)
SELECT *
FROM Customer_Ranking
WHERE segment_rank = 1;


-- ============================================================
-- END OF BLINKIT SQL ANALYSIS
-- ============================================================

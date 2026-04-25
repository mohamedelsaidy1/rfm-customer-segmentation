WITH orders AS (
    SELECT
        Customer_ID,
        Order_ID,
        MIN(Order_Date) AS order_date,
        SUM(Sales) AS order_value
    FROM dbo.Superstore
    GROUP BY Customer_ID, Order_ID
),

rfm AS (
    SELECT
        Customer_ID,
        MAX(order_date) AS last_order_date,
        COUNT(Order_ID) AS frequency,
        SUM(order_value) AS monetary
    FROM orders
    GROUP BY Customer_ID
),

rfm_calc AS (
    SELECT
        *,
        DATEDIFF(day, last_order_date, (SELECT MAX(order_date) FROM orders)) AS recency
    FROM rfm
),

rfm_scores AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY recency DESC) AS R_score,
        NTILE(5) OVER (ORDER BY frequency) AS F_score,
        NTILE(5) OVER (ORDER BY monetary) AS M_score
    FROM rfm_calc
)

SELECT
    *,
    CASE
        WHEN R_score >= 4 AND F_score >= 4 AND M_score >= 4 THEN 'Champions'
        WHEN R_score >= 4 AND F_score >= 3 THEN 'Loyal Customers'
        WHEN R_score >= 3 AND F_score >= 2 THEN 'Potential Loyalists'
        WHEN R_score >= 4 AND F_score <= 2 THEN 'New Customers'
        WHEN R_score <= 2 AND F_score >= 3 THEN 'At Risk'
        WHEN R_score <= 2 AND F_score <= 2 THEN 'Lost Customers'
        ELSE 'Others'
    END AS Segment
FROM rfm_scores;
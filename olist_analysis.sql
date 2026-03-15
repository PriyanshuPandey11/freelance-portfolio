# Common Query
use olist_db;
select * from olist_customers_dataset;
select * from olist_order_items_dataset;
select * from olist_order_payments_dataset;
select * from olist_orders_dataset;
select * from olist_products_dataset;


# Query 1 - Monthly Revenue Trend
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%y-m%') AS order_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(p.payment_value),2) AS total_revenue
FROM
    olist_orders_dataset o
        JOIN
    olist_order_payments_dataset p ON o.order_id = p.order_id
WHERE
    o.order_status = 'delivered'
GROUP BY order_month
ORDER BY order_month;


# Query 2 - Top 10 Product Category by Revenue
SELECT 
    pr.product_category_name AS category,
    COUNT(oi.order_id) AS item_sold,
    ROUND(SUM(oi.price), 2) AS revenue
FROM
    olist_products_dataset pr
        JOIN
    olist_order_items_dataset oi ON pr.product_id = oi.product_id
        JOIN
    olist_orders_dataset o ON o.order_id = oi.order_id
WHERE
    order_status = 'delivered'
GROUP BY pr.product_category_name
ORDER BY revenue DESC
LIMIT 10;


#Query 3 - Cancellation Rate by Month
SELECT 
    DATE_FORMAT(order_purchase_timestamp, '%y-%m') AS order_month,
    COUNT(order_id) AS total_orders,
    SUM(CASE
        WHEN order_status = 'canceled' THEN 1
        ELSE 0
    END) AS canceld_orders,
    ROUND(SUM(CASE
                WHEN order_status = 'canceled' THEN 1
                ELSE 0
            END) / COUNT(*),
            2) AS canceled_rate
FROM
    olist_orders_dataset
GROUP BY order_month
ORDER BY order_month;


#Query 4 - Customer Segmentation by Spend
WITH customer_spend AS (
    SELECT 
        o.customer_id,
        ROUND(SUM(p.payment_value), 2) AS total_spend
    FROM olist_orders_dataset o
    JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.customer_id
),
ranked AS (
    SELECT *,
        NTILE(10) OVER (ORDER BY total_spend DESC) AS spend_decile
    FROM customer_spend
)
SELECT 
    CASE 
        WHEN spend_decile <= 2 THEN 'High (Top 20%)'
        WHEN spend_decile <= 5 THEN 'Mid (Next 30%)'
        ELSE 'Low (Bottom 50%)'
    END AS segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(total_spend), 2) AS avg_spend
FROM ranked
GROUP BY segment;


#Query 5 - Average Delivery by State
SELECT 
    c.customer_state AS state,
    COUNT(o.customer_id) AS customer,
    AVG(DATEDIFF(o.order_estimated_delivery_date,
            o.order_purchase_timestamp)) AS avg_delivery
FROM
    olist_customers_dataset c
        JOIN
    olist_orders_dataset o ON c.customer_id = o.customer_id
WHERE
    order_status = 'delivered'
        AND order_estimated_delivery_date IS NOT NULL
GROUP BY state
ORDER BY avg_delivery DESC;


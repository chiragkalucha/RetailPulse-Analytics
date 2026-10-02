-- Q1: What is our total revenue across all transactions?
SELECT SUM(quantity * price) AS revenue FROM order_items;

-- Q3: Top 10 customers by revenue, excluding guest checkouts
SELECT o.customer_id, SUM(oi.quantity * oi.price) AS revenue
FROM order_items oi
JOIN orders o USING(invoice)
WHERE o.customer_id IS NOT NULL
GROUP BY o.customer_id
ORDER BY revenue DESC
LIMIT 10;

-- Q4: Total revenue by month
SELECT DATE_TRUNC('month', o.invoice_date) AS month, SUM(oi.quantity * oi.price) AS revenue
FROM order_items oi
JOIN orders o USING(invoice)
GROUP BY month
ORDER BY month;
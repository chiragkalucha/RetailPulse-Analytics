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

-- Q5: Rank each order by value (window function, no row collapsing)
SELECT 
    o.customer_id,
    o.invoice,
    SUM(oi.quantity * oi.price) AS order_value,
    RANK() OVER (ORDER BY SUM(oi.quantity * oi.price) DESC) AS order_rank
FROM order_items oi
JOIN orders o USING(invoice)
WHERE o.customer_id IS NOT NULL
GROUP BY o.customer_id, o.invoice;

-- Q6: For each customer, rank their OWN orders by value (PARTITION BY = reset ranking per group)
SELECT 
    o.customer_id,
    o.invoice,
    SUM(oi.quantity * oi.price) AS order_value,
    RANK() OVER (PARTITION BY o.customer_id ORDER BY SUM(oi.quantity * oi.price) DESC) AS rank_within_customer
FROM order_items oi
JOIN orders o USING(invoice)
WHERE o.customer_id IS NOT NULL
GROUP BY o.customer_id, o.invoice
ORDER BY o.customer_id, rank_within_customer;

-- Q7: Running cumulative revenue total over time (SUM as a window function)
SELECT 
    DATE_TRUNC('month', o.invoice_date) AS month,
    SUM(oi.quantity * oi.price) AS monthly_revenue,
    SUM(SUM(oi.quantity * oi.price)) OVER (ORDER BY DATE_TRUNC('month', o.invoice_date)) AS running_total
FROM order_items oi
JOIN orders o USING(invoice)
GROUP BY month
ORDER BY month;

-- Q8: Month-over-month revenue change (LAG = look at the previous row without a self-join)
SELECT 
    month,
    monthly_revenue,
    LAG(monthly_revenue) OVER (ORDER BY month) AS previous_month_revenue,
    monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month) AS change
FROM (
    SELECT DATE_TRUNC('month', o.invoice_date) AS month, SUM(oi.quantity * oi.price) AS monthly_revenue
    FROM order_items oi
    JOIN orders o USING(invoice)
    GROUP BY month
) monthly_totals
ORDER BY month;

-- Q9: Same as Q8, rewritten as a CTE instead of a subquery (cleaner, more readable for multi-step logic)
WITH monthly_totals AS (
    SELECT DATE_TRUNC('month', o.invoice_date) AS month, SUM(oi.quantity * oi.price) AS monthly_revenue
    FROM order_items oi
    JOIN orders o USING(invoice)
    GROUP BY month
)
SELECT 
    month,
    monthly_revenue,
    LAG(monthly_revenue) OVER (ORDER BY month) AS previous_month_revenue
FROM monthly_totals
ORDER BY month;

-- Q10: Top 3 highest-value orders PER customer (common real interview question: "top N per group")
WITH ranked_orders AS (
    SELECT 
        o.customer_id,
        o.invoice,
        SUM(oi.quantity * oi.price) AS order_value,
        ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY SUM(oi.quantity * oi.price) DESC) AS rn
    FROM order_items oi
    JOIN orders o USING(invoice)
    WHERE o.customer_id IS NOT NULL
    GROUP BY o.customer_id, o.invoice
)
SELECT * FROM ranked_orders WHERE rn <= 3
ORDER BY customer_id, rn;

-- Q11: Query optimization — check how Postgres actually executes a query (no index yet)
EXPLAIN ANALYZE
SELECT * FROM order_items WHERE stock_code = '85123A';

-- Q12: Add an index on a frequently-filtered/joined column, then re-run EXPLAIN ANALYZE to compare
CREATE INDEX idx_order_items_stock_code ON order_items(stock_code);

EXPLAIN ANALYZE
SELECT * FROM order_items WHERE stock_code = '85123A';

-- Q13: Index the foreign key columns used in every JOIN so far — real production habit, not optional
CREATE INDEX idx_order_items_invoice ON order_items(invoice);
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
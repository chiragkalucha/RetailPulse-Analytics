CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY
);

CREATE TABLE products (
    stock_code VARCHAR(50) PRIMARY KEY,
    description VARCHAR(1000),
    is_non_product BOOLEAN
);

CREATE TABLE orders (
    invoice VARCHAR(50) PRIMARY KEY,
    invoice_date DATE,
    country VARCHAR(50),
    customer_id INTEGER REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    invoice VARCHAR(50) REFERENCES orders(invoice),
    stock_code VARCHAR(50) REFERENCES products(stock_code),
    quantity INTEGER,
    price NUMERIC(10,2)
);
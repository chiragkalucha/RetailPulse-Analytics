import os
import pandas as pd
from sqlalchemy import text
from sqlalchemy import create_engine
from dotenv import load_dotenv

load_dotenv()  # reads .env file into environment variables

DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_USER = "postgres"
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "RetailPulse"

engine = create_engine(f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}")

# Load cleaned data
df = pd.read_csv("data/processed/online_retail_cleaned.csv")

print(f"Loaded {df.shape[0]} rows from processed CSV")
print(f"Connection test...")

with engine.connect() as conn:
    print("Connected to PostgreSQL successfully.")
  


with engine.begin() as conn:
    conn.execute(text("TRUNCATE TABLE order_items, orders, products, customers RESTART IDENTITY CASCADE;"))
    print("Truncated existing tables for a clean reload.")
  
# 1. Load unique customers (drop nulls — guest checkouts have no customer to insert)
customers_df = df[['Customer ID']].dropna().drop_duplicates()
customers_df.columns = ['customer_id']
customers_df['customer_id'] = customers_df['customer_id'].astype(int)

customers_df.to_sql('customers', engine, if_exists='append', index=False)
print(f"Inserted {len(customers_df)} unique customers")

# 2. Load unique products
products_df = df[['StockCode', 'Description', 'is_non_product']].drop_duplicates(subset='StockCode')
products_df.columns = ['stock_code', 'description', 'is_non_product']

products_df.to_sql('products', engine, if_exists='append', index=False)
print(f"Inserted {len(products_df)} unique products")

# 3. Load unique orders — one row per invoice
orders_df = df.groupby('Invoice').agg(
    invoice_date=('InvoiceDate', 'first'),
    country=('Country', 'first'),
    customer_id=('Customer ID', 'first')
).reset_index()

orders_df.columns = ['invoice', 'invoice_date', 'country', 'customer_id']

# customer_id must be nullable-safe: convert to Int64 (capital I) which supports NaN, unlike int
orders_df['customer_id'] = orders_df['customer_id'].astype('Int64')

orders_df.to_sql('orders', engine, if_exists='append', index=False)
print(f"Inserted {len(orders_df)} unique orders")

# 4. Load order_items — one row per original line item, no collapsing needed
order_items_df = df[['Invoice', 'StockCode', 'Quantity', 'Price']].copy()
order_items_df.columns = ['invoice', 'stock_code', 'quantity', 'price']

order_items_df.to_sql('order_items', engine, if_exists='append', index=False)
print(f"Inserted {len(order_items_df)} order line items")
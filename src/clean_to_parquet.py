import pandas as pd
from src.clean_data import clean_retail_data   # use your actual function name

RAW = "data/raw/online_retail_II.xlsx"
OUT = "data/processed/retail_clean.parquet"

sheets = pd.read_excel(RAW, sheet_name=None)
df = pd.concat(sheets.values(), ignore_index=True)
df = clean_retail_data(df)
for col in ["Invoice", "StockCode"]:
    df[col] = df[col].astype("string")

# Customer ID is float because of missing values; keep it as a nullable integer
df["Customer ID"] = df["Customer ID"].astype("Int64")

df.to_parquet(OUT, index=False)
df.to_parquet(OUT, index=False)
print(df.shape)
print(df.dtypes)
'''This file contains code to clean messy excel files based on our observations 
from the EDA notebook'''
import pandas as pd
import glob
import os

def load_raw_data(folder:str= "data/raw")->pd.DataFrame:
    '''This functions loads the dataset and return the data frame'''
    files = glob.glob(os.path.join(folder, "*.xlsx")) + glob.glob(os.path.join(folder, "*.csv"))
    
    if len(files) == 0:
        raise FileNotFoundError(f"No data file found in {folder}")
    if len(files) > 1:
        raise ValueError(f"Expected exactly one file in {folder}, found {len(files)}: {files}")
    
    filepath = files[0]
    print(f"Loading: {filepath}")
    
    if filepath.endswith('.csv'):
        return pd.read_csv(filepath)
    return pd.read_excel(filepath)

def clean_retail_data(df:pd.DataFrame)->pd.DataFrame:
    
    df=df.copy()
    
    df['StockCode'] = df['StockCode'].astype(str)
    
    df=df[df['StockCode']!='B']
    
    not_present= (df['Price']==0) &(df['Customer ID'].isna())
    df=df[~not_present]
    
    df['Description']=df['Description'].fillna('Unknown')
    df=df.drop_duplicates()
    
    df['StockCode']=df['StockCode'].replace({'m':'M'})
    
    codes_to_drop=['TEST001', 'TEST002', 'BANK CHARGES', 'AMAZONFEE', 'S']
    df=df[~df['StockCode'].isin(codes_to_drop)]
    
    codes_to_flag=['POST', 'DOT', 'C2', 'D', 'ADJUST', 'ADJUST2', 'M']
    df['is_non_product']=df['StockCode'].isin(codes_to_flag)
    
    # Validation check: warn if any unrecognized non-numeric StockCode appears
    # (protects against silently mis-treating a future/unknown code as a normal product)
    known_special_codes = codes_to_drop + codes_to_flag + [
    'DCGS0058', 'DCGS0068', 'DCGS0004', 'DCGS0076', 'DCGS0003', 'DCGS0072',
    'gift_0001_80', 'gift_0001_20', 'DCGS0044', 'gift_0001_10', 'gift_0001_50',
    'DCGS0066N', 'gift_0001_30', 'PADS', 'DCGS0069', 'DCGS0070', 'DCGS0075',
    'DCGS0041', 'gift_0001_70', 'DCGS0037', 'DCGSSBOY', 'DCGSSGIRL',
    'gift_0001_40', 'SP1002', 'DCGS0062'
   ]
    unexpected_codes = df[
        (~df['StockCode'].str[0].str.isdigit()) &
        (~df['StockCode'].isin(known_special_codes))
    ]['StockCode'].unique()

    if len(unexpected_codes) > 0:
        print(f"⚠️ WARNING: Found {len(unexpected_codes)} unrecognized non-product code(s): {list(unexpected_codes)}")
        print("These were NOT dropped or flagged automatically — review and update clean_data.py.")
    return df

if __name__=="__main__":
    raw_df=load_raw_data()
    print(f"Raw data: {raw_df.shape}")
    
    clean_df=clean_retail_data(raw_df)
    print(f"Clean data: {clean_df.shape}")
    
    output_path="data/processed/online_retail_cleaned.csv"
    clean_df.to_csv(output_path, index=False)
    print(f"Cleaned data saved to :{output_path}")
    
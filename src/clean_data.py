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
    
    df=df[df['StockCode']!='B']
    
    not_present= (df['Price']==0) &(df['Customer ID'].isna())
    df=df[~not_present]
    
    df['Description']=df['Description'].fillna('Unknown')
    df=df.drop_duplicates()
    return df

if __name__=="__main__":
    raw_df=load_raw_data()
    print(f"Raw data: {raw_df.shape}")
    
    clean_df=clean_retail_data(raw_df)
    print(f"Clean data: {clean_df.shape}")
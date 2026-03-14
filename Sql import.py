import pandas as pd
from sqlalchemy import create_engine

# Read Excel directly (no CSV needed!)
excel_file = '/Users/soumalya/Downloads/Inventory Data.xlsx'
orders = pd.read_excel(excel_file, sheet_name=0)
inventory = pd.read_excel(excel_file, sheet_name=1)

# Clean column names
orders.columns = orders.columns.str.strip()
inventory.columns = inventory.columns.str.strip()

# Fix dates
orders['Order Date'] = pd.to_datetime(orders['Order Date'], format='%d/%m/%y')

# Connect to MySQL (change password!)
engine = create_engine('mysql+mysqlconnector://root:Riju%401111@localhost/Inventory_managements')

# Upload (handles encoding automatically)
orders.to_sql('orders', engine, if_exists='replace', index=False)
inventory.to_sql('inventory', engine, if_exists='replace', index=False)

print("✓ Data loaded successfully!")

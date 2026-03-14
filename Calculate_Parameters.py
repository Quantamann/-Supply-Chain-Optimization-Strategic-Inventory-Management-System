import pandas as pd
import numpy as np
from scipy import stats
from sqlalchemy import create_engine


print("INVENTORY PARAMETERS CALCULATION")


# Step 1: Connect to MySQL
engine = create_engine('mysql+mysqlconnector://root:Riju%401111@localhost/inventory_managements')

# Step 2: Load data from SQL
print("\\nLoading data from MySQL...")
df = pd.read_sql("SELECT * FROM v_inventory_master", engine)
print(f"✓ Loaded {len(df)} SKUs")

# Step 3: Filter SKUs with demand
df = df[df['total_demand'] > 0].copy()
print(f"✓ Processing {len(df)} SKUs with demand")

# Step 4: Calculate EOQ
print("\\nCalculating EOQ...")
ordering_cost = 500
holding_rate = 0.25

df['holding_cost'] = df['unit_price'] * holding_rate
df['eoq'] = np.sqrt((2 * df['annual_demand'] * ordering_cost) / df['holding_cost']).round(0)
df['orders_per_year'] = (df['annual_demand'] / df['eoq']).round(1)

# Step 5: Calculate Safety Stock
print("Calculating Safety Stock...")
service_level = 0.95  # 95% service level
z_score = stats.norm.ppf(service_level)

df['daily_demand'] = df['annual_demand'] / 365
df['lead_time'] = df['average_lead_time_days'].fillna(df['average_lead_time_days'].median())
df['demand_during_leadtime'] = df['daily_demand'] * df['lead_time']

# Calculate standard deviation during lead time
df['daily_std'] = df['std_order_size'] / np.sqrt(df['days_active'] / df['order_count']).fillna(1)
df['std_during_leadtime'] = df['daily_std'] * np.sqrt(df['lead_time'])
df['safety_stock'] = (z_score * df['std_during_leadtime']).round(0).clip(lower=0)
df['reorder_point'] = (df['demand_during_leadtime'] + df['safety_stock']).round(0)

# Step 6: Stock Status
print("Determining Stock Status...")
df['stock_status'] = np.where(
    df['current_stock_quantity'] < df['reorder_point'],
    'REORDER NOW',
    np.where(
        df['current_stock_quantity'] < df['reorder_point'] * 1.2,
        'LOW STOCK',
        'ADEQUATE'
    )
)

df['days_of_stock'] = df['current_stock_quantity'] / df['daily_demand'].replace(0.0,1)
df['is_overstock'] = df['days_of_stock'] > 180

# Step 7: Calculate Savings
current_orders_per_year = 12  
df['current_annual_cost'] = (
    current_orders_per_year * ordering_cost +
    (df['annual_demand'] / current_orders_per_year / 2) * df['holding_cost']
)
df['optimized_annual_cost'] = (
    df['orders_per_year'] * ordering_cost +
    (df['eoq'] / 2) * df['holding_cost']
)
df['potential_savings'] = df['current_annual_cost'] - df['optimized_annual_cost']

# Step 8: Prepare results
results = df[[
    'sku_id', 'annual_demand', 'daily_demand', 'holding_cost', 'eoq', 
    'orders_per_year', 'lead_time', 'demand_during_leadtime', 
    'std_during_leadtime', 'safety_stock', 'reorder_point',
    'current_stock_quantity', 'stock_status', 'days_of_stock', 
    'is_overstock', 'current_annual_cost', 'optimized_annual_cost', 
    'potential_savings'
]].copy().fillna(0)

results.columns = [
    'sku_id', 'annual_demand', 'daily_demand', 'holding_cost', 'eoq',
    'orders_per_year', 'lead_time_days', 'demand_during_leadtime',
    'std_during_leadtime', 'safety_stock', 'reorder_point',
    'current_stock', 'stock_status', 'days_of_stock', 'is_overstock',
    'current_annual_cost', 'optimized_annual_cost', 'potential_savings'
]

# Step 9: Save to CSV
results.to_csv('/Users/soumalya/Downloads/inventory_parameters4.csv', index=False)
print(f"\\n✓ Saved results to: inventory_parameters.csv")

# Step 10: Upload to MySQL
results.to_sql('inventory_parameters', engine, if_exists='replace', index=False)
print(f"✓ Uploaded results to MySQL table: inventory_parameters")

# Summary

print("SUMMARY")

print(f"Total SKUs processed: {len(results)}")
print(f"REORDER NOW: {(results['stock_status']=='REORDER NOW').sum()} SKUs")
print(f"LOW STOCK: {(results['stock_status']=='LOW STOCK').sum()} SKUs")
print(f"ADEQUATE: {(results['stock_status']=='ADEQUATE').sum()} SKUs")
print(f"OVERSTOCKED: {results['is_overstock'].sum()} SKUs")
print(f"Total potential savings: ₹{results['potential_savings'].sum():,.0f}")
print("="*80)

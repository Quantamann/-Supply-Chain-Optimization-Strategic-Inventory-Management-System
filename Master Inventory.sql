Use inventory_managements;
Select database();
Create view v_inventory_master as
select 
	i.`SKU ID` AS sku_id,
    i.`Current Stock Quantity` AS current_stock_quantity,
    i.`Unit Price` AS unit_price,
    i.`Average Lead Time (days)` AS average_lead_time_days,
    d.total_demand,
    d.avg_order_size,
    d.std_order_size,
    d.order_count,
    d.days_active,
    abc.abc_class,
    abc.cumulative_pct,
    xyz.xyz_class,
    xyz.coefficient_variation,
	Concat(coalesce(abc.abc_class,'N'),coalesce(xyz.xyz_class,'N'))as combined_class,
    round(i.`Current Stock Quantity`*i.`Unit Price`,2) as current_stock_value,
    case
		when d.days_active>0
			Then round(d.total_demand*(365/d.days_active),2)
            else 0
	end as annual_demand
From inventory i
Join demand_analysis d on i.`SKU ID`=d.sku_id
Join abc_classification abc on i.`SKU ID`=abc.sku_id
Join xyz_classification xyz on i.`SKU ID`=xyz.sku_id;

Select * from v_inventory_master limit 10;


SELECT 
    abc_class,
    SUM(CASE WHEN xyz_class = 'X' THEN 1 ELSE 0 END) AS X_stable,
    SUM(CASE WHEN xyz_class = 'Y' THEN 1 ELSE 0 END) AS Y_moderate,
    SUM(CASE WHEN xyz_class = 'Z' THEN 1 ELSE 0 END) AS Z_variable
FROM v_inventory_master
WHERE abc_class IS NOT NULL
GROUP BY abc_class;
Select * from v_inventory_master;



Select * from inventory_parameters;



CREATE VIEW v_inventory_complete AS
SELECT 
    i.`SKU ID`,
    i.`Current Stock Quantity`,
    i.`Unit Price`,
    abc.abc_class,
    xyz.xyz_class,
    CONCAT(abc.abc_class, xyz.xyz_class) AS combined_class,
    p.eoq,
    p.safety_stock,
    p.reorder_point,
    p.stock_status,
    p.days_of_stock,
    p.potential_savings,
    ROUND(i.`Current Stock Quantity`* i.`Unit Price`, 2) AS current_stock_value
FROM inventory i
LEFT JOIN abc_classification abc ON i.`SKU ID` = abc.sku_id
LEFT JOIN xyz_classification xyz ON i.`SKU ID` = xyz.sku_id
LEFT JOIN inventory_parameters p ON i.`SKU ID` = p.sku_id;

SELECT * FROM v_inventory_complete LIMIT 10;

SELECT 
    combined_class,
    COUNT(*) AS sku_count,
    SUM(CASE WHEN stock_status = 'REORDER NOW' THEN 1 ELSE 0 END) AS reorder_now,
    SUM(CASE WHEN stock_status = 'LOW STOCK' THEN 1 ELSE 0 END) AS low_stock,
    ROUND(SUM(current_stock_value), 0) AS total_value
FROM v_inventory_complete
WHERE combined_class IS NOT NULL
GROUP BY combined_class
ORDER BY combined_class;

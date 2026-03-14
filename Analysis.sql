use inventory_managements;
select database();
Create table demand_analysis as
select 
	o.`SKU ID` as sku_id,
    count(*) as order_count,
    sum(o.`Order Quantity`) as total_demand,
    avg(o.`Order Quantity`) as avg_order_size,
    stddev(o.`Order Quantity`) AS std_order_size,
    min(o.`Order Date`) as first_order_date,
    MAX(o.`Order Date`) AS last_order_date,
    DATEDIFF(MAX(o.`Order Date`), MIN(o.`Order Date`)) AS days_active,
    SUM(o.`Order Quantity` * i.`Unit Price`) AS total_order_value
from orders o
join inventory i on o.`SKU ID`=i.`SKU ID`
group by o.`SKU ID`;

Create table abc_classification as
With ranked_skus as
(
select
	sku_id,
    total_order_value,
    row_number() over (order by total_order_value desc) as value_rank
from demand_analysis
where total_order_value > 0),


cumulative_calc as
(

SELECT 
        sku_id,
        total_order_value,
        value_rank,
        SUM(total_order_value) OVER (ORDER BY value_rank) AS cumulative_value,
        SUM(total_order_value) OVER () AS total_value
    FROM ranked_skus
)
Select
		sku_id,
        
        total_order_value,
        cumulative_value,
        round((cumulative_value/total_value)/100,2) as cumulative_pct,
        CASE 
			WHEN (cumulative_value / total_value) * 100 <= 70 THEN 'A'
			WHEN (cumulative_value / total_value) * 100 <= 90 THEN 'B'
			ELSE 'C'
		END AS abc_class
from cumulative_calc;    


select abc_class,count(*) from abc_classification group by abc_class;

CREATE TABLE xyz_classification AS
SELECT 
    sku_id,
    avg_order_size,
    std_order_size,
    order_count,
    CASE 
        WHEN avg_order_size > 0 THEN 
            ROUND((std_order_size / avg_order_size) * 100, 2)
        ELSE 0
    END AS coefficient_variation,
    CASE 
        WHEN avg_order_size = 0 THEN 'N'
        WHEN order_count < 3 THEN 'N'
        WHEN (std_order_size / avg_order_size) * 100 < 25 THEN 'X'
        WHEN (std_order_size / avg_order_size) * 100 < 50 THEN 'Y'
        ELSE 'Z'
    END AS xyz_class
FROM demand_analysis;
select xyz_class,count(*) from xyz_classification group by xyz_class;

Select count(sku_id) from xyz_classification; 
SELECT COUNT(*) FROM demand_analysis;
with base as (
    select * from {{ ref('int_property_sales') }}
    where price_per_sqft between 1 and 10000
)
select
    borough_code,
    sale_year,
    building_type,
    count(*) as sale_count,
    round(avg(price_per_sqft), 2) as avg_price_per_sqft,
    round(median(price_per_sqft), 2) as median_price_per_sqft,
    round(sum(sale_price), 0) as total_sale_volume
from base
group by borough_code, sale_year, building_type
order by borough_code, sale_year, building_type
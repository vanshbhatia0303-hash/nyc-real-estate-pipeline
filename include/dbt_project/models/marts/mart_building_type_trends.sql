select
    building_type,
    sale_year,
    count(*) as transaction_count,
    median(price_per_sqft) filter (where psf_eligible) as median_price_per_sqft,
    count(*) filter (where psf_eligible) as psf_eligible_count
from {{ ref('int_property_sales') }}
group by building_type, sale_year
order by building_type, sale_year
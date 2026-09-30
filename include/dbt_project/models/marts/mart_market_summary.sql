with yearly as (
    select
        sale_year,
        count(*) as transaction_count,
        sum(sale_price) as total_sale_volume,
        median(price_per_sqft) filter (where psf_eligible) as median_price_per_sqft,
        avg(price_per_sqft) filter (where psf_eligible) as avg_price_per_sqft
    from {{ ref('int_property_sales') }}
    group by sale_year
),
bounds as (
    select min(sale_year) as first_year, max(sale_year) as last_year from yearly
)
select
    y.*,
    b.first_year,
    b.last_year,
    y.median_price_per_sqft / f.median_price_per_sqft - 1 as change_since_first_year
from yearly y
cross join bounds b
join yearly f on f.sale_year = b.first_year
order by y.sale_year
with base as (
    select * from {{ ref('int_property_sales') }}
    where psf_eligible and neighborhood is not null
),
neighborhood_yearly as (
    select
        borough_code,
        neighborhood,
        sale_year,
        count(*) as transaction_count,
        median(price_per_sqft) as median_price_per_sqft
    from base
    group by borough_code, neighborhood, sale_year
),
borough_yearly as (
    select
        borough_code,
        sale_year,
        median(price_per_sqft) as borough_median_price_per_sqft
    from base
    group by borough_code, sale_year
)
select
    n.borough_code,
    n.neighborhood,
    n.sale_year,
    n.transaction_count,
    n.median_price_per_sqft,
    b.borough_median_price_per_sqft,
    n.median_price_per_sqft - b.borough_median_price_per_sqft as diff_vs_borough,
    100.0 * (n.median_price_per_sqft - b.borough_median_price_per_sqft) / b.borough_median_price_per_sqft as pct_vs_borough
from neighborhood_yearly n
join borough_yearly b on n.borough_code = b.borough_code and n.sale_year = b.sale_year
order by n.borough_code, n.sale_year, pct_vs_borough desc
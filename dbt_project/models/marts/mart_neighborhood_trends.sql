with base as (
    select * from {{ ref('int_property_sales') }}
    where price_per_sqft between 1 and 10000
      and neighborhood is not null
),
neighborhood_agg as (
    select
        borough_code,
        neighborhood,
        sale_year,
        count(*) as sale_count,
        round(avg(price_per_sqft), 2) as avg_price_per_sqft
    from base
    group by borough_code, neighborhood, sale_year
),
borough_agg as (
    select
        borough_code,
        sale_year,
        round(avg(price_per_sqft), 2) as borough_avg_price_per_sqft
    from base
    group by borough_code, sale_year
)
select
    n.borough_code,
    n.neighborhood,
    n.sale_year,
    n.sale_count,
    n.avg_price_per_sqft,
    b.borough_avg_price_per_sqft,
    round(n.avg_price_per_sqft - b.borough_avg_price_per_sqft, 2) as diff_vs_borough_avg,
    round(100.0 * (n.avg_price_per_sqft - b.borough_avg_price_per_sqft) / b.borough_avg_price_per_sqft, 1) as pct_vs_borough_avg
from neighborhood_agg n
join borough_agg b on n.borough_code = b.borough_code and n.sale_year = b.sale_year
order by n.borough_code, n.sale_year, n.avg_price_per_sqft desc
with sales as (
    select * from {{ ref('stg_rolling_sales') }}
),
parcels as (
    select * from {{ ref('stg_pluto') }}
)
select
    s.bbl,
    s.borough_code,
    s.neighborhood,
    s.nta,
    s.sale_date,
    extract(year from s.sale_date) as sale_year,
    s.sale_price,
    s.building_class_category,
    case
        when s.building_class_category ilike '%apartment%'
          or s.building_class_category ilike '%family dwelling%'
          or s.building_class_category ilike '%coop%'
        then 'multifamily'
        when s.building_class_category ilike '%with commercial%'
        then 'mixed-use'
        when s.building_class_category ilike '%office%'
          or s.building_class_category ilike '%store%'
          or s.building_class_category ilike '%warehouse%'
          or s.building_class_category ilike '%factor%'
          or s.building_class_category ilike '%garage%'
          or s.building_class_category ilike '%hotel%'
        then 'commercial'
        else 'other'
    end as building_type,
    (s.building_class_category ilike '%condo%' or s.building_class_category ilike '%coop%') as is_unit_sale,
    p.building_area_sqft,
    p.lot_area_sqft,
    p.zonedist1,
    p.year_built,
    (p.bbl is not null) as matched_parcel,
    (s.sale_price > 0) as valid_price,
    (p.building_area_sqft is not null and p.building_area_sqft > 0) as valid_sqft,
    case when p.building_area_sqft > 0 then s.sale_price / p.building_area_sqft end as price_per_sqft,
    (
        p.bbl is not null
        and s.sale_price > 0
        and p.building_area_sqft is not null and p.building_area_sqft > 0
        and not (s.building_class_category ilike '%condo%' or s.building_class_category ilike '%coop%')
        and (s.sale_price / p.building_area_sqft) between 10 and 10000
    ) as psf_eligible
from sales s
left join parcels p on s.bbl = p.bbl
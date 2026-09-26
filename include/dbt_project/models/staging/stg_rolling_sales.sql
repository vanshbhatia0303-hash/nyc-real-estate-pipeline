select
    try_cast(borough as integer) as borough_code,
    neighborhood,
    building_class_category,
    tax_class_as_of_final_roll as tax_class,
    try_cast(block as integer) as block,
    try_cast(lot as integer) as lot,
    try_cast(bbl as bigint) as bbl,
    building_class_as_of_final as building_class,
    address,
    apartment_number,
    zip_code,
    try_cast(residential_units as integer) as residential_units,
    try_cast(commercial_units as integer) as commercial_units,
    try_cast(total_units as integer) as total_units,
    try_cast(land_square_feet as double) as land_square_feet,
    try_cast(gross_square_feet as double) as gross_square_feet,
    try_cast(year_built as integer) as year_built,
    try_cast(sale_price as double) as sale_price,
    sale_date,
    try_cast(latitude as double) as latitude,
    try_cast(longitude as double) as longitude,
    nta,
    community_board,
    council_district
from {{ source('raw', 'rolling_sales') }}
where try_cast(sale_price as double) > 0
  and try_cast(bbl as bigint) is not null
select
    case borough
        when 'MN' then 1
        when 'BX' then 2
        when 'BK' then 3
        when 'QN' then 4
        when 'SI' then 5
    end as borough_code,
    try_cast(block as integer) as block,
    try_cast(lot as integer) as lot,
    try_cast(bbl as bigint) as bbl,
    address,
    zonedist1,
    landuse,
    bldgclass as building_class,
    ownertype,
    try_cast(lotarea as double) as lot_area_sqft,
    try_cast(bldgarea as double) as building_area_sqft,
    try_cast(comarea as double) as commercial_area_sqft,
    try_cast(resarea as double) as residential_area_sqft,
    try_cast(numbldgs as integer) as num_buildings,
    try_cast(numfloors as double) as num_floors,
    try_cast(unitsres as integer) as residential_units,
    try_cast(unitstotal as integer) as total_units,
    try_cast(yearbuilt as integer) as year_built,
    try_cast(latitude as double) as latitude,
    try_cast(longitude as double) as longitude
from {{ source('raw', 'pluto') }}
where try_cast(bbl as bigint) is not null
  and try_cast(bldgarea as double) > 0
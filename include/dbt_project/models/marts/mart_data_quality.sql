select
    count(*) as total_transactions,
    count(*) filter (where not valid_price) as zero_or_negative_price_excluded,
    count(*) filter (where not matched_parcel) as unmatched_parcel_excluded,
    count(*) filter (where matched_parcel and not valid_sqft) as missing_or_zero_sqft_excluded,
    count(*) filter (where is_unit_sale) as condo_coop_excluded_from_psf,
    count(*) filter (
        where valid_price and valid_sqft and matched_parcel and not is_unit_sale
        and price_per_sqft not between 10 and 10000
    ) as extreme_outlier_excluded,
    count(*) filter (where psf_eligible) as psf_eligible_transactions
from {{ ref('int_property_sales') }}
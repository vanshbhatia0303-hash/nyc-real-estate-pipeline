# NYC Property Market Monitor

Transaction-level price per square foot trends across boroughs, property types, and neighborhoods

```sql latest_summary
select * from market_summary where sale_year = last_year
```
​
Rolling sales analysis, {latest_summary[0].first_year} to {latest_summary[0].last_year}

## Market Snapshot

<BigValue data={latest_summary} value=transaction_count title="Transactions" fmt=num0/>
<BigValue data={latest_summary} value=total_sale_volume title="Total Sale Volume" fmt=usd0m/>
<BigValue data={latest_summary} value=median_price_per_sqft title="Median $/sqft" fmt=usd0/>
<BigValue data={latest_summary} value=avg_price_per_sqft title="Average $/sqft" fmt=usd0/>
<BigValue data={latest_summary} value=change_since_first_year title="Change vs First Year" fmt=pct1/>

Median is used as the primary metric throughout this page, since transaction-level $/sqft is heavily skewed by property type and size, not just changes in market value. Average is shown alongside for reference.

## Three Year Price Trend

```sql borough_named
select
    *,
    case borough_code
        when 1 then 'Manhattan'
        when 2 then 'Bronx'
        when 3 then 'Brooklyn'
        when 4 then 'Queens'
        when 5 then 'Staten Island'
    end as borough_name
from borough_trends
```
​
Median transaction $/sqft by borough, {latest_summary[0].first_year} to {latest_summary[0].last_year}. Reflects observed transaction prices, not a constant-property valuation index.

<LineChart
    data={borough_named}
    x=sale_year
    y=median_price_per_sqft
    series=borough_name
    xType=category
    yAxisTitle="$/sqft"
    yFmt=usd0
/>

```sql borough_first_year
select borough_code, median_price_per_sqft as first_year_psf
from ${borough_named}
where sale_year = (select min(sale_year) from ${borough_named})
```

```sql borough_latest
select
    b.*,
    f.first_year_psf,
    b.median_price_per_sqft / f.first_year_psf - 1 as change_since_first_year
from ${borough_named} b
join ${borough_first_year} f on b.borough_code = f.borough_code
where b.sale_year = (select max(sale_year) from ${borough_named})
```

```sql city_latest_volume
select total_sale_volume as city_total_volume from market_summary
where sale_year = last_year
```

```sql borough_table
select
    b.borough_name,
    b.median_price_per_sqft,
    b.change_since_first_year,
    b.transaction_count,
    b.total_sale_volume / c.city_total_volume as share_of_city_volume
from ${borough_latest} b
cross join ${city_latest_volume} c
order by b.median_price_per_sqft desc
```

## Borough Performance

<DataTable data={borough_table}>
    <Column id=borough_name title="Borough"/>
    <Column id=median_price_per_sqft title="Latest $/sqft" fmt=usd0/>
    <Column id=change_since_first_year title="Change" fmt=pct1/>
    <Column id=transaction_count title="Transactions" fmt=num0/>
    <Column id=share_of_city_volume title="Share of City Volume" fmt=pct1/>
</DataTable>

## Property Type Decomposition

```sql building_type_trend
select * from building_type_trends where building_type != 'other'
```
​
Median $/sqft trend, excluding the small "other" category from the chart below (still shown in the table). Mixed-use has too few qualifying transactions in some years to produce a reliable median, shown as a blank in that case rather than a misleading number.

<LineChart
    data={building_type_trend}
    x=sale_year
    y=median_price_per_sqft
    series=building_type
    xType=category
    yAxisTitle="$/sqft"
    yFmt=usd0
/>

```sql building_type_table
select building_type, transaction_count, median_price_per_sqft
from building_type_trends
where sale_year = (select max(sale_year) from building_type_trends)
order by transaction_count desc
```

<DataTable data={building_type_table}>
    <Column id=building_type title="Type"/>
    <Column id=transaction_count title="Transactions" fmt=num0/>
    <Column id=median_price_per_sqft title="Median $/sqft" fmt=usd0/>
</DataTable>

## Neighborhood Performance vs Borough Benchmark

```sql neighborhood_named
select
    *,
    case borough_code
        when 1 then 'Manhattan'
        when 2 then 'Bronx'
        when 3 then 'Brooklyn'
        when 4 then 'Queens'
        when 5 then 'Staten Island'
    end as borough_name
from neighborhood_performance
where sale_year = (select max(sale_year) from neighborhood_performance)
  and transaction_count >= 20
```
​
Limited to neighborhoods with at least 20 transactions in the latest year, to avoid comparing thin samples as if they carry equal statistical weight.

```sql top_performers
select * from ${neighborhood_named} order by pct_vs_borough desc limit 8
```

**Above Borough Benchmark**

<DataTable data={top_performers}>
    <Column id=neighborhood/>
    <Column id=borough_name title="Borough"/>
    <Column id=transaction_count title="Transactions" fmt=num0/>
    <Column id=median_price_per_sqft title="$/sqft" fmt=usd0/>
    <Column id=pct_vs_borough title="vs Borough" fmt=num1/>
</DataTable>

```sql bottom_performers
select * from ${neighborhood_named} order by pct_vs_borough asc limit 8
```

**Below Borough Benchmark**

<DataTable data={bottom_performers}>
    <Column id=neighborhood/>
    <Column id=borough_name title="Borough"/>
    <Column id=transaction_count title="Transactions" fmt=num0/>
    <Column id=median_price_per_sqft title="$/sqft" fmt=usd0/>
    <Column id=pct_vs_borough title="vs Borough" fmt=num1/>
</DataTable>

## Methodology and Data Quality

```sql dq
select * from data_quality limit 1
```
​
Source data: NYC Department of Finance Rolling Sales and NYC PLUTO parcel records, {latest_summary[0].first_year} to {latest_summary[0].last_year}.

Of {dq[0].total_transactions} total recorded transactions, {dq[0].psf_eligible_transactions} are used in $/sqft calculations. Exclusions: {dq[0].zero_or_negative_price_excluded} with zero or negative sale price (non-market transfers), {dq[0].missing_or_zero_sqft_excluded} with missing or zero building square footage, {dq[0].unmatched_parcel_excluded} with no matching parcel record, {dq[0].condo_coop_excluded_from_psf} condo or co-op unit sales (building-level square footage does not represent the individual unit sold, so $/sqft cannot be reliably computed for these), and {dq[0].extreme_outlier_excluded} extreme values outside a 10 to 10,000 dollar per square foot range, set from the 99.9th percentile of this dataset's own distribution.

Median, not average, is used as the primary metric throughout, since transaction-level $/sqft is heavily skewed. Neighborhood comparisons require a minimum of 20 transactions in the latest year. Neighborhood-level year-over-year change is not shown, since sale volume per neighborhood is too uneven year to year to support a reliable trend at that granularity.
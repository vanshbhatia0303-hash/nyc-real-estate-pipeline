import duckdb
con = duckdb.connect("../include/nyc_property.duckdb")
print(con.sql("""
    select
        count(*) as neighborhood_year_rows,
        count(*) filter (where transaction_count < 5) as under_5,
        count(*) filter (where transaction_count >= 5 and transaction_count < 10) as band_5_10,
        count(*) filter (where transaction_count >= 10 and transaction_count < 20) as band_10_20,
        count(*) filter (where transaction_count >= 20 and transaction_count < 30) as band_20_30,
        count(*) filter (where transaction_count >= 30) as over_30,
        median(transaction_count) as median_count
    from main.mart_neighborhood_performance
    where sale_year = (select max(sale_year) from main.mart_neighborhood_performance)
"""))
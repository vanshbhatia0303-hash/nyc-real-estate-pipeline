import duckdb
con = duckdb.connect('nyc_property.duckdb')
print(con.sql("select distinct borough from raw.rolling_sales limit 10"))
print(con.sql("select distinct borough from raw.pluto limit 10"))
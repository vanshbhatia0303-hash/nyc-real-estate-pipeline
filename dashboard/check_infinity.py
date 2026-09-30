import duckdb
con = duckdb.connect("sources/nyc_property/nyc_property.duckdb")
print(con.sql("select * from main.mart_neighborhood_trends limit 20 offset 1000"))
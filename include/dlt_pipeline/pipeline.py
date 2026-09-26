import os
import time
import dlt
import requests

BASE = "https://data.cityofnewyork.us/resource"
SALES_ID = "w2pb-icbu"
PLUTO_ID = "64uk-42ks"
PAGE = 20000
DEV = os.getenv("DEV") == "1"

def fetch(resource_id, params, retries=5):
    for attempt in range(retries):
        r = requests.get(f"{BASE}/{resource_id}.json", params=params, timeout=90)
        if r.status_code == 503 and attempt < retries - 1:
            time.sleep(2 ** attempt)
            continue
        r.raise_for_status()
        return r.json()

def paginate(resource_id, where=None):
    last_id = None
    total = 0
    while True:
        clauses = [c for c in [where, f":id > '{last_id}'" if last_id else None] if c]
        params = {"$order": ":id", "$limit": PAGE, "$select": "*,:id"}
        if clauses:
            params["$where"] = " AND ".join(clauses)
        rows = fetch(resource_id, params)
        if not rows:
            break
        total += len(rows)
        print(f"{resource_id}: {total} rows fetched so far")
        yield rows
        last_id = rows[-1][":id"]
        if len(rows) < PAGE:
            break

@dlt.resource(name="rolling_sales", write_disposition="merge",
              primary_key=["borough", "block", "lot", "sale_date", "sale_price"])
def rolling_sales(sale_date=dlt.sources.incremental("sale_date", initial_value="2022-01-01T00:00:00.000")):
    where = f"sale_date > '{sale_date.last_value}'" if sale_date.last_value else None
    yield from paginate(SALES_ID, where)

@dlt.resource(name="pluto", write_disposition="replace")
def pluto():
    yield from paginate(PLUTO_ID)

@dlt.source
def nyc_property_source():
    return rolling_sales(), pluto()

if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    duckdb_path = os.path.join(script_dir, "..", "nyc_property.duckdb")
    pipelines_dir = os.path.join(script_dir, "..", ".dlt_pipelines")
    pipeline = dlt.pipeline(
        pipeline_name="nyc_property",
        destination=dlt.destinations.duckdb(duckdb_path),
        dataset_name="raw",
        pipelines_dir=pipelines_dir,
    )
    info = pipeline.run(nyc_property_source())
    print(info)
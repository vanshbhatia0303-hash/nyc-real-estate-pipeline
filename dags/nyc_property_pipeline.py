import os
from datetime import datetime
from airflow.decorators import dag
from airflow.operators.bash import BashOperator

INCLUDE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "include")
DBT_PROJECT = os.path.join(INCLUDE, "dbt_project")

default_args = {"owner": "vansh", "retries": 1}

@dag(
    dag_id="nyc_property_pipeline",
    schedule="@weekly",
    start_date=datetime(2026, 9, 1),
    catchup=False,
    default_args=default_args,
    tags=["nyc-property"],
)
def nyc_property_pipeline():
    ingest = BashOperator(
        task_id="dlt_ingest",
        bash_command=f"rm -rf ~/.dlt/pipelines/nyc_property && python {INCLUDE}/dlt_pipeline/pipeline.py",
    )
    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command=f"dbt run --project-dir {DBT_PROJECT} --profiles-dir {DBT_PROJECT}",
    )
    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=f"dbt test --project-dir {DBT_PROJECT} --profiles-dir {DBT_PROJECT}",
    )
    ingest >> dbt_run >> dbt_test

nyc_property_pipeline()
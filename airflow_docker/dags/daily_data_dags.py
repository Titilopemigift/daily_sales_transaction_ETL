from datetime import datetime

from airflow import DAG
from airflow.operators.python import PythonOperator
from daily_sales_data import generate_and_upload_sales_data
from airflow.providers.amazon.aws.transfers.s3_to_redshift import S3ToRedshiftOperator


date_str = datetime.now().strftime('%Y-%m-%d')

# constants
S3_BUCKET = "trnx-data"
S3_KEY = f"daily_trnx_data/{date_str}_tranx.parquet"
REDSHIFT_SCHEMA = "public"
REDSHIFT_TABLE = "daily_sales_tranx"
REDSHIFT_CONN_ID = "redshift"
AWS_CONN_ID = "aws_default"


default_args = {
    'owner': 'Titilope',
    'retries': 1
}

dag = DAG(
    dag_id="daily_sales_data",
    description="Generate transactional data and upload to s3",
    schedule_interval="@daily",
    catchup=False,
    start_date=datetime(2025, 7, 28),
    default_args=default_args
)

load_to_s3 = PythonOperator(
    task_id="load_to_s3",
    dag=dag,
    python_callable=generate_and_upload_sales_data
)


s3_to_redshift = S3ToRedshiftOperator(
    task_id="s3_to_redshiftt",
    dag=dag,
    schema=REDSHIFT_SCHEMA,
    table=REDSHIFT_TABLE,
    s3_bucket=S3_BUCKET,
    s3_key=S3_KEY,
    redshift_conn_id=REDSHIFT_CONN_ID,
    aws_conn_id=AWS_CONN_ID,
    copy_options=["FORMAT AS PARQUET"]

)

load_to_s3 >> s3_to_redshift

import random
from datetime import datetime

import awswrangler as wr
import boto3
import pandas as pd
from airflow.models import Variable
from faker import Faker

fake = Faker()


product_catalog = [
    {"product_id": "P1001", "name": "Laptop", "category": "Electronics"},
    {"product_id": "P1002", "name": "Smartphone", "category": "Electronics"},
    {"product_id": "P1003", "name": "Desk Chair", "category": "Furniture"},
    {"product_id": "P1004", "name": "Water Bottle", "category": "Home"},
    {"product_id": "P1005", "name": "Notebook", "category": "Stationery"},
]

payment_methods = ["card", "cash", "bank_transfer", "wallet"]


def generate_and_upload_sales_data():
    """
    Generate sales transaction data and upload
    the to an Amazon S3 bucket in Parquet format.
    """
    access_key = Variable.get("MY_ACCESS_KEY")
    secret_key = Variable.get("MY_SECRET_KEY")
    region_key = Variable.get("REGION_NAME")

    session = boto3.Session(
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key,
        region_name=region_key
    )
    num_records = random.randint(500_000, 1_000_000)
    records = []

    for i in range(num_records):
        product = random.choice(product_catalog)
        amount = round(random.uniform(5.0, 500.0), 2)

        records.append({
            "transaction_id": f"TXN{str(i).zfill(10)}",
            "customer_id": fake.random_int(min=1000, max=50000),
            "customer_name": fake.name(),
            "customer_email": fake.email(),
            "product_id": product["product_id"],
            "product_name": product["name"],
            "category": product["category"],
            "amount": amount,
            "transaction_type": random.choice(["purchase", "return"]),
            "payment_method": random.choice(payment_methods),
            "transaction_date": fake.date_time_this_year(),
            "store_location": fake.city(),
            "employee_id": f"E{random.randint(100, 999)}"
        })

    df_sales = pd.DataFrame(records)

# S3 path
    s3_bucket = 'trnx-data'
    s3_folder = 'daily_trnx_data'
    date_str = datetime.now().strftime('%Y-%m-%d')
    s3_path = f"s3://{s3_bucket}/{s3_folder}/{date_str}_tranx.parquet"

    wr.s3.to_parquet(
        df_sales,
        path=s3_path,
        dataset=True,
        index=False,
        mode="overwrite",
        compression="snappy",
        boto3_session=session
    )

    return s3_path

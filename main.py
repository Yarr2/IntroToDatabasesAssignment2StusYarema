import os
import random
from datetime import datetime, timedelta
import psycopg2
from psycopg2.extras import execute_values
from faker import Faker

DB_SETTINGS = {
    "dbname": "shop",
    "user": "postgres",
    "password": "somePassword",
    "host": "localhost",
    "port": "5432"
}

customer_count = 30000
product_count = 30000
order_count = 90000


def generate_data():
    fake = Faker()
    print("Start of generation...")

    print("Client generation...")
    customer_statuses = ['active', 'premium', 'inactive']
    customers_data = []

    start_reg_date = datetime(2020, 1, 1)
    end_reg_date = datetime(2025, 12, 31)

    for _ in range(customer_count):
        profile = fake.profile()
        reg_date = fake.date_between(start_date=start_reg_date, end_date=end_reg_date)
        status = random.choices(customer_statuses, weights=[70, 20, 10], k=1)[0]

        customers_data.append((
            profile['name'],
            profile['mail'],
            reg_date,
            status
        ))

    print("Generating products...")
    categories = ['Electronics', 'Appliances', 'Gadgets', 'Computers', 'Smartphones', 'Audio']
    products_data = []

    for _ in range(product_count):
        title = f"{fake.word().capitalize()} {fake.word()} {random.randint(100, 999)}"
        category = random.choice(categories)
        price = round(random.uniform(10.0, 2500.0), 2)

        products_data.append((title, category, price))

    print("Generating orders...")
    order_statuses = ['Delivered', 'Processing', 'Cancelled']
    orders_data = []

    start_order_date = datetime(2022, 1, 1)
    end_order_date = datetime(2026, 6, 1)

    for _ in range(order_count):
        customer_id = random.randint(1, 10000)
        product_id = random.randint(1, 10000)
        order_date = fake.date_between(start_date=start_order_date, end_date=end_order_date)
        quantity = random.choices([1, 2, 3, 4, 5], weights=[60, 25, 10, 3, 2], k=1)[0]
        status = random.choices(order_statuses, weights=[75, 15, 10], k=1)[0]

        orders_data.append((customer_id, product_id, order_date, quantity, status))

    try:
        conn = psycopg2.connect(**DB_SETTINGS)
        cursor = conn.cursor()

        print("Clearing old data...")
        cursor.execute("TRUNCATE orders, customers, products RESTART IDENTITY CASCADE;")

        print("Client insertion...")
        execute_values(
            cursor,
            "INSERT INTO customers (name, email, registration_date, status) VALUES %s",
            customers_data
        )

        print("Products insertion...")
        execute_values(
            cursor,
            "INSERT INTO products (title, category, price) VALUES %s",
            products_data
        )

        print("Orders inserting into DB...")
        execute_values(
            cursor,
            "INSERT INTO orders (customer_id, product_id, order_date, quantity, status) VALUES %s",
            orders_data
        )

        conn.commit()
        print("All data generated!")

    except Exception as e:
        print(f"Error with DB: {e}")
        if conn:
            conn.rollback()
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()


if __name__ == "__main__":
    generate_data()

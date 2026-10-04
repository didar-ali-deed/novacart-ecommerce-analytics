import sqlite3
from pathlib import Path

import pandas as pd

# Location of this script:
# Ecommerce_Analytics_Project/sql/create_database.py
SCRIPT_DIR = Path(__file__).resolve().parent

# Project root:
# Ecommerce_Analytics_Project/
PROJECT_ROOT = SCRIPT_DIR.parent

CLEAN_DIR = PROJECT_ROOT / "data" / "cleaned"
DB_PATH = SCRIPT_DIR / "novacart.db"

print("Project root:", PROJECT_ROOT)
print("Clean data:", CLEAN_DIR)
print("Database:", DB_PATH)

files = {
    "customers": CLEAN_DIR / "customers_clean.csv",
    "products": CLEAN_DIR / "products_clean.csv",
    "orders": CLEAN_DIR / "orders_clean.csv",
    "order_items": CLEAN_DIR / "order_items_clean.csv",
    "returns": CLEAN_DIR / "returns_clean.csv",
    "marketing": CLEAN_DIR / "marketing_clean.csv",
}

# Check every input before opening the database so missing files fail clearly
# without replacing an existing database with a partial load.
missing_files = [path for path in files.values() if not path.is_file()]
if missing_files:
    missing_list = "\n".join(f"  - {path}" for path in missing_files)
    raise FileNotFoundError(
        "Required cleaned CSV file(s) are missing:\n"
        f"{missing_list}\n"
        "Run notebooks/02_data_cleaning.ipynb from the notebooks directory "
        "to create them."
    )

parse_dates = {
    "customers": ["Signup_Date"],
    "orders": ["Order_Date", "Ship_Date"],
    "returns": ["Return_Date"],
    "marketing": ["Month"],
}

DB_PATH.parent.mkdir(parents=True, exist_ok=True)

with sqlite3.connect(DB_PATH) as conn:
    for table_name, file_path in files.items():
        kwargs = {}
        if table_name in parse_dates:
            kwargs["parse_dates"] = parse_dates[table_name]

        df = pd.read_csv(file_path, **kwargs)

        # Store datetimes as ISO date strings for SQLite compatibility.
        for col in parse_dates.get(table_name, []):
            if col in df.columns:
                df[col] = pd.to_datetime(df[col], errors="coerce").dt.strftime(
                    "%Y-%m-%d"
                )

        df.to_sql(table_name, conn, if_exists="replace", index=False)

    # Helpful indexes
    conn.executescript("""
    CREATE INDEX IF NOT EXISTS idx_orders_order_id
        ON orders(Order_ID);

    CREATE INDEX IF NOT EXISTS idx_orders_customer_id
        ON orders(Customer_ID);

    CREATE INDEX IF NOT EXISTS idx_orders_order_date
        ON orders(Order_Date);

    CREATE INDEX IF NOT EXISTS idx_order_items_order_id
        ON order_items(Order_ID);

    CREATE INDEX IF NOT EXISTS idx_order_items_product_id
        ON order_items(Product_ID);

    CREATE INDEX IF NOT EXISTS idx_returns_order_item_id
        ON returns(Order_Item_ID);

    CREATE INDEX IF NOT EXISTS idx_products_category
        ON products(Category);
    """)

    print("SQLite database created successfully:")
    print(DB_PATH.resolve())

    print("\nTables:")
    tables = pd.read_sql_query(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;", conn
    )
    print(tables.to_string(index=False))

    print("\nRow counts:")
    for table_name in files:
        count = conn.execute(f"SELECT COUNT(*) FROM {table_name}").fetchone()[0]
        print(f"{table_name:12s} {count:,}")

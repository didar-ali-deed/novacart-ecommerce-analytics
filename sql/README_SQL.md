# NovaCart SQL Stage

Files:

- `create_database.py` — loads the cleaned CSV files into SQLite and creates indexes.
- `business_analysis.sql` — portfolio-quality business queries.
- `novacart.db` — generated after running the loader.

## Run

From the `Ecommerce_Analytics_Project/sql/` folder:

```powershell
python create_database.py
```

Or from the project root:

```powershell
python sql/create_database.py
```

Then open `novacart.db` in DB Browser for SQLite, DBeaver, or a VS Code SQLite extension and run queries from `business_analysis.sql`.

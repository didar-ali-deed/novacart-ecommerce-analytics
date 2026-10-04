# NovaCart SQL Stage

Files:

- `create_database.py` — loads the cleaned CSV files into SQLite and creates indexes.
- `business_analysis.sql` — portfolio-quality business queries.
- `novacart.db` — generated SQLite database included for convenient inspection; it can be recreated from the cleaned CSV files.

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

The database is a generated artifact kept in the repository so reviewers can inspect the SQL results immediately. Rebuild it from the project root with:

```powershell
python sql/create_database.py
```

This regenerates `sql/novacart.db` from the files in `data/cleaned/`.

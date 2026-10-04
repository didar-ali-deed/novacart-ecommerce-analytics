# NovaCart E-Commerce Analytics

An end-to-end portfolio case study that turns fixed, synthetic but intentionally business-realistic e-commerce data into validated datasets, SQL analysis, and a four-page Power BI dashboard. It demonstrates a practical **Python / Pandas → SQLite / SQL → Power BI / DAX** workflow for sales, profitability, customer, product, returns, marketing, and shipping analysis.

**Dashboard preview**

![Executive Overview](screenshots/01_executive_overview.png)

**Headline KPIs:** $16.44M revenue · $4.93M profit · 29.98% profit margin · 107K completed orders · 22K active customers · 7.07% return rate

**Workflow:** data quality review → Python cleaning and validation → exploratory analysis and CSV reports → SQLite business queries → interactive Power BI dashboard.

## Dashboard

The Power BI report contains four pages:

1. **Executive Overview** — revenue, profit, customers, orders, units, average order value, monthly trends, category, and channel.
2. **Product & Profitability** — product contribution, margins, discount bands, and returns.
3. **Customer Analysis** — customer value, repeat purchasing, segments, and new versus returning customers.
4. **Returns & Operations** — return reasons, refunds, category return rates, shipping time, and monthly returns.

![Product Analysis](screenshots/02_product_analysis.png)

![Customer Analysis](screenshots/03_customer_analysis.png)

![Returns & Operations](screenshots/04_returns_operations.png)

## Data and model

The six raw CSV files in `data/raw/` are the fixed source data supplied with this case study. They are synthetic, intentionally business-realistic inputs; the repository does not include a raw-data generator. The notebooks document the audit, cleaning, validation, and analysis that produce `data/cleaned/` and `reports/`. See [the data dictionary](docs/data_dictionary.md) for CSV columns and table meanings.

The Power BI relationships are:

```text
Customers (1) ── (*) Orders
Orders (1) ── (*) OrderItems
Products (1) ── (*) OrderItems
OrderItems (1) ── (1) Returns
Date (1) ── (*) Orders
```

`Marketing` is a disconnected campaign-month table in the model. Its spend and engagement measures describe campaign activity; channel-level sales-to-spend comparisons are directional and do not establish causal attribution.

**Power BI portability:** the PBIX contains the model and dashboard. Refreshing its data on another computer may require updating Power BI data source paths to that computer's local `data/cleaned/` directory.

## Key results

| KPI | Result |
|---|---:|
| Total revenue | **$16.44M** |
| Total profit | **$4.93M** |
| Profit margin | **29.98%** |
| Completed orders | **107K** |
| Active customers | **22K** |
| Units sold | **330K** |
| Average order value | **$153.29** |
| Revenue per customer | **$758.72** |
| Repeat customers / rate | **18K / 82.55%** |
| Returns / returned orders | **16K / 15K** |
| Return rate | **7.07%** |
| Refund amount | **$1.26M** |

Additional findings include Electronics leading category revenue, Beauty having the highest category profit margin, Fashion having the highest category return rate, and observed average delivery times of 0.5 days for Same Day, 2.0 for Express, and 4.0 for Standard. These are descriptive results from the supplied case-study data.

## Repository structure

```text
├── data/
│   ├── raw/                 # Fixed case-study CSV source data
│   └── cleaned/             # Notebook outputs used by analysis and Power BI
├── docs/
│   └── data_dictionary.md
├── notebooks/
│   ├── 01_data_quality.ipynb
│   ├── 02_data_cleaning.ipynb
│   └── 03_exploratory_analysis.ipynb
├── powerbi/
│   └── NovaCart_Ecommerce_Analytics.pbix
├── reports/                 # Exported analysis tables
├── screenshots/             # Dashboard page previews
├── sql/
│   ├── business_analysis.sql
│   ├── create_database.py
│   ├── novacart.db           # Generated SQLite database, included for inspection
│   └── README_SQL.md
├── .gitignore
├── LICENSE
├── README.md
└── requirements.txt
```

## Reproduce the workflow

```bash
git clone https://github.com/didar-ali-deed/novacart-ecommerce-analytics.git
cd novacart-ecommerce-analytics
python -m venv .venv
```

Activate the environment (`.venv\Scripts\Activate.ps1` in PowerShell or `source .venv/bin/activate` on macOS/Linux), then install the direct Python dependencies:

```bash
python -m pip install -r requirements.txt
```

Run the notebooks in order, launching Jupyter from `notebooks/` because their paths are relative to that working directory:

```bash
cd notebooks
jupyter lab
```

Run `01_data_quality.ipynb`, `02_data_cleaning.ipynb`, and `03_exploratory_analysis.ipynb` in order. Cleaning writes the cleaned CSVs; exploratory analysis writes the reports. The supplied cleaned data and reports are already present for inspection.

The SQLite database can be recreated from the project root after the cleaned CSVs are available:

```bash
python sql/create_database.py
```

This replaces `sql/novacart.db` with a database built from the cleaned CSVs. To inspect the 25 SQLite queries, open `sql/business_analysis.sql` with the database in DB Browser for SQLite, DBeaver, or another SQLite client. Open `powerbi/NovaCart_Ecommerce_Analytics.pbix` in Power BI Desktop to explore the report.

## Tools demonstrated

Python, Pandas, NumPy, Matplotlib, Jupyter, SQLite, SQL, Power Query, Power BI, and DAX.

## Author

**Didar Ali** · Computer Systems Engineering Graduate · Data Analytics · Power BI · SQL · Python

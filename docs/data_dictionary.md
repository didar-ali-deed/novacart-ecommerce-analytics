# Data Dictionary

This dictionary describes the six cleaned CSV tables supplied in `data/cleaned/`. The notebooks load the fixed source files from `data/raw/`, audit and clean them, and write these cleaned outputs. Column names below are taken from the cleaned CSV headers.

## `customers`

**Purpose:** One row per customer, including profile and signup information.

**Primary key:** `Customer_ID`; **foreign keys:** None. `Customer_ID` is referenced by `orders.Customer_ID`.

| Column | Business meaning |
|---|---|
| `Customer_ID` | Unique customer identifier. |
| `Customer_Name` | Customer display name. |
| `City`, `State` | Customer location. |
| `Customer_Segment` | Business segment assigned to the customer. |
| `Signup_Date` | Date the customer signed up. |
| `Email_Opt_In` | Whether the customer opted in to email. |

## `products`

**Purpose:** Product catalog and baseline pricing, cost, margin, and return assumptions.

**Primary key:** `Product_ID`; **foreign keys:** None. `Product_ID` is referenced by `order_items.Product_ID` and `returns.Product_ID`.

| Column | Business meaning |
|---|---|
| `Product_ID` | Unique product identifier. |
| `Product_Name` | Product display name. |
| `Category`, `Subcategory` | Product classification. |
| `Brand` | Product brand. |
| `List_Price` | Catalog list price. |
| `Unit_Cost` | Baseline cost per unit. |
| `Base_Margin` | Product's baseline margin field. |
| `Base_Return_Rate` | Product's baseline return-rate field. |

## `orders`

**Purpose:** Order-level customer, date, channel, payment, and fulfillment details.

**Primary key:** `Order_ID`; **foreign keys:** `Customer_ID` references `customers.Customer_ID`. `Order_ID` is referenced by `order_items.Order_ID`.

| Column | Business meaning |
|---|---|
| `Order_ID` | Unique order identifier. |
| `Customer_ID` | Customer who placed the order. |
| `Order_Date` | Date the order was placed. |
| `Channel` | Acquisition or sales channel recorded for the order. |
| `Payment_Method` | Recorded payment method. |
| `Shipping_Method` | Selected shipping service. |
| `Order_Status` | Order completion/status field. |
| `Ship_Date` | Shipment date; may be null when unavailable. |

## `order_items`

**Purpose:** Order-line detail with quantities and calculated sales, discount, cost, and profit values.

**Primary key:** `Order_Item_ID`; **foreign keys:** `Order_ID` references `orders.Order_ID`; `Product_ID` references `products.Product_ID`. `Order_Item_ID` is referenced by `returns.Order_Item_ID`.

| Column | Business meaning |
|---|---|
| `Order_Item_ID` | Unique order-line identifier. |
| `Order_ID` | Parent order. |
| `Product_ID` | Product sold on the line. |
| `Quantity` | Units sold on the line. |
| `Unit_Price` | Selling price per unit before line-level discount. |
| `Discount_Pct` | Discount rate applied to the line. |
| `Gross_Sales` | Pre-discount line sales. |
| `Discount_Amount` | Discount value for the line. |
| `Net_Sales` | Sales after discount. |
| `Cost_Amount` | Line cost amount. |
| `Profit` | Line profit amount. |

## `returns`

**Purpose:** Returned order-line records, including reason, refund, and return status.

**Primary key:** `Return_ID`; **foreign keys:** `Order_Item_ID` references `order_items.Order_Item_ID` (one-to-one in the Power BI model); `Order_ID` references `orders.Order_ID`; `Product_ID` references `products.Product_ID`.

| Column | Business meaning |
|---|---|
| `Return_ID` | Unique return-record identifier. |
| `Order_Item_ID` | Order line associated with the return. |
| `Order_ID` | Order associated with the return. |
| `Product_ID` | Returned product. |
| `Return_Date` | Date the return was recorded. |
| `Return_Reason` | Recorded reason for return. |
| `Refund_Amount` | Refund amount associated with the return. |
| `Return_Status` | Status of the return. |

## `marketing`

**Purpose:** Campaign activity and spend by campaign, month, and channel.

**Primary key:** `Campaign_ID` in the supplied cleaned data; **foreign keys:** None. `Channel` is a shared label used for directional comparisons with `orders.Channel`; it is not a relational key to individual orders.

| Column | Business meaning |
|---|---|
| `Campaign_ID` | Unique campaign-row identifier. |
| `Month` | Campaign reporting month. |
| `Channel` | Marketing channel. |
| `Campaign_Type` | Campaign classification. |
| `Spend` | Recorded campaign spend. |
| `Impressions` | Number of campaign impressions. |
| `Clicks` | Number of campaign clicks. |
| `Attributed_Orders` | Orders attributed by the supplied marketing data. |
| `CTR` | Click-through-rate field supplied in the data. |
| `Conversion_Rate` | Conversion-rate field supplied in the data. |

## Main relationships

The transaction tables relate as follows:

```text
customers (1) ── (*) orders (1) ── (*) order_items
products  (1) ── (*) order_items
order_items (1) ── (1) returns
Date (1) ── (*) orders
```

The Power BI `Date` dimension filters `orders` by `Order_Date`. `Marketing` is disconnected from this transaction model and is analyzed at its own campaign-month grain. Channel-level revenue-to-spend comparisons are directional summaries, not causal ROAS attribution.

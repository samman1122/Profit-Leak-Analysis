# Data Quality Findings — Profit Leak & Growth Analysis V2

## Audit basis
Independent re-check of the V2 dataset currently used for the project.

### Dataset scope
- Customers: 30,000
- Products: 1,000
- Stores: 30
- Campaigns: 60
- Orders: 75,000
- Order items: 105,000
- Returns: 14,479
- Shipments: 30,000
- Marketing daily rows: 7,965
- Date dimension rows: 1,520

## QA status
- PASS: 48
- REVIEW: 10
- FAIL: 3

## Confirmed clean areas
- Primary keys are unique and non-null for the main dimension/fact tables.
- All tested foreign-key relationships have **0 orphan records**.
- Customer signup → order timing is valid.
- Product launch → first sale timing is valid.
- Campaign start → marketing activity timing is valid.
- Shipment/order/promised/delivery date logic is valid.
- Return dates occur after orders.
- Quantity and line-item financial arithmetic reconcile.
- Returns are linked to completed orders.
- Return product IDs match their referenced order items.
- Refunds do not exceed realized selling value.
- Physical-store/store-ID/device logic is valid.
- Clicks do not exceed impressions.
- Marketing funnel metrics contain no negative values.

## Issues requiring cleaning or review

### 1. Marketing daily grain violation — HIGH PRIORITY
The declared grain is one row per `date + campaign_id`.

- Duplicate rows by that composite key: **2,321**
- Duplicate key groups: **1,806**
- Exact duplicate rows: **0**

This is more important than a simple formatting issue because it can inflate marketing spend, orders and attributed revenue.

**Action:** investigate the duplicate groups before aggregation/deduplication. Because the file has no additional ad-set/platform key, do not silently sum or delete these rows until the intended grain is explicitly defined.

### 2. Return quantity violations — HIGH PRIORITY
- Affected order items: **51**
- Return rows involved: **102**
- Excess returned units: **51**

Each affected item has cumulative returned quantity above the purchased quantity.

**Action:** flag the duplicate/over-return events in the cleaned layer. Keep the raw rows unchanged.

### 3. Acquisition-channel standardization — MEDIUM PRIORITY
- Variant rows: **113**
- Canonical labels should be:
  `Organic`, `Direct`, `Meta`, `Email`, `Affiliate`, `Google Ads`

Examples include `META`, `meta`, `DIRECT`, `direct`, `GOOGLE ADS`, `google ads`, and `Google_Ads`.

**Action:** standardize casing/formatting in the cleaned layer.

### 4. Date fields — MEDIUM PRIORITY
The 11 date fields load as object/string values.

**Action:** convert them to pandas datetime in the cleaned layer. Do not change the raw CSV files.

### 5. Missing values — REVIEW
Known missing values:
- Customer city: **240**
- Customer income band: **90**
- Order store ID: **56,358** — expected for digital channels
- Order payment method: **450**
- Order coupon code: **37,660** — can legitimately mean no coupon
- Marketing clicks: **7**

**Action:** do not blanket-fill or delete. Handle each field according to business meaning.

### 6. Coupon/discount mapping — REVIEW, NOT AN AUTOMATIC ERROR
`WELCOME10` appears with a 5% order discount in **14,236** orders.

The name alone is not enough evidence that the value is wrong, so this should be treated as a business-rule clarification rather than an automatic correction.

### 7. Marketing clicks data type — LOW PRIORITY
`clicks` is loaded as float because 7 rows are missing. The values themselves are integer-valued.

**Action:** after deciding how to handle missing clicks, use nullable integer (`Int64`) if appropriate.



### 8. Marketing outlier review — REVIEW, not automatic errors
The descriptive statistics show no negative marketing values and no clicks above impressions.

An IQR screening gives:
- Impressions: **0** IQR outliers
- Clicks: **301**
- Ad spend: **371**
- New customers: **705**
- Attributed orders: **704**
- Attributed revenue: **694**

These should **not** be deleted simply because they exceed the IQR threshold. Marketing data is naturally right-skewed, and large campaigns can legitimately produce much larger values. Investigate them later by campaign, date and performance efficiency rather than treating them as bad data.

The screenshot's descriptive statistics also match the current V2 marketing file: 7,965 rows, 7 missing clicks, and the same min/median/max values.

## Cleaning priorities
1. Resolve `raw_marketing_daily` date+campaign duplicate grain.
2. Resolve the 51 over-returned order items.
3. Standardize acquisition-channel labels.
4. Convert date fields to datetime in the cleaned layer.
5. Handle missing values by business meaning.
6. Resolve/ document the WELCOME10 discount mapping.
7. Convert marketing clicks to nullable integer after missing-value treatment.

## Raw-data rule
**Never overwrite the raw files.**

The project should maintain:
`RAW → CLEANED → ANALYTICAL`

The QA report validates the raw layer and records what must be addressed before analysis.

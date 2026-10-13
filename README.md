# Profit Leak Analysis

**Finding Where Retail Revenue Loses Value**

An end-to-end retail analytics project built with **SQL Server, Python, and Power BI** to investigate declining revenue, changing profitability, return-related costs, customer value, fulfillment performance, and marketing efficiency.

## Project Overview

Revenue alone doesn't tell the whole story of a business.

A company can generate millions in sales and still face problems with returns, discounting, shipping costs, and customer profitability. This project looks beyond sales figures to understand what is happening to the money a retail business generates.

Using a synthetic omnichannel retail dataset, I built an end-to-end analysis pipeline, from data validation and SQL analysis to Python-based investigation and an interactive Power BI dashboard.

The goal was simple: **identify the factors affecting profitability and turn the findings into practical business actions.**

> **Data note:** This project uses synthetic retail data. The findings demonstrate an analytical approach and should not be interpreted as the actual performance of a real company.

## Business Questions

- Is the business becoming more or less profitable?
- Which costs are putting pressure on contribution profit?
- Which product categories and return reasons deserve attention?
- How do discounts relate to product margins?
- Which customer segments generate the strongest contribution?
- How reliable is fulfillment across warehouses?
- How do marketing channels compare on spend and attributed revenue?

## Tools & Technologies

- **SQL Server:** Data validation, analytical queries, and reusable analytical views.
- **Python:** Data cleaning, validation, exploratory analysis, deeper profitability analysis, and summary tables.
- **Power BI:** Interactive dashboards, KPI tracking, comparisons, and business insights.
- **Pandas & NumPy:** Data manipulation and calculations.
- **Matplotlib & Seaborn:** Data visualization during analysis.
- **Git & GitHub:** Project documentation and portfolio presentation.

## Key Findings

### 1. Revenue and contribution profit declined

- Total revenue: **$8.00 million**
- Total contribution profit: **$3.00 million**
- Overall contribution margin: **37.53%**
- Revenue declined by **1.77%** in 2025.
- Contribution profit declined by **2.54%**, from approximately $1.52 million to $1.48 million.

The decline was mainly associated with lower sales volume, while higher return-related costs added further pressure.

### 2. Return-related costs increased

Return-related costs reached approximately **$782,319** across refunds, return shipping, and restocking.

These costs increased by approximately $7,517 in 2025 despite lower revenue. Apparel stood out as a category worth investigating, with approximately $1.68 million in revenue and an 11.27% return rate.

### 3. Discounts deserve closer attention

Higher discount levels were associated with lower product margins in the analysis. This makes discounting an important area to review rather than treating higher sales volume as an automatic win.

### 4. Customer value varies significantly

Repeat customers generated higher contribution per customer than one-time customers. Small Business customers also showed stronger contribution per customer than Consumer customers.

These findings support a closer look at customer retention and segment-specific strategies.

### 5. Fulfillment and marketing need separate evaluation

Approximately **39.13% of shipments were late**, highlighting an opportunity to investigate warehouse and delivery performance.

Marketing channels also differed in attributed return on ad spend (ROAS). However, attributed revenue does not establish incremental revenue or prove that a campaign caused the sales.


## Project Workflow

1. Reviewed the raw datasets and documented data quality issues.
2. Validated key fields, relationships, and financial calculations.
3. Prepared and standardized data while preserving raw values.
4. Built SQL Server analytical views for profitability, customer economics, returns, fulfillment, and marketing.
5. Used Python to investigate the results, test business assumptions, and prepare analytical summary tables.
6. Built the Power BI dashboard to present the findings clearly.
7. Documented the conclusions, limitations, and recommended business actions in PDF reports.

## Business Recommendations

Based on the analysis, the main priorities are:

- **Recover profitable sales volume:** Investigate the decline in orders and units rather than focusing on revenue alone.
- **Review avoidable returns:** Examine return reasons, product descriptions, sizing information, and high-return products.
- **Control discounting:** Evaluate whether additional sales justify the associated reduction in product margin.
- **Retain valuable customers:** Develop retention strategies for repeat buyers and high-contribution customer segments.
- **Investigate late deliveries:** Compare warehouse performance and identify potential operational improvements.
- **Evaluate marketing carefully:** Compare channel costs and attributed results without assuming that attribution proves incremental impact.

## Important Limitations

- The dataset is synthetic and does not represent a real company's financial results.
- Contribution profit is not net profit; general overhead, taxes, interest, and other unmodeled expenses are excluded.
- Marketing ROAS is attribution-based and should not be interpreted as causal or incremental return.
- Relationships observed in the data do not automatically establish cause and effect.

## Project Outcome

This project brought together SQL, Python, and Power BI to answer a business question that sales figures alone cannot answer: **where is profitability under pressure, and what should the business investigate next?**

It demonstrates my approach to data validation, financial analysis, dashboard development, and translating analytical findings into business recommendations.

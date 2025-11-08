/*===========================================================================================================================
 Project Name   : SupaStore Database (Exploratory analysis)
 Script Name    : Exploratory analysis script 
 Description:
   This script performs exploratory analysis on the 'supastore_db' dataset to uncover business performance patterns, 
   regional and product trends, and customer behavior insights. It transforms transactional data into metrics that inform 
   revenue growth, profitability, and operational efficiency.

 Scope:
   1. Trend analysis – Revenue growth, profit margin, and order trends (yoy, mom).
   2. Regional analysis – Sales, profit, and contribution by region.
   3. Category analysis – Performance across categories and subcategories.
   4. Customer analysis – Revenue, loyalty, and behavior across segments.
   5. Discount analysis – Impact of discounts on profit margin.
   6. Shipping analysis – Efficiency and profitability by shipping mode.

Author         : Oladigbolu Taofeek
  Version        : 1.0
  Last Updated   : 2025-10-29
  Target DBMS    : MySQL 8.0+
  Execution Mode : Post-ETL Validation / Silver Layer
  Usage:
   - Run after completing data quality checks on the silver layer.
   - Optimized for mysql 8.0+ using ctes and window functions.
   - Use results for dashboards, kpi reporting, and profitability diagnostics.
   
Revision History:
      Version | Date        | Author   | Description
      --------|-------------|----------|-----------------------------------------------
      1.0     | 2025-10-28  | Taofeek  | Initial version created
      1.1     | 2025-10-29  | Taofeek  | Standardized formatting & improved logic
===========================================================================================================================*/

/*----------------------------------------------------------------------------------------------------------------
TREND ANALYSIS
-----------------------------------------------------------------------------------------------------------------*/
-- YoY REVENUE GROWTH RATE 
with yearly as (
  select
    year(order_date) as financial_year,
    sum(sales) as revenue
  from supastore_db
  group by year(order_date)
)
select
  financial_year,
  revenue,
  lag(revenue) over (order by financial_year) as prev_year_revenue,
  round(
    case
      when lag(revenue) over (order by financial_year) is null then null
      else (revenue - lag(revenue) over (order by financial_year)) * 100.0 / nullif(lag(revenue) over (order by financial_year), 0)
    end, 2
  ) as revenue_growth_pct
from yearly
order by financial_year;

-- YEARLY NET PROFIT MARGIN 
with yearly as (
  select
    year(order_date) as financial_year,
    sum(profit) as net_profit,
    sum(sales) as revenue
  from supastore_db
  group by year(order_date)
)
select
  financial_year,
  net_profit,
  revenue,
  round(net_profit * 100.0 / nullif(revenue, 0), 2) as net_profit_margin_pct
from yearly
order by financial_year;

-- ORDER GROWTH RATE
with cte as (
  select
    year(order_date) as financial_year,
    count(order_id) as total_orders
  from supastore_db
  group by year(order_date)
)
select
  financial_year,
  total_orders,
  round(
    case when lag(total_orders) over (order by financial_year) is null then null
    else (total_orders - lag(total_orders) over (order by financial_year)) * 100.0 / nullif(lag(total_orders) over (order by financial_year), 0)
    end, 2
  ) as order_growth_pct
from cte
order by financial_year;

/*----------------------------------------------------------------------------------------------------------------
 REGIONAL ANALYSIS 
-----------------------------------------------------------------------------------------------------------------*/

-- ANNUAL REVENUE AND GROWTH BY REGION 
with annual_sales as (
  select
    year(order_date) as financial_year,
    region,
    sum(sales) as revenue
  from supastore_db
  group by year(order_date), region
)
select
  region,
  sum(case when financial_year = 2021 then revenue else 0 end) as sales_2021,
  sum(case when financial_year = 2022 then revenue else 0 end) as sales_2022,
  sum(case when financial_year = 2023 then revenue else 0 end) as sales_2023,
  sum(case when financial_year = 2024 then revenue else 0 end) as sales_2024
from annual_sales
group by region
order by sales_2024 desc;

-- PROFIT CONTRIBUTION BY REGION 
select
  financial_year,
  region,
  profit,
  sum(profit) over (partition by financial_year) as annual_profit,
  round(profit * 100.0 / nullif(sum(profit) over (partition by financial_year), 0), 2) as profit_contribution_pct
from (
  select
    year(order_date) as financial_year,
    region,
    sum(profit) as profit
  from supastore_db
  group by year(order_date), region
) t
order by financial_year, profit desc;

/*----------------------------------------------------------------------------------------------------------------
CATEGORY AND SUBCATEGORY ANALYSIS 
-----------------------------------------------------------------------------------------------------------------*/
-- REVENUE SHARE BY CATEGORY 
with cte as (
  select
    category,
    sum(sales) as category_revenue
  from supastore_db
  group by category
)
select
  category,
  category_revenue,
  round(category_revenue * 100.0 / sum(category_revenue) over (), 2) as revenue_share_pct
from cte
order by revenue_share_pct desc;

-- PROFIT MARGIN BY CATEGORY 
with cte as (
  select
    category,
    sum(profit) as profit,
    sum(sales) as revenue
  from supastore_db
  group by category
)
select
  category,
  profit,
  revenue,
  round(profit * 100.0 / nullif(revenue, 0), 2) as profit_margin_pct
from cte
order by profit_margin_pct desc;

-- YoY PROFIT GROWTH BY SUBCATEGORY
with cte as (
  select
    year(order_date) as financial_year,
    sub_category,
    sum(profit) as profit
  from supastore_db
  group by year(order_date), sub_category
)
select
  sub_category,
  sum(case when financial_year = 2021 then profit end) as profit_2021,
  sum(case when financial_year = 2022 then profit end) as profit_2022,
  sum(case when financial_year = 2023 then profit end) as profit_2023,
  sum(case when financial_year = 2024 then profit end) as profit_2024,
  round(((sum(case when financial_year = 2022 then profit end) - sum(case when financial_year = 2021 then profit end)) * 100.0) /
        nullif(sum(case when financial_year = 2021 then profit end), 0), 2) as growth_2022,
  round(((sum(case when financial_year = 2023 then profit end) - sum(case when financial_year = 2022 then profit end)) * 100.0) /
        nullif(sum(case when financial_year = 2022 then profit end), 0), 2) as growth_2023,
  round(((sum(case when financial_year = 2024 then profit end) - sum(case when financial_year = 2023 then profit end)) * 100.0) /
        nullif(sum(case when financial_year = 2023 then profit end), 0), 2) as growth_2024
from cte
group by sub_category
order by growth_2024 desc;

/*----------------------------------------------------------------------------------------------------------------
 CUSTOMER ANALYSIS 
-----------------------------------------------------------------------------------------------------------------*/
-- REVENUE PER SEGMENT
with cte as (
  select
    segment,
    sum(sales) as revenue
  from supastore_db
  group by segment
)
select
  segment,
  revenue,
  round(revenue * 100.0 / sum(revenue) over (), 2) as revenue_share_pct
from cte
order by revenue_share_pct desc;

-- PROFIT PER SEGMENT 
with cte as (
  select
    segment,
    sum(profit) as profit
  from supastore_db
  group by segment
)
select
  segment,
  profit,
  round(profit * 100.0 / sum(profit) over (), 2) as profit_share_pct
from cte
order by profit_share_pct desc;

-- REPEAT CUSTOMER RATE 
select
  financial_year,
  round(count(distinct case when purchase_count > 1 then customer_id end) * 100.0 / count(distinct customer_id), 2) as repeat_customer_pct
from (
  select
    year(order_date) as financial_year,
    customer_id,
    count(order_id) over (partition by customer_id) as purchase_count
  from supastore_db
) t
group by financial_year
order by financial_year;

/*----------------------------------------------------------------------------------------------------------------
 DISCOUNT ANALYSIS 
-----------------------------------------------------------------------------------------------------------------*/
-- DISCOUNT IMPACT ON PROFIT MARGIN 
select
  case
    when discount = 0 then '0%'
    when discount <= 0.10 then '1–10%'
    when discount <= 0.20 then '11–20%'
    when discount <= 0.30 then '21–30%'
    else '>30%'
  end as discount_band,
  count(*) as order_count,
  sum(sales) as revenue,
  sum(profit) as profit,
  round(sum(profit) * 100.0 / nullif(sum(sales), 0), 2) as profit_margin_pct
from supastore_db
group by discount_band
order by discount_band;

/*----------------------------------------------------------------------------------------------------------------
 SHIPPING ANALYSIS 
-----------------------------------------------------------------------------------------------------------------*/
-- SHIPPING MODE EFFICIENCY
select
  ship_mode,
  count(distinct order_id) as order_count,
  sum(sales) as revenue,
  sum(profit) as profit,
  round(sum(profit) * 100.0 / nullif(sum(sales), 0), 2) as profit_margin_pct,
  round(avg(profit), 2) as avg_profit_per_order
from supastore_db
group by ship_mode
order by profit_margin_pct desc;

-- ORDER SHARE BY SHIPPING MODE BY YEAR
select
  year(order_date) as financial_year,
  ship_mode,
  count(*) as order_count,
  round(count(*) * 100.0 / nullif(sum(count(*)) over (partition by year(order_date)), 0), 2) as pct_of_year
from supastore_db
group by year(order_date), ship_mode
order by financial_year, pct_of_year desc;

-- SHIPPING MODE COST 
with cte as (
	select year(order_date) as financial_year,
	  category,
	  sum(sales) revenue
    from supastore_db
    group by financial_year, category)
		select 
			financial_year,
            category,
            revenue,
            case when category = "Furniture" then 0.06*revenue -- shipping cost for Furniture is 6% of sales 
                 when category = "Technology" then 0.03*revenue -- shipping cost for Technology is 3% of sales
                 when category = "Office Supplies" then 0.02*revenue -- shipping cost for Office Supplies is 2% of sales
		    else 0
            end shipping_cost
		from cte;

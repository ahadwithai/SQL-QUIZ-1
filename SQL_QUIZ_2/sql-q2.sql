---============= ASSIGMNENTS ==========================
--Assignment Tasks
--Task 1 — Build the Sales Detail Dataset (6 marks)

--Task 1 — Build the Sales Detail Dataset (6 marks)
--Management needs a detailed sales dataset for analysis. Return one row per order item containing:
--order_id and order_date
--customer full name
--store name
--staff full name
--product name
--category name
--brand name
--quantity, list_price, discount
--calculated net_line_revenue


 --Include only completed orders (order_status = 4). Sort the result from newest order to oldest.---


SELECT
    o.order_id,
    o.order_date,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_full_name,
    s.store_name,
    CONCAT(st.first_name, ' ', st.last_name) AS staff_full_name,
    p.product_name,
    cat.category_name,
    b.brand_name,
    oi.quantity,
    oi.list_price,
    oi.discount,
    oi.quantity * oi.list_price * (1 - oi.discount) AS net_line_revenue
from sales.orders as o
INNER JOIN sales.order_items as oi
    on o.order_id = oi.order_id
INNER JOIN sales.customers as c
    on o.customer_id = c.customer_id
INNER JOIN sales.stores as s
    on o.store_id = s.store_id
INNER JOIN sales.staffs as st
    on o.staff_id = st.staff_id
INNER JOIN production.products as p
    on oi.product_id = p.product_id
INNER JOIN production.categories as cat
    on p.category_id = cat.category_id
INNER JOIN production.brands as b
    on p.brand_id = b.brand_id
where o.order_status = 4
order BY o.order_date DESC;


--Task 2 — Store Performance Summary (5 marks)
--Create a store-level performance report for completed orders showing:
--store name
--number of distinct orders
--total units sold
--total net revenue
--average order value

--Return one row per store and order the stores from highest to lowest total net revenue.
---------------------------------------------------------------------------------------------

  SELECT
    s.store_name,
    count(distinct o.order_id) AS number_of_orders,
    sum(oi.quantity) AS total_units_sold,
    sum(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_net_revenue,
    sum(oi.quantity * oi.list_price * (1 - oi.discount))
        / count(distinct o.order_id) AS average_order_value
from sales.orders as o
INNER JOIN sales.order_items as oi
    on o.order_id = oi.order_id
INNER JOIN sales.stores as s
    on o.store_id = s.store_id
where o.order_status = 4
group by s.store_name
order by total_net_revenue desc;




--Task 3 — High-Value Customers (5 marks)
--Management wants to identify high-value customers. Return customers whose total completed-order 
--spending is greater than the average total spending of customers who have completed orders.

--Show customer_id, customer name, completed order count, and total spending. Order the result by total spending descending.
---------------------------------------------------------------------------------------------------------------------------------
    
    with customer_spending as (
    SELECT
        c.customer_id,
        concat(c.first_name, ' ', c.last_name) AS customer_name,
        count(DISTINCT o.order_id) AS completed_order_count,
        sum(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_spending
    from sales.customers as c
    INNER JOIN sales.orders as o
        on c.customer_id = o.customer_id
    INNER JOIN sales.order_items as oi
        on o.order_id = oi.order_id
    where o.order_status = 4
    group by
        c.customer_id,
        c.first_name,
        c.last_name
    )
   SELECT
       customer_id,
        customer_name,
        completed_order_count,
       total_spending
from customer_spending
where total_spending > (
    select AVG(total_spending)
    from customer_spending
)
order by total_spending desc;


--Task 4 — Inventory Risk Report (5 marks)
--Operations wants to identify inventory risk.
--Return products where the stock quantity is below 5 in at least one store.

--Show product name, store name, current quantity, category name, and brand name.
--Products with zero stock should appear first, followed by the lowest remaining quantities.


   SELECT
       p.product_name,
       s.store_name,
       st.quantity AS current_quantity,
       c.category_name,
       b.brand_name
from production.products as p
INNER JOIN production.stocks as st
    on p.product_id = st.product_id
INNER JOIN sales.stores as s
    on st.store_id = s.store_id
INNER JOIN production.categories as c
    on p.category_id = c.category_id
INNER JOIN production.brands as b
    on p.brand_id = b.brand_id
where st.quantity < 5
order by
    st.quantity asc,
    p.product_name;



--Task 5 — Top Products Within Each Category (6 marks)
--For each product category, identify the top 3 products by total net revenue from completed orders.

--Return category name, product name, total units sold, total net revenue,
--and the product's position within its category.
--Tied products must receive the same position and the next position should not contain gaps.

  with product_sales as (
    SELECT
        c.category_name,
         p.product_id,
        p.product_name,
        sum(oi.quantity) as total_units_sold,
        sum(oi.quantity * oi.list_price * (1 - oi.discount)) as total_net_revenue
    FROM sales.orders as o
    INNER JOIN sales.order_items as oi
        on o.order_id = oi.order_id
    INNER JOIN production.products as p
        on oi.product_id = p.product_id
    INNER JOIN production.categories as c
        on p.category_id = c.category_id
    where o.order_status = 4
    group by
           c.category_name,
           p.product_id,
           p.product_name
    ),
    ranked_products as (
    SELECT
        category_name,
        product_name,
        total_units_sold,
        total_net_revenue,
        dense_rank() over (
            partition by category_name
            order by total_net_revenue desc
        ) as product_position
    from product_sales
    )
   SELECT
    category_name,
    product_name,
    total_units_sold,
    total_net_revenue,
    product_position
from ranked_products
where product_position <= 3
order by  category_name,
  product_position,
    total_net_revenue desc;



--Task 6 — Monthly Sales Trend (6 marks)
--Create a monthly sales trend for completed orders.

--For each calendar month return:
--year
--month
--total net revenue
--previous month's total net revenue
--revenue change from the previous month

--The first month may have NULL for the previous-month comparison. Sort chronologically.

       
       with monthly_sales as (
    SELECT
        year(o.order_date) as year,
        month(o.order_date) as month,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_net_revenue
    from sales.orders as o
    INNER JOIN sales.order_items as oi
        on o.order_id = oi.order_id
    where o.order_status = 4
    group by
        year(o.order_date),
        month(o.order_date)
    ),
   monthly_comparison as (
     SELECT
        year,
        month,
        total_net_revenue,
        lag(total_net_revenue) over (
            ORDER BY year, month
        ) as previous_month_revenue
    from monthly_sales
   )
   SELECT
      year,
      month,
     total_net_revenue,
     previous_month_revenue,
     total_net_revenue - previous_month_revenue as revenue_change
  from monthly_comparison
 order by
     year,
     month;



--Task 7 — Reusable Reporting View (4 marks)
--Create a view named sales.vw_customer_sales_summary that returns one row per customer and includes:
--customer_id
--customer full name
--total number of completed orders
--total units purchased
--total net revenue
--most recent completed order date

--Customers with no completed orders must still be represented where possible,
--with appropriate zero/NULL values.


    create view sales.vw_customer_sales_summary
as
SELECT
    c.customer_id,
    concat(c.first_name, ' ', c.last_name) AS customer_full_name,
    concat(distinct case
        when o.order_status = 4 then o.order_id
    end) AS total_completed_orders,
    coalesce(sum(case
        when o.order_status = 4 then oi.quantity
        else 0
    end), 0) AS total_units_purchased,
    coalesce(sum(case
        when o.order_status = 4
        then oi.quantity * oi.list_price * (1 - oi.discount)
        else 0
    end), 0) as total_net_revenue,
    max(case
        when o.order_status = 4 then o.order_date
    end) as most_recent_completed_order_date
from sales.customers as c
LEFT JOIN sales.orders as o
    on c.customer_id = o.customer_id
LEFT JOIN sales.order_items as oi
    on o.order_id = oi.order_id
   group by
    c.customer_id,
    c.first_name,
    c.last_name;
  go

SELECT *
from sales.vw_customer_sales_summary;


  --Task 8 — Safe Data Modification (4 marks)
--A customer with customer_id = 1 has requested that their phone number be changed to '(999) 555-0101'.

--Write SQL that performs this update inside an explicit transaction. 
--Include a validation query after the UPDATE and show how the change can be rolled back during testing so the assessment database is not permanently changed.
  
    begin transaction;

update sales.customers
set phone = '(999) 555-0101'
where customer_id = 1;

-- Validation
   SELECT
      customer_id,
      first_name,
      last_name,
      phone
from sales.customers
where customer_id = 1;

-- Testing: undo the change
ROLLBACK TRANSACTION;


--Task 9 — Store Sales Procedure (6 marks)
--Create a stored procedure named sales.usp_store_sales_report with these input parameters:
--@store_id
--@start_date
--@end_date

--The procedure should return completed-order sales for the requested store and date range, grouped by product. Return product name, total units sold, and total net revenue, ordered by revenue descending.

--Add appropriate error handling for invalid date ranges where @start_date is later than @end_date.



          CREATE PROCEDURE sales.usp_store_sales_report
    @store_id INT,
    @start_date DATE,
    @end_date DATE
AS
BEGIN
    set nocount on;

    if @start_date > @end_date
    BEGIN
        throw 50001, 'Start date cannot be later than end date.', 1;
    end;

    SELECT
        p.product_name,
        SUM(oi.quantity) AS total_units_sold,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_net_revenue
    FROM sales.orders AS o
    INNER JOIN sales.order_items AS oi
        ON o.order_id = oi.order_id
    INNER JOIN production.products AS p
        ON oi.product_id = p.product_id
    WHERE o.store_id = @store_id
      AND o.order_status = 4
      AND o.order_date >= @start_date
      AND o.order_date <= @end_date
    group by
        p.product_id,
        p.product_name
    order by
        total_net_revenue desc;
  END;
  GO

  -- Example execution
  EXEC sales.usp_store_sales_report
    @store_id = 1,
    @start_date = '2016-01-01',
    @end_date = '2018-12-31';





   -- Task 10 — Management Insight Query (3 marks)
--Write one additional SQL query that you believe would provide useful insight to BikeStores management using at least three tables.

--Below the query, add a SQL comment of no more than three lines explaining:
--1. the business question,
--2. what the result measures, and
--3. why management should care about it.



    SELECT
    s.store_name,
    c.category_name,
    sum(oi.quantity) as total_units_sold,
    sum(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_net_revenue
from sales.orders as o
INNER JOIN sales.order_items as oi
    on o.order_id = oi.order_id
INNER JOIN sales.stores as s
    on o.store_id = s.store_id
INNER JOIN production.products as p
    as oi.product_id = p.product_id
INNER JOIN production.categories as c
    as p.category_id = c.category_id
where o.order_status = 4
group by
    s.store_name,
    c.category_name
order by
    total_net_revenue desc;

-- Business question: Which product categories generate the most revenue at each store?
-- Measures: Total units sold and total net revenue by store and category.
-- Management should care because it helps identify strong categories and sales opportunities.



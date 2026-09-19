--1.(Easy)  List every order with the customer's full name, store name,
--and the full name of the staff member who handled it.

 SELECT
    o.order_id,
    c.first_name + ' ' + c.last_name AS customer_name,
    s.store_name,
    st.first_name + ' ' + st.last_name AS staff_name
from sales.orders As o
INNER JOIN sales.customers as c
    on o.customer_id = c.customer_id
INNER JOIN sales.stores As s
    on o.store_id = s.store_id
INNER JOIN sales.staffs as st
    on o.staff_id = st.staff_id;


--.  (Easy)  Show each product with its brand name and category name.
--Include products even if they have no brand or category assigned

  SELECT
    p.product_name,
    b.brand_name,
    c.category_name
FROM production.products AS p
LEFT JOIN production.brands AS b
    ON p.brand_id = b.brand_id
LEFT JOIN production.categories AS c
    ON p.category_id = c.category_id;

--3.  (Medium)  Find all customers who have never placed an order. Return their name, city, and email.


     SELECT 
    c.first_name + ' ' + c.last_name AS customer_name,
    c.city,
    c.email
from sales.customers as c
LEFT JOIN sales.orders as o
    on c.customer_id = o.customer_id
where o.customer_id IS null;


--GROUP BY
--4.(Easy)  Calculate total revenue per store. Revenue = quantity * list_price * (1 - discount).
--Sort from highest to lowest.

    select
    s.store_name
    sum(oi.quantity * oi .list_price * (1 - oi.discount)) as total revenue
from sales.orders as o
INNER JOIN  sales.stores as s
   on o.store_id = s.store_id
   INNER JOIN sales.order_item as oi
   on o.order_id = oi.order_id
   group by
     s.store_name
     order by 
     total revenue desc;

--5 (Medium)  For each brand, show the number of products, the average list price,
--and the highest list price. Only include brands with more than 5 products.

  select
    b.brand_name,
    count(p.product_id) as product_count,
    avg(p.list_price) as average_list_price,
    max(p.list_price) as highest_list_price
from production.brands as b
INNER JOIN production.products as p
    on b.brand_id = p.brand_id
group by    b.brand_name
having count(p.product_id) > 5;


--6.(Medium)  Show the number of orders and total revenue per month for the year 2017, ordered chronologically.


   SELECT 
       month(o.order_date) as order_month,
       count(distinct o.order_id) as order_count,
       sum(oi.quantity * oi.list_price * (1 - oi.discount)) as total_revenue
      from sales.orders as o
      INNER JOIN sales.order_items as oi
      on o.order_id = oi.order_id
      where year(o.order_date) = 2017
      group by month(o.order_date)
      order by order_month asc;

 ---Subqueries
--7.(Medium)  Find all products priced above the average list price of their own category.
--Hint: Use a correlated subquery.
       
       select 
            p.product_name,
            p.list_price,
            p.category_id
        from production.products as p
        where p.list_price > (
              select avg(p2.list_price)
              from production.products as p2
              where p2.category_id = p.category_id
  );

 
 --8.(Medium)  List the customers who have placed more orders than the average number of orders per customer.
  


  SELECT 
    c.customer_id,
    c.first_name + ' ' + c.last_name AS customer_name,
    COUNT(o.order_id) AS order_count
FROM sales.customers AS c
INNER JOIN sales.orders AS o
    ON c.customer_id = o.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
HAVING COUNT(o.order_id) > (
    SELECT AVG(order_count)
    FROM (
        SELECT
            customer_id,
            COUNT(order_id) AS order_count
        FROM sales.orders
        GROUP BY customer_id
    ) AS customer_orders
)
ORDER BY order_count DESC;



--CTEs
--9.  (Hard)  Using a CTE, calculate each customer's total spend, then return the top 10 customers 
--with their spend and rank. Add a second CTE that labels each customer as "High" (above the overall average spend) or "Regular".
   

    WITH customer_spend AS (
    SELECT
        c.customer_id,
        c.first_name + ' ' + c.last_name AS customer_name,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_spend
    FROM sales.customers AS c
    INNER JOIN sales.orders AS o
        ON c.customer_id = o.customer_id
    INNER JOIN sales.order_items AS oi
        ON o.order_id = oi.order_id
    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name
),

customer_labels AS (
    SELECT
        customer_id,
        customer_name,
        total_spend,
        CASE
            WHEN total_spend > (SELECT AVG(total_spend) FROM customer_spend)
                THEN 'High'
            ELSE 'Regular'
        END AS customer_label
    FROM customer_spend
)

SELECT TOP 10
    customer_id,
    customer_name,
    total_spend,
    customer_label,
    RANK() OVER (ORDER BY total_spend DESC) AS spend_rank
FROM customer_labels
ORDER BY total_spend DESC;

 --9.  (Hard)  Using a CTE, calculate each customer's total spend, then return the top 10 customers with their spend and rank.
 --Add a second CTE that labels each customer as "High" (above the overall average spend) or "Regular".


        WITH customer_spend AS (
    SELECT
        c.customer_id,
        c.first_name + ' ' + c.last_name AS customer_name,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_spend
    FROM sales.customers AS c
    INNER JOIN sales.orders AS o
        ON c.customer_id = o.customer_id
    INNER JOIN sales.order_items AS oi
        ON o.order_id = oi.order_id
    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name
),

customer_labels AS (
    SELECT
        customer_id,
        customer_name,
        total_spend,
        CASE
            WHEN total_spend > (
                SELECT AVG(total_spend)
                FROM customer_spend
            )
            THEN 'High'
            ELSE 'Regular'
        END AS spend_label
    FROM customer_spend
)

SELECT TOP 10
    customer_id,
    customer_name,
    total_spend,
    RANK() OVER (ORDER BY total_spend DESC) AS spend_rank,
    spend_label
FROM customer_labels
ORDER BY total_spend DESC;


--10.  (Hard)  Using CTEs, find the best-selling product (by quantity) in each category, and show how much of that product's stock is currently available across all stores.
--Hint: Use ROW_NUMBER() or RANK() partitioned by category, then join to production.stocks.


WITH product_sales AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category_id,
        c.category_name,
        SUM(oi.quantity) AS total_quantity
    FROM production.products AS p
    INNER JOIN production.categories AS c
        ON p.category_id = c.category_id
    INNER JOIN sales.order_items AS oi
        ON p.product_id = oi.product_id
    GROUP BY
        p.product_id,
        p.product_name,
        p.category_id,
        c.category_name
),

best_products AS (
    SELECT
        product_id,
        product_name,
        category_id,
        category_name,
        total_quantity,
        ROW_NUMBER() OVER (
            PARTITION BY category_id
            ORDER BY total_quantity DESC
        ) AS rn
    FROM product_sales
),

product_stock AS (
    SELECT
        product_id,
        SUM(quantity) AS total_stock
    FROM production.stocks
    GROUP BY product_id
)

SELECT
    bp.category_name,
    bp.product_name,
    bp.total_quantity,
    ps.total_stock
FROM best_products AS bp
LEFT JOIN product_stock AS ps
    ON bp.product_id = ps.product_id
WHERE bp.rn = 1
ORDER BY bp.category_name;


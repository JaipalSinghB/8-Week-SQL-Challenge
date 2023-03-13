CREATE DATABASE Dannys_Dinner;
use Dannys_Dinner;
CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  Customer_id VARCHAR(1),
  Order_date DATE,
  Product_id INT
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  Product_id INT,
  Product_name VARCHAR(5),
  Price INT
);

INSERT INTO menu
  (Product_id, Product_name, Price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  Customer_id VARCHAR(1),
  Join_date DATE
);

INSERT INTO members
  (Customer_id, Join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  SELECT * FROM dannys_dinner.sales;
  SELECT * FROM dannys_dinner.members;
  SELECT * FROM dannys_dinner.menu;
  
  create table master_table as 
  select s.customer_id,s.order_Date,s.product_id,m.join_date,me.price,me.product_name
  from sales s 
  left outer join members m using(customer_id)
  left outer join menu me using(product_id);
  
  select* from master_table;
  
  -- 1) What is the total amount each customer spent at the restaurant?
  
  select customer_id,sum(price) Amount_spent from master_table
  group by 1
  order by 2 desc;
  --  Insights --->> Customer A spent more amount which is 76$ followed by Customer B 74$ and Customer C 36$ respectively;
  
  
  -- 2) How many days has each customer visited the restaurant?
  select customer_id,count(day(order_date))as days from master_table
  group by 1;
  
  -- Insights --->> It seems that customer A & B enjoying visiting Restaurant with total count of 6 days each while Customer C visited 3 times.
  
  -- 3)  What was the first item from the menu purchased by each customer?
  
  select a.customer_id,a.order_date, a.product_name from (select *,
  row_number()over(partition by customer_id order by order_date asc)as first_item
  from master_table)a
  where first_item =1 ;
   
  -- Insights --->> From the results it's clear that each Customer ordered different items first day of their visit.
  
  -- 4)  What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT  COUNT(product_id) AS most_purchased, product_name
FROM master_table
GROUP BY product_id, product_name
ORDER BY most_purchased DESC
limit 1;

-- Insights --->> It seems that Ramen is the most delicious item they are selling with order count of 8

-- 5)  Which item was the most popular for each customer?
-- Solution with CTE 

WITH Most_popular_item as 
(
	SELECT  customer_id,product_name,count(product_id)order_count,
	dense_rank()over(partition by customer_id order by count(product_id) desc) as Most_popular_item
	FROM master_table
	GROUP BY 1,2
)
 select * from Most_popular_item
 where Most_popular_item = 1;
 
 -- Solution with Subquery
 
 select a.*  FROM  
(	SELECT  customer_id,product_name,
	count(product_id) as order_count,
	dense_rank()over(partition by customer_id order by count(product_id) desc) as Most_popular_item
	FROM master_table
	GROUP BY 1,2
) a
 where Most_popular_item = 1;
 
  -- Insights --->> Customer A and C ordered Ramen 3 times while Customer B liked every Item there
  -- I personally like CTE's but here I observed that CTE took 16ms while Subquery took 2ms which is good for performance. 
 
 -- 6)  Which item was purchased first by the customer after they became a member?

 select * from
 (	SELECT  *,
	dense_rank()over(partition by customer_id order by order_date asc) as First_purchased_after_membership
	FROM master_table
	where join_date <= order_date
) a
    where First_purchased_after_membership = 1;
    
--  Insights --->> After becoming memeber Customer A purchased Curry and Customer B purchaed Sushi.

-- 7 Which item was purchased just before the customer became a member?

  select * from 
(	SELECT  *,
	dense_rank()over(partition by customer_id order by order_date desc) as First_purchased_after_membership
	FROM master_table
	where order_date < join_date
) a
    where First_purchased_after_membership = 1;
    
    --  Insights --->> Before becoming memeber Customer A purchased Curry & Sushi and Customer B purchaed Sushi only.

    
    -- 8 What is the total items and amount spent for each member before they became a member?
select customer_id,count(product_id) Total_items_purchased, sum(price) Total_Amount_Spent
from 
(Select * from master_table where order_date < join_date) a
group by 1;

-- If I haven't created master Table my query would look like this below --->
--  More complicated right ?
  
  SELECT s.customer_id, COUNT(DISTINCT s.product_id) AS unique_menu_item, SUM(mm.price) AS total_sales
FROM sales AS s
JOIN members AS m
 ON s.customer_id = m.customer_id
JOIN menu AS mm
 ON s.product_id = mm.product_id
WHERE s.order_date < m.join_date
GROUP BY s.customer_id;

--  Insights --->> Before becoming memeber Customer A purchased 2 items and Spent 25$
-- 				   Customer B purchaed 3 items and Spent 40$.

-- 9 If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select customer_id,sum(points) as Total_points from
(Select *,
		Case 
        When Product_Name = 'Sushi' Then price*20 
        else Price*10 end as Points
from Master_Table)a 
group by 1
order by 2 desc;

--  Insights --->> With Sushi has Doulble Multiplier points Cusomer B has 940 points
-- 				   followed by A 860 and C 360 points respectively.


-- 10 In the first week after a customer joins the program (including their join date)
--  they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

With T1 as 
			(select customer_id, price, product_name, order_date, join_date,
            date_add(join_date,interval 6 day) as 1st_week ,
	        last_day("2021-01-31")as last_day 
            from master_table),

 t2 as(  select customer_id, price, product_name, order_date, join_date,
sum(case 
		when order_date between join_date and 1st_week
        then price*20 
        else null end )as Total_points 
        from T1 
        group by 1,2,3,4,5)

select *,
sum(total_points)over(partition by customer_id) as Points_earned 
from T2 where total_points is not null and join_date is not null;

--  Insights --->> In 1st Week after becoming memeber Customer A earned Total 1020 by the end of month January
-- 				   While Customer B earned 200 points only .

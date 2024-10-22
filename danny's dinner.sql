-- 1. What is the total amount each customer spent at the restaurant?

--Check sales you can see product_id but not price
select * from sales;

--But in menu you can see price and product but you can not see customer
select*from menu;

--So that is why use join and see price for each customer 
select * 
from sales as s 
join menu as m on m.product_id=s.product_id;

--For each customer we need to check price
select customer_id,
sum(price)
from sales as s 
join menu as m on m.product_id=s.product_id
group by 1
order by 2 desc;

-- 2. How many days has each customer visited the restaurant?

--First
select * from sales as s  
join menu as m on m.product_id=s.product_id
order by customer_id,order_date;

--We can see customers can order more than 1 product in same day.

--Second
select customer_id,
count(DISTINCT order_date) 
from sales
group by 1
order by 2 desc;

-- 3. What was the first item from the menu purchased by each customer?

--First
select * from sales as s  ,
join menu as m on m.product_id=s.product_id
order by customer_id,order_date;

--Second
select customer_id,
order_date,
product_name,
row_number() over(PARTITION BY customer_id ORDER BY order_date) 
from sales as s  
join menu as m on m.product_id=s.product_id
order by customer_id,order_date;

--Third
select customer_id,
order_date,
product_name,
row_number() over(PARTITION BY customer_id ORDER BY order_date),
rank() over(PARTITION BY customer_id ORDER By order_date),
dense_rank() over(PARTITION BY customer_id ORDER BY order_date)
from sales as s 
join menu as m on m.product_id=s.product_id
order by customer_id,order_date;

--Fourth

with tab as(
select customer_id,
order_date,
product_name,
rank() over(PARTITION BY customer_id ORDER By order_date) as rn
from sales as s 
join menu as m on m.product_id=s.product_id
)
select customer_id,
  product_name
from tab
where rn=1;

--Fifth
with tab as(
select distinct customer_id,
order_date,
product_name,
rank() over(PARTITION BY customer_id ORDER By order_date) as rn
from sales as s 
join menu as m on m.product_id=s.product_id
)
select customer_id,
  product_name
from tab
where rn=1
order by 1;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select product_name,
       count(s.product_id)
from sales as s  
join menu as m on m.product_id=s.product_id
group by 1 
order by 2 desc
limit 1;

-- 5. Which item was the most popular for each customer?
with tablo as(
select customer_id,
       product_name,
	   count(s.product_id) total,
	   dense_rank() over (PARTITION BY customer_id order by count(s.product_id) DESC) as rn
from sales as s  
join menu as m on m.product_id=s.product_id
group by 1,2
)
select customer_id,
       product_name,
	   total
from tablo
where rn=1;

-- 6. Which item was purchased first by the customer after they became a member?


--If we use left join we can see that C isn't member of restaurant.
select *
from sales as s
left join menu as m on m.product_id=s.product_id
left join members as me on me.customer_id=s.customer_id;

--They are asking for members so that is why we will use join

with tablo as(
select s.customer_id,
	order_date,
	product_name,
row_number() over (PARTITION BY s.customer_id order by order_date) as rn
from sales as s
join menu as m on m.product_id=s.product_id
join members as me on me.customer_id=s.customer_id
where order_date >= join_date -- you can use just (>) 
order by 1,2
	)
select customer_id,
       product_name
from tablo
where rn=1;

-- 7. Which item was purchased just before the customer became a member?

with table_1 as(
select s.customer_id,
		order_date,
		product_name,
		rank() over(partition by s.customer_id order by order_date desc)as rn
from sales as s
join menu m on m.product_id = s.product_id
join members as me on s.customer_id = me.customer_id
where order_date < join_date
)
select customer_id,
	product_name
from table_1
where rn = 1;

-- 8. What is the total items and amount spent for each member before they became a member?

select s.customer_id,
		count (s.product_id),
		sum(price)
from sales as s
join menu as m on m.product_id = s.product_id
join members as me on me.customer_id = s.customer_id
where order_date < join_date
group by 1
order by 1;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

with tablo as(
select customer_id,
		s.product_id,
		product_name,
		price,
		case 
			when product_name = 'sushi' then price * 2* 10
			else price * 10
			end points
from sales as s
join menu as m on m.product_id = s.product_id
)
select customer_id,
		sum(points)
from tablo
group by 1
order by 2 desc;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


with tablo as(
Select s.customer_id,
		join_date start_date,
		join_date + 6 end_date,
		order_date,		
		product_name,
		price,
		case 
			when order_date BETWEEN join_date and join_date + 6 then price * 2*10
			when product_name = 'sushi' then price * 2* 10
			else price*10
			end as points
from sales as s
join members as me on me.customer_id = s.customer_id
join menu as m on m.product_id = s.product_id
WHERE order_date <= '2021-01-31'
)
SELECT customer_id,
		sum(points)
from tablo
group by 1;



--First BONUS QUESTION

SELECT s.customer_id,
		order_date,
		product_name,
		price, 
		case 
			when join_date is null then 'N' --We use null statement because of 'C' member 
			when order_date >= join_date then 'Y' else 'N' end as member

from sales as s
join menu as m on s.product_id = m.product_id
LEFT join members as me on me.customer_id = s.customer_id
order by 1,2;

--Second BONUS QUESTION

with tablo as(
SELECT s.customer_id,
		order_date,
		product_name,
		price, 
		case 
			when join_date is null then 'N' 
			when order_date >= join_date then 'Y' else 'N' end as member

from sales as  s
join menu as m on s.product_id = m.product_id
LEFT join members as me on me.customer_id = s.customer_id
order by 1,2
	)
SELECT *,
		case 
			WHEN member = 'N' then NULL
			else
				rank() OVER(PARTITION by customer_id, member order by order_date) end as ranking
from tablo;
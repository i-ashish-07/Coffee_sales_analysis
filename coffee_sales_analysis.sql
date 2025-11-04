
-- COFFEE SALES ANALYSIS PROJECT
-- Complete SQL Script with Business Questions and Recommendations

CREATE TABLE city
(
	city_id	INT PRIMARY KEY,
	city_name VARCHAR(15),	
	population	BIGINT,
	estimated_rent	FLOAT,
	city_rank INT
);

CREATE TABLE customers
(
	customer_id INT PRIMARY KEY,	
	customer_name VARCHAR(25),	
	city_id INT,
	CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id)
);

CREATE TABLE products
(
	product_id	INT PRIMARY KEY,
	product_name VARCHAR(35),	
	Price float
);

CREATE TABLE sales
(
	sale_id	INT PRIMARY KEY,
	sale_date	date,
	product_id	INT,
	customer_id	INT,
	total FLOAT,
	rating INT,
	CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id),
	CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id) 
);

select * from city;
select * from customers;
select * from products;
select * from sales;

-- BUSINESS QUESTIONS

-- Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?
select city_id , city_name , 
round((population * 0.25)/1000000,2) as coffee_consuemer_in_millions, city_rank
from city
order by population desc;

-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
select sum(total)as total_revenue,c.city_name
from sales as s
join customers as j on s.customer_id = j.customer_id
join city as c on j.city_id = c.city_id
where extract(year from sale_date) = 2023 and extract(quarter from sale_date) = 4
group by c.city_name
order by sum(total) desc;

-- Sales Count for Each Product
-- How many units of each coffee product have been sold?
select count(s.sale_id)as total_order , p.product_name
from products as p
left join sales as s on p.product_id = s.product_id
group by p.product_name
order by 1 desc;

-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?
with cte as 
(
select c.customer_name , j.city_name ,sum(s.total) as total_sales
from sales as s
join customers as c on s.customer_id = c.customer_id
join city as j on j.city_id = c.city_id
group by 1,2
)
select city_name ,round(avg(total_sales:: numeric),2) AS avg_total_sale, count(*) as total_cux from cte
group by city_name
order by city_name;

-- City Population and Coffee Consumers
-- Provide a list of cities along with their populations and estimated coffee consumers(25%).
select j.city_name , j.population , 
count(c.customer_name) as estimated_consumers,
round((j.population * 0.25)/1000000,2) as eestimated_coffee_consumer
from city as j
join customers as c on j.city_id = c.city_id
group by 1,2
order by 4;

-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?
with cte as
(
	select p.product_name , ci.city_name, count(sale_id) as total_count,
	dense_rank() over (partition by ci.city_name order by count(sale_id) desc) as rn
	from sales as s
	join products as p on s.product_id = p.product_id
	join customers as c on s.customer_id = c.customer_id
	join city as ci on c.city_id = ci.city_id
	group by 1,2
)
select product_name , city_name , total_count ,rn from cte
where rn<=3
group by 1,2,3,4
order by 2,4;

-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?
select j.city_name, count(distinct(c.customer_id)) as unique_customers
from city as j
join customers as c on j.city_id = c.city_id
join sales as s on s.customer_id = c.customer_id
join products as p on p.product_id = s.product_id
where s.product_id <=14 
group by 1;

-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).
with monthly_sale as(
	select ci.city_name , extract(month from s.sale_date) as months , extract (year from s.sale_date) as year,
	sum(s.total) as total_sale
	from sales as s
	join customers as c on s.customer_id = c.customer_id
	join city as ci on ci.city_id =  c.city_id
	group by 1,2,3
	order by 1,3,2
),
growth_cte as(
	select city_name , months, year,total_sale as cr_month_sale,
	lag(total_sale,1) over(partition by city_name order by year , months) as pv_month_sale
	from monthly_sale
)
select city_name, months, year,cr_month_sale, pv_month_sale,
	round((cr_month_sale - pv_month_sale):: numeric /pv_month_sale:: numeric *100,2) as growth_ratio
	from growth_cte
	where pv_month_sale is not null;

-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer
with cte as
(
select ci.city_name , sum(s.total) as total_sales ,ci.estimated_rent as total_estimated_rent, 
count(distinct c.customer_id) as total_cx,
round((ci.population * 0.25)/1000000,3) as estimated_coffee_consumer
from city as ci
join customers as c on ci.city_id = c.city_id
join sales as s on c.customer_id = s.customer_id
join products as p on s.product_id =p.product_id
group by ci.city_name, ci.estimated_rent , ci.population
)
select city_name , total_sales, total_estimated_rent, total_cx,estimated_coffee_consumer,
round((total_estimated_rent / total_cx):: numeric,2) as avg_estimated_rent , 
round((total_sales / total_cx):: numeric,2) as avg_sale
from cte
order by 2 desc;

-- Final Ranking Query
WITH cte AS (
    SELECT 
        ci.city_name, 
        SUM(s.total) AS total_sales, 
        ci.estimated_rent AS total_estimated_rent, 
        COUNT(DISTINCT c.customer_id) AS total_cx,
        ROUND((ci.population * 0.25)/1000000, 3) AS estimated_coffee_consumer
    FROM city AS ci
    JOIN customers AS c ON ci.city_id = c.city_id
    JOIN sales AS s ON c.customer_id = s.customer_id
    JOIN products AS p ON s.product_id = p.product_id
    GROUP BY ci.city_name, ci.estimated_rent, ci.population
),
city_avg AS (
    SELECT 
        city_name, total_sales, total_estimated_rent, total_cx,
        estimated_coffee_consumer,
        ROUND((total_estimated_rent / total_cx)::numeric, 2) AS avg_estimated_rent, 
        ROUND((total_sales / total_cx)::numeric, 2) AS avg_sale
    FROM cte
)
SELECT city_name, total_sales, total_estimated_rent, total_cx, estimated_coffee_consumer,
       avg_estimated_rent, avg_sale,
       RANK() OVER (ORDER BY total_sales DESC) AS highest_sales,
       RANK() OVER (ORDER BY avg_estimated_rent DESC) AS rent_rank
FROM city_avg
ORDER BY highest_sales, rent_rank;

-- BUSINESS RECOMMENDATIONS

-- Pune:
-- 1. Highest total revenue with low average rent -> focus on premium coffee line expansion.
-- 2. High average sales per customer -> introduce loyalty programs.
-- 3. Strong profitability -> invest in store growth.

-- Delhi:
-- 1. Highest estimated coffee consumer base (7.7M) -> large untapped potential.
-- 2. High customer volume and average rent -> focus on upscale cafes.
-- 3. Launch pop-up stores and student-friendly promotions.

-- Jaipur:
-- 1. High customer count, low rent -> maximize profit margins.
-- 2. Focus marketing on professionals and students.
-- 3. Implement discount-driven loyalty campaigns.

-- Overall:
-- 1. Focus expansion in cities with high sales but low rent (Pune, Jaipur).
-- 2. Capture Delhi’s market with population-targeted advertising.
-- 3. Use sales trend analysis to plan inventory and promotions efficiently.
-- 4. Personalize offers for repeat customers to increase retention.

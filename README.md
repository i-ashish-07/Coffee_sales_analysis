
## Coffee Sales Analysis — SQL Project ##

## Project Overview

This project analyzes **coffee sales performance across multiple cities** using SQL.
It explores sales trends, customer behavior, and market potential to identify business opportunities and growth insights.

---

## Database Schema

| Table         | Description                                                  |
| ------------- | ------------------------------------------------------------ |
| **city**      | Contains city-level data (population, estimated rent, rank). |
| **customers** | Stores customer details and their linked city.               |
| **products**  | Contains product names and prices.                           |
| **sales**     | Records every sale with amount, product, date, and rating.   |

---

## Table Creation Queries

```sql
CREATE TABLE city (
    city_id INT PRIMARY KEY,
    city_name VARCHAR(15),
    population BIGINT,
    estimated_rent FLOAT,
    city_rank INT
);

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(25),
    city_id INT,
    CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id)
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(35),
    Price FLOAT
);

CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    sale_date DATE,
    product_id INT,
    customer_id INT,
    total FLOAT,
    rating INT,
    CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id),
    CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
```

---

## Business Questions and Solutions

## Business Questions

1. **Top 3 Products by Sales in Each City**
   - Find the top 3 selling products for each city based on total sales.

2. **Top 3 Products per City by Count of Sales**
   - Identify which products are sold the most (by count) in each city using DENSE_RANK.

3. **Average Sale vs Estimated Rent per City**
   - Compare average total sales per customer with average estimated rent per customer in each city.

4. **Estimated Coffee Consumers per City**
   - Calculate estimated coffee consumers assuming 25% of the population consumes coffee.

5. **Customer Segmentation by Sales Volume**
   - Categorize customers into groups (e.g., High, Medium, Low) based on their total purchases.

6. **City Performance Ranking**
   - Rank cities by overall sales performance and customer engagement.

7. **Potential Market Recommendation**
   - Identify cities with high coffee consumer potential but lower actual sales — suggesting marketing opportunities.

8. **Product Popularity Trend**
   - Find the most consistently top-selling products across all cities.

9. **Revenue vs Rent Efficiency**
   - Measure how efficiently each city converts rent cost into sales (Sales-to-Rent ratio).


### 1. Coffee Consumers Count
**Question:** How many people in each city are estimated to consume coffee, given that 25% of the population does?

```sql
SELECT city_id, city_name, 
       ROUND((population * 0.25) / 1000000, 2) AS coffee_consuemer_in_millions, 
       city_rank
FROM city
ORDER BY population DESC;
```

---

### 2. Total Revenue from Coffee Sales

**Question:** What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

```sql
SELECT SUM(total) AS total_revenue, c.city_name
FROM sales AS s
JOIN customers AS j ON s.customer_id = j.customer_id
JOIN city AS c ON j.city_id = c.city_id
WHERE EXTRACT(YEAR FROM sale_date) = 2023 
  AND EXTRACT(QUARTER FROM sale_date) = 4
GROUP BY c.city_name
ORDER BY SUM(total) DESC;
```

---

### 3. Sales Count for Each Product

**Question:** How many units of each coffee product have been sold?

```sql
SELECT COUNT(s.sale_id) AS total_order, p.product_name
FROM products AS p
LEFT JOIN sales AS s ON p.product_id = s.product_id
GROUP BY p.product_name
ORDER BY 1 DESC;
```

---

### 4. Average Sales Amount per City

**Question:** What is the average sales amount per customer in each city?

```sql
WITH cte AS (
    SELECT c.customer_name, j.city_name, SUM(s.total) AS total_sales
    FROM sales AS s
    JOIN customers AS c ON s.customer_id = c.customer_id
    JOIN city AS j ON j.city_id = c.city_id
    GROUP BY 1,2
)
SELECT city_name, 
       ROUND(AVG(total_sales::NUMERIC), 2) AS avg_total_sale, 
       COUNT(*) AS total_cux
FROM cte
GROUP BY city_name
ORDER BY city_name;
```

---

### 5. City Population and Coffee Consumers

**Question:** Provide a list of cities along with their populations and estimated coffee consumers (25%).

```sql
SELECT j.city_name, j.population, 
       COUNT(c.customer_name) AS estimated_consumers,
       ROUND((j.population * 0.25) / 1000000, 2) AS estimated_coffee_consumer
FROM city AS j
JOIN customers AS c ON j.city_id = c.city_id
GROUP BY 1,2
ORDER BY 4;
```

---

### 6. Top 3 Selling Products by City

**Question:** What are the top 3 selling products in each city based on sales volume?

```sql
WITH cte AS (
    SELECT p.product_name, ci.city_name, COUNT(sale_id) AS total_count,
           DENSE_RANK() OVER (PARTITION BY ci.city_name ORDER BY COUNT(sale_id) DESC) AS rn
    FROM sales AS s
    JOIN products AS p ON s.product_id = p.product_id
    JOIN customers AS c ON s.customer_id = c.customer_id
    JOIN city AS ci ON c.city_id = ci.city_id
    GROUP BY 1,2
)
SELECT product_name, city_name, total_count, rn
FROM cte
WHERE rn <= 3
GROUP BY 1,2,3,4
ORDER BY 2,4;
```

---

### 7. Customer Segmentation by City

**Question:** How many unique customers are there in each city who have purchased coffee products?

```sql
SELECT j.city_name, COUNT(DISTINCT c.customer_id) AS unique_customers
FROM city AS j
JOIN customers AS c ON j.city_id = c.city_id
JOIN sales AS s ON s.customer_id = c.customer_id
JOIN products AS p ON p.product_id = s.product_id
WHERE s.product_id <= 14
GROUP BY 1;
```

---

### 8. Monthly Sales Growth

**Question:** Calculate the percentage growth (or decline) in sales over different months by city.

```sql
WITH monthly_sale AS (
    SELECT ci.city_name, 
           EXTRACT(MONTH FROM s.sale_date) AS months, 
           EXTRACT(YEAR FROM s.sale_date) AS year,
           SUM(s.total) AS total_sale
    FROM sales AS s
    JOIN customers AS c ON s.customer_id = c.customer_id
    JOIN city AS ci ON ci.city_id = c.city_id
    GROUP BY 1,2,3
    ORDER BY 1,3,2
),
growth_cte AS (
    SELECT city_name, months, year, total_sale AS cr_month_sale,
           LAG(total_sale,1) OVER (PARTITION BY city_name ORDER BY year, months) AS pv_month_sale
    FROM monthly_sale
)
SELECT city_name, months, year, cr_month_sale, pv_month_sale,
       ROUND((cr_month_sale - pv_month_sale)::NUMERIC / pv_month_sale::NUMERIC * 100, 2) AS growth_ratio
FROM growth_cte
WHERE pv_month_sale IS NOT NULL;
```

---

### 9. Market Potential Analysis

**Question:** Identify the top cities based on highest sales, along with total sales, rent, customers, and estimated coffee consumers.

```sql
WITH cte AS (
    SELECT ci.city_name, 
           SUM(s.total) AS total_sales, 
           ci.estimated_rent AS total_estimated_rent, 
           COUNT(DISTINCT c.customer_id) AS total_cx,
           ROUND((ci.population * 0.25) / 1000000, 3) AS estimated_coffee_consumer
    FROM city AS ci
    JOIN customers AS c ON ci.city_id = c.city_id
    JOIN sales AS s ON c.customer_id = s.customer_id
    JOIN products AS p ON s.product_id = p.product_id
    GROUP BY ci.city_name, ci.estimated_rent, ci.population
)
SELECT city_name, total_sales, total_estimated_rent, total_cx, estimated_coffee_consumer,
       ROUND((total_estimated_rent / total_cx)::NUMERIC, 2) AS avg_estimated_rent,
       ROUND((total_sales / total_cx)::NUMERIC, 2) AS avg_sale
FROM cte
ORDER BY 2 DESC;
```

---

## Business Recommendations

### City 1: Pune

* Average rent per customer is very low.
* Highest total revenue among all cities.
* High sales efficiency — average sale per customer is very high.

### City 2: Delhi

* Highest estimated coffee consumer base (~7.7M).
* Highest total number of customers (68+).
* Moderate average rent per customer (~₹330).

### City 3: Jaipur

* Large customer base with high engagement.
* Low average rent per customer.
* Good average sale per customer (~₹11.6K).

---

## Key Insights

* Cities with **lower rent per customer** tend to have **higher average sales per customer**.
* **Delhi** performs strongly due to a **large consumer base**, despite higher rent.
* **Monthly growth trends** reveal city-level seasonality, helping in future marketing planning.

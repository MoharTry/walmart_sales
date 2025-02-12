use walmart_db;
-- drop table walmart; 

SELECT * FROM walmart;

SELECT COUNT(*) FROM walmart;

SELECT payment_method , count(*) from walmart group by payment_method;

select count(distinct branch) from walmart;

select min(quantity) from walmart;


-- 1: What are the different payment methods, and how many transactions and items were sold with each method?
SELECT 
	payment_method , 
	count(*) as 'no_of_payments',
    sum(quantity) as 'quantity sold'
from walmart 
group by payment_method;


-- 2: Which category received the highest average rating in each branch?
select branch, category, avg_rating
from (
	select 
		rank() over(partition by branch order by avg_rating desc) as `rank`,
		branch,	
		category, 
		avg_rating
	from (
		select 
			branch,	
			category, 
			avg(rating) as avg_rating
		from walmart
		group by branch, category
	)as AvgRatings
) as RankedCategories
where `rank` = 1;


 -- 3: What is the busiest day of the week for each branch based on transaction volume?
select branch, day, total_transactions
from(	
    select 
		rank() over(partition by branch order by count(*) desc) `rank`,
		branch,
		dayname(date) as day,
		count(*) as total_transactions
	from walmart
	group by branch, day
) ranked
where `rank` = 1;

-- 4: How many items were sold through each payment method?
select 
	payment_method,
    sum(quantity) as total_items
from walmart
group by payment_method;

-- 5: What are the average, minimum, and maximum ratings for each category in each city?
select 
	category,
    city,
    avg(rating) as avg_rating,
    max(rating) as max_rating,
    min(rating) as min_rating
from walmart
group by category, city;

-- 6: What is the total profit for each category, ranked from highest to lowest?
select category, profit
from 
(	select
		category, 
		sum(profit_margin * total_price) as profit,
		rank() over(order by sum(profit_margin * total_price) desc) as `rank`
	from walmart
	group by category
) ProfitRanked
order by profit desc;

-- 7: What is the most frequently used payment method in each branch?
select branch, payment_method, transactions
from (
	select 
		branch, 
		payment_method,
		count(*) as transactions,
		rank() over(partition by branch order by count(*) desc) as `rank`
	from walmart 
	group by branch,payment_method
) RankedPayements
where `rank` = 1;

-- 8: How many transactions occur in each shift (Morning, Afternoon, Evening) across branches?
select
	branch,
    case
		when time(time) between '06:00:00' and '11:59:59' then 'Morning'
        when time(time) between '12:00:00' and '17:59:59' then 'Afternoon'
        else 'evening'
	end as shift,
    count(*) as total_transactions
from walmart
group by branch, shift
order by branch, total_transactions desc;

-- 9: Which branches experienced the largest decrease in revenue compared to the previous year?
select
	curr.branch,
    curr.year,
    curr.total_revenue as current_year_revenue,
    prev.total_revenue as previous_year_revenue,
    (curr.total_revenue - prev.total_revenue) as revenue_change
from (
	select 
		branch,
		year(date) as year,
		sum(total_price) as total_revenue
	from walmart
	group by branch, year(date)
) curr
left join (
	select 
		branch,
		year(date) as year,
		sum(total_price) as total_revenue
	from walmart
	group by branch, year(date)
) prev
on curr.branch = prev.branch and curr.year = prev.year + 1
where (curr.total_revenue - prev.total_revenue) < 0 
order by revenue_change asc;

-- 10: Find the total sales per category.
select 
	category,
    sum(total_price) as sales
from walmart
group by category;


-- 11: Find the average spending per transaction for each payment method
select 
	avg(total_price) as avg_spending,
    payment_method
    
from walmart
group by payment_method;

-- 12: Determine the branch with the highest average rating.
select 
	branch, 
    avg_rating
from(
    select 
		branch,
		avg(rating) as avg_rating,
		rank() over(partition by branch order by avg(rating) desc) as `highest_rating`
	from walmart
	group by branch
)AvgRating;

-- 13: Find the top 2 best-selling product categories in each city.
select best_selling, city, category, avg_rating
from(
	select 
		rank() over(partition by category order by avg_rating desc) as best_selling,
		city,
		category,
		avg_rating
	from (
		select
			city,
            category, 
            avg(rating) as avg_rating
		from walmart
        group by city, category
    )AvgRatings
)BestSelling
where best_selling in (1,2); 

-- 14: Identify the month with the highest revenue overall
select `month`    
from(
    select 
		month(date) as `month`,
		sum(total_price) as revenue,
		rank() over(order by sum(total_price) desc) as `rank`
	from walmart
	group by `month`
) HighestRevenue
where `rank` = 1;

-- 15: Which city had the highest total sales in each category
select category, city, sales
from(
	select 
		category,
		city,
		sum(total_price) as sales,
		rank() over(partition by category order by sum(total_price) desc) as `rank`
	 from walmart
	 group by city, category
)HighestSales
where `rank` = 1;

-- 16: Find the percentage contribution of each product line to the total revenue.
select 
	category,
    (sum(total_price)*100) / (select sum(total_price) from walmart) as percentage_contribution
from walmart
group by category
order by percentage_contribution desc;

--1) How many customers has Foodie-Fi ever had?
select 
    count(distinct customer_id) as customers_count 
from 
    subscriptions;


--2) What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

select 
    date_trunc(month,sub.start_date) month_start_date,
    count(1)
from
    subscriptions sub
inner join plans p on p.plan_id = sub.plan_id
where sub.plan_id = 0
group by month_start_date
order by month_start_date;


--3) What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

select 
    p.plan_id plan_id,
    p.plan_name plan_name,
    count(1) events
from
    subscriptions sub
inner join plans p on p.plan_id = sub.plan_id
where year(sub.start_date) > 2020
group by p.plan_id, p.plan_name
order by p.plan_id;


--4) What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

select 
    count(distinct sub.customer_id) customer_count,
    count(case when p.plan_name = 'churn' then sub.customer_id end) as churn_count,
    round(100*churn_count/customer_count,1) as churn_percentage
from 
    subscriptions sub
inner join plans p on p.plan_id = sub.plan_id;


--5) How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
with plan_rn_cte as (select 
    sub.customer_id customer_id, 
    sub.start_date start_date, 
    sub.plan_id plan_id,
    dense_rank() over(partition by sub.customer_id order by sub.plan_id) plan_rank
from 
    subscriptions sub)
select 
    count(case 
            when plan_id = 4 then customer_id
            end
        ) as churn_count,
    round(100*churn_count/count(1),2) as churn_percentage
    
from plan_rn_cte
where plan_rank = 2;


--6) What is the number and percentage of customer plans after their initial free trial?

select 
    sub.plan_id plan_id,
    p.plan_name plan_name,
    dense_rank() over (partition by sub.customer_id order by sub.plan_id)
    
from 
    subscriptions sub
inner join plans p on p.plan_id = sub.plan_id
where p.plan_name != 'trial'
group by sub.plan_id, p.plan_name;


WITH ranked_plans AS (
  SELECT customer_id, plan_id,ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY plan_id asc) AS plan_rank
  FROM subscriptions)
SELECT p.plan_id, p.plan_name,
  COUNT(*) AS customer_count,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM ranked_plans rp
INNER JOIN plans p
  ON rp.plan_id = p.plan_id
WHERE plan_rank = 2
GROUP BY p.plan_id, p.plan_name
ORDER BY p.plan_id;

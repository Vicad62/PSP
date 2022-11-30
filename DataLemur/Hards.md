## Active User Retention (POSTGRE)
Link: [Problem](https://datalemur.com/questions/user-retention)

Solution without join
``` sql
select extract(month from curr_date) as month,
       count(1) as monthly_active_users
from
(
  select user_id,
         date_trunc('month',event_date) as curr_date,
         date_trunc('month',lag(event_date) 
                            over (partition by user_id order by event_date asc)
                   ) as prev_date
  from user_actions
  where extract(year from event_date) = 2022
        and extract(month from event_date) between 6 and 7
) input_data
where extract(month from age(curr_date,prev_date)) = 1
group by extract(month from curr_date)
```

Solution with join
``` sql 
with input_data as
(
  select user_id,
         date_trunc('month',event_date) as dates
  from user_actions
)

select extract(month from x.dates) as month,
       count(distinct x.user_id) as monthly_active_users
from input_data x 
join input_data y
     on x.user_id = y.user_id
     and x.dates - interval '1 month' = y.dates
where extract(year from x.dates) = 2022
      and extract(month from x.dates) = 7
group by extract(month from x.dates)
```

## Y-on-Y Growth Rate (POSTGRE)
Link: [Problem](https://datalemur.com/questions/yoy-growth-rate)

``` sql
select extract(year from x.transaction_date) as year,
       x.product_id,
       x.spend as curr_year_spend,
       y.spend as prev_year_spend,
       round((x.spend/y.spend*100)-100.0,2) as yoy_rate
from user_transactions x 
left join user_transactions y 
     on x.product_id = y.product_id
     and x.transaction_date - interval '1 year' = y.transaction_date
```

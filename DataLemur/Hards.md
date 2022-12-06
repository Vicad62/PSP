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

## Maximize Prime Item Inventory (POSTGRE)
Link: [Problem](https://datalemur.com/questions/prime-warehouse-storage)

First solution
``` sql
with input_data as
(
  select item_type,
         count(1) as cnt_items_in_pack,
         sum(square_footage) as sum_square_in_pack,
         500000::int as total_square
  from inventory
  group by item_type
),
prime_eligible_data as
(
  select item_type,
         trunc(total_square/sum_square_in_pack) as cnt_combinatons,
         cnt_items_in_pack * trunc(total_square/sum_square_in_pack) as cnt_items_in_wh,
         total_square - (sum_square_in_pack * trunc(total_square/sum_square_in_pack)) as square_left
  from input_data
  where item_type = 'prime_eligible'
),
not_prime_data as
(
  select item_type,
         trunc((select square_left from prime_eligible_data)/sum_square_in_pack) as cnt_combinatons,
         cnt_items_in_pack * trunc((select square_left from prime_eligible_data)/sum_square_in_pack) as cnt_items_in_wh
  from input_data
  where item_type = 'not_prime'
)

select item_type,
       cnt_items_in_wh
from prime_eligible_data
union all
select item_type,
       cnt_items_in_wh
from not_prime_data
```

Second solution. More optimized.
```sql
with input_data as
(
  select item_type,
         count(1) as cnt_items_in_pack,
         sum(square_footage) as sum_square_in_pack,
         500000::int as total_square
  from inventory
  group by item_type
),
prime_area_data as
(
  select trunc(total_square/sum_square_in_pack)*sum_square_in_pack as prime_area
  from input_data
  where item_type = 'prime_eligible'
)

select item_type,
       case
        when item_type = 'prime_eligible' 
         then trunc((select prime_area from prime_area_data)/sum_square_in_pack)*cnt_items_in_pack
        when item_type = 'not_prime' 
         then trunc((total_square - (select prime_area from prime_area_data))/sum_square_in_pack)*cnt_items_in_pack
        end as items_cnt_in_wh
from input_data
order by items_cnt_in_wh desc
```

## Median Google Search Frequency
Link: [Problem](https://datalemur.com/questions/median-search-freq)

First solution without recursion
``` sql
with searches_searies as
(
  select searches
  from search_frequency
  cross join generate_series(1, num_users)
)

select round(percentile_cont(0.5) within group (order by searches asc)::dec,1) as median
from searches_searies
```

Secon solution with recursion
``` sql
with recursive searches_searies as
(
  select searches, num_users, 1 as n from search_frequency
  union all
  select searches, num_users, n + 1 from searches_searies
  where n + 1 <= num_users
)

select round(percentile_cont(0.5) within group (order by searches asc)::dec,1) as median
from searches_searies
```

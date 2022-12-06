## Which year saw the highest and lowest no of countries participating in olympics

<sub>  Note 1: I've added dummy game with lowest no of countries to validate the solution against different test cases. </sub>

<sub> Note 2: The solution has poor optimization due to using "order by + fetch" approach. </sub>
``` sql
with games_lowest_qty_participants as
(
	select row_number() over (order by count(distinct y.region) asc) as rn,
	       concat(games, ' - ', count(distinct y.region)) as games_countries
	from olympics_history x
	join olympics_history_noc_regions y
	     on x.noc = y.noc
	group by games
	order by count(distinct y.region) asc
	fetch first 1 row with ties
),
games_highest_qty_participants as
(
	select row_number() over (order by count(distinct y.region) desc) as rn,
	       concat(games, ' - ', count(distinct y.region)) as games_countries
	from olympics_history x
	join olympics_history_noc_regions y
	     on x.noc = y.noc
	group by games
	order by count(distinct y.region) desc
	fetch first 1 row with ties
)

select coalesce(x.games_countries, '') as games_countries_min, 
       coalesce(y.games_countries, '') as games_countries_max
from games_lowest_qty_participants x 
full join games_highest_qty_participants y
          on x.rn = y.rn
```
<sub> Output </sub>

![Query1_Output](https://user-images.githubusercontent.com/108180514/205983798-3cb88e1c-113e-4a0a-86a8-a947f29310aa.PNG)

## List down total gold, silver and bronze medals won by each country.

``` sql
select region,
       count(case when medal = 'Gold'   then medal end) as gold,
       count(case when medal = 'Silver' then medal end) as silver,
       count(case when medal = 'Bronze' then medal end) as bronze
from olympics_history x
join olympics_history_noc_regions y
     on x.noc = y.noc
group by region
order by gold desc, silver desc, bronze desc
```
<sub> Output </sub>

![Query2_Output](https://user-images.githubusercontent.com/108180514/206012499-a475acc0-cd2b-4f66-8dd4-e8db0faac298.PNG)


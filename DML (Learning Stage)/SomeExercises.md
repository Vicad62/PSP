## 25
Найдите производителей принтеров, которые производят ПК с наименьшим объемом RAM и с самым быстрым процессором среди всех ПК, имеющих наименьший объем RAM. 
Вывести: Maker

``` sql
select distinct 
	pt.maker 
from product pt
join (
	  select 
		  maker,
		  rank() over (order by ram,speed desc) rnk
	  from pc
	  join product pt
		  on pc.model = pt.model
     ) pm
	on  pm.rnk = 1
	and pt.maker = pm.maker
where pt.type = 'printer'
```
## 39
Найдите корабли, `сохранившиеся для будущих сражений`; т.е. выведенные из строя в одной битве (damaged), они участвовали в другой, произошедшей позже.

``` sql
select distinct
	ship 
from outcomes os
join battles bs
	on os.battle = bs.name
group by ship
having min(iif(result = 'damaged', date,null)) < max(date)
```

## 41
Для каждого производителя, у которого присутствуют модели хотя бы в одной из таблиц PC, Laptop или Printer, определить максимальную цену на его продукцию.
Вывод: имя производителя, если среди цен на продукцию данного производителя присутствует NULL, то выводить для этого производителя NULL,
иначе максимальную цену.

``` sql
with ut
	as (
		select model,price from pc
		union all
		select model,price from laptop
		union all
		select model,price from printer
	   )
	   
select
	pt.maker,
	case
	 when max(case when ut.price is not null then 0 else 1 end) = 0
	      then max(price)
		  else null
	end m_price
from product pt
join ut on pt.model = ut.model
group by pt.maker
```

## 47
Определить страны, которые потеряли в сражениях все свои корабли.

``` sql
select 
	country 
from classes cs
join (
	select 
	   coalesce(ss.class,os.ship) class, 
	   coalesce(ss.name,os.ship) ship,
	   case when result = 'sunk' then 0 else 1 end flag
	from ships ss
	full join (
		   select 
	              ship,
		      max(result) result,
                      max(date) date 
	           from outcomes os
		   join battles bs 
		   	on os.battle = bs.name
		   group by ship
	) os 
		on ss.name = os.ship
) t1 
	on cs.class = t1.class
group by country
having max(flag) = 0
```

## 51 
Найдите названия кораблей, имеющих наибольшее число орудий среди всех имеющихся кораблей такого же водоизмещения (учесть корабли из таблицы Outcomes)

``` sql
select 
	ship 
from (
	select 
		ship, 
		rank() over (partition by cs.displacement order by cs.numguns desc) rnk 
	from classes cs
	join (
		select class, name as ship from ships 
		union
		select ship, ship from outcomes
	     ) t1
		on cs.class = t1.class
	where numguns is not null 
              and displacement is not null
) t2
where t2.rnk = 1
```

## 56
Для каждого класса определите число кораблей этого класса, потопленных в сражениях. Вывести: класс и число потопленных кораблей.

``` sql
select 
	cs.class, 
	count(ship) sunked 
from classes cs
left join (
	select 
		coalesce(ss.class,os.ship) as class, 
		ship 
	from outcomes os
	left join ships ss 
		on os.ship = ss.name
	where os.result = 'sunk'
	) t1
on cs.class = t1.class
group by cs.class
```

## 57
Для классов, имеющих потери в виде потопленных кораблей и не менее 3 кораблей в базе данных, вывести имя класса и число потопленных кораблей. 

``` sql
select 
	coalesce(class,ship) class, 
	count(case when result= 'sunk' then result end) class 
from ships ss
full join outcomes os
	on ss.name = os.ship
group by coalesce(class,ship)
having count(distinct coalesce(ship,name)) > 2 
       and max(result) = 'sunk'
```

## 58
Для каждого типа продукции и каждого производителя из таблицы Product c точностью до двух десятичных знаков найти процентное отношение числа моделей 
данного типа данного производителя к общему числу моделей этого производителя.
Вывод: maker, type, процентное отношение числа моделей данного типа к общему числу моделей производителя

``` sql
with raw_data(maker,type,model)
	as (
		select distinct
			a.maker,
			b.type,
			iif(a.type = b.type, a.model, null)
		from product a
		cross join (select distinct type from product) b
	   ),
cnt_cacl_table(maker,type,cnt_per_type,cnt_total)
	as (
		select
			maker,
			type,
			count(model)*1.00,
			sum(count(model)) over (partition by maker)*1.00
		from raw_data
		group by maker,type
	   )

select
	maker,
	type,
	cast((cnt_per_type/cnt_total)*100 as decimal(10,2)) prcnt
from cnt_cacl_table
```

## 60
Посчитать остаток денежных средств на начало дня 15/04/01 на каждом пункте приема для базы данных с отчетностью не чаще одного раза в день. 
Вывод: пункт, остаток.
Замечание. Не учитывать пункты, информации о которых нет до указанной даты. 

``` sql
select 
	point, 
	sum(case when type = 'inc' then inc else -out end) remain 
from (
	select point,date,'inc' type,inc,null as out from income_o
	union all
	select point,date,'out' type,null,out from outcome_o
) merged_data
where date < '2001-04-15'
group by point
```

## 64
Используя таблицы Income и Outcome, для каждого пункта приема определить дни, когда был приход, но не было расхода и наоборот.
Вывод: пункт, дата, тип операции (inc/out), денежная сумма за день. 

``` sql
select
	point,
	date,
	type,
	sum(turn)
from (
	  select 
		 isnull(i.point,o.point) point,
		 isnull(i.date,o.date) date,
		 iif(i.code is null,'out','inc') type,
		 case when o.code is null then inc else out end turn
	  from income i
	  full join outcome o
		    on i.point = o.point and i.date = o.date
	  where i.code is null 
	        or o.code is null
	 ) raw_data
group by point,date,type
```

## 65
Пронумеровать уникальные пары {maker, type} из Product, упорядочив их следующим образом:
- имя производителя (maker) по возрастанию;
- тип продукта (type) в порядке PC, Laptop, Printer.
Если некий производитель выпускает несколько типов продукции, то выводить его имя только в первой строке;
остальные строки для ЭТОГО производителя должны содержать пустую строку символов ('').

``` sql
select 
	row_number() over (order by maker,right(type,1)) rn,
	case 
	 when lag(maker) over (partition by maker order by maker) is null 
	  then maker 
	  else ''
	end maker,
	type
from product
group by maker,type
```

## 66
Для всех дней в интервале с 01/04/2003 по 07/04/2003 определить число рейсов из Rostov.
Вывод: дата, количество рейсов

``` sql
with rt(s_date)
as (
select cast('2003-04-01' as datetime) s_date 
union all
select dateadd(dd,1,s_date) from rt
where s_date < '2003-04-07'
)

select
	s_date,
	count(distinct trip_no) qty_trip
from rt
left join pass_in_trip pit
	on rt.s_date = pit.date
	and pit.trip_no in (select trip_no from trip where town_from = 'rostov')
group by s_date
``` 

## 68
Найти количество маршрутов, которые обслуживаются наибольшим числом рейсов.
Замечания.
1) A - B и B - A считать ОДНИМ И ТЕМ ЖЕ маршрутом.
2) Использовать только таблицу Trip

``` sql
select 
	count(*) cnt_top_trips 
from (
	select
		rank() over (order by count(trip_no) desc) trips_rnk,
		iif(town_from > town_to,town_from+town_to,town_to+town_from) route
	from trip
	group by iif(town_from > town_to,town_from+town_to,town_to+town_from)
) dt
where trips_rnk = 1
```

## 69
По таблицам Income и Outcome для каждого пункта приема найти остатки денежных средств на конец каждого дня,
в который выполнялись операции по приходу и/или расходу на данном пункте.
Учесть при этом, что деньги не изымаются, а остатки/задолженность переходят на следующий день.
Вывод: пункт приема, день в формате "dd/mm/yyyy", остатки/задолженность на конец этого дня.

``` sql
select distinct
	point,
	convert(char(10),date,103) date,
	sum(inc) over (partition by point order by date range unbounded preceding) remain
from (
	select point,date,inc from income
	union all
	select point,date,-out from outcome
) t
```

## 76 
Определить время, проведенное в полетах, для пассажиров, летавших всегда на разных местах. Вывод: имя пассажира, время в минутах. 

``` sql
with ct as (
select
	id_psg,
	row_number() over (partition by id_psg,place order by id_psg) place_cnt,
	datediff(mi,time_out,case when time_in < time_out then dateadd(dd,1,time_in) else time_in end) min_in_fly
from pass_in_trip pit
join trip tp
	on pit.trip_no = tp.trip_no
)

select
	(select name from passenger pr where pr.id_psg = ct.id_psg) name,
	sum(min_in_fly) min
from ct
group by id_psg
having max(place_cnt) = 1
```

## 82
В наборе записей из таблицы PC, отсортированном по столбцу code (по возрастанию) найти среднее значение цены для каждой шестерки подряд идущих ПК.
Вывод: значение code, которое является первым в наборе из шести строк, среднее значение цены в наборе.

``` sql
with dt as (
select 
	lead(code,5) over (order by code) lc,
	code,
	avg(price) over (order by code rows between current row and 5 following) avg_price
from pc
)

select 
	code,
	avg_price
from dt
where lc is not null
```

## 88
Среди тех, кто пользуется услугами только одной компании, определить имена разных пассажиров, летавших чаще других.
Вывести: имя пассажира, число полетов и название компании. 

``` sql
select top 1 with ties
	(select name from passenger pr where pr.id_psg = pit.id_psg) name,
	count(tp.trip_no) trip_cnt,
	(select name from company cy where cy.id_comp = min(tp.id_comp)) comp
from pass_in_trip pit
join trip tp
	on pit.trip_no = tp.trip_no
group by id_psg 
having min(id_comp) = max(id_comp)
order by count(tp.trip_no) desc
```

## 92
Выбрать все белые квадраты, которые окрашивались только из баллончиков,
пустых к настоящему времени. Вывести имя квадрата 

``` sql
select
	(select q_name from utq where utq.q_id = dt.b_q_id) q_name
from (
select top 1 with ties
	utb.*,
	sum(b_vol) over (partition by b_v_id) - 255 lvl
from utb
order by sum(b_vol) over (partition by b_q_id) desc
) dt
group by b_q_id
having min(lvl) = 0
```

## 93
Для каждой компании, перевозившей пассажиров, подсчитать время, которое провели в полете самолеты с пассажирами.
Вывод: название компании, время в минутах. 

``` sql
select distinct 
	(select name from company cy where cy.id_comp = tp.id_comp) comp,
	sum(datediff(mi,time_out,case 
				  when time_out > time_in 
				  then time_in + 1 
				  else time_in 
				 end
		)
	) over (partition by tp.id_comp) time_in_fly
from trip tp
left join (
	select 
		trip_no,
		date 
	from pass_in_trip
	group by trip_no,date
) pit
```

## 94
Для семи последовательных дней, начиная от минимальной даты, когда из Ростова было совершено максимальное число рейсов, определить число рейсов из Ростова.
Вывод: дата, количество рейсов 

``` sql
with dates (s_date, n) 
as (
	select top 1 
		pit.date,
		0
	from trip tp
	join (
		select 
			trip_no,
			date 
		from pass_in_trip
		group by trip_no,date
	) pit
		on tp.trip_no = pit.trip_no
	where tp.town_from = 'Rostov'
	group by pit.date
	order by count(pit.trip_no) desc, pit.date asc
	union all
	select 
		s_date + 1,
		n + 1 
	from dates
	where n + 1 < 7
)

select 
	s_date, 
	isnull(dt.cnt,0)
from dates ds
left join (
	select
		pit.date, 
		count(pit.trip_no) cnt
	from trip tp
	join (
		select 
			trip_no,
			date 
		from pass_in_trip
		group by trip_no,date
	) pit
			on tp.trip_no = pit.trip_no
	where town_from = 'Rostov'
	group by pit.date
) dt
	on ds.s_date = dt.date
```

## 96
При условии, что баллончики с красной краской использовались более одного раза, выбрать из них такие, которыми окрашены квадраты, имеющие голубую компоненту.
Вывести название баллончика

``` sql
select distinct 
	v_name 
from (
	select 
		v_name,
		sum(case when v_color = 'R' then 1 else 0 end) 
			over (partition by v_name) red_cnt, 
		max(case when v_color = 'B' then 'found' end) 
			over (partition by b_q_id) blue_check
from utb
join utv 
	on utv.v_id = utb.b_v_id
) t1
where  red_cnt >= 2 
       and blue_check = 'found'
```

## 99
Рассматриваются только таблицы Income_o и Outcome_o. Известно, что прихода/расхода денег в воскресенье не бывает.
Для каждой даты прихода денег на каждом из пунктов определить дату инкассации по следующим правилам:
1. Дата инкассации совпадает с датой прихода, если в таблице Outcome_o нет записи о выдаче денег в эту дату на этом пункте.
2. В противном случае - первая возможная дата после даты прихода денег, которая не является воскресеньем и в Outcome_o не отмечена выдача денег сдатчикам вторсырья в эту дату на этом пункте.
Вывод: пункт, дата прихода денег, дата инкассации.

``` sql
with cte1 -- возвращает даты, в которые изначально была выдача день в день или на след. день, с следующим свободным днем
 as (
select 
	t2.point,
	t2.date_inc,
/* Берем ближающую, т.е. следующую дату (из условия ниже понимаем, что добавление не создаст пересечений с выдачей */
	(select dateadd(dd,case when datename(dw,min(date)) = 'Saturday' then 2 else 1 end, min(date))
	 from (
		select point, date
		from outcome_o o1
/* Отбираем только те даты, добавляя к которым день или два будет день без выдачи */
		where not exists (
			      select 1 from outcome_o o2
			      where o1.point = o2.point
				    and case 
					 when datename(dw,o1.date) = 'Saturday' then o1.date + 2 else o1.date + 1 
					end = o2.date
			     ) 
	      ) t0
/* Дата больше, чем предыдущая дата выдачи */
	 where t0.point = t2.point and t0.date >= t2.date_coll 
	) as date_coll2
from (
select
	point,
	date_inc,
	date_coll
from (
	select
		point,
		date as date_inc,
		case when datename(dw,date) = 'Saturday' then date + 2 else date + 1 end as date_coll
	from outcome_o
     ) t1
where exists (
	      select 2 from income_o i
	      where t1.point = i.point and t1.date_inc = i.date
	     )
) t2
join outcome_o o
	on t2.point = o.point and t2.date_coll = o.date
),
cte2 -- возвращает даты, в которые не было выдачи
 as (
select 
	point,
	date as date_inc,
	date as date_coll
from income_o i
where not exists (
		  select 1 from outcome_o o
		  where i.point = o.point and i.date = o.date
		 )
),
cte3 -- возвращает даты, в которые была выдача, не попадающие на следующую выдачу
 as (
select
	point,
	date_inc,
	date_coll
from (
	select
		point,
		date as date_inc,
		case when datename(dw,date) = 'Saturday' then date + 2 else date + 1 end as date_coll
	from outcome_o
     ) t1
where not exists (
		  select 1 from outcome_o o
		  where t1.point = o.point and t1.date_coll = o.date
		 )
      and exists (
	    	  select 2 from income_o i
	          where t1.point = i.point and t1.date_inc = i.date
	         )
)

select * from cte1
union all
select * from cte2
union all
select * from cte3
```

## 101
Таблица Printer сортируется по возрастанию поля code.
Упорядоченные строки составляют группы: первая группа начинается с первой строки, каждая строка со значением color='n' начинает новую группу, группы строк не перекрываются.
Для каждой группы определить: наибольшее значение поля model (max_model), количество уникальных типов принтеров (distinct_types_cou) и среднюю цену (avg_price).
Для всех строк таблицы вывести: code, model, color, type, price, max_model, distinct_types_cou, avg_price. 

``` sql
with grouped_data
 as (
	select 
		code,
		model,
		color,
		type,
		price,
		sum(case when code = 1 then 1 when color='n' then 1 else 0 end) 
			over (order by code asc) as seq_no
	from printer
)

select
	code,
	model,
	color,
	type,
	price,
	max(model) over (partition by seq_no) as max_model,
	(select count(distinct type) from grouped_data gd2 where gd1.seq_no = gd2.seq_no) as dist_type,
	avg(price) over (partition by seq_no) as avg_price
from grouped_data gd1
```

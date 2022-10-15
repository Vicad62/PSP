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

	�������: 39
select distinct
	ship 
from outcomes os
join battles bs
	on os.battle = bs.name
group by ship
having min(iif(result = 'damaged', date,null)) < max(date)

	�������: 41
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
	 when max(case
				when ut.price is not null
					 then 0
					 else 1
	          end
	         ) = 0
	      then max(price)
		  else null
	end m_price
from product pt
join ut on pt.model = ut.model
group by pt.maker

	�������: 47
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

	�������: 51
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
	where 1=1
		  and numguns is not null 
          and displacement is not null
) t2
where t2.rnk = 1

	�������: 56
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

	�������: 57
select 
	coalesce(class,ship) class, 
	count(case when result = 'sunk' then result end) sunks 
from ships ss
full join outcomes os
	on ss.name = os.ship
group by coalesce(class,ship)
having count(distinct coalesce(ship,name)) > 2 
       and max(result) = 'sunk'

	�������: 58
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

	�������: 60 
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

	�������: 64
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
		    on i.point = o.point 
			and i.date = o.date
	  where i.code is null 
	        or o.code is null
	 ) raw_data
group by point,date,type

	�������: 65
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

	�������: 66
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

	�������: 68
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

	�������: 69
select distinct
	point,
	convert(char(10),date,103) date,
	sum(inc) over (partition by point order by date range unbounded preceding) remain
from (
	  select point,date,inc from income
	  union all
	  select point,date,-out from outcome
	 ) t
 
	�������: 76
with ct 
	as (
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

	�������: 82
with dt 
	as (
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

	�������: 88
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

	�������: 92
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

	�������: 93 
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
	on tp.trip_no = pit.trip_no
where pit.trip_no is not null

	�������: 94
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

	�������: 96
select distinct 
	v_name 
from (
	  select 
		  v_name,
		  sum(case when v_color = 'R' then 1 else 0 end) over (partition by v_name) red_cnt, 
		  max(case when v_color = 'B' then 'found' end) over (partition by b_q_id) blue_check
	  from utb
	  join utv 
		  on utv.v_id = utb.b_v_id
	 ) t1
where  red_cnt >= 2 
       and blue_check = 'found'

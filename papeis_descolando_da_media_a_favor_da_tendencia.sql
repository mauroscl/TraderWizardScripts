declare @d1 as datetime = '2017-2-8', @d2 as datetime = '2017-2-9', @titulosMinimo as int = 100000, @valorMinimo as int = 1000000, @negociosMinimo as int = 100

select p10.codigo as p10, p21.codigo as p21
from 
(
	select c1.codigo
	from 
	(
		select c.Codigo
		from Cotacao c inner join Media_Diaria m on c.Codigo = m.Codigo and c.data = m.Data and Tipo = 'MMA' AND NumPeriodos = 10
		where c.Data = @d1
		and m.Valor between c.ValorMinimo and c.ValorMaximo
	) as c1
	inner join
	(
		select c.Codigo
		from Cotacao c inner join Media_Diaria m on c.Codigo = m.Codigo and c.data = m.Data and Tipo = 'MMA' AND NumPeriodos = 10
		where c.Data = @d2
		and m.Valor < c.ValorMinimo
		AND C.valorfechamento > (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2)) 
		AND C.Titulos_Total >= @titulosMinimo
		AND C.Valor_Total >= @valorMinimo
		AND C.Negocios_Total >= @negociosMinimo

	) as c2
	on c1.Codigo = c2.Codigo
) as p10
full outer join
(
	select c1.codigo
	from 
	(
		select c.Codigo
		from Cotacao c inner join Media_Diaria m on c.Codigo = m.Codigo and c.data = m.Data and Tipo = 'MMA' AND NumPeriodos = 21
		where c.Data = @d1
		and m.Valor between c.ValorMinimo and c.ValorMaximo
	) as c1
	inner join
	(
		select c.Codigo
		from Cotacao c inner join Media_Diaria m on c.Codigo = m.Codigo and c.data = m.Data and Tipo = 'MMA' AND NumPeriodos = 21
		where c.Data = @d2
		and m.Valor < c.ValorMinimo
		AND C.valorfechamento > (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2)) 
		AND C.Titulos_Total >= @titulosMinimo
		AND C.Valor_Total >= @valorMinimo
		AND C.Negocios_Total >= @negociosMinimo

	) as c2
	on c1.Codigo = c2.Codigo
) as p21
on p10.codigo = p21.codigo
order by  case when p21.Codigo is null then 0 else 1 end, p10.Codigo, p21.Codigo
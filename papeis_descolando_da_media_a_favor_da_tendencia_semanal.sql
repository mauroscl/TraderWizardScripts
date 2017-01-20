declare @d1 as datetime = '2017-1-2', @d2 as datetime = '2017-1-9', @titulosMinimo as int = 500000, @valorMinimo as int = 5000000, @negociosMinimo as int = 500

select p10.Codigo as p10, p21.Codigo as p21
from 
(
	select c1.codigo
	from 
	(
		select c.Codigo
		from Cotacao_Semanal c inner join Media_Semanal m on c.Codigo = m.Codigo and c.data = m.Data and Tipo = 'MMA' AND NumPeriodos = 10
		where c.Data = @d1
		and m.Valor between c.ValorMinimo and c.ValorMaximo
	) as c1
	inner join
	(
		select c.Codigo
		from Cotacao_Semanal c inner join Media_Semanal m on c.Codigo = m.Codigo and c.data = m.Data and Tipo = 'MMA' AND NumPeriodos = 10
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
		from Cotacao_Semanal c inner join Media_Semanal m on c.Codigo = m.Codigo and c.data = m.Data and Tipo = 'MMA' AND NumPeriodos = 21
		where c.Data = @d1
		and m.Valor between c.ValorMinimo and c.ValorMaximo
	) as c1
	inner join
	(
		select c.Codigo
		from Cotacao_Semanal c inner join Media_Semanal m on c.Codigo = m.Codigo and c.data = m.Data and Tipo = 'MMA' AND NumPeriodos = 21
		where c.Data = @d2
		and m.Valor < c.ValorMinimo
		AND C.valorfechamento > (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2)) 
		AND C.Titulos_Total >= @titulosMinimo
		AND C.Valor_Total >= @valorMinimo
		AND C.Negocios_Total >= @negociosMinimo
		
	) as c2
	on c1.Codigo = c2.Codigo
) as p21
on p10.Codigo = p21.Codigo
order by  case when p21.Codigo is null then 0 else 1 end, p10.Codigo, p21.Codigo

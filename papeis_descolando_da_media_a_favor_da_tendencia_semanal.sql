declare @d1 as datetime = '2016-11-28', @d2 as datetime = '2016-12-5', @numPeriodos as int = 10

select c1.codigo
from 
(
	select c.Codigo
	from Cotacao_Semanal c inner join Media_Semanal m on c.Codigo = m.Codigo and c.data = m.Data and Tipo = 'MMA' AND NumPeriodos = @numPeriodos
	where c.Data = @d1
	and m.Valor between c.ValorMinimo and c.ValorMaximo
) as c1
inner join
(
	select c.Codigo
	from Cotacao_Semanal c inner join Media_Semanal m on c.Codigo = m.Codigo and c.data = m.Data and Tipo = 'MMA' AND NumPeriodos = @numPeriodos
	where c.Data = @d2
	and m.Valor < c.ValorMinimo
	AND C.valorfechamento > (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2)) 
	AND C.Titulos_Total >= 500000
	AND C.Valor_Total >= 5000000
	AND C.Negocios_Total >= 500
	
) as c2
on c1.Codigo = c2.Codigo


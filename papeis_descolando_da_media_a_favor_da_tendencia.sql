declare @d1 as datetime = '2017-1-5', @d2 as datetime = '2017-1-6', @numPeriodos as int = 21

select c1.codigo
from 
(
	select c.Codigo
	from Cotacao c inner join Media_Diaria m on c.Codigo = m.Codigo and c.data = m.Data and Tipo = 'MMA' AND NumPeriodos = @numPeriodos
	where c.Data = @d1
	and m.Valor between c.ValorMinimo and c.ValorMaximo
) as c1
inner join
(
	select c.Codigo
	from Cotacao c inner join Media_Diaria m on c.Codigo = m.Codigo and c.data = m.Data and Tipo = 'MMA' AND NumPeriodos = @numPeriodos
	where c.Data = @d2
	and m.Valor < c.ValorMinimo
	AND C.valorfechamento > (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2)) 
	AND C.Titulos_Total >= 100000
	AND C.Valor_Total >= 1000000
	AND C.Negocios_Total >= 100

) as c2
on c1.Codigo = c2.Codigo


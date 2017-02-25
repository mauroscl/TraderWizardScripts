--dois últimos fechamentos acima da mm21
--inclinação da mm21 para cima
--minima do último candle menor que a mínima dos outros dois anteriores

declare @d1 as datetime = '2017-1-30', @d2 as datetime = '2017-2-6', @d3 as datetime = '2017-2-13'

select c3.codigo, c3.candle, c3.distancia
from 
(
	select Codigo, ValorMinimo
	FROM Cotacao_Semanal
	WHERE Data = @d1

) as c1
inner join 
(
	select C.Codigo, ValorMinimo, m.Valor
	FROM Cotacao_Semanal C INNER JOIN Media_Semanal M ON C.Codigo = M.Codigo AND C.Data = M.Data AND M.Tipo = 'MMA' AND M.NumPeriodos = 21
	WHERE C.Data = @d2
	AND C.ValorFechamento > M.Valor
) as c2
ON c1.codigo = c2.codigo
inner join
(
	select C.Codigo, ValorMinimo, m21.Valor, 
	ROUND((C.ValorMaximo / M21.Valor - 1) * 10, 3)  AS distancia,
	CASE WHEN C.valorfechamento > (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2)) THEN 'COMPRADOR' ELSE 'VENDEDOR' END AS candle
	FROM Cotacao_Semanal C 
	INNER JOIN Media_Semanal M21 ON C.Codigo = M21.Codigo AND C.Data = M21.Data AND M21.Tipo = 'MMA' AND M21.NumPeriodos = 21
	INNER JOIN Media_Semanal M10 ON C.Codigo = M10.Codigo AND C.Data = M10.Data AND M10.Tipo = 'MMA' AND M10.NumPeriodos = 10
	WHERE C.Data = @d3
	AND C.Titulos_Total >= 500000
	AND C.Valor_Total >= 5000000
	AND C.Negocios_Total >= 500
	AND C.ValorFechamento > M21.Valor
	--FECHOU ACIMA DA METADE DA AMPLITUDE
	--AND C.valorfechamento > (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2)) 
	AND NOT M21.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo
	AND NOT M10.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo
) as c3

ON c3.codigo = c2.codigo

where c3.ValorMinimo < c1.ValorMinimo --|menor mínima dos últimos 3 períodos
and c3.ValorMinimo < c2.ValorMinimo	  --|
and c2.Valor < c3.Valor --média ascedente

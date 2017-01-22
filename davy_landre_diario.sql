--dois últimos fechamentos acima da mm21
--inclinação da mm21 para cima
--minima do último candle menor que a mínima dos outros dois anteriores

declare @d1 as datetime = '2017-1-18', @d2 as datetime = '2017-1-19', @d3 as datetime = '2017-1-20'

select c3.codigo
from 
(
	select Codigo, ValorMinimo
	FROM Cotacao 
	WHERE Data = @d1

) as c1
inner join 
(
	select C.Codigo, ValorMinimo, m.Valor
	FROM Cotacao C INNER JOIN Media_Diaria M ON C.Codigo = M.Codigo AND C.Data = M.Data AND M.Tipo = 'MMA' AND M.NumPeriodos = 21
	WHERE C.Data = @d2
	AND C.ValorFechamento > M.Valor
) as c2
ON c1.codigo = c2.codigo
inner join
(
	select C.Codigo, ValorMinimo, M21.Valor
	FROM Cotacao C 
	INNER JOIN Media_Diaria M21 ON C.Codigo = M21.Codigo AND C.Data = M21.Data AND M21.Tipo = 'MMA' AND M21.NumPeriodos = 21
	INNER JOIN Media_Diaria M10 ON C.Codigo = M10.Codigo AND C.Data = M10.Data AND M10.Tipo = 'MMA' AND M10.NumPeriodos = 10
	WHERE C.Data = @d3
	AND C.Titulos_Total >= 100000
	AND C.Valor_Total >= 1000000
	AND C.Negocios_Total >= 100
	AND C.ValorFechamento > M21.Valor
	AND NOT M21.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo
	AND NOT M10.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo
) as c3

ON c3.codigo = c2.codigo

where c3.ValorMinimo < c1.ValorMinimo --|menor mínima dos últimos 3 períodos
and c3.ValorMinimo < c2.ValorMinimo	  --|
and c2.Valor < c3.Valor --média ascedente

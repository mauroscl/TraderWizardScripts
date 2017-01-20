--dois �ltimos fechamentos acima da mm21
--inclina��o da mm21 para cima
--minima do �ltimo candle menor que a m�nima dos outros dois anteriores

declare @d1 as datetime = '2017-1-2', @d2 as datetime = '2017-1-9', @d3 as datetime = '2017-1-16'

select c3.codigo
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
	select C.Codigo, ValorMinimo, m21.Valor
	FROM Cotacao_Semanal C 
	INNER JOIN Media_Semanal M21 ON C.Codigo = M21.Codigo AND C.Data = M21.Data AND M21.Tipo = 'MMA' AND M21.NumPeriodos = 21
	INNER JOIN Media_Semanal M10 ON C.Codigo = M10.Codigo AND C.Data = M10.Data AND M10.Tipo = 'MMA' AND M10.NumPeriodos = 10
	WHERE C.Data = @d3
	AND C.ValorFechamento > M21.Valor
	AND NOT M21.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo
	AND NOT M10.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo
) as c3

ON c3.codigo = c2.codigo

where c3.ValorMinimo < c1.ValorMinimo --|menor m�nima dos �ltimos 3 per�odos
and c3.ValorMinimo < c2.ValorMinimo	  --|
and c2.Valor < c3.Valor --m�dia ascedente

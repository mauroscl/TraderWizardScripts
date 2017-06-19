--dois últimos fechamentos acima da mm21
--inclinação da mm21 para cima
--minima do último candle menor que a mínima dos outros dois anteriores

declare @d1 as datetime = '2017-6-13', @d2 as datetime = '2017-6-14', @d3 as datetime = '2017-6-16',
@percentualMinimoVolume as float = 0.8, @percentualDesejadoVolume as float = 1.0


select c3.codigo, c3.candle, c3.distancia, c3.percentual_candle
from 
(	
	select Codigo, ValorMinimo
	FROM Cotacao 
	WHERE Data = @d1

) as c1
inner join 
(
	select C.Codigo, C.ValorMinimo, m.Valor, c.Titulos_Total
	FROM Cotacao C INNER JOIN Media_Diaria M ON C.Codigo = M.Codigo AND C.Data = M.Data AND M.Tipo = 'MMA' AND M.NumPeriodos = 21
	WHERE C.Data = @d2
	AND C.ValorFechamento > M.Valor
) as c2
ON c1.codigo = c2.codigo
inner join
(
	select C.Codigo, C.ValorMinimo, M21.Valor,
	ROUND((C.ValorMaximo / M21.Valor - 1) * 10, 3)  AS distancia,
	CASE WHEN C.valorfechamento > (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2)) THEN 'COMPRADOR' ELSE 'VENDEDOR' END AS candle,
	c.Titulos_Total, c.Titulos_Total / MVOL.Valor as percentual_volume,
	((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle
	FROM Cotacao C 
	INNER JOIN Media_Diaria M21 ON C.Codigo = M21.Codigo AND C.Data = M21.Data AND M21.Tipo = 'MMA' AND M21.NumPeriodos = 21
	INNER JOIN Media_Diaria M10 ON C.Codigo = M10.Codigo AND C.Data = M10.Data AND M10.Tipo = 'MMA' AND M10.NumPeriodos = 10
	inner join Media_Diaria MVOL on c.Codigo = MVOL.Codigo and c.Data = MVOL.Data and MVOL.Tipo = 'VMA' AND MVOL.NumPeriodos = 21

	WHERE C.Data = @d3
	AND C.Titulos_Total >= 100000
	AND C.Valor_Total >= 1000000
	AND C.Negocios_Total >= 100
	AND C.ValorFechamento > M21.Valor
	--FECHOU ACIMA DA METADE DA AMPLITUDE
	--AND C.valorfechamento > (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2)) 
	AND NOT M21.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo
	AND NOT M10.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo

	--VOLUME MAIOR OU IGUAL A 80% DA MÉDIA DO VOLUME
	AND c.Titulos_Total / MVOL.Valor >= @percentualMinimoVolume

) as c3

ON c3.codigo = c2.codigo

where c3.ValorMinimo < c1.ValorMinimo --|menor mínima dos últimos 3 períodos
and c3.ValorMinimo < c2.ValorMinimo	  --|
and c2.Valor < c3.Valor --média ascedente

--TERCEIRO CANDLE TEM MAIOR VOLUME QUE O CANDLE ANTERIOR OU ESTÁ PELO MENOS NA MÉDIA DO VOLUME
AND (C3.percentual_volume  >= @percentualDesejadoVolume OR C3.Titulos_Total >= C2.Titulos_Total OR C3.percentual_candle >= 0.75)


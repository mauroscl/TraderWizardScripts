--dois últimos fechamentos acima da mm21
--inclinação da mm21 para cima
--minima do último candle menor que a mínima dos outros dois anteriores

declare @d1 as datetime = '2018-1-8', @d2 as datetime = '2018-1-15', @d3 as datetime = '2018-1-22',
@percentualMinimoVolume as float = 0.8, @percentualDesejadoVolume as float = 1.0

select c3.codigo, C3.percentual_candle, C3.percentual_volume,
ROUND((c3.ValorMaximo  * (1 + c3.Volatilidade * 1.25 / 100) / c3.MM21 - 1) * 100, 3) / 10 / c3.Volatilidade AS distancia,
c3.ValorMinimo, c3.ValorMaximo, c3.Volatilidade
from 
(
	select Codigo, ValorMinimo
	FROM Cotacao_Semanal
	WHERE Data = @d1

) as c1
inner join 
(
	select C.Codigo, ValorMinimo, ValorMaximo, m.Valor as MM21, c.Titulos_Total
	FROM Cotacao_Semanal C INNER JOIN Media_Semanal M ON C.Codigo = M.Codigo AND C.Data = M.Data AND M.Tipo = 'MMA' AND M.NumPeriodos = 21
	WHERE C.Data = @d2
	AND C.ValorFechamento > M.Valor
) as c2
ON c1.codigo = c2.codigo
inner join
(
	select C.Codigo, ValorMinimo, ValorMaximo, m21.Valor AS MM21, 
	ROUND((C.ValorMaximo / M21.Valor - 1) * 100, 3)  AS distancia,
	c.Titulos_Total, c.Titulos_Total / MVOL.Valor as percentual_volume,
	((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle, dbo.MaxValue(VD.Valor, MVD.Valor) AS Volatilidade

	FROM Cotacao_Semanal C 
	INNER JOIN Media_Semanal M21 ON C.Codigo = M21.Codigo AND C.Data = M21.Data AND M21.Tipo = 'MMA' AND M21.NumPeriodos = 21
	INNER JOIN Media_Semanal M10 ON C.Codigo = M10.Codigo AND C.Data = M10.Data AND M10.Tipo = 'MMA' AND M10.NumPeriodos = 10
	inner join Media_Semanal MVOL on c.Codigo = MVOL.Codigo and c.Data = MVOL.Data and MVOL.Tipo = 'VMA' AND MVOL.NumPeriodos = 21
	INNER JOIN VolatilidadeSemanal VD ON C.Codigo = VD.Codigo AND C.DATA = VD.Data
	LEFT JOIN MediaVolatilidadeSemanal MVD ON C.Codigo = MVD.Codigo AND C.DATA = MVD.Data

	WHERE C.Data = @d3
	AND C.Titulos_Total >= 500000
	AND C.Valor_Total >= 5000000
	AND C.Negocios_Total >= 500
	AND C.ValorFechamento > M21.Valor
	AND NOT M21.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo
	AND NOT M10.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo

	--VOLUME MAIOR OU IGUAL A 80% DA MÉDIA DO VOLUME
	AND c.Titulos_Total / MVOL.Valor >= @percentualMinimoVolume
	--FECHOU ACIMA DA METADE DA AMPLITUDE
	AND C.valorfechamento > (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2))

	--amplitude do candle maior que 10% da volatilidade
	AND (C.ValorMaximo / C.ValorMinimo -1 ) >= dbo.MinValue(VD.Valor, MVD.Valor) / 10

) as c3

ON c3.codigo = c2.codigo

where c3.ValorMinimo < c1.ValorMinimo --|menor mínima dos últimos 3 períodos
and c3.ValorMinimo < c2.ValorMinimo	  --|
and c2.MM21 < c3.MM21 --média ascedente

--distância do ponto de entrada para a média de 21 nao é mais do que 2,5 x a volatilidade
AND ROUND((c3.ValorMaximo  * (1 + c3.Volatilidade * 1.25 / 100) / c3.MM21 - 1) * 100, 3) / 10 / c3.Volatilidade <= 2.5

--amplitude do candle maior que a amplitude do candle anterior
--AND (C3.ValorMaximo - C3.ValorMinimo) > (C2.ValorMaximo - C2.ValorMinimo)

--TERCEIRO CANDLE TEM MAIOR VOLUME QUE O CANDLE ANTERIOR OU ESTÁ PELO MENOS NA MÉDIA DO VOLUME
--AND (C3.percentual_volume  >= @percentualDesejadoVolume OR C3.Titulos_Total >= C2.Titulos_Total OR C3.percentual_candle >= 0.75)


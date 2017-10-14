--dois últimos fechamentos acima da mm21
--inclinação da mm21 para cima
--minima do último candle menor que a mínima dos outros dois anteriores

declare @d1 as datetime = '2017-10-17', @d2 as datetime = '2017-10-18', @d3 as datetime = '2017-10-19',
@percentualMinimoVolume as float = 0.8--, @percentualDesejadoVolume as float = 1.0

select c3.codigo, C3.percentual_candle, C3.percentual_volume,
ROUND((c3.ValorMaximo  * (1 + c3.Volatilidade * 1.25 / 100) / c3.MM21 - 1) * 100, 3) / 10 / c3.Volatilidade AS distancia,
c3.ValorMinimo
from 
(
	select Codigo, ValorMinimo
	FROM Cotacao
	WHERE Data = @d1

) as c1
inner join 
(
	select C.Codigo, ValorMinimo, ValorMaximo, m.Valor as MM21, c.Titulos_Total
	FROM Cotacao C INNER JOIN Media_Diaria M ON C.Codigo = M.Codigo AND C.Data = M.Data AND M.Tipo = 'MMA' AND M.NumPeriodos = 21
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

	FROM Cotacao C 
	INNER JOIN Media_Diaria M21 ON C.Codigo = M21.Codigo AND C.Data = M21.Data AND M21.Tipo = 'MMA' AND M21.NumPeriodos = 21
	INNER JOIN Media_Diaria M10 ON C.Codigo = M10.Codigo AND C.Data = M10.Data AND M10.Tipo = 'MMA' AND M10.NumPeriodos = 10
	inner join Media_Diaria MVOL on c.Codigo = MVOL.Codigo and c.Data = MVOL.Data and MVOL.Tipo = 'VMA' AND MVOL.NumPeriodos = 21
	INNER JOIN VolatilidadeDiaria VD ON C.Codigo = VD.Codigo AND C.DATA = VD.Data
	LEFT JOIN MediaVolatilidadeDiaria MVD ON C.Codigo = MVD.Codigo AND C.DATA = MVD.Data

	WHERE C.Data = @d3
	AND C.Titulos_Total >= 100000
	AND C.Valor_Total >= 1000000
	AND C.Negocios_Total >= 100
	AND C.ValorFechamento > M21.Valor
	--AND C.valorfechamento > (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2)) 
	AND NOT M21.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo
	AND NOT M10.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo

	--VOLUME MAIOR OU IGUAL A 80% DA MÉDIA DO VOLUME
	AND c.Titulos_Total / MVOL.Valor >= @percentualMinimoVolume
	--FECHOU ACIMA DA METADE DA AMPLITUDE
	AND C.valorfechamento > (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2))
) as c3

ON c3.codigo = c2.codigo

where c3.ValorMinimo < c1.ValorMinimo --|menor mínima dos últimos 3 períodos
and c3.ValorMinimo < c2.ValorMinimo	  --|
and c2.MM21 < c3.MM21 --média ascedente

--amplitude do candle maior que a amplitude do candle anterior
--AND (C3.ValorMaximo - C3.ValorMinimo) > (C2.ValorMaximo - C2.ValorMinimo)

--amplitude do candle maior que 10% da volatilidade
AND c3.ValorMaximo / c3.ValorMinimo - 1 > c3.Volatilidade / 10

--TERCEIRO CANDLE TEM MAIOR VOLUME QUE O CANDLE ANTERIOR OU ESTÁ PELO MENOS NA MÉDIA DO VOLUME
--AND (C3.percentual_volume  >= @percentualDesejadoVolume OR C3.Titulos_Total >= C2.Titulos_Total OR C3.percentual_candle >= 0.75)


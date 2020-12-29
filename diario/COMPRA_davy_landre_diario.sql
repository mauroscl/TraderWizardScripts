--dois últimos fechamentos acima da mm21
--inclinação da mm21 para cima
--minima do último candle menor que a mínima dos outros dois anteriores

declare @d1 as datetime = '2020-12-17', @d2 as datetime = '2020-12-18', @d3 as datetime = '2020-12-21',
@percentualMinimoVolume as float = 0.8--, @percentualDesejadoVolume as float = 1.0

select c3.codigo, C3.percentual_candle, C3.percentual_volume,
ROUND((c3.ValorMaximo  * (1 + c3.Volatilidade * 1.5 / 100) / c3.MM21 - 1) * 100, 3) / 10 / c3.Volatilidade AS distancia,
c3.ValorMinimo, c3.ValorMaximo, c3.MM21, c3.Volatilidade
from 
(
	select Codigo, ValorMinimo
	FROM Cotacao
	WHERE Data = @d1

) as c1
inner join 
(
	select C.Codigo, ValorMinimo, ValorMaximo, ROUND(m.Valor, 2) as MM21, c.Titulos_Total
	FROM Cotacao C INNER JOIN Media_Diaria M ON C.Codigo = M.Codigo AND C.Data = M.Data AND M.Tipo = 'MMA' AND M.NumPeriodos = 21
	WHERE C.Data = @d2
	AND C.ValorFechamento > M.Valor
) as c2
ON c1.codigo = c2.codigo
inner join
(
	select C.Codigo, ValorMinimo, ValorMaximo, ROUND(m21.Valor, 2) AS MM21, 
	ROUND((C.ValorMaximo / M21.Valor - 1) * 100, 3)  AS distancia,
	c.Titulos_Total, c.Titulos_Total / MVOL.Valor as percentual_volume,
	((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle, dbo.MaxValue(VD.Valor, MVD.Valor) AS Volatilidade

	FROM Cotacao C 
	INNER JOIN Media_Diaria M21 ON C.Codigo = M21.Codigo AND C.Data = M21.Data AND M21.Tipo = 'MMA' AND M21.NumPeriodos = 21
	INNER JOIN Media_Diaria M10 ON C.Codigo = M10.Codigo AND C.Data = M10.Data AND M10.Tipo = 'MMA' AND M10.NumPeriodos = 10
	inner join Media_Diaria MVOL on c.Codigo = MVOL.Codigo and c.Data = MVOL.Data and MVOL.Tipo = 'VMA' AND MVOL.NumPeriodos = 21
	inner join MediaNegociosDiaria MND on c.Codigo = MND.Codigo and c.Data = MND.Data
	INNER JOIN VolatilidadeDiaria VD ON C.Codigo = VD.Codigo AND C.DATA = VD.Data
	LEFT JOIN MediaVolatilidadeDiaria MVD ON C.Codigo = MVD.Codigo AND C.DATA = MVD.Data

	WHERE C.Data = @d3
	AND MVOL.Valor >= 100000
	AND C.Valor_Total >= 1000000
	AND MND.Valor >= 100
	AND C.ValorMinimo > M10.Valor
	AND C.ValorMinimo > M21.Valor

	--VOLUME MAIOR OU IGUAL A 80% DA MÉDIA DO VOLUME
	AND c.Titulos_Total / MVOL.Valor >= @percentualMinimoVolume
	AND c.Negocios_Total / MND.Valor >= @percentualMinimoVolume

	--FECHOU ACIMA DA METADE DA AMPLITUDE
	--AND C.valorfechamento > (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2))

	--amplitude do candle maior que 10% da volatilidade
	--AND (C.ValorMaximo / C.ValorMinimo -1 ) >= dbo.MinValue(VD.Valor, MVD.Valor) / 10

) as c3

ON c3.codigo = c2.codigo

where c3.ValorMinimo < c1.ValorMinimo --|menor mínima dos últimos 3 períodos
and c3.ValorMinimo < c2.ValorMinimo	  --|
and c3.MM21 > c2.MM21 --média ascendente

--distância do ponto de entrada para a média de 21 nao é mais do que 2,5 x a volatilidade
AND ROUND(ABS((c3.ValorMaximo * (1 + c3.Volatilidade * 1.5 / 100) / c3.MM21 - 1)) * 100, 3) / 10 / c3.Volatilidade <= 2.5

--amplitude do candle maior que a amplitude do candle anterior
--AND (C3.ValorMaximo - C3.ValorMinimo) > (C2.ValorMaximo - C2.ValorMinimo)


--TERCEIRO CANDLE TEM MAIOR VOLUME QUE O CANDLE ANTERIOR OU ESTÁ PELO MENOS NA MÉDIA DO VOLUME
--AND (C3.percentual_volume  >= @percentualDesejadoVolume OR C3.Titulos_Total >= C2.Titulos_Total OR C3.percentual_candle >= 0.75)


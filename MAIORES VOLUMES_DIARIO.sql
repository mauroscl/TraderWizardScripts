declare @dataAnterior as datetime = '2017-6-29', @dataAtual as datetime = '2017-6-30',
@percentualMinimoVolume as float = 1.0, @percentualDesejadoVolume as float = 1.2

SELECT P2.Codigo, P2.Titulos_Total, P1.percentual_volume AS PercentualVolume1, p1.percentual_candle as PercentualCandle1, 
P2.percentual_volume as PercentualVolume2, p2.percentual_candle as PercentualCandle2 , P2.distancia
FROM
(
	SELECT C.Codigo, C.ValorMinimo, C.ValorMaximo, C.Titulos_Total, (C.Titulos_Total  / M.Valor) as percentual_volume,
	((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle
	FROM Cotacao C
	INNER JOIN Media_Diaria M ON C.Codigo = M.Codigo AND  C.Data = M.Data AND M.Tipo = 'VMA' AND M.NumPeriodos = 21
	WHERE C.Data = @dataAnterior
) as P1
INNER JOIN
(
	SELECT C.Codigo, C.ValorMinimo, C.ValorMaximo, C.Titulos_Total,(C.Titulos_Total  / M.Valor) as percentual_volume,
	((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle, 
	ROUND((C.ValorMaximo / M21.Valor - 1) * 10, 3)  AS distancia
	FROM COTACAO C
	INNER JOIN Media_Diaria M ON C.Codigo = M.Codigo AND  C.Data = M.Data AND M.Tipo = 'VMA' AND M.NumPeriodos = 21
	INNER JOIN Media_Diaria M21 ON C.Codigo = M21.Codigo AND  C.Data = M21.Data AND M21.Tipo = 'MMA' AND M21.NumPeriodos = 21
	INNER JOIN IFR_Diario IFR2 ON C.Codigo = IFR2.Codigo AND C.DATA = IFR2.Data AND IFR2.NumPeriodos = 2
	INNER JOIN IFR_Diario IFR14 ON C.Codigo = IFR14.Codigo AND C.DATA = IFR14.Data AND IFR14.NumPeriodos = 14

	WHERE C.DATA = @dataAtual
	AND M.Valor >= 100000
	AND C.Negocios_Total >= 100
	AND C.Valor_Total >= 1000000
	AND ((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) >= 0.75
	--AND ((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) <= 0.25
	AND C.Titulos_Total / M.Valor  >= @percentualMinimoVolume

	AND IFR2.Valor < 98
	AND IFR14.Valor < 75

) AS P2
ON P1.Codigo = P2.Codigo
WHERE NOT ((P2.ValorMinimo BETWEEN P1.ValorMinimo AND P1.ValorMaximo) AND (P2.ValorMaximo BETWEEN P1.ValorMinimo AND P1.ValorMaximo))  
AND (P2.percentual_volume  >= @percentualDesejadoVolume OR (p1.percentual_volume >= @percentualMinimoVolume AND P1.percentual_candle >= 0.5))
ORDER BY P2.percentual_volume DESC





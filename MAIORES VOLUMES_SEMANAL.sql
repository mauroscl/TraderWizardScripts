declare @dataAnterior as datetime = '2017-6-19', @dataAtual as datetime = '2017-6-26',
@percentualMinimoVolume as float = 1.0, @percentualDesejadoVolume as float = 1.2

SELECT P2.Codigo, P2.Titulos_Total, P2.percentual_volume, P2.distancia
FROM
(
	SELECT C.Codigo, C.Titulos_Total, C.ValorMinimo, C.ValorMaximo, (C.Titulos_Total  / M.Valor) as percentual_volume,
	((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle
	FROM Cotacao_Semanal C
	INNER JOIN Media_Semanal M ON C.Codigo = M.Codigo AND  C.Data = M.Data AND M.Tipo = 'VMA' AND M.NumPeriodos = 21
	WHERE C.Data = @dataAnterior
) as P1
INNER JOIN
(
	SELECT C.Codigo, C.Titulos_Total, C.ValorMinimo, C.ValorMaximo,  (C.Titulos_Total / M.Valor) as percentual_volume, ROUND((C.ValorMaximo / M21.Valor - 1) * 10, 3)  AS distancia
	FROM Cotacao_Semanal C 
	INNER JOIN Media_Semanal M ON C.Codigo = M.Codigo AND  C.Data = M.Data AND M.Tipo = 'VMA' AND M.NumPeriodos = 21
	INNER JOIN Media_Semanal M21 ON C.Codigo = M21.Codigo AND  C.Data = M21.Data AND M21.Tipo = 'MMA' AND M21.NumPeriodos = 21
	INNER JOIN IFR_Semanal IFR2 ON C.Codigo = IFR2.Codigo AND C.DATA = IFR2.Data AND IFR2.NumPeriodos = 2
	INNER JOIN IFR_Semanal IFR14 ON C.Codigo = IFR14.Codigo AND C.DATA = IFR14.Data AND IFR14.NumPeriodos = 14
	WHERE C.DATA = @dataAtual
	AND C.Negocios_Total >= 500
	AND C.Titulos_Total >= 500000
	AND C.Valor_Total >= 5000000
	AND ((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) >= 0.75
	AND C.Titulos_Total / M.Valor  >= 1
	AND IFR2.Valor < 98
	AND IFR14.Valor < 75
) AS P2
ON P1.Codigo = P2.Codigo
WHERE NOT ((P2.ValorMinimo BETWEEN P1.ValorMinimo AND P1.ValorMaximo) AND (P2.ValorMaximo BETWEEN P1.ValorMinimo AND P1.ValorMaximo)) 
AND (P2.percentual_volume  >= @percentualDesejadoVolume OR (p1.percentual_volume >= @percentualMinimoVolume AND P1.percentual_candle >= 0.5))

ORDER BY P2.percentual_volume DESC

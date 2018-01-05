declare @dataAnterior as datetime = '2017-12-26', @dataAtual as datetime = '2018-1-2',
@percentualMinimoVolume as float = 1.0, @percentualDesejadoVolume as float = 1.2

SELECT P2.Codigo, P2.Titulos_Total, P1.percentual_volume AS PercentualVolume1, p1.percentual_candle as PercentualCandle1, 
P2.percentual_volume_quantidade as PercentualVolume2, p2.percentual_candle as PercentualCandle2, p2.percentual_volume_negocios,
ROUND((P2.ValorMaximo  * (1 + P2.Volatilidade * 1.25 / 100) / P2.MM21 - 1) * 100, 3) / 10 / P2.Volatilidade AS distancia,
P2.ValorMinimo, P2.ValorMaximo, P2.MM21, P2.volatilidade
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
	SELECT C.Codigo, C.Titulos_Total, C.ValorMinimo, C.ValorMaximo, M21.Valor as MM21, 
	(C.Titulos_Total / M.Valor) as percentual_volume_quantidade,
	C.Negocios_Total / MNS.Valor as percentual_volume_negocios,
	((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle, 
	dbo.MaxValue(VD.Valor, MVD.Valor) AS Volatilidade
	FROM Cotacao_Semanal C 
	INNER JOIN Media_Semanal M ON C.Codigo = M.Codigo AND  C.Data = M.Data AND M.Tipo = 'VMA' AND M.NumPeriodos = 21
	INNER JOIN MediaNegociosSemanal MNS ON C.Codigo = MNS.Codigo AND C.Data = MNS.Data
	INNER JOIN Media_Semanal M21 ON C.Codigo = M21.Codigo AND  C.Data = M21.Data AND M21.Tipo = 'MMA' AND M21.NumPeriodos = 21
	INNER JOIN IFR_Semanal IFR2 ON C.Codigo = IFR2.Codigo AND C.DATA = IFR2.Data AND IFR2.NumPeriodos = 2
	INNER JOIN IFR_Semanal IFR14 ON C.Codigo = IFR14.Codigo AND C.DATA = IFR14.Data AND IFR14.NumPeriodos = 14
	INNER JOIN VolatilidadeSemanal VD ON C.Codigo = VD.Codigo AND C.DATA = VD.Data
	LEFT JOIN MediaVolatilidadeSemanal MVD ON C.Codigo = MVD.Codigo AND C.DATA = MVD.Data
	WHERE C.DATA = @dataAtual
	AND C.Negocios_Total >= 500
	AND C.Titulos_Total >= 500000
	AND C.Valor_Total >= 5000000
	AND ((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) >= 0.75
	AND (C.ValorMinimo + ((C.ValorMaximo - C.ValorMinimo) / 2)) > M21.Valor
	AND C.Titulos_Total / M.Valor  >= 1
	AND C.Negocios_Total / MNS.Valor >= 1
	AND IFR2.Valor < 99
	AND IFR14.Valor < 75
	AND (C.ValorMaximo / C.ValorMinimo -1 ) >= dbo.MinValue(VD.Valor, MVD.Valor) / 10
) AS P2
ON P1.Codigo = P2.Codigo
WHERE NOT ((P2.ValorMinimo BETWEEN P1.ValorMinimo AND P1.ValorMaximo) AND (P2.ValorMaximo BETWEEN P1.ValorMinimo AND P1.ValorMaximo)) 
AND ( dbo.MaxValue(P2.percentual_volume_quantidade, p2.percentual_volume_negocios)  >= @percentualDesejadoVolume OR (p1.percentual_volume >= @percentualMinimoVolume AND P1.percentual_candle >= 0.5))

ORDER BY P2.percentual_volume_quantidade DESC

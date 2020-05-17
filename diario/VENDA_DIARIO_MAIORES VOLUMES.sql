declare @dataAnterior as datetime = '2020-5-14', @dataAtual as datetime = '2020-5-15',
@percentualMinimoVolume as float = 0.8, @percentualIntermediarioVolume as float = 1.0, @percentualDesejadoVolume as float = 1.2


SELECT P2.Codigo, P2.Titulos_Total, P1.percentual_volume_quantidade AS PercentualVolumeQuantidade1, p1.percentual_candle as PercentualCandle1, 
P2.percentual_volume_quantidade, p2.percentual_volume_negocios, p2.percentual_candle as PercentualCandle2, 
P2.distancia as distancia_mm21,
CASE WHEN ROUND(P2.MM21, 2) > ROUND(P1.MM21,2) THEN 'SUBINDO' WHEN ROUND(P2.MM21,2) = ROUND(P1.MM21, 2) THEN 'LATERAL' ELSE 'DESCENDO' END AS INCLINACAO,
ROUND(ABS((P2.ValorMinimo  * (1 + P2.Volatilidade * 1.5 / 100) / P1.ValorFechamento - 1)) * 100, 3) / 10 / P2.Volatilidade AS distancia_fechamento_anterior,
P2.ValorMinimo, P2.ValorMaximo, P2.MM21, P2.volatilidade
FROM
(
	SELECT C.Codigo, C.Titulos_Total, C.Negocios_Total, C.ValorMinimo, C.ValorMaximo, C.ValorFechamento, M21.Valor as MM21
	, (C.Titulos_Total  / M.Valor) as percentual_volume_quantidade
	, C.Negocios_Total / MND.Valor as percentual_volume_negocios
	, ((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle
	FROM Cotacao C
	INNER JOIN Media_Diaria M ON C.Codigo = M.Codigo AND  C.Data = M.Data AND M.Tipo = 'VMA' AND M.NumPeriodos = 21
	INNER JOIN Media_Diaria M21 ON C.Codigo = M21.Codigo AND  C.Data = M21.Data AND M21.Tipo = 'MMA' AND M21.NumPeriodos = 21
	INNER JOIN MediaNegociosDiaria MND on c.Codigo = MND.Codigo and c.Data = MND.Data
	WHERE C.Data = @dataAnterior
) as P1
INNER JOIN
(
	SELECT C.Codigo, C.Titulos_Total, C.Negocios_Total, C.ValorMinimo, C.ValorMaximo, M21.Valor as MM21, 
	C.Titulos_Total / M.Valor as percentual_volume_quantidade,
	C.Negocios_Total / MND.Valor as percentual_volume_negocios,
	((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle, 
	dbo.MaxValue(VD.Valor, MVD.Valor) AS Volatilidade, 
	ABS(ROUND((C.ValorMinimo * (1 - dbo.MaxValue(VD.Valor, MVD.Valor) * 1.5 / 100) / M21.Valor - 1) * 100, 3)) / 10 / dbo.MaxValue(VD.Valor, MVD.Valor) AS distancia
	FROM Cotacao C 
	INNER JOIN Media_Diaria M ON C.Codigo = M.Codigo AND  C.Data = M.Data AND M.Tipo = 'VMA' AND M.NumPeriodos = 21
	INNER JOIN Media_Diaria M21 ON C.Codigo = M21.Codigo AND  C.Data = M21.Data AND M21.Tipo = 'MMA' AND M21.NumPeriodos = 21
	INNER JOIN IFR_Diario IFR2 ON C.Codigo = IFR2.Codigo AND C.DATA = IFR2.Data AND IFR2.NumPeriodos = 2
	INNER JOIN IFR_Diario IFR14 ON C.Codigo = IFR14.Codigo AND C.DATA = IFR14.Data AND IFR14.NumPeriodos = 14
	INNER JOIN MediaNegociosDiaria MND on c.Codigo = MND.Codigo and c.Data = MND.Data
	INNER JOIN VolatilidadeDiaria VD ON C.Codigo = VD.Codigo AND C.DATA = VD.Data
	LEFT JOIN MediaVolatilidadeDiaria MVD ON C.Codigo = MVD.Codigo AND C.DATA = MVD.Data
	WHERE C.DATA = @dataAtual
	AND C.Negocios_Total >= 100
	AND C.Titulos_Total >= 100000
	AND C.Valor_Total >= 1000000
	AND ((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) <= 0.25
	AND (C.ValorMinimo + ((C.ValorMaximo - C.ValorMinimo) / 2)) < M21.Valor

	AND IFR14.Valor > 25
	AND (C.ValorMaximo / C.ValorMinimo -1 ) >= dbo.MinValue(VD.Valor, MVD.Valor) / 10
	--AND (C.Oscilacao / 100) / (dbo.MaxValue(VD.Valor, MVD.Valor) / 10) >= -1.5


) AS P2
ON P1.Codigo = P2.Codigo
WHERE NOT ((P2.ValorMinimo BETWEEN P1.ValorMinimo AND P1.ValorMaximo) AND (P2.ValorMaximo BETWEEN P1.ValorMinimo AND P1.ValorMaximo)) 
--AND P2.MM21 < P1.MM21
AND (
	(dbo.MinValue(P2.percentual_volume_quantidade, p2.percentual_volume_negocios) >= @percentualIntermediarioVolume
	AND	(
			--percentual de volume acima da média 
			dbo.MaxValue(P2.percentual_volume_quantidade, p2.percentual_volume_negocios) >= @percentualDesejadoVolume
			--ou candle anterior com volume pelo menos na média e fechando acima da metade do candle (sinal comprador)
			OR (dbo.MinValue(p1.percentual_volume_quantidade, p1.percentual_volume_negocios) >= @percentualIntermediarioVolume AND P1.percentual_candle <= 0.5)
		)
	)
	--ou volume de negócios e de ações negociadas pelo menos 30% maior que o período anterior
	OR (p2.Negocios_Total / p1.Negocios_Total >= 1.3 AND p2.Titulos_Total / p1.Titulos_Total >= 1.3)
)

--DISTANCIA PARA MÉDIA DE 21 PERÍODOS NO MÁXIMO 2.5 vezes a volatilidade
and p2.distancia <= 2.5

ORDER BY P2.percentual_volume_quantidade DESC

declare @dataAnterior as datetime = '2021-9-27', @dataAtual as datetime = '2021-10-4',
@percentualMinimoVolume as float = 0.8, @percentualIntermediarioVolume as float = 0.9


SELECT P2.Codigo, p1.percentual_candle as PercentualCandle1
, p2.percentual_candle as PercentualCandle2, 
ROUND((P2.ValorMaximo  * (1 + P2.Volatilidade * 1.5 / 100) / P1.ValorFechamento - 1) * 100, 3) / 10 / P2.Volatilidade AS distancia_fechamento_anterior,
CASE WHEN P2.MM21 > P1.MM21 THEN 'SUBINDO' WHEN P2.MM21 = P1.MM21 THEN 'LATERAL' ELSE 'DESCENDO' END AS INCLINACAO
FROM
(
	SELECT C.Codigo, C.Titulos_Total, c.Negocios_Total, C.ValorMinimo, C.ValorMaximo, C.ValorFechamento, ROUND(M21.Valor,2) as MM21,
	((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle
	FROM Cotacao_Semanal C
	INNER JOIN Media_Semanal M21 ON C.Codigo = M21.Codigo AND  C.Data = M21.Data AND M21.Tipo = 'MMA' AND M21.NumPeriodos = 21
	WHERE C.Data = @dataAnterior
	AND C.ValorFechamento < M21.Valor
) as P1
INNER JOIN
(
	SELECT C.Codigo, C.Titulos_Total, c.Negocios_Total, C.ValorMinimo, C.ValorMaximo, C.ValorFechamento, ROUND(M21.Valor, 2) as MM21, 
	((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle, 
	dbo.MaxValue(VD.Valor, MVD.Valor) AS Volatilidade,
	C.Titulos_Total / MVOL.Valor as Razao_Titulos_Media,
	C.Negocios_Total /MND.Valor as Razao_Negocios_Media
	FROM Cotacao_Semanal C 
	INNER JOIN Media_Semanal M21 ON C.Codigo = M21.Codigo AND  C.Data = M21.Data AND M21.Tipo = 'MMA' AND M21.NumPeriodos = 21
	INNER JOIN VolatilidadeSemanal VD ON C.Codigo = VD.Codigo AND C.DATA = VD.Data
	LEFT JOIN MediaVolatilidadeSemanal MVD ON C.Codigo = MVD.Codigo AND C.DATA = MVD.Data
	INNER JOIN Media_Semanal MVOL on c.Codigo = MVOL.Codigo and c.Data = MVOL.Data and MVOL.Tipo = 'VMA' AND MVOL.NumPeriodos = 21
	INNER JOIN MediaNegociosSemanal MND on c.Codigo = MND.Codigo and c.Data = MND.Data

	WHERE C.DATA = @dataAtual
	AND C.ValorFechamento > M21.Valor
	AND C.Negocios_Total >= 500
	AND C.Titulos_Total >=500000
	AND C.Valor_Total >= 5000000
	and c.ValorFechamento >= 1
	AND ((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) >= 0.7
	AND dbo.MaxValue(ABS(C.Oscilacao) / 100, C.ValorMaximo / C.ValorMinimo -1 ) >= dbo.MinValue(VD.Valor, MVD.Valor) / 10
	--AND C.Titulos_Total >= MVOL.Valor

	--AND C.Negocios_Total >= MND.Valor

) AS P2
ON P1.Codigo = P2.Codigo
WHERE P2.ValorFechamento > P1.ValorMaximo
AND ((P2.Razao_Negocios_Media >=1 AND P2.Razao_Titulos_Media >=1)
OR (P2.MM21 > P1.MM21 AND P2.Razao_Negocios_Media >= 0.65 AND P2.Razao_Titulos_Media >= 0.65)
)
ORDER BY INCLINACAO

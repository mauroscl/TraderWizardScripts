declare @dataAnterior as datetime = '2017-4-17', @dataAtual as datetime = '2017-4-24',
@percentualMinimoVolume as float = 1.0, @percentualDesejadoVolume as float = 1.2

SELECT P2.*
FROM
(
	SELECT C.Codigo, C.Titulos_Total
	FROM Cotacao_Semanal C
	WHERE C.Data = @dataAnterior
) as P1
INNER JOIN
(
	SELECT C.Codigo, C.Titulos_Total,  (C.Titulos_Total / M.Valor) as percentual_volume, ROUND((C.ValorMaximo / M21.Valor - 1) * 10, 3)  AS distancia
	FROM Cotacao_Semanal C 
	INNER JOIN Media_Semanal M ON C.Codigo = M.Codigo AND  C.Data = M.Data AND M.Tipo = 'VMA' AND M.NumPeriodos = 21
	INNER JOIN Media_Semanal M21 ON C.Codigo = M21.Codigo AND  C.Data = M21.Data AND M21.Tipo = 'MMA' AND M21.NumPeriodos = 21
	WHERE C.DATA = @dataAtual
	AND C.Negocios_Total >= 500
	AND C.Titulos_Total >= 500000
	AND C.Valor_Total >= 5000000
	AND ((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) >= 0.75
	AND C.Titulos_Total / M.Valor  >= 1
) AS P2
ON P1.Codigo = P2.Codigo
WHERE (P2.percentual_volume  >= @percentualDesejadoVolume OR p2.Titulos_Total >= p1.Titulos_Total)
ORDER BY P2.percentual_volume DESC

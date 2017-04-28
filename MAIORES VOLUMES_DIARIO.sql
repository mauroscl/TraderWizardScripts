declare @dataAnterior as datetime = '2017-4-26', @dataAtual as datetime = '2017-4-27',
@percentualMinimoVolume as float = 1.0, @percentualDesejadoVolume as float = 1.2

SELECT P2.*
FROM
(
	SELECT C.Codigo, C.Titulos_Total
	FROM Cotacao C
	WHERE C.Data = @dataAnterior
) as P1
INNER JOIN
(
	SELECT C.Codigo, C.Titulos_Total,(C.Titulos_Total  / M.Valor) as percentual_volume, ROUND((C.ValorMaximo / M21.Valor - 1) * 10, 3)  AS distancia
	FROM COTACAO C 
	INNER JOIN Media_Diaria M ON C.Codigo = M.Codigo AND  C.Data = M.Data AND M.Tipo = 'VMA' AND M.NumPeriodos = 21
	INNER JOIN Media_Diaria M21 ON C.Codigo = M21.Codigo AND  C.Data = M21.Data AND M21.Tipo = 'MMA' AND M21.NumPeriodos = 21

	WHERE C.DATA = @dataAtual
	AND M.Valor >= 100000
	AND C.Negocios_Total >= 100
	AND C.Valor_Total >= 1000000
	AND ((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) >= 0.75
	AND C.Titulos_Total / M.Valor  >= @percentualMinimoVolume
) AS P2
ON P1.Codigo = P2.Codigo
WHERE (P2.percentual_volume  >= @percentualDesejadoVolume OR p2.Titulos_Total >= p1.Titulos_Total)
ORDER BY P2.percentual_volume DESC





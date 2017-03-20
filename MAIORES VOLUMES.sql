	SELECT C.CODIGO,  (C.Titulos_Total  / M.Valor - 1) * 100, ROUND((C.ValorMaximo / M21.Valor - 1) * 10, 3)  AS distancia
	FROM COTACAO C 
	INNER JOIN Media_Diaria M ON C.Codigo = M.Codigo AND  C.Data = M.Data AND M.Tipo = 'VMA' AND M.NumPeriodos = 21
	INNER JOIN Media_Diaria M21 ON C.Codigo = M21.Codigo AND  C.Data = M21.Data AND M21.Tipo = 'MMA' AND M21.NumPeriodos = 21

	WHERE C.DATA = '2017-3-16'
	AND M.Valor >= 100000
	AND C.Negocios_Total >= 100
	AND C.Valor_Total >= 1000000
	AND ((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) >= 0.75
	AND C.Titulos_Total / M.Valor  >= 1.25
	ORDER BY C.Titulos_Total / M.Valor DESC




SELECT C.CODIGO,  (C.Titulos_Total  / M.Valor - 1) * 100, ROUND((C.ValorMaximo / M21.Valor - 1) * 10, 3)  AS distancia
FROM Cotacao_Semanal C INNER JOIN Media_Semanal M ON C.Codigo = M.Codigo AND  C.Data = M.Data AND M.Tipo = 'VMA' AND M.NumPeriodos = 21
INNER JOIN Media_Semanal M21 ON C.Codigo = M21.Codigo AND  C.Data = M21.Data AND M21.Tipo = 'MMA' AND M21.NumPeriodos = 21
WHERE C.DATA = '2017-3-13'
AND C.Negocios_Total >= 500
AND C.Titulos_Total >= 500000
AND C.Valor_Total >= 5000000
AND ((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) >= 0.75
AND C.Titulos_Total / M.Valor  >= 1.25
ORDER BY C.Titulos_Total / M.Valor DESC
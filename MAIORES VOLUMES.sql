SELECT C.CODIGO,  (C.Titulos_Total  / M.Valor - 1) * 100
FROM COTACAO C INNER JOIN Media_Diaria M ON C.Codigo = M.Codigo AND  C.Data = M.Data AND M.Tipo = 'VMA' AND M.NumPeriodos = 21
WHERE C.DATA = '2017-1-6'
AND M.Valor >= 100000
AND C.Negocios_Total >= 100
AND C.Valor_Total >= 1000000

ORDER BY C.Titulos_Total / M.Valor DESC




SELECT C.CODIGO,  (C.Titulos_Total  / M.Valor - 1) * 100
FROM Cotacao_Semanal C INNER JOIN Media_Semanal M ON C.Codigo = M.Codigo AND  C.Data = M.Data AND M.Tipo = 'VMA' AND M.NumPeriodos = 21
WHERE C.DATA = '2017-1-2'
AND C.Negocios_Total >= 500
AND C.Titulos_Total >= 500000
AND C.Valor_Total >= 5000000
ORDER BY C.Titulos_Total / M.Valor DESC
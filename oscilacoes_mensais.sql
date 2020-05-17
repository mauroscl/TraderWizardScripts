DECLARE @ultimo_dia_mes1 as date = '2020-3-31', @ultimo_dia_mes2 as date = '2020-4-30'


SELECT mes1.Codigo, (mes2.ValorFechamento / mes1.ValorFechamento -1) * 100
FROM 
(SELECT Codigo, ValorFechamento
FROM Cotacao
WHERE Data = @ultimo_dia_mes1
AND Titulos_Total >= 100000
AND Valor_Total >= 1000000
) as mes1
INNER JOIN 
(SELECT Codigo, ValorFechamento
FROM Cotacao
WHERE Data = @ultimo_dia_mes2
AND Titulos_Total >= 100000
AND Valor_Total >= 1000000
) as mes2
ON mes1.Codigo = mes2.Codigo
ORDER BY mes2.ValorFechamento / mes1.ValorFechamento DESC
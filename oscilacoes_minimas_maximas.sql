SELECT d.codigo, (ValorMinimo / ValorMaximo -1 ) * 100  as minimo, (ValorFechamento / ValorMaximo -1 ) * 100  as fechamento
FROM

(SELECT CODIGO, MAX(ValorMaximo)  AS ValorMaximo
FROM COTACAO
WHERE DATA >= '2020-1-1'
GROUP BY Codigo) AS MAXIMO
INNER JOIN
(SELECT Codigo, ValorMinimo, ValorFechamento
FROM Cotacao
WHERE DATA = '2020-3-18') AS D
ON MAXIMO.Codigo = D.Codigo

order by minimo


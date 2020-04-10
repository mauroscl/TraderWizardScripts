SELECT d1.codigo, (ValorMinimo / ValorFechamento -1 ) * 100  as oscilacao_maxima
FROM

(SELECT CODIGO, ValorFechamento
FROM COTACAO
WHERE DATA = '2020-3-11') AS D1
INNER JOIN
(SELECT Codigo, ValorMinimo
FROM Cotacao
WHERE DATA = '2020-3-12') AS D2
ON D1.Codigo = D2.Codigo
order by oscilacao_maxima

DECLARE @data1 as datetime = '2020-9-28', @data2 as datetime = '2020-9-29', @precisao as int = 2

SELECT SUM(CASE WHEN ROUND(P2.Valor, @precisao) > ROUND(P1.VALOR, @precisao) THEN 1 ELSE 0 END) AS SUBINDO, 
SUM(CASE WHEN ROUND(P2.Valor, @precisao) < ROUND(P1.VALOR, @precisao) THEN 1 ELSE 0 END) AS DESCENDO,
SUM(CASE WHEN ROUND(P2.Valor, @precisao) = ROUND(P1.VALOR, @precisao) THEN 1 ELSE 0 END) AS LATERAL
FROM 
(select Codigo, valor
from Media_Diaria
where data = @data1
and tipo = 'MMA'
AND NumPeriodos = 21) AS P1
INNER JOIN 
(select Codigo, valor
from Media_Diaria
where data = @data2
and tipo = 'MMA'
AND NumPeriodos = 21) AS P2
ON P1.Codigo = P2.Codigo

--média subindo
SELECT P1.Codigo AS SUBINDO
FROM 
(select Codigo, valor
from Media_Diaria
where data = @data1
and tipo = 'MMA'
AND NumPeriodos = 21) AS P1
INNER JOIN 
(select Codigo, valor
from Media_Diaria
where data = @data2
and tipo = 'MMA'
AND NumPeriodos = 21) AS P2
ON P1.Codigo = P2.Codigo
WHERE ROUND(P2.Valor, @precisao) > ROUND(P1.Valor, @precisao)


--média descendo
SELECT P1.Codigo AS DESCENDO
FROM 
(select Codigo, valor
from Media_Diaria
where data = @data1
and tipo = 'MMA'
AND NumPeriodos = 21) AS P1
INNER JOIN 
(select Codigo, valor
from Media_Diaria
where data = @data2
and tipo = 'MMA'
AND NumPeriodos = 21) AS P2
ON P1.Codigo = P2.Codigo
WHERE ROUND(P2.Valor, @precisao) < ROUND(P1.Valor, @precisao)



DECLARE @data1 as datetime = '2020-3-9', @data2 as datetime = '2020-3-16'

SELECT SUM(CASE WHEN P2.Valor > P1.VALOR THEN 1 ELSE 0 END) AS SUBINDO, SUM(CASE WHEN P2.Valor < P1.VALOR THEN 1 ELSE 0 END) AS DESCENDO
FROM 
(select Codigo, valor
from Media_Semanal
where data = @data1
and tipo = 'MMA'
AND NumPeriodos = 21) AS P1
INNER JOIN 
(select Codigo, valor
from Media_Semanal
where data = @data2
and tipo = 'MMA'
AND NumPeriodos = 21) AS P2
ON P1.Codigo = P2.Codigo

--média subindo
SELECT P1.Codigo
FROM 
(select Codigo, valor
from Media_Semanal
where data = @data1
and tipo = 'MMA'
AND NumPeriodos = 21) AS P1
INNER JOIN 
(select Codigo, valor
from Media_Semanal
where data = @data2
and tipo = 'MMA'
AND NumPeriodos = 21) AS P2
ON P1.Codigo = P2.Codigo
WHERE P2.Valor > P1.Valor


--média descendo
SELECT P1.Codigo
FROM 
(select Codigo, valor
from Media_Semanal
where data = @data1
and tipo = 'MMA'
AND NumPeriodos = 21) AS P1
INNER JOIN 
(select Codigo, valor
from Media_Semanal
where data = @data2
and tipo = 'MMA'
AND NumPeriodos = 21) AS P2
ON P1.Codigo = P2.Codigo
WHERE P2.Valor < P1.Valor

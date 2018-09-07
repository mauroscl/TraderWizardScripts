SELECT SUM(CASE WHEN P2.Valor > P1.VALOR THEN 1 ELSE 0 END) AS SUBINDO, SUM(CASE WHEN P2.Valor < P1.VALOR THEN 1 ELSE 0 END) AS DESCENDO
FROM 
(select Codigo, valor
from Media_Diaria
where data = '2018-8-15'
and tipo = 'MMA'
AND NumPeriodos = 21) AS P1
INNER JOIN 
(select Codigo, valor
from Media_Diaria
where data = '2018-8-16'
and tipo = 'MMA'
AND NumPeriodos = 21) AS P2
ON P1.Codigo = P2.Codigo


SELECT SUM(CASE WHEN P2.Valor > P1.VALOR THEN 1 ELSE 0 END) AS SUBINDO, SUM(CASE WHEN P2.Valor < P1.VALOR THEN 1 ELSE 0 END) AS DESCENDO
FROM 
(select Codigo, valor
from Media_Semanal
where data = '2018-8-6'
and tipo = 'MMA'
AND NumPeriodos = 21) AS P1
INNER JOIN 
(select Codigo, valor
from Media_Semanal
where data = '2018-8-13'
and tipo = 'MMA'
AND NumPeriodos = 21) AS P2
ON P1.Codigo = P2.Codigo


SELECT P1.Codigo
FROM 
(select Codigo, valor
from Media_Diaria
where data = '2018-8-6'
and tipo = 'MMA'
AND NumPeriodos = 21) AS P1
INNER JOIN 
(select Codigo, valor
from Media_Diaria
where data = '2018-8-7'
and tipo = 'MMA'
AND NumPeriodos = 21) AS P2
ON P1.Codigo = P2.Codigo
WHERE P2.Valor < P1.Valor


SELECT P1.Codigo
FROM 
(select Codigo, valor
from Media_Semanal
where data = '2018-7-10'
and tipo = 'MMA'
AND NumPeriodos = 21) AS P1
INNER JOIN 
(select Codigo, valor
from Media_Semanal
where data = '2018-7-16'
and tipo = 'MMA'
AND NumPeriodos = 21) AS P2
ON P1.Codigo = P2.Codigo
WHERE P2.Valor < P1.Valor

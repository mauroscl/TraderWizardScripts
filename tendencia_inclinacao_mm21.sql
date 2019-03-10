SELECT SUM(CASE WHEN P2.Valor > P1.VALOR THEN 1 ELSE 0 END) AS SUBINDO, SUM(CASE WHEN P2.Valor < P1.VALOR THEN 1 ELSE 0 END) AS DESCENDO
FROM 
(select Codigo, valor
from Media_Diaria
where data = '2019-3-7'
and tipo = 'MMA'
AND NumPeriodos = 21) AS P1
INNER JOIN 
(select Codigo, valor
from Media_Diaria
where data = '2019-3-8'
and tipo = 'MMA'
AND NumPeriodos = 21) AS P2
ON P1.Codigo = P2.Codigo


SELECT SUM(CASE WHEN P2.Valor > P1.VALOR THEN 1 ELSE 0 END) AS SUBINDO, SUM(CASE WHEN P2.Valor < P1.VALOR THEN 1 ELSE 0 END) AS DESCENDO
FROM 
(select Codigo, valor
from Media_Semanal
where data = '2019-2-18'
and tipo = 'MMA'
AND NumPeriodos = 21) AS P1
INNER JOIN 
(select Codigo, valor
from Media_Semanal
where data = '2019-2-25'
and tipo = 'MMA'
AND NumPeriodos = 21) AS P2
ON P1.Codigo = P2.Codigo


SELECT P1.Codigo
FROM 
(select Codigo, valor
from Media_Diaria
where data = '2019-3-6'
and tipo = 'MMA'
AND NumPeriodos = 21) AS P1
INNER JOIN 
(select Codigo, valor
from Media_Diaria
where data = '2019-3-7'
and tipo = 'MMA'
AND NumPeriodos = 21) AS P2
ON P1.Codigo = P2.Codigo
WHERE P2.Valor > P1.Valor


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

declare @d1 as datetime = '2020-4-13', @d2 as datetime = '2020-4-14', @d3 as datetime = '2020-4-15'
--papéis que viraram a média PARA BAIXO
SELECT P1.Codigo
FROM 
(select Codigo, valor
from Media_Diaria
where data = @d1
and tipo = 'MMA'
AND NumPeriodos = 21) AS P1
INNER JOIN 
(select Codigo, valor
from Media_Diaria
where data = @d2
and tipo = 'MMA'
AND NumPeriodos = 21) AS P2
ON P1.Codigo = P2.Codigo
INNER JOIN 
(select Codigo, valor
from Media_Diaria
where data = @d3
and tipo = 'MMA'
AND NumPeriodos = 21) AS P3
ON P2.Codigo = P3.Codigo
WHERE P2.Valor >= P1.Valor
AND P3.Valor < P2.Valor

--papéis que viraram a média PARA CIMA
SELECT P1.Codigo
FROM 
(select Codigo, valor
from Media_Diaria
where data = @d1
and tipo = 'MMA'
AND NumPeriodos = 21) AS P1
INNER JOIN 
(select Codigo, valor
from Media_Diaria
where data = @d2
and tipo = 'MMA'
AND NumPeriodos = 21) AS P2
ON P1.Codigo = P2.Codigo
INNER JOIN 
(select Codigo, valor
from Media_Diaria
where data = @d3
and tipo = 'MMA'
AND NumPeriodos = 21) AS P3
ON P2.Codigo = P3.Codigo
WHERE P2.Valor <= P1.Valor
AND P3.Valor > P2.Valor

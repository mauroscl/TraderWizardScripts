declare @d1 as datetime = '2020-9-28', @d2 as datetime = '2020-10-5', @d3 as datetime = '2020-10-13', @precisao as int = 2
--papéis que viraram a média PARA BAIXO
SELECT P1.Codigo as PARA_BAIXO
FROM 
(select Codigo, valor
from Media_Semanal
where data = @d1
and tipo = 'MMA'
AND NumPeriodos = 21) AS P1
INNER JOIN 
(select Codigo, valor
from Media_Semanal
where data = @d2
and tipo = 'MMA'
AND NumPeriodos = 21) AS P2
ON P1.Codigo = P2.Codigo
INNER JOIN 
(select Codigo, valor
from Media_Semanal
where data = @d3
and tipo = 'MMA'
AND NumPeriodos = 21) AS P3
ON P2.Codigo = P3.Codigo
WHERE ROUND(P2.Valor, @precisao) >= ROUND(P1.Valor, @precisao)
AND ROUND(P3.Valor, @precisao) < ROUND(P2.Valor, @precisao)

--papéis que viraram a média PARA CIMA
SELECT P1.Codigo AS PARA_CIMA
FROM 
(select Codigo, valor
from Media_Semanal
where data = @d1
and tipo = 'MMA'
AND NumPeriodos = 21) AS P1
INNER JOIN 
(select Codigo, valor
from Media_Semanal
where data = @d2
and tipo = 'MMA'
AND NumPeriodos = 21) AS P2
ON P1.Codigo = P2.Codigo
INNER JOIN 
(select Codigo, valor
from Media_Semanal
where data = @d3
and tipo = 'MMA'
AND NumPeriodos = 21) AS P3
ON P2.Codigo = P3.Codigo
WHERE ROUND(P2.Valor, @precisao) <= ROUND(P1.Valor, @precisao)
AND ROUND(P3.Valor, @precisao) > ROUND(P2.Valor, @precisao)

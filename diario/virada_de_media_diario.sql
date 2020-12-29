declare @d1 as datetime = '2020-10-19', @d2 as datetime = '2020-10-20', @d3 as datetime = '2020-10-21', @precisao as int = 2
--pap�is que viraram a m�dia PARA BAIXO
SELECT P1.Codigo AS PARA_BAIXO
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
WHERE ROUND(P2.Valor, @precisao) >= ROUND(P1.Valor, @precisao)
AND ROUND(P3.Valor, @precisao) < ROUND(P2.Valor, @precisao)

--pap�is que viraram a m�dia PARA CIMA
SELECT P1.Codigo AS PARA_CIMA
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
(select M.Codigo, valor
from Media_Diaria M 
INNER JOIN Cotacao C ON M.Codigo = C.Codigo AND M.Data = C.Data
where M.data = @d3
and tipo = 'MMA'
AND NumPeriodos = 21

AND C.ValorMinimo > M.Valor

) AS P3
ON P2.Codigo = P3.Codigo
WHERE ROUND(P2.Valor, @precisao) <= ROUND(P1.Valor, @precisao)
AND ROUND(P3.Valor, @precisao) > ROUND(P2.Valor, @precisao)



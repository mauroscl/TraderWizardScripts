DECLARE			
@data1 as date = '2019-3-6', @data2 as date = '2019-3-7', @data3 as date = '2019-3-8'
select p2.codigo
from 
(
	SELECT c.Codigo, c.ValorMaximo, c.ValorFechamento
	FROM Cotacao C
	WHERE C.Data = @data1
) AS p1
INNER JOIN 
(
	SELECT c.Codigo, c.ValorMaximo, c.ValorMinimo, c.ValorFechamento, M.Valor as MM21
	FROM Cotacao C
	INNER JOIN Media_Diaria M ON C.Codigo = M.Codigo AND C.Data = M.Data AND M.NumPeriodos = 21 AND M.Tipo = 'MMA'
	WHERE C.Data = @data2
) AS p2
on p1.codigo = p2.codigo
INNER JOIN 

(
SELECT c.codigo, C.ValorFechamento, C.ValorMinimo, C.ValorMaximo, M.Valor AS MM21
FROM Cotacao C INNER JOIN IFR_Diario IFR ON C.Data = IFR.Data AND C.Codigo = IFR.Codigo AND IFR.NumPeriodos = 14
INNER JOIN Media_Diaria M ON C.Codigo = M.Codigo AND C.Data = M.Data AND M.NumPeriodos = 21 AND M.Tipo = 'MMA'
AND C.Data = @data3
AND IFR.Valor <= 65

) as p3

on p2.codigo = p3.codigo
where 
(
	P2.ValorFechamento < p1.ValorMaximo
	OR (p3.MM21 - P3.ValorMaximo > P3.ValorMaximo - P3.ValorMinimo AND p2.MM21 - P2.ValorMaximo < P2.ValorMaximo - P2.ValorMinimo )
)
AND P3.ValorFechamento > P2.ValorMaximo
AND 
(
	P3.MM21 > P2.MM21 
	OR (NOT P3.MM21 BETWEEN P3.ValorMinimo AND P3.ValorMaximo AND (p3.MM21 - P3.ValorMaximo > P3.ValorMaximo - P3.ValorMinimo))
	OR (P3.ValorMaximo - P3.MM21 > P3.MM21 - P3.ValorMinimo ))


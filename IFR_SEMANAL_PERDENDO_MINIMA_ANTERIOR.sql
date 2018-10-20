DECLARE 
@data1 as date = '2018-9-3', @data2 as date = '2018-9-10', @data3 as date = '2018-9-17'
select p2.codigo
from 
(
	SELECT c.Codigo, c.ValorMinimo, c.ValorFechamento
	FROM Cotacao_Semanal C
	WHERE C.Data = @data1
) AS p1
INNER JOIN 
(
	SELECT c.Codigo, c.ValorMinimo, c.ValorFechamento
	FROM Cotacao_Semanal C
	WHERE C.Data = @data2
) AS p2
on p1.codigo = p2.codigo
INNER JOIN	

(
SELECT c.codigo, C.ValorFechamento, C.ValorMinimo
FROM Cotacao_Semanal C INNER JOIN IFR_Semanal IFR ON C.Data = IFR.Data AND C.Codigo = IFR.Codigo AND IFR.NumPeriodos = 14
INNER JOIN Media_Semanal M ON C.Codigo = M.Codigo AND C.Data = M.Data AND M.NumPeriodos = 21 AND M.Tipo = 'MMA'
AND C.Data = @data3
AND IFR.Valor >= 35
AND (C.ValorFechamento < M.Valor OR (C.ValorMinimo - M.Valor > C.ValorMaximo - C.ValorMinimo))
) as p3
on p2.codigo = p3.codigo
where P2.ValorMinimo > p1.ValorMinimo
--AND p3.ValorFechamento < p2.ValorMaximo
AND P3.ValorMinimo < P2.ValorMinimo

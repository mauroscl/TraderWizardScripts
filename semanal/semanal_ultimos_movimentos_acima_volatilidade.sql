DECLARE			
@data as date = '2019-6-10', @codigo as varchar(6) = 'tots3'

--SELECT MAX(C.DATA) AS ULTIMA_ALTA
SELECT TOP 2 C.DATA AS ULTIMA_ALTA
FROM Cotacao_Semanal C
INNER JOIN VolatilidadeSemanal V ON C.Codigo = V.Codigo AND C.DATA = V.Data
LEFT JOIN MediaVolatilidadeSemanal MV ON C.Codigo = MV.Codigo AND C.DATA = MV.Data
WHERE C.DATA <= @data
AND C.CODIGO = @codigo
--FECHOU ACIMA DA METADE DA AMPLITUDE
AND C.valorfechamento > (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2)) 
--ACIMA DA VOLATILIDADE
AND (C.ValorMaximo / C.ValorMinimo -1 ) >= dbo.MinValue(V.Valor, MV.Valor) / 10
ORDER BY C.DATA DESC


SELECT MAX(C.DATA) AS ULTIMA_BAIXA
FROM Cotacao_Semanal C
INNER JOIN VolatilidadeSemanal V ON C.Codigo = V.Codigo AND C.DATA = V.Data
LEFT JOIN MediaVolatilidadeSemanal MV ON C.Codigo = MV.Codigo AND C.DATA = MV.Data
WHERE C.DATA <= @data
AND C.CODIGO = @codigo
--FECHOU ACIMA DA METADE DA AMPLITUDE
AND C.valorfechamento < (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2)) 
--ACIMA DA VOLATILIDADE
AND (C.ValorMaximo / C.ValorMinimo -1 ) >= dbo.MinValue(V.Valor, MV.Valor) / 10



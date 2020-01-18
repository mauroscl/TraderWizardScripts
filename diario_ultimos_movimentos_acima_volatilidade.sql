DECLARE			
@data as date = '2019-6-27', @codigo as varchar(6) = 'tots3'

--SELECT MAX(C.DATA) AS ULTIMA_ALTA
SELECT TOP 3 C.DATA AS ULTIMA_ALTA
FROM COTACAO C
INNER JOIN VolatilidadeDiaria VD ON C.Codigo = VD.Codigo AND C.DATA = VD.Data
LEFT JOIN MediaVolatilidadeDiaria MVD ON C.Codigo = MVD.Codigo AND C.DATA = MVD.Data
WHERE C.DATA <= @data
AND C.CODIGO = @codigo
--FECHOU ACIMA DA METADE DA AMPLITUDE
AND C.valorfechamento > (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2)) 
--ACIMA DA VOLATILIDADE
AND (C.ValorMaximo / C.ValorMinimo -1 ) >= dbo.MinValue(VD.Valor, MVD.Valor) / 10
ORDER BY C.DATA DESC


SELECT TOP 2 C.DATA AS ULTIMA_BAIXA
FROM COTACAO C
INNER JOIN VolatilidadeDiaria VD ON C.Codigo = VD.Codigo AND C.DATA = VD.Data
LEFT JOIN MediaVolatilidadeDiaria MVD ON C.Codigo = MVD.Codigo AND C.DATA = MVD.Data
WHERE C.DATA <= @data
AND C.CODIGO = @codigo
--FECHOU ACIMA DA METADE DA AMPLITUDE
AND C.valorfechamento < (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2)) 
--ACIMA DA VOLATILIDADE
AND (C.ValorMaximo / C.ValorMinimo -1 ) >= dbo.MinValue(VD.Valor, MVD.Valor) / 10
ORDER BY C.DATA DESC


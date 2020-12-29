SELECT CODIGO, ROUND((c.ValorMaximo  * (1 + c.Volatilidade * 1.25 / 100) / c.MM21 - 1) * 100, 3) / 10 / c.Volatilidade AS distancia

FROM (

SELECT C.Codigo, C.ValorMaximo, M21.Valor AS MM21, dbo.MaxValue(VD.Valor, MVD.Valor) AS Volatilidade
	FROM Cotacao C 
	INNER JOIN Media_Diaria M21 ON C.Codigo = M21.Codigo AND C.Data = M21.Data AND M21.Tipo = 'MMA' AND M21.NumPeriodos = 21
	inner join MediaNegociosDiaria MND on c.Codigo = MND.Codigo and c.Data = MND.Data
	INNER JOIN VolatilidadeDiaria VD ON C.Codigo = VD.Codigo AND C.DATA = VD.Data
	INNER JOIN MediaVolatilidadeDiaria MVD ON C.Codigo = MVD.Codigo AND C.DATA = MVD.Data
	WHERE C.DATA = '2020-10-13'
	AND C.CODIGO IN ('ANIM3', 'BBDC4', 'BPAN4')
) AS C
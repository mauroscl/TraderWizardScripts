DECLARE @dataAtual as datetime = '2018-11-16'
SELECT atual.Codigo, c.Data, c.Oscilacao, ROUND((C.ValorMaximo  * (1 + dbo.MaxValue(VD.Valor, mvd.Valor) * 1.25 / 100) / M21.Valor - 1) * 100, 3) / 10 / dbo.MaxValue(VD.Valor, mvd.Valor) as distancia_media
FROM Cotacao atual
INNER JOIN VolatilidadeDiaria VD ON atual.Codigo = VD.Codigo AND atual.DATA = VD.Data
INNER JOIN MediaVolatilidadeDiaria MVD ON atual.Codigo = MVD.Codigo AND atual.DATA = MVD.Data
INNER JOIN Media_Diaria M21 ON atual.Codigo = M21.Codigo AND  atual.Data = M21.Data AND M21.Tipo = 'MMA' AND M21.NumPeriodos = 21
INNER JOIN
(
	SELECT C.Codigo, c.Data, C.Oscilacao, C.Sequencial, C.ValorMaximo
	FROM Cotacao C
	INNER JOIN VolatilidadeDiaria VD ON C.Codigo = VD.Codigo AND C.DATA = VD.Data
	INNER JOIN MediaVolatilidadeDiaria MVD ON C.Codigo = MVD.Codigo AND C.DATA = MVD.Data
	INNER JOIN Media_Diaria M21 ON C.Codigo = M21.Codigo AND  C.Data = M21.Data AND M21.Tipo = 'MMA' AND M21.NumPeriodos = 21
	AND (
	(C.Oscilacao / 100) / (dbo.MaxValue(VD.Valor, MVD.Valor) / 10) > 1.5
	--OR (c.Oscilacao > 0 AND		ROUND((C.ValorMaximo  * (1 + dbo.MaxValue(VD.Valor, mvd.Valor) * 1.25 / 100) / M21.Valor - 1) * 100, 3) / 10 / dbo.MaxValue(VD.Valor, mvd.Valor) > 2.5)
	)
	--NÃO SUPEROU A MÁXIMA EM COTAÇÕES POSTERIORES
	AND NOT EXISTS (
		SELECT 1
		FROM COTACAO CP
		WHERE C.Codigo = CP.Codigo
		AND CP.Data > C.Data
		AND CP.ValorFechamento > C.ValorMaximo
	)

) as C
ON atual.Codigo = c.Codigo
AND atual.Sequencial - C.Sequencial <= 6
WHERE atual.[Data] = @dataAtual
AND ROUND((C.ValorMaximo * (1 + dbo.MaxValue(VD.Valor, mvd.Valor) * 1.25 / 100) / M21.Valor - 1) * 100, 3) / 10 / dbo.MaxValue(VD.Valor, mvd.Valor) <= 2.5

order by c.Data

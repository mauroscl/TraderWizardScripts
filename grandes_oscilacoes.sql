DECLARE @dataAtual as datetime = '2018-10-19'
SELECT atual.Codigo, c.Data, c.Oscilacao
FROM Cotacao atual
INNER JOIN
(
	SELECT C.Codigo, c.Data, C.Oscilacao, C.Sequencial
	FROM Cotacao C
	INNER JOIN VolatilidadeDiaria VD ON C.Codigo = VD.Codigo AND C.DATA = VD.Data
	INNER JOIN MediaVolatilidadeDiaria MVD ON C.Codigo = MVD.Codigo AND C.DATA = MVD.Data
	AND (C.Oscilacao / 100) / (dbo.MaxValue(VD.Valor, MVD.Valor) / 10) > 1.5
) as C
ON atual.Codigo = c.Codigo
AND atual.Sequencial - C.Sequencial <= 6
WHERE atual.[Data] = @dataAtual
order by c.Data

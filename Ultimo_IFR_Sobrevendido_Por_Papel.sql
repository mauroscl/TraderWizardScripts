
SELECT IFR.CODIGO, MAX(IFR.DATA) AS DATA
FROM IFR_DIARIO IFR INNER JOIN MEDIA_DIARIA M ON IFR.CODIGO = M.Codigo AND IFR.DATA = M.DATA AND M.NumPeriodos = 21 AND M.TIPO = 'VMA'
INNER JOIN COTACAO C ON IFR.CODIGO =  C.CODIGO AND IFR.DATA = C.DATA
WHERE IFR.Valor <= 10
AND IFR.CODIGO NOT LIKE '%34'
AND M.VALOR >= 100000
AND C.Titulos_Total >=100000
GROUP BY IFR.CODIGO
ORDER BY DATA DESC


declare @dataAnterior as datetime = '2017-1-5', @dataAtual as datetime = '2017-1-6'
select sobrevendido.Codigo, Data
FROM
(SELECT IFR.CODIGO, MAX(IFR.DATA) AS DATA
FROM IFR_DIARIO IFR 
INNER JOIN COTACAO C ON IFR.CODIGO =  C.CODIGO AND IFR.DATA = C.DATA
WHERE IFR.Valor <= 10
AND IFR.CODIGO NOT LIKE '%34'
AND C.Negocios_Total >= 100
AND C.Titulos_Total >=100000
AND C.Valor_Total >= 1000000
and c.ValorFechamento >= 1
AND NOT EXISTS 
(
	select 1 
	from IFR_Diario IfrSobreComprado 
	WHERE IFR.Codigo = IfrSobreComprado.Codigo
	AND IfrSobreComprado.[Data] > IFR.[Data]
	AND IfrSobreComprado.Valor >= 90
)
AND NOT EXISTS 
(
	SELECT 1 
	FROM IfrSobrevendidoDescartadoDiario ISDD
	WHERE IFR.Codigo = ISDD.Codigo
	and ISDD.[Data] > IFR.[Data]
)
GROUP BY IFR.CODIGO) as sobrevendido INNER JOIN
(
	select p1.Codigo
	from
	(
		select c.Codigo, c.ValorMinimo, c.ValorMaximo, c.ValorFechamento
		from cotacao c
		where c.Data = @dataAnterior) as p1
		inner join
	(
		select c.Codigo, c.ValorMinimo, c.ValorMaximo, c.ValorFechamento, mm200.Valor as ValorMM200
		from cotacao c-- inner join Media_Diaria mm10 on c.Codigo = mm10.Codigo and c.Data = mm10.Data
		--inner join Media_Diaria mm21 on c.Codigo = mm21.Codigo and c.Data = mm21.Data
		left join Media_Diaria mm200 on c.Codigo = mm200.Codigo and c.Data = mm200.Data and mm200.Tipo = 'MMA' and mm200.NumPeriodos = 200

		where c.Data = @dataAtual
		and (c.ValorMaximo - c.ValorFechamento) < (c.ValorFechamento - c.ValorMinimo)
		--and mm10.Tipo = 'MMA'
		---and mm10.NumPeriodos = 10
		--and not (mm10.Valor between c.ValorMinimo and c.ValorFechamento)
		--and mm21.Tipo = 'MMA'
		--and mm21.NumPeriodos = 21
		--and not (mm21.Valor between c.ValorMinimo and c.ValorFechamento)

	) as p2
	on p1.Codigo = p2.Codigo
	where NOT ((P2.ValorMinimo BETWEEN P1.ValorMinimo AND P1.ValorMaximo) AND (P2.ValorMaximo BETWEEN P1.ValorMinimo AND P1.ValorMaximo)) 
	--n�o tem m�dia OU acima da m�dia de 200 OU fechou acima da m�xima do candle de p1
	AND (ValorMM200 IS NULL OR p2.ValorFechamento > ValorMM200 OR  P2.ValorFechamento >  P1.ValorMaximo)

) as atual on sobrevendido.Codigo = atual.Codigo
order by Data desc






SELECT IFR.CODIGO, MAX(IFR.DATA) AS DATA
FROM IFR_Semanal IFR INNER JOIN MEDIA_SEMANAL M ON IFR.CODIGO = M.Codigo AND IFR.DATA = M.DATA AND M.NumPeriodos = 21 AND M.TIPO = 'VMA'
INNER JOIN Cotacao_Semanal C ON IFR.CODIGO =  C.CODIGO AND IFR.DATA = C.DATA
WHERE IFR.Valor <= 10
AND IFR.CODIGO NOT LIKE '%34'
AND M.VALOR >= 500000
AND C.Titulos_Total >=500000
AND C.Valor_Total >= 1000000
GROUP BY IFR.CODIGO
ORDER BY DATA DESC



declare @dataAnterior as datetime = '2016-12-26', @dataAtual as datetime = '2017-1-2'
select sobrevendido.Codigo, Data
FROM
(SELECT IFR.CODIGO, MAX(IFR.DATA) AS DATA
FROM IFR_Semanal IFR 
INNER JOIN Cotacao_Semanal C ON IFR.CODIGO =  C.CODIGO AND IFR.DATA = C.DATA
WHERE IFR.Valor <= 10
AND IFR.CODIGO NOT LIKE '%34'
AND C.Titulos_Total >=500000
AND C.Valor_Total >= 5000000
AND C.Negocios_Total >= 500
and c.ValorFechamento >= 1
AND NOT EXISTS 
(
	select 1 
	from IFR_Semanal IfrSobreComprado 
	WHERE IFR.Codigo = IfrSobreComprado.Codigo
	AND IfrSobreComprado.[Data] > IFR.[Data]
	AND IfrSobreComprado.Valor >= 90
)
AND NOT EXISTS 
(
	SELECT 1 
	FROM IfrSobrevendidoDescartadoSemanal ISDS
	WHERE IFR.Codigo = ISDS.Codigo
	and ISDS.[Data] > IFR.[Data]
)

GROUP BY IFR.CODIGO) as sobrevendido INNER JOIN
(
	select p1.Codigo
	from
	(
		select c.Codigo, c.ValorMinimo, c.ValorMaximo, c.ValorFechamento
		from Cotacao_Semanal c
		where c.Data = @dataAnterior
	) as p1
	inner join
	(
		select c.Codigo, c.ValorMinimo, c.ValorMaximo, c.ValorFechamento, mm200.Valor as ValorMM200
		from Cotacao_Semanal c --inner join Media_Semanal mm10 on c.Codigo = mm10.Codigo and c.Data = mm10.Data
		--inner join Media_Semanal mm21 on c.Codigo = mm21.Codigo and c.Data = mm21.Data
		left join Media_Semanal mm200 on c.Codigo = mm200.Codigo and c.Data = mm200.Data and mm200.Tipo = 'MMA' and mm200.NumPeriodos = 200
		where c.Data = @dataAtual
		--CANDLE COMPRADOR
		and (c.ValorMaximo - c.ValorFechamento) < (c.ValorFechamento - c.ValorMinimo)
		--and mm10.Tipo = 'MMA'
		--and mm10.NumPeriodos = 10
		--N�O EST� TOCANDO A MMA 10
		--and not (mm10.Valor between c.ValorMinimo and c.ValorFechamento)
		--and mm21.Tipo = 'MMA'
		--and mm21.NumPeriodos = 21
		--N�O EST� TOCANDO A MMA 21
		--and not (mm21.Valor between c.ValorMinimo and c.ValorFechamento)

	) as p2
	on p1.Codigo = p2.Codigo
	--N�O EST� CONTIDO NO CANDLE ANTERIOR
	where NOT ((P2.ValorMinimo BETWEEN P1.ValorMinimo AND P1.ValorMaximo) AND (P2.ValorMaximo BETWEEN P1.ValorMinimo AND P1.ValorMaximo)) 
	--n�o tem m�dia OU acima da m�dia de 200 OU fechou acima da m�xima do candle de p1
	AND (ValorMM200 IS NULL OR p2.ValorFechamento > ValorMM200 OR  P2.ValorFechamento >  P1.ValorMaximo)
) as atual on sobrevendido.Codigo = atual.Codigo
order by Data desc

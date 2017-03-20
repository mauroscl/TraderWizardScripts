declare @dataAnterior as datetime = '2017-3-16', @dataAtual as datetime = '2017-3-17',
--@numPeriodos as int = 2, @valorSobrevendido as int = 10, @valorSobreComprado as int = 90
@numPeriodos as int = 14, @valorSobrevendido as int = 35, @valorSobreComprado as int = 65

select sobrevendido.Codigo, Data, atual.ValorMM21, atual.AlvoAproximado
FROM
(SELECT IFR.CODIGO, MAX(IFR.DATA) AS DATA
FROM IFR_DIARIO IFR 
INNER JOIN COTACAO C ON IFR.CODIGO =  C.CODIGO AND IFR.DATA = C.DATA
WHERE IFR.NumPeriodos = @numPeriodos
AND IFR.Valor <= @valorSobrevendido
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
	AND IfrSobreComprado.NumPeriodos = @numPeriodos
	AND IfrSobreComprado.Valor >= @valorSobreComprado
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
	select p1.Codigo, p2.ValorMM21, ROUND( (P2.ValorMaximo - P2.ValorMinimo) + P2.ValorMaximo, 2) as AlvoAproximado
	from
	(
		select c.Codigo, c.ValorMinimo, c.ValorMaximo, c.ValorFechamento
		from cotacao c
		where c.Data = @dataAnterior) as p1
		inner join
	(
		select c.Codigo, c.ValorMinimo, c.ValorMaximo, c.ValorFechamento, mm200.Valor as ValorMM200, ROUND(mm21.Valor, 2) as ValorMM21
		from cotacao c-- inner join Media_Diaria mm10 on c.Codigo = mm10.Codigo and c.Data = mm10.Data
		inner join Media_Diaria mm21 on c.Codigo = mm21.Codigo and c.Data = mm21.Data and mm21.Tipo = 'MMA' and mm21.NumPeriodos = 21
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
	--não tem média OU acima da média de 200 OU fechou acima da máxima do candle de p1
	AND (ValorMM200 IS NULL OR p2.ValorFechamento > ValorMM200 OR  P2.ValorFechamento >  P1.ValorMaximo)

) as atual on sobrevendido.Codigo = atual.Codigo
order by Data desc



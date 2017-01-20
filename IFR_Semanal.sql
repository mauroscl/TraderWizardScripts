declare @dataAnterior as datetime = '2017-1-9', @dataAtual as datetime = '2017-1-16',
--@numPeriodos as int = 14, @valorSobrevendido as int = 35, @valorSobreComprado as int = 65
@numPeriodos as int = 2, @valorSobrevendido as int = 10, @valorSobreComprado as int = 90
select sobrevendido.Codigo, Data
FROM
(SELECT IFR.CODIGO, MAX(IFR.DATA) AS DATA
FROM IFR_Semanal IFR 
INNER JOIN Cotacao_Semanal C ON IFR.CODIGO =  C.CODIGO AND IFR.DATA = C.DATA
WHERE ifr.NumPeriodos = @numPeriodos
and IFR.Valor <= @valorSobrevendido
AND IFR.CODIGO NOT LIKE '%34'
AND C.Titulos_Total >=500000
AND C.Valor_Total >= 5000000
AND C.Negocios_Total >= 500
and c.ValorFechamento >= 1
AND NOT EXISTS 
(
	select 1 
	from IFR_Semanal IfrSobreComprado 
	WHERE IFR.NumPeriodos = @numPeriodos
	AND IFR.Codigo = IfrSobreComprado.Codigo
	AND IfrSobreComprado.[Data] > IFR.[Data]
	AND IfrSobreComprado.Valor >= @valorSobreComprado
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

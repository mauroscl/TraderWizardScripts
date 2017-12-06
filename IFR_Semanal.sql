declare @dataAnterior as datetime = '2017-11-21', @dataAtual as datetime = '2017-11-27',
@percentualMinimoVolume as float = 0.8,-- @percentualDesejadoVolume as float = 1.0,

--@numPeriodos as int = 14, @valorSobrevendido as int = 35, @valorSobreComprado as int = 65
@numPeriodos as int = 2, @valorSobrevendido as int = 10, @valorSobreComprado as int = 90
select sobrevendido.Codigo, Data, atual.ValorMM21, entrada * 2 - ValorMinimo as alvo1, entrada * 2 - saida as alvo2, atual.percentual_volume, atual.percentual_candle,
atual.ValorMinimo, atual.ValorMaximo, atual.MM21, atual.Volatilidade, entrada, saida
FROM
(
	--ESTA PROJEÇÃO RETORNAR OS IFR SOBREVENDIDOS
	SELECT IFR.CODIGO, MAX(IFR.DATA) AS DATA
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
		--NÃO EXISTE IFR SOBRECOMPRADO POSTERIOR
		select 1 
		from IFR_Semanal IfrSobreComprado 
		WHERE IfrSobreComprado.NumPeriodos = @numPeriodos
		AND IFR.Codigo = IfrSobreComprado.Codigo
		AND IfrSobreComprado.[Data] > IFR.[Data]
		AND IfrSobreComprado.Valor >= @valorSobreComprado
	)
	AND NOT EXISTS 
	(
		--NAO ESTÁ DESCARTADO
		SELECT 1 
		FROM IfrSobrevendidoDescartadoSemanal ISDS
		WHERE IFR.Codigo = ISDS.Codigo
		and ISDS.[Data] >= IFR.[Data]
	)

	GROUP BY IFR.CODIGO
) as sobrevendido INNER JOIN
(
	--ESTA PROJECAO RETORNA OS ATIVOS NO ÚLTIMO PERÍODO
	select p1.Codigo, p2.ValorMM21, ROUND( (P2.ValorMaximo - P2.ValorMinimo) + P2.ValorMaximo, 2) as AlvoAproximado1, 
	ROUND((P2.ValorMaximo - P2.ValorMinimo) * 1.5 + P2.ValorMaximo, 2) as AlvoAproximado2, p2.percentual_volume, p2.percentual_candle,
	p2.ValorMinimo, p2.ValorMaximo, p2.ValorMM21 as MM21, p2.Volatilidade, entrada,
	ROUND((entrada - (entrada - p2.ValorMinimo) * 1.5) * (1 - Volatilidade * 1.25 / 100) , 2) as saida
	from
	(
		select c.Codigo, c.ValorMinimo, c.ValorMaximo, c.ValorFechamento, c.Titulos_Total
		from Cotacao_Semanal c
		where c.Data = @dataAnterior
	) as p1
	inner join
	(
		select c.Codigo, c.ValorMinimo, c.ValorMaximo, c.ValorFechamento, dbo.MaxValue(VD.Valor, MVD.Valor) AS Volatilidade,
		ROUND(mm21.Valor, 2) as ValorMM21, c.Titulos_Total, (c.Titulos_Total / mvol.Valor) as percentual_volume,
		((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle,
		ROUND(c.ValorMaximo  * (1 + dbo.MaxValue(VD.Valor, MVD.Valor) * 1.25 / 100) , 2) as entrada
		from Cotacao_Semanal c 
		--inner join Media_Semanal mm10 on c.Codigo = mm10.Codigo and c.Data = mm10.Data
		inner join Media_Semanal mm21 on c.Codigo = mm21.Codigo and c.Data = mm21.Data and mm21.Tipo = 'MMA' and mm21.NumPeriodos = 21
		inner join Media_Semanal mvol on c.Codigo = mvol.Codigo and c.Data = mvol.Data and mvol.Tipo = 'VMA' and mvol.NumPeriodos = 21
		--left join Media_Semanal mm200 on c.Codigo = mm200.Codigo and c.Data = mm200.Data and mm200.Tipo = 'MMA' and mm200.NumPeriodos = 200
		INNER JOIN VolatilidadeSemanal VD ON C.Codigo = VD.Codigo AND C.DATA = VD.Data
		LEFT JOIN MediaVolatilidadeSemanal MVD ON C.Codigo = MVD.Codigo AND C.DATA = MVD.Data

		where c.Data = @dataAtual
		--fechou acima da metade do candle
		and (c.ValorMaximo - c.ValorFechamento) < (c.ValorFechamento - c.ValorMinimo)

		and c.Titulos_Total / mvol.Valor >= @percentualMinimoVolume

		AND (C.ValorMaximo / C.ValorMinimo -1 ) >= dbo.MinValue(VD.Valor, MVD.Valor) / 10


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
	where --NOT ((P2.ValorMinimo BETWEEN P1.ValorMinimo AND P1.ValorMaximo) AND (P2.ValorMaximo BETWEEN P1.ValorMinimo AND P1.ValorMaximo)) 
	--n�o tem m�dia OU acima da m�dia de 200 OU fechou acima da m�xima do candle de p1
	--AND (ValorMM200 IS NULL OR p2.ValorFechamento > ValorMM200 OR  P2.ValorFechamento >  P1.ValorMaximo)
	--SEGUNDO CANDLE TEM MAIOR VOLUME QUE O CANDLE ANTERIOR OU ESTÁ PELO MENOS NA MÉDIA DO VOLUME
	--AND 
	
	(/*P2.percentual_volume  >= @percentualDesejadoVolume OR */ p2.percentual_candle >= 0.75 OR p2.Titulos_Total >= p1.Titulos_Total OR P2.ValorMaximo > P1.ValorMaximo)

) as atual on sobrevendido.Codigo = atual.Codigo
order by Data desc

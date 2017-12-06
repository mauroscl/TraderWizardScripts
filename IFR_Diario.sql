declare @dataAnterior as datetime = '2017-12-5', @dataAtual as datetime = '2017-12-6',
@percentualMinimoVolume as float = 0.8,-- @percentualDesejadoVolume as float = 1.0

--@numPeriodos as int = 2, @valorSobrevendido as int = 10, @valorSobreComprado as int = 90
@numPeriodos as int = 14, @valorSobrevendido as int = 35, @valorSobreComprado as int = 65

select sobrevendido.Codigo, Data, entrada * 2 - ValorMinimo as alvo1, entrada * 2 - saida as alvo2, atual.percentual_volume, atual.percentual_candle_anterior, atual.percentual_candle_atual,
atual.ValorMinimo, atual.ValorMaximo, atual.MM21, atual.VolatilidadeMaxima, entrada, saida

FROM
(SELECT IFR.CODIGO, MAX(IFR.DATA) AS DATA
FROM IFR_DIARIO IFR 
INNER JOIN COTACAO C ON IFR.CODIGO =  C.CODIGO AND IFR.DATA = C.DATA
WHERE IFR.NumPeriodos = @numPeriodos
AND IFR.Valor <= @valorSobrevendido
AND IFR.CODIGO NOT LIKE '%34'

AND NOT EXISTS 
(
	SELECT 1 
	FROM IfrSobrevendidoDescartadoDiario ISDD
	WHERE IFR.Codigo = ISDD.Codigo
	and ISDD.[Data] >= IFR.[Data]
)
GROUP BY IFR.CODIGO) as sobrevendido INNER JOIN
(
	select p1.Codigo, p2.ValorMM21, ROUND( (P2.ValorMaximo - P2.ValorMinimo) + P2.ValorMaximo, 2) as AlvoAproximado1, 
	ROUND((P2.ValorMaximo - P2.ValorMinimo) * 1.5 + P2.ValorMaximo, 2) as AlvoAproximado2, p2.percentual_volume, p1.percentual_candle as percentual_candle_anterior, p2.percentual_candle percentual_candle_atual,
	p2.ValorMinimo, p2.ValorMaximo, p2.ValorMM21 as MM21, p2.VolatilidadeMinima, p2.VolatilidadeMaxima, entrada,
	ROUND((entrada - (entrada - p2.ValorMinimo) * 1.5) * (1 - VolatilidadeMaxima * 1.25 / 100) , 2) as saida

	from
	(
		select c.Codigo, c.ValorMinimo, c.ValorMaximo, c.ValorFechamento, c.Titulos_Total,
		((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle

		from cotacao c
		where c.Data = @dataAnterior) as p1
		inner join
	(
		select c.Codigo, c.ValorMinimo, c.ValorMaximo, c.ValorFechamento, dbo.MinValue(VD.Valor, MVD.Valor) AS VolatilidadeMinima , dbo.MaxValue(VD.Valor, MVD.Valor) AS VolatilidadeMaxima,
		ROUND(mm21.Valor, 2) as ValorMM21, c.Titulos_Total, (c.Titulos_Total / mvol.Valor) as percentual_volume,
		((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle,
		ROUND(c.ValorMaximo  * (1 + dbo.MaxValue(VD.Valor, MVD.Valor) * 1.25 / 100) , 2) as entrada

		from cotacao c
		inner join Media_Diaria mm21 on c.Codigo = mm21.Codigo and c.Data = mm21.Data and mm21.Tipo = 'MMA' and mm21.NumPeriodos = 21
		inner join Media_Diaria mvol on c.Codigo = mvol.Codigo and c.Data = mvol.Data and mvol.Tipo = 'VMA' and mvol.NumPeriodos = 21
		--left join Media_Diaria mm200 on c.Codigo = mm200.Codigo and c.Data = mm200.Data and mm200.Tipo = 'MMA' and mm200.NumPeriodos = 200
		INNER JOIN VolatilidadeDiaria VD ON C.Codigo = VD.Codigo AND C.DATA = VD.Data
		LEFT JOIN MediaVolatilidadeDiaria MVD ON C.Codigo = MVD.Codigo AND C.DATA = MVD.Data

		where c.Data = @dataAtual
		--fechou acima da metade do candle
		and (c.ValorMaximo - c.ValorFechamento) < (c.ValorFechamento - c.ValorMinimo)

		and c.Titulos_Total / mvol.Valor >= @percentualMinimoVolume

		AND C.Negocios_Total >= 100
		AND C.Titulos_Total >=100000
		AND C.Valor_Total >= 1000000
		and c.ValorFechamento >= 1

		AND (C.ValorMaximo / C.ValorMinimo -1 ) >= dbo.MinValue(VD.Valor, MVD.Valor) / 10


		--and mm10.Tipo = 'MMA'
		---and mm10.NumPeriodos = 10
		--and not (mm10.Valor between c.ValorMinimo and c.ValorFechamento)
		--and mm21.Tipo = 'MMA'
		--and mm21.NumPeriodos = 21
		--and not (mm21.Valor between c.ValorMinimo and c.ValorFechamento)

	) as p2
	on p1.Codigo = p2.Codigo
	--não está contido no candle anterior
	where 
	--NOT ((P2.ValorMinimo BETWEEN P1.ValorMinimo AND P1.ValorMaximo) AND (P2.ValorMaximo BETWEEN P1.ValorMinimo AND P1.ValorMaximo)) 
	--não tem média OU acima da média de 200 OU fechou acima da máxima do candle de p1
	--AND (ValorMM200 IS NULL OR p2.ValorFechamento > ValorMM200 OR  P2.ValorFechamento >  P1.ValorMaximo)

	--SEGUNDO CANDLE TEM MAIOR VOLUME QUE O CANDLE ANTERIOR OU ESTÁ PELO MENOS NA MÉDIA DO VOLUME
	--AND (/*P2.percentual_volume  >= @percentualDesejadoVolume OR */ 
	--and 
	p2.percentual_candle >= 0.75 OR p2.Titulos_Total >= p1.Titulos_Total OR P2.ValorMaximo > P1.ValorMaximo--)


) as atual on sobrevendido.Codigo = atual.Codigo

--amplitude do candle maior que 10% da volatilidade
where atual.ValorMaximo / atual.ValorMinimo - 1 > atual.VolatilidadeMinima / 10

order by Data desc, percentual_volume desc



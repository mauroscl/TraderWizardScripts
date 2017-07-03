declare @dataAnterior as datetime = '2017-6-29', @dataAtual as datetime = '2017-6-30',
@percentualMinimoVolume as float = 0.8,-- @percentualDesejadoVolume as float = 1.0

@numPeriodos as int = 2, @valorSobrevendido as int = 10, @valorSobreComprado as int = 90
--@numPeriodos as int = 14, @valorSobrevendido as int = 35, @valorSobreComprado as int = 65

select sobrevendido.Codigo, Data, atual.ValorMM21, atual.AlvoAproximado1, atual.AlvoAproximado2, atual.percentual_volume, percentual_candle
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
	and ISDD.[Data] >= IFR.[Data]
)
GROUP BY IFR.CODIGO) as sobrevendido INNER JOIN
(
	select p1.Codigo, p2.ValorMM21, ROUND( (P2.ValorMaximo - P2.ValorMinimo) + P2.ValorMaximo, 2) as AlvoAproximado1, 
	ROUND((P2.ValorMaximo - P2.ValorMinimo) * 1.5 + P2.ValorMaximo, 2) as AlvoAproximado2, p2.percentual_volume, p2.percentual_candle
	from
	(
		select c.Codigo, c.ValorMinimo, c.ValorMaximo, c.ValorFechamento, c.Titulos_Total
		from cotacao c
		where c.Data = @dataAnterior) as p1
		inner join
	(
		select c.Codigo, c.ValorMinimo, c.ValorMaximo, c.ValorFechamento, mm200.Valor as ValorMM200, 
		ROUND(mm21.Valor, 2) as ValorMM21, c.Titulos_Total, (c.Titulos_Total / mvol.Valor) as percentual_volume,
		((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle
		from cotacao c-- inner join Media_Diaria mm10 on c.Codigo = mm10.Codigo and c.Data = mm10.Data
		inner join Media_Diaria mm21 on c.Codigo = mm21.Codigo and c.Data = mm21.Data and mm21.Tipo = 'MMA' and mm21.NumPeriodos = 21
		inner join Media_Diaria mvol on c.Codigo = mvol.Codigo and c.Data = mvol.Data and mvol.Tipo = 'VMA' and mvol.NumPeriodos = 21
		left join Media_Diaria mm200 on c.Codigo = mm200.Codigo and c.Data = mm200.Data and mm200.Tipo = 'MMA' and mm200.NumPeriodos = 200

		where c.Data = @dataAtual
		--fechou acima da metade do candle
		and (c.ValorMaximo - c.ValorFechamento) < (c.ValorFechamento - c.ValorMinimo)

		and c.Titulos_Total / mvol.Valor >= @percentualMinimoVolume
		--and mm10.Tipo = 'MMA'
		---and mm10.NumPeriodos = 10
		--and not (mm10.Valor between c.ValorMinimo and c.ValorFechamento)
		--and mm21.Tipo = 'MMA'
		--and mm21.NumPeriodos = 21
		--and not (mm21.Valor between c.ValorMinimo and c.ValorFechamento)

	) as p2
	on p1.Codigo = p2.Codigo
	--não está contido no candle anterior
	where NOT ((P2.ValorMinimo BETWEEN P1.ValorMinimo AND P1.ValorMaximo) AND (P2.ValorMaximo BETWEEN P1.ValorMinimo AND P1.ValorMaximo)) 
	--não tem média OU acima da média de 200 OU fechou acima da máxima do candle de p1
	--AND (ValorMM200 IS NULL OR p2.ValorFechamento > ValorMM200 OR  P2.ValorFechamento >  P1.ValorMaximo)

	--SEGUNDO CANDLE TEM MAIOR VOLUME QUE O CANDLE ANTERIOR OU ESTÁ PELO MENOS NA MÉDIA DO VOLUME
	AND (/*P2.percentual_volume  >= @percentualDesejadoVolume OR */ p2.percentual_candle >= 0.75 OR p2.Titulos_Total >= p1.Titulos_Total OR P2.ValorMaximo > P1.ValorMaximo)


) as atual on sobrevendido.Codigo = atual.Codigo
order by Data desc, percentual_volume desc



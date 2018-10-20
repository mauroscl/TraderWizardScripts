declare @dataAnterior as datetime = '2018-10-1', @dataAtual as datetime = '2018-10-8',
@percentualMinimoVolume as float = 0.8, @percentualIntermediarioVolume as float = 0.9, @percentualDesejadoVolume as float = 1.0, @percentualVolumeRompimento as float = 1.2,
@percentual_candle_para_stop as float = 1.25, @percentual_volatilidade_para_entrada_saida as float = 1.5

--@numPeriodos as int = 14, @valorSobrevendido as int = 35, @valorSobreComprado as int = 65
--@numPeriodos as int = 2, @valorSobrevendido as int = 10, @valorSobreComprado as int = 90


select sobrevendido.Codigo, Data, atual.percentual_volume_quantidade, atual.percentual_volume_negocios, atual.percentual_candle_anterior, atual.percentual_candle_atual,
atual.VolatilidadeMaxima, atual.ValorMinimo, atual.ValorMaximo, entrada, saida, entrada * 2 - saida as alvo

FROM
(
	SELECT IFR.CODIGO, MAX(IFR.DATA) AS DATA
	FROM
	(
		SELECT IFR.CODIGO, IFR.DATA, C.Sequencial
		FROM IFR_Semanal IFR
		INNER JOIN Cotacao_Semanal C ON IFR.CODIGO =  C.CODIGO AND IFR.DATA = C.DATA
		WHERE IFR.NumPeriodos = 2
		AND IFR.Valor <= 10
		AND IFR.CODIGO NOT LIKE '%34'
		UNION
		SELECT IFR.CODIGO, IFR.DATA, C.Sequencial
		FROM IFR_Semanal IFR
		INNER JOIN Cotacao_Semanal C ON IFR.CODIGO =  C.CODIGO AND IFR.DATA = C.DATA
		WHERE IFR.NumPeriodos = 14
		AND IFR.Valor <= 35
		AND IFR.CODIGO NOT LIKE '%34'
	) IFR

	WHERE EXISTS 
	(
		SELECT 1 
		FROM Cotacao_Semanal C
		WHERE IFR.Codigo = C.Codigo
		and C.[Data] = @dataAtual
		AND C.Sequencial - IFR.Sequencial <= 6
	)
GROUP BY IFR.CODIGO
) as sobrevendido INNER JOIN
(
	--ESTA PROJECAO RETORNA OS ATIVOS NO ÚLTIMO PERÍODO
	select p1.Codigo, P1.ValorMM21 as mm21anterior, p2.ValorMM21, p2.percentual_volume_quantidade, p2.percentual_volume_negocios,
	p1.percentual_candle percentual_candle_anterior,  p2.percentual_candle percentual_candle_atual,
	p2.ValorMinimo, p2.ValorMaximo, p2.VolatilidadeMaxima, entrada,
	ROUND((entrada - (entrada - p2.ValorMinimo) * @percentual_candle_para_stop) * (1 - VolatilidadeMaxima * @percentual_volatilidade_para_entrada_saida / 100) , 2) as saida
	from
	(
		select c.Codigo, c.ValorMinimo, c.ValorMaximo, c.ValorFechamento, c.Titulos_Total, c.Negocios_Total,
		((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle,
		ROUND(mm21.Valor, 2) as ValorMM21,
		C.Titulos_Total / mvol.Valor as percentual_volume_quantidade,
		C.Negocios_Total / MND.Valor as percentual_volume_negocios
		from Cotacao_Semanal c
		inner join Media_Semanal mm21 on c.Codigo = mm21.Codigo and c.Data = mm21.Data and mm21.Tipo = 'MMA' and mm21.NumPeriodos = 21
		inner join Media_Semanal mvol on c.Codigo = mvol.Codigo and c.Data = mvol.Data and mvol.Tipo = 'VMA' and mvol.NumPeriodos = 21
		inner join MediaNegociosSemanal MND on c.Codigo = MND.Codigo and c.Data = MND.Data
		where c.Data = @dataAnterior
	) as p1
	inner join
	(
		select c.Codigo, c.ValorMinimo, c.ValorMaximo, c.ValorFechamento, dbo.MaxValue(VD.Valor, MVD.Valor) AS VolatilidadeMaxima,
		ROUND(mm21.Valor, 2) as ValorMM21, c.Titulos_Total, c.Negocios_Total, (c.Titulos_Total / mvol.Valor) as percentual_volume_quantidade,
		C.Negocios_Total / MNS.Valor as percentual_volume_negocios,
		((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle,
		ROUND(c.ValorMaximo  * (1 + dbo.MaxValue(VD.Valor, MVD.Valor) * @percentual_volatilidade_para_entrada_saida / 100) , 2) as entrada
		from Cotacao_Semanal c 
		inner join Media_Semanal mm21 on c.Codigo = mm21.Codigo and c.Data = mm21.Data and mm21.Tipo = 'MMA' and mm21.NumPeriodos = 21
		inner join Media_Semanal mvol on c.Codigo = mvol.Codigo and c.Data = mvol.Data and mvol.Tipo = 'VMA' and mvol.NumPeriodos = 21
		inner join MediaNegociosSemanal MNS on c.Codigo = MNS.Codigo and c.Data = MNS.Data
		INNER JOIN VolatilidadeSemanal VD ON C.Codigo = VD.Codigo AND C.DATA = VD.Data
		LEFT JOIN MediaVolatilidadeSemanal MVD ON C.Codigo = MVD.Codigo AND C.DATA = MVD.Data

		where c.Data = @dataAtual
		--fechou acima da metade do candle
		and (c.ValorMaximo - c.ValorFechamento) < (c.ValorFechamento - c.ValorMinimo)
		and c.Titulos_Total / mvol.Valor >= @percentualMinimoVolume
		and c.Negocios_Total / MNS.Valor >= @percentualMinimoVolume
		--amplitude do candle maior que 10% da volatilidade
		AND (C.ValorMaximo / C.ValorMinimo -1 ) >= dbo.MinValue(VD.Valor, MVD.Valor) / 10
		AND C.Negocios_Total >= 500
		AND C.Titulos_Total >=500000
		AND C.Valor_Total >= 5000000
		and c.ValorFechamento >= 1

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
	
	--(/*P2.percentual_volume  >= @percentualDesejadoVolume OR */ 
	--p2.percentual_candle >= 0.75 OR p2.Titulos_Total >= p1.Titulos_Total OR P2.ValorMaximo > P1.ValorMaximo)

(
	(dbo.MinValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualIntermediarioVolume
	AND dbo.MaxValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualDesejadoVolume)  
	OR p2.Titulos_Total >= p1.Titulos_Total
	OR p2.Negocios_Total >= p1.Negocios_Total
)
AND 
(
	(p2.ValorMM21 > p1.ValorMM21) 
	OR 
	(
		(
			p2.percentual_candle >= 0.75 
			AND dbo.MaxValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualVolumeRompimento 
			AND dbo.MinValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualDesejadoVolume
		) 
		OR 
		(
			p1.percentual_candle >= 0.5 and p2.percentual_candle >= 0.5
			AND dbo.MinValue(P1.percentual_volume_quantidade, P1.percentual_volume_negocios) >= @percentualIntermediarioVolume
			AND dbo.MinValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualIntermediarioVolume
		)
		OR
		(
			p2.Titulos_Total / p1.Titulos_Total >= 1.3
			AND p2.Negocios_Total / p1.Negocios_Total >= 1.3
		)

	)
)


) as atual on sobrevendido.Codigo = atual.Codigo
order by Data desc

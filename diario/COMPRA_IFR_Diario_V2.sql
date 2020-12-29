declare @datap0 as datetime = '2020-12-17', @dataAnterior as datetime = '2020-12-18', @dataAtual as datetime = '2020-12-21',
@percentualMinimoVolume as float = 0.8, @percentualDesejadoVolume as float = 1.0, @percentualVolumeRompimento as float = 1.2,
@percentual_candle_para_stop as float = 1.25, @percentual_volatilidade_para_entrada_saida as float = 1.5

select sobrevendido.Codigo, Data, atual.percentual_volume_quantidade, atual.percentual_volume_negocios, atual.percentual_candle_anterior, atual.percentual_candle_atual, 
atual.amplitude_anterior, atual.amplitude_atual,atual.direcao_m21, atual.distancia_fechamento_anterior

--,atual.Oscilacao ,atual.VolatilidadeMaxima, atual.ValorMinimo, atual.ValorMaximo, entrada, saida, entrada * 2 - saida as alvo, atual.MM21

FROM
(
	SELECT IFR.CODIGO, MAX(IFR.DATA) AS DATA, MAX(IFR.ValorFechamento) as ValorFechamento
	FROM	
	(
		SELECT IFR.CODIGO, IFR.DATA, C.Sequencial, C.ValorFechamento
		FROM IFR_DIARIO IFR
		INNER JOIN COTACAO C ON IFR.CODIGO =  C.CODIGO AND IFR.DATA = C.DATA
		WHERE IFR.NumPeriodos = 2
		AND IFR.Valor <= 10
		AND IFR.CODIGO NOT LIKE '%34'
		UNION
		SELECT IFR.CODIGO, IFR.DATA, C.Sequencial, C.ValorFechamento
		FROM IFR_DIARIO IFR
		INNER JOIN COTACAO C ON IFR.CODIGO =  C.CODIGO AND IFR.DATA = C.DATA
		WHERE IFR.NumPeriodos = 14
		AND IFR.Valor <= 35
		AND IFR.CODIGO NOT LIKE '%34'
	) IFR
	WHERE EXISTS 
	(
		SELECT 1 
		FROM Cotacao C
		WHERE IFR.Codigo = C.Codigo
		and C.[Data] = @dataAtual
		AND C.Sequencial - IFR.Sequencial <= 5
		
	)
	GROUP BY IFR.CODIGO
) as sobrevendido INNER JOIN
(
	select p1.Codigo, p2.ValorMM21, ROUND( (P2.ValorMaximo - P2.ValorMinimo) + P2.ValorMaximo, 2) as AlvoAproximado1, 
	ROUND((P2.ValorMaximo - P2.ValorMinimo) * 1.5 + P2.ValorMaximo, 2) as AlvoAproximado2, p2.percentual_volume_quantidade, p2.percentual_volume_negocios,
	p1.percentual_candle as percentual_candle_anterior, p2.percentual_candle percentual_candle_atual,
	CASE WHEN P2.ValorMM21 > P1.ValorMM21  THEN 'SUBINDO' WHEN P2.ValorMM21 = P1.ValorMM21 THEN 'FLAT' ELSE 'DESCENDO' END AS direcao_m21,
	ROUND((p2.ValorMaximo  * (1 + p2.VolatilidadeMaxima * 1.5 / 100) / p1.ValorFechamento- 1) * 100, 3) / 10 / p2.VolatilidadeMaxima as distancia_fechamento_anterior,
	(dbo.MaxValue(p0.ValorFechamento, p1.ValorMaximo) / dbo.MinValue(p0.ValorFechamento, p1.ValorMinimo) - 1) * 100 as amplitude_anterior, 
	(dbo.MaxValue(p1.ValorFechamento, p2.ValorMaximo) / dbo.MinValue(p1.ValorFechamento, p2.ValorMinimo) - 1) * 100 as amplitude_atual,
	p2.ValorMaximo, p2.VolatilidadeMaxima
	--p2.ValorMinimo, p2.ValorMaximo, p2.ValorMM21 as MM21, p2.Oscilacao, p2.VolatilidadeMinima, p2.VolatilidadeMaxima, entrada,
	--ROUND((entrada - (entrada - p2.ValorMinimo) * @percentual_candle_para_stop) * (1 - VolatilidadeMaxima * @percentual_volatilidade_para_entrada_saida / 100) , 2) as saida

	from
	( select Codigo, ValorMinimo, ValorMaximo, ValorFechamento
		from Cotacao
		where data = @datap0
	) as p0
	inner join 
	(
		select c.Codigo, c.ValorMinimo, c.ValorMaximo, c.ValorFechamento, c.Titulos_Total, c.Negocios_Total,
		((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle,
		ROUND(mm21.Valor, 2) as ValorMM21,
		C.Titulos_Total / mvol.Valor as percentual_volume_quantidade,
		C.Negocios_Total / MND.Valor as percentual_volume_negocios,
		dbo.MinValue(VD.Valor, MVD.Valor) AS VolatilidadeMinima
		from cotacao c
		inner join Media_Diaria mm21 on c.Codigo = mm21.Codigo and c.Data = mm21.Data and mm21.Tipo = 'MMA' and mm21.NumPeriodos = 21
		inner join Media_Diaria mvol on c.Codigo = mvol.Codigo and c.Data = mvol.Data and mvol.Tipo = 'VMA' and mvol.NumPeriodos = 21
		inner join MediaNegociosDiaria MND on c.Codigo = MND.Codigo and c.Data = MND.Data
		INNER JOIN VolatilidadeDiaria VD ON C.Codigo = VD.Codigo AND C.DATA = VD.Data
		LEFT JOIN MediaVolatilidadeDiaria MVD ON C.Codigo = MVD.Codigo AND C.DATA = MVD.Data

		where c.Data = @dataAnterior) as p1

		on p0.Codigo = p1.Codigo

		inner join
	(
		select c.Codigo, c.ValorMinimo, c.ValorMaximo, c.ValorFechamento, C.Oscilacao, 
		dbo.MinValue(VD.Valor, MVD.Valor) AS VolatilidadeMinima , dbo.MaxValue(VD.Valor, MVD.Valor) AS VolatilidadeMaxima,
		ROUND(mm21.Valor, 2) as ValorMM21, c.Titulos_Total, c.Negocios_Total,
		C.Titulos_Total / mvol.Valor as percentual_volume_quantidade,
		C.Negocios_Total / MND.Valor as percentual_volume_negocios,
		((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle,
		ROUND(c.ValorMaximo  * (1 + dbo.MaxValue(VD.Valor, MVD.Valor) * 1.25 / 100) , 2) as entrada

		from cotacao c
		inner join Media_Diaria mm21 on c.Codigo = mm21.Codigo and c.Data = mm21.Data and mm21.Tipo = 'MMA' and mm21.NumPeriodos = 21
		inner join Media_Diaria mvol on c.Codigo = mvol.Codigo and c.Data = mvol.Data and mvol.Tipo = 'VMA' and mvol.NumPeriodos = 21
		inner join MediaNegociosDiaria MND on c.Codigo = MND.Codigo and c.Data = MND.Data
		INNER JOIN VolatilidadeDiaria VD ON C.Codigo = VD.Codigo AND C.DATA = VD.Data
		LEFT JOIN MediaVolatilidadeDiaria MVD ON C.Codigo = MVD.Codigo AND C.DATA = MVD.Data

		where c.Data = @dataAtual
		--fechou acima da metade do candle
		and (c.ValorMaximo - c.ValorFechamento) < (c.ValorFechamento - c.ValorMinimo)
		--and c.Titulos_Total / mvol.Valor >= @percentualMinimoVolume
		--and c.Negocios_Total / MND.Valor >= @percentualMinimoVolume

		AND C.Negocios_Total >= 100
		AND C.Titulos_Total >=100000
		AND C.Valor_Total >= 1000000
		and c.ValorFechamento >= 1

		AND (C.ValorMaximo / C.ValorMinimo -1 ) >= dbo.MinValue(VD.Valor, MVD.Valor) / 10

		--AND (C.Oscilacao / 100) / (dbo.MaxValue(VD.Valor, MVD.Valor) / 10) <= 1.5

		and ROUND((c.ValorMaximo  * (1 + dbo.MaxValue(VD.Valor, MVD.Valor) * 1.5 / 100) / mm21.Valor- 1) * 100, 3) / 10 / dbo.MaxValue(VD.Valor, MVD.Valor) <=2.5




	) as p2
	on p1.Codigo = p2.Codigo
	where 
	--EVITAR PAP�IS QUE SUPERARAM A M�XIMA E DEPOIS FECHARAM ABAIXO DA M�XIMA
	(p2.ValorFechamento > p1.ValorMaximo OR P2.ValorMaximo <= P1.ValorMaximo)

	--quando amplitude do movimento anterior (p1) for maior que a volatilidade, se o movimento for negativo, o candle de p2 deve fechar acima da m�xima de p1 (removido para tentar pegar fechou fora fechou dentro)
	--AND
	--(
	--	P2.ValorFechamento	>  P1.ValorMaximo --fechou acima da m�xima anterior
	--	OR P2.ValorMM21 > P1.ValorMM21 --MM21 est� subindo
	--	OR (P1.ValorMaximo - P1.ValorFechamento) < (P1.ValorFechamento - P1.ValorMinimo) --candle anterior fechou acima da metadade da amplitude
	--	OR (P1.ValorMaximo / P1.ValorMinimo -1 ) < P1.VolatilidadeMinima / 10 --candle anterior tem amplitude menor que a volatilidade m�nima
	--)

	--MEDIA DE 21 EST� SUBINDO OU CANDLE NAO EST� CORTANDO A M�DIA OU MAIS DA METADE DO CORPO DO CANDLE EST� ACIMA DA M�DIA DE 21
	AND (P2.ValorMM21 > P1.ValorMM21 OR NOT P2.ValorMM21 BETWEEN P2.ValorMinimo AND P2.ValorMaximo OR (P2.ValorMaximo - P2.ValorMM21 > P2.ValorMM21 - P2.ValorMinimo ))

	AND 
	(
		(
			-- MAIS VOLUME QUE O ANTERIOR E VOLUME MINIMO. SOMENTE EM ALTA
			dbo.MinValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualMinimoVolume
			AND p2.ValorMM21 > p1.ValorMM21  
		)
		OR
		(
		-- 120% DA M�DIA AND 75% CANDLE. QUALQUER TENDENCIA
			p2.percentual_candle >= 0.75 
			AND dbo.MaxValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualVolumeRompimento 
			AND dbo.MinValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualDesejadoVolume
		) 
		OR
		(
			-- 120% DO VOLUME DO CANDLE ANTERIOR. QUALQUER TENDENCIA
			p2.percentual_candle >= 0.75 
			AND p2.Titulos_Total / p1.Titulos_Total >= 1.3
			AND p2.Negocios_Total / p1.Negocios_Total >= 1.3
		)
		OR 
		(
			-- DOIS CANDLE COM VOLUME INTERMEDIARIO E CANDLE 50%. QUALQUER TENDENCIA
			p1.percentual_candle >= 0.5 and p2.percentual_candle >= 0.5
			AND dbo.MinValue(P1.percentual_volume_quantidade, P1.percentual_volume_negocios) >= @percentualDesejadoVolume
			AND dbo.MinValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualDesejadoVolume
		)
	)
) as atual on sobrevendido.Codigo = atual.Codigo

WHERE ROUND((atual.ValorMaximo /* * (1 + atual.VolatilidadeMaxima * 1.5 / 100) */ / sobrevendido.ValorFechamento - 1) * 100, 3) / 10 / atual.VolatilidadeMaxima <= 1.75

order by Data desc, percentual_volume_quantidade desc



declare @dataAnterior as datetime = '2020-6-22', @dataAtual as datetime = '2020-6-29',
@percentualMinimoVolume as float = 0.8, @percentualDesejadoVolume as float = 1.0, @percentualVolumeRompimento as float = 1.2,
@percentual_candle_para_stop as float = 1.25, @percentual_volatilidade_para_entrada_saida as float = 1.5


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
		AND C.Sequencial - IFR.Sequencial <= 4
	)
GROUP BY IFR.CODIGO
) as sobrevendido INNER JOIN
(
	--ESTA PROJECAO RETORNA OS ATIVOS NO ÚLTIMO PERÍODO
	select p1.Codigo, P1.ValorMM21 as mm21anterior, p2.ValorMM21, p2.percentual_volume_quantidade, p2.percentual_volume_negocios,
	p1.percentual_candle percentual_candle_anterior,  p2.percentual_candle percentual_candle_atual,
	p2.ValorMinimo, p2.ValorMaximo, P1.VolatilidadeMinima, p2.VolatilidadeMaxima, entrada,
	ROUND((entrada - (entrada - p2.ValorMinimo) * @percentual_candle_para_stop) * (1 - VolatilidadeMaxima * @percentual_volatilidade_para_entrada_saida / 100) , 2) as saida
	from
	(
		select c.Codigo, c.ValorMinimo, c.ValorMaximo, c.ValorFechamento, c.Titulos_Total, c.Negocios_Total,
		((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle,
		ROUND(mm21.Valor, 2) as ValorMM21,
		C.Titulos_Total / mvol.Valor as percentual_volume_quantidade,
		C.Negocios_Total / MNS.Valor as percentual_volume_negocios,
		dbo.MinValue(VS.Valor, MVS.Valor) AS VolatilidadeMinima
		from Cotacao_Semanal c
		inner join Media_Semanal mm21 on c.Codigo = mm21.Codigo and c.Data = mm21.Data and mm21.Tipo = 'MMA' and mm21.NumPeriodos = 21
		inner join Media_Semanal mvol on c.Codigo = mvol.Codigo and c.Data = mvol.Data and mvol.Tipo = 'VMA' and mvol.NumPeriodos = 21
		inner join MediaNegociosSemanal MNS on c.Codigo = MNS.Codigo and c.Data = MNS.Data
		INNER JOIN VolatilidadeSemanal VS ON C.Codigo = VS.Codigo AND C.DATA = VS.Data
		LEFT JOIN MediaVolatilidadeSemanal MVS ON C.Codigo = MVS.Codigo AND C.DATA = MVS.Data
		where c.Data = @dataAnterior
	) as p1
	inner join
	(
		select c.Codigo, c.ValorMinimo, c.ValorMaximo, c.ValorFechamento, dbo.MaxValue(VS.Valor, MVS.Valor) AS VolatilidadeMaxima,
		ROUND(mm21.Valor, 2) as ValorMM21, c.Titulos_Total, c.Negocios_Total, (c.Titulos_Total / mvol.Valor) as percentual_volume_quantidade,
		C.Negocios_Total / MNS.Valor as percentual_volume_negocios,
		((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle,
		ROUND(c.ValorMaximo  * (1 + dbo.MaxValue(VS.Valor, MVS.Valor) * @percentual_volatilidade_para_entrada_saida / 100) , 2) as entrada
		from Cotacao_Semanal c 
		inner join Media_Semanal mm21 on c.Codigo = mm21.Codigo and c.Data = mm21.Data and mm21.Tipo = 'MMA' and mm21.NumPeriodos = 21
		inner join Media_Semanal mvol on c.Codigo = mvol.Codigo and c.Data = mvol.Data and mvol.Tipo = 'VMA' and mvol.NumPeriodos = 21
		inner join MediaNegociosSemanal MNS on c.Codigo = MNS.Codigo and c.Data = MNS.Data
		INNER JOIN VolatilidadeSemanal VS ON C.Codigo = VS.Codigo AND C.DATA = VS.Data
		LEFT JOIN MediaVolatilidadeSemanal MVS ON C.Codigo = MVS.Codigo AND C.DATA = MVS.Data

		where c.Data = @dataAtual
		--fechou acima da metade do candle
		and (c.ValorMaximo - c.ValorFechamento) < (c.ValorFechamento - c.ValorMinimo)
		--amplitude do candle maior que 10% da volatilidade
		AND (C.ValorMaximo / C.ValorMinimo -1 ) >= dbo.MinValue(VS.Valor, MVS.Valor) / 10
		AND C.Negocios_Total >= 500
		AND C.Titulos_Total >=500000
		AND C.Valor_Total >= 5000000
		and c.ValorFechamento >= 1

	) as p2
	on p1.Codigo = p2.Codigo
	where 
	--EVITAR PAPÉIS QUE SUPERARAM A MÁXIMA E DEPOIS FECHARAM ABAIXO DA MÁXIMA
	(p2.ValorFechamento > p1.ValorMaximo OR P2.ValorMaximo <= P1.ValorMaximo)

	AND
	(
		P2.ValorFechamento	>  P1.ValorMaximo --fechou acima da máxima anterior
		OR P2.ValorMM21 > P1.ValorMM21 --MM21 está subindo
		OR (P1.ValorMaximo - P1.ValorFechamento) < (P1.ValorFechamento - P1.ValorMinimo) --candle anterior fechou acima da metadade da amplitude
		OR (P1.ValorMaximo / P1.ValorMinimo -1 ) < P1.VolatilidadeMinima / 10 --candle anterior tem amplitude menor que a volatilidade mínima
	)


	--MEDIA DE 21 ESTÁ SUBINDO OU CANDLE NAO ESTÁ CORTANDO A MÉDIA OU MAIS DA METADE DO CORPO DO CANDLE ESTÁ ACIMA DA MÉDIA DE 21
	AND (P2.ValorMM21 > P1.ValorMM21 OR NOT P2.ValorMM21 BETWEEN P2.ValorMinimo AND P2.ValorMaximo OR (P2.ValorMaximo - P2.ValorMM21 > P2.ValorMM21 - P2.ValorMinimo ))
	AND
	(
		(
			-- MAIS VOLUME QUE O ANTERIOR E VOLUME MINIMO. SOMENTE EM ALTA
			dbo.MinValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualMinimoVolume
			AND p2.ValorMM21 > p1.ValorMM21  
			AND (p2.Titulos_Total >= p1.Titulos_Total
			OR p2.Negocios_Total >= p1.Negocios_Total)
		)
		OR

			(
			-- 120% DA MÉDIA AND 75% CANDLE. QUALQUER TENDENCIA
				p2.percentual_candle >= 0.75 
				AND dbo.MaxValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualVolumeRompimento 
				AND dbo.MinValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualDesejadoVolume
			) 
			OR
			(
				-- 130% DO CANDLE ANTERIOR. QUALQUER TENDENCIA
				p2.Titulos_Total / p1.Titulos_Total >= 1.3
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
order by Data desc

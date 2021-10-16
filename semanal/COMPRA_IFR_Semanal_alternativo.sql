declare @datap0 as datetime = '2021-9-20', @dataAnterior as datetime = '2021-9-27', @dataAtual as datetime = '2021-10-4',
@percentualMinimoVolume as float = 0.8, @percentualDesejadoVolume as float = 0.9, @percentualVolumeRompimento as float = 0.9,
@percentual_candle_para_stop as float = 1.25, @percentual_volatilidade_para_entrada_saida as float = 1.5

select sobrevendido.Codigo, sobrevendido.Data/*, atual.percentual_volume_quantidade, atual.percentual_volume_negocios, atual.percentual_candle_anterior */
, atual.percentual_candle_abertura, atual.percentual_candle_fechamento, 
atual.amplitude_anterior, atual.amplitude_atual,atual.direcao_m21, atual.distancia_fechamento_anterior

FROM
(
	
	SELECT IFR.CODIGO, MAX(IFR.DATA) AS DATA
	FROM	
	(
		SELECT IFR.CODIGO, IFR.DATA, C.Sequencial, C.ValorFechamento
		FROM IFR_Semanal IFR
		INNER JOIN Cotacao_Semanal C ON IFR.CODIGO =  C.CODIGO AND IFR.DATA = C.DATA
		WHERE IFR.NumPeriodos = 2
		AND IFR.Valor <= 10
		UNION
		SELECT IFR.CODIGO, IFR.DATA, C.Sequencial, C.ValorFechamento
		FROM IFR_Semanal IFR
		INNER JOIN Cotacao_Semanal C ON IFR.CODIGO =  C.CODIGO AND IFR.DATA = C.DATA
		WHERE IFR.NumPeriodos = 14
		AND IFR.Valor <= 35
	) IFR
	GROUP BY IFR.CODIGO
) as sobrevendido INNER JOIN
(
	select p1.Codigo, p2.ValorMM21, ROUND( (P2.ValorMaximo - P2.ValorMinimo) + P2.ValorMaximo, 2) as AlvoAproximado1, 
	ROUND((P2.ValorMaximo - P2.ValorMinimo) * 1.5 + P2.ValorMaximo, 2) as AlvoAproximado2, p2.percentual_volume_quantidade, p2.percentual_volume_negocios,
	p1.percentual_candle as percentual_candle_anterior, p2.percentual_candle_abertura, p2.percentual_candle_fechamento,
	CASE WHEN P2.ValorMM21 > P1.ValorMM21  THEN 'SUBINDO' WHEN P2.ValorMM21 = P1.ValorMM21 THEN 'FLAT' ELSE 'DESCENDO' END AS direcao_m21,
	ROUND((p2.ValorMaximo  * (1 + p2.VolatilidadeMaxima * 1.5 / 100) / p1.ValorFechamento- 1) * 100, 3) / 10 / p2.VolatilidadeMaxima as distancia_fechamento_anterior,
	(dbo.MaxValue(p0.ValorFechamento, p1.ValorMaximo) / dbo.MinValue(p0.ValorFechamento, p1.ValorMinimo) - 1) * 100 as amplitude_anterior, 
	(dbo.MaxValue(p1.ValorFechamento, p2.ValorMaximo) / dbo.MinValue(p1.ValorFechamento, p2.ValorMinimo) - 1) * 100 as amplitude_atual,
	p2.ValorMaximo, p2.VolatilidadeMaxima
	--p2.ValorMinimo, p2.ValorMaximo, p2.ValorMM21 as MM21, p2.Oscilacao, p2.VolatilidadeMinima, p2.VolatilidadeMaxima, entrada,
	--ROUND((entrada - (entrada - p2.ValorMinimo) * @percentual_candle_para_stop) * (1 - VolatilidadeMaxima * @percentual_volatilidade_para_entrada_saida / 100) , 2) as saida

	from
	( select Codigo, ValorMinimo, ValorMaximo, ValorFechamento
		from Cotacao_Semanal
		where data = @datap0
	) as p0
	inner join 
	(
		select c.Codigo, c.ValorMinimo, c.ValorMaximo, c.ValorFechamento, c.Titulos_Total, c.Negocios_Total,
		((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle,
		ROUND(mm21.Valor, 2) as ValorMM21,
		C.Titulos_Total / mvol.Valor as percentual_volume_quantidade,
		C.Negocios_Total / MN.Valor as percentual_volume_negocios,
		dbo.MinValue(VOLAT.Valor, MVOLAT.Valor) AS VolatilidadeMinima
		from Cotacao_Semanal c
		inner join Media_Semanal mm21 on c.Codigo = mm21.Codigo and c.Data = mm21.Data and mm21.Tipo = 'MMA' and mm21.NumPeriodos = 21
		inner join Media_Semanal mvol on c.Codigo = mvol.Codigo and c.Data = mvol.Data and mvol.Tipo = 'VMA' and mvol.NumPeriodos = 21
		inner join MediaNegociosSemanal MN on c.Codigo = MN.Codigo and c.Data = MN.Data
		INNER JOIN MediaVolatilidadeSemanal VOLAT ON C.Codigo = VOLAT.Codigo AND C.DATA = VOLAT.Data
		LEFT JOIN MediaVolatilidadeSemanal MVOLAT ON C.Codigo = MVOLAT.Codigo AND C.DATA = MVOLAT.Data

		where c.Data = @dataAnterior
	) as p1

		on p0.Codigo = p1.Codigo

	inner join
	(
		select c.Codigo, c.ValorMinimo, c.ValorMaximo, c.ValorFechamento, C.Oscilacao, 
		dbo.MinValue(VOLAT.Valor, MVOLAT.Valor) AS VolatilidadeMinima , dbo.MaxValue(VOLAT.Valor, MVOLAT.Valor) AS VolatilidadeMaxima,
		ROUND(mm21.Valor, 2) as ValorMM21, c.Titulos_Total, c.Negocios_Total,
		C.Titulos_Total / mvol.Valor as percentual_volume_quantidade,
		C.Negocios_Total / MN.Valor as percentual_volume_negocios,
		((C.ValorAbertura - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle_abertura,
		((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle_fechamento,
		ROUND(c.ValorMaximo  * (1 + dbo.MaxValue(VOLAT.Valor, MVOLAT.Valor) * 1.25 / 100) , 2) as entrada
		
		from Cotacao_Semanal c
		inner join Media_Semanal mm21 on c.Codigo = mm21.Codigo and c.Data = mm21.Data and mm21.Tipo = 'MMA' and mm21.NumPeriodos = 21
		inner join Media_Semanal mvol on c.Codigo = mvol.Codigo and c.Data = mvol.Data and mvol.Tipo = 'VMA' and mvol.NumPeriodos = 21
		inner join MediaNegociosSemanal MN on c.Codigo = MN.Codigo and c.Data = MN.Data
		INNER JOIN VolatilidadeSemanal VOLAT ON C.Codigo = VOLAT.Codigo AND C.DATA = VOLAT.Data
		LEFT JOIN MediaVolatilidadeSemanal MVOLAT ON C.Codigo = MVOLAT.Codigo AND C.DATA = MVOLAT.Data

		where c.Data = @dataAtual
		--fechou acima da metade do candle
		and (c.ValorMaximo - c.ValorFechamento) < (c.ValorFechamento - c.ValorMinimo)
		--and c.Titulos_Total / mvol.Valor >= @percentualMinimoVolume
		--and c.Negocios_Total / MND.Valor >= @percentualMinimoVolume

		AND C.Negocios_Total >= 100
		AND C.Titulos_Total >=100000
		AND C.Valor_Total >= 1000000
		and c.ValorFechamento >= 1

		AND dbo.MaxValue(ABS(C.Oscilacao) / 100, C.ValorMaximo / C.ValorMinimo -1 ) >= dbo.MinValue(VOLAT.Valor, MVOLAT.Valor) / 10


		--AND (C.Oscilacao / 100) / (dbo.MaxValue(VD.Valor, MVD.Valor) / 10) <= 1.5

		and ROUND((c.ValorMaximo  * (1 + dbo.MaxValue(VOLAT.Valor, mvolat.Valor) * 1.5 / 100) / mm21.Valor- 1) * 100, 3) / 10 / dbo.MaxValue(VOLAT.Valor, MVOLAT.Valor) <=2.5

	) as p2
	on p1.Codigo = p2.Codigo
	where 
	--EVITAR PAPÉIS QUE SUPERARAM A MÁXIMA E DEPOIS FECHARAM ABAIXO DA MÁXIMA (COMENTADO EM 21/02/2021)
	--(p2.ValorFechamento > p1.ValorMaximo OR P2.ValorMaximo <= P1.ValorMaximo)

	--quando amplitude do movimento anterior (p1) for maior que a volatilidade, se o movimento for negativo, o candle de p2 deve fechar acima da máxima de p1 (removido para tentar pegar fechou fora fechou dentro)
	--AND
	--(
	--	P2.ValorFechamento	>  P1.ValorMaximo --fechou acima da máxima anterior
	--	OR P2.ValorMM21 > P1.ValorMM21 --MM21 está subindo
	--	OR (P1.ValorMaximo - P1.ValorFechamento) < (P1.ValorFechamento - P1.ValorMinimo) --candle anterior fechou acima da metadade da amplitude
	--	OR (P1.ValorMaximo / P1.ValorMinimo -1 ) < P1.VolatilidadeMinima / 10 --candle anterior tem amplitude menor que a volatilidade mínima
	--)

	--MEDIA DE 21 ESTÁ SUBINDO OU CANDLE NAO ESTÁ CORTANDO A MÉDIA OU MAIS DA METADE DO CORPO DO CANDLE ESTÁ ACIMA DA MÉDIA DE 21
	--AND 
	(P2.ValorMM21 > P1.ValorMM21 OR NOT P2.ValorMM21 BETWEEN P2.ValorMinimo AND P2.ValorMaximo OR (P2.ValorMaximo - P2.ValorMM21 > P2.ValorMM21 - P2.ValorMinimo ))

	AND 
	(
		(
			-- MAIS VOLUME QUE O ANTERIOR E VOLUME MINIMO. SOMENTE EM ALTA
			dbo.MinValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualMinimoVolume
			AND p2.ValorMM21 > p1.ValorMM21  
		)
		OR
		(
		-- 120% DA MÉDIA AND 75% CANDLE. QUALQUER TENDENCIA
			p2.percentual_candle_fechamento >= 0.7 
			AND dbo.MaxValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualVolumeRompimento 
			AND dbo.MinValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualDesejadoVolume
		) 
		OR
		(
			-- 120% DO VOLUME DO CANDLE ANTERIOR. QUALQUER TENDENCIA
			p2.percentual_candle_fechamento >= 0.7 
			AND p2.Titulos_Total / p1.Titulos_Total >= 1.3
			AND p2.Negocios_Total / p1.Negocios_Total >= 1.3
		)
		OR 
		(
			-- DOIS CANDLE COM VOLUME INTERMEDIARIO E CANDLE 50%. QUALQUER TENDENCIA
			p1.percentual_candle >= 0.5 and p2.percentual_candle_fechamento >= 0.5
			AND dbo.MinValue(P1.percentual_volume_quantidade, P1.percentual_volume_negocios) >= @percentualDesejadoVolume
			AND dbo.MinValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualDesejadoVolume
		)
		OR (P2.percentual_candle_abertura <= 0.25 AND P2.percentual_candle_fechamento >= 0.75)
	)
) as atual on sobrevendido.Codigo = atual.Codigo

inner join Cotacao_Semanal cotacao_sobrevendida
on sobrevendido.Codigo = cotacao_sobrevendida.Codigo
and sobrevendido.DATA = cotacao_sobrevendida.Data
WHERE (SELECT COUNT(1) 
FROM Cotacao_Semanal cotacao_posterior
WHERE cotacao_posterior.Codigo = cotacao_sobrevendida.Codigo
and cotacao_posterior.Data >= cotacao_sobrevendida.Data
and cotacao_posterior.Data <= @dataAtual
and cotacao_posterior.ValorFechamento > cotacao_sobrevendida.ValorMaximo
) <= 2


order by direcao_m21, sobrevendido.Data desc, percentual_volume_quantidade desc



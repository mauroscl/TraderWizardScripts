----SEMANAL
DECLARE @percentualMinimoVolume as float = 0.8, @percentualIntermediarioVolume as float = 0.9, @percentualDesejadoVolume as float = 1.0, @percentualVolumeRompimento as float = 1.0,
@ifr2Maximo as float = 98, @ifr14Maximo as float = 75

--PONTO CONTINIUO (10)
DECLARE @dataInicial as datetime = '2021-9-27', @dataFinal as datetime = '2021-10-4'

select pc10.codigo pc10, pc10.percentual_volume_quantidade, pc10.percentual_candle2,pc10.distancia_mm21, pc10.distancia_fechamento_anterior,
pc21.codigo as pc21, pc21.percentual_volume_quantidade, pc21.percentual_candle,pc21.distancia_mm21, pc21.distancia_fechamento_anterior
from			
(select p2.codigo, p2.percentual_volume_quantidade, p2.percentual_candle as percentual_candle2, p2.ValorMinimo, p2.ValorMaximo, p2.MM21, p2.Volatilidade, p2.distancia_mm21,
ROUND((p2.ValorMaximo  * (1 + p2.Volatilidade * 1.5 / 100) / p1.ValorFechamento- 1) * 100, 3) / 10 / p2.Volatilidade as distancia_fechamento_anterior

from 
(
	select c.codigo, C.ValorMinimo, C.ValorMaximo, C.ValorFechamento, c.Titulos_Total, c.Negocios_Total, 
	((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle,
	MM21.Valor AS MM21,
	c.Titulos_Total / MVOL.Valor as percentual_volume_quantidade, C.Negocios_Total / MN.Valor as percentual_volume_negocios
	from Cotacao_Semanal c 
	inner join Media_Semanal MM10 on c.Codigo = MM10.Codigo and c.Data = MM10.Data and MM10.Tipo = 'MMA' AND MM10.NumPeriodos = 10
	inner join Media_Semanal MM21 on c.Codigo = MM21.Codigo and c.Data = MM21.Data and MM21.Tipo = 'MMA' AND MM21.NumPeriodos = 21
	inner join Media_Semanal MVOL on c.Codigo = MVOL.Codigo and c.Data = MVOL.Data and MVOL.Tipo = 'VMA' AND MVOL.NumPeriodos = 21
	inner join MediaNegociosSemanal MN on c.Codigo = MN.Codigo and c.Data = MN.Data

	where c.Data = @dataInicial
	AND C.ValorMaximo >= MM10.Valor
) p1
inner join 
(	
	select c.codigo, ValorAbertura, ValorFechamento, ValorMinimo, ValorMaximo, M10.Valor, c.Titulos_Total, c.Negocios_Total ,
	c.Titulos_Total / MVOL.Valor as percentual_volume_quantidade, 
	C.Negocios_Total / MNS.Valor as percentual_volume_negocios,
	M21.Valor AS MM21, dbo.MaxValue(VD.Valor, MVD.Valor) AS Volatilidade,
	((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle,
	ROUND((c.ValorMaximo  * (1 + dbo.MaxValue(VD.Valor, MVD.Valor) * 1.25 / 100) / m21.Valor - 1) * 100, 3) / 10 / dbo.MaxValue(VD.Valor, MVD.Valor) as distancia_mm21
	from Cotacao_Semanal c 
	inner join Media_Semanal m10 on c.Codigo = m10.Codigo and c.Data = m10.Data and m10.Tipo = 'MMA' AND M10.NumPeriodos = 10
	inner join Media_Semanal m21 on c.Codigo = m21.Codigo and c.Data = m21.Data and m21.Tipo = 'MMA' AND M21.NumPeriodos = 21
	inner join Media_Semanal MVOL on c.Codigo = MVOL.Codigo and c.Data = MVOL.Data and MVOL.Tipo = 'VMA' AND MVOL.NumPeriodos = 21
	inner join MediaNegociosSemanal MNS on c.Codigo = MNS.Codigo and c.Data = MNS.Data
	inner join IFR_Semanal IFR2 on C.Codigo = IFR2.Codigo AND C.Data = IFR2.Data AND IFR2.NumPeriodos = 2
	inner join IFR_Semanal IFR14 on C.Codigo = IFR14.Codigo AND C.Data = IFR14.Data AND IFR14.NumPeriodos = 14
	INNER JOIN VolatilidadeSemanal VD ON C.Codigo = VD.Codigo AND C.DATA = VD.Data
	LEFT JOIN MediaVolatilidadeSemanal MVD ON C.Codigo = MVD.Codigo AND C.DATA = MVD.Data
	where c.Data = @dataFinal
	AND M10.Valor > M21.Valor
	AND IFR2.Valor < @ifr2Maximo
	AND IFR14.Valor < @ifr14Maximo
	AND C.Titulos_Total >= 500000
	AND C.ValorFechamento >= 1
	AND M10.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo
	--FECHOU ACIMA DA METADE DA AMPLITUDE
	AND C.valorfechamento > (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2))
	--VOLUME MAIOR OU IGUAL A 80% DA M�DIA DO VOLUME
	AND dbo.MaxValue(ABS(C.Oscilacao) / 100, C.ValorMaximo / C.ValorMinimo -1 ) >= dbo.MinValue(VD.Valor, MVD.Valor) / 10

)  p2
on p1.codigo = p2.codigo
WHERE 
(p2.ValorFechamento > p2.MM21 OR P2.ValorFechamento > P1.ValorMinimo)
--evitar segundo candle com sombra acima do candle anterior
--AND NOT P1.ValorMaximo BETWEEN P2.ValorFechamento AND P2.ValorMaximo

and p2.distancia_mm21 <= 2.5

AND 
(
	(
		-- MAIS VOLUME QUE O ANTERIOR E VOLUME MINIMO. SOMENTE EM ALTA
		p2.MM21 > p1.MM21  
		AND (dbo.MinValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualMinimoVolume
		OR p2.ValorFechamento > p1.ValorMaximo)
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
		-- 130% DO VOLUME DO CANDLE ANTERIOR. QUALQUER TENDENCIA
		p2.percentual_candle >= 0.5 
		AND p2.Titulos_Total / p1.Titulos_Total >= 1.2
		AND p2.Negocios_Total / p1.Negocios_Total >= 1.2
	)
	OR 
	(
		-- DOIS CANDLE COM VOLUME INTERMEDIARIO E CANDLE 50%. QUALQUER TENDENCIA
		p1.percentual_candle >= 0.5 and p2.percentual_candle >= 0.5
		AND dbo.MinValue(P1.percentual_volume_quantidade, P1.percentual_volume_negocios) >= @percentualDesejadoVolume
		AND dbo.MinValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualDesejadoVolume
	)
)


) as pc10

full outer join
--PONTO CONTINIUO (21)

(select p2.codigo, p2.percentual_volume_quantidade, p2.percentual_candle, p2.ValorMinimo, p2.ValorMaximo, p2.MM21, p2.Volatilidade, p2.distancia_mm21,
ROUND((p2.ValorMaximo  * (1 + p2.Volatilidade * 1.5 / 100) / p1.ValorFechamento- 1) * 100, 3) / 10 / p2.Volatilidade as distancia_fechamento_anterior

from 
(
	select c.codigo, C.ValorMinimo, C.ValorMaximo, C.ValorFechamento, c.Titulos_Total, c.Negocios_Total, 
	((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle, M.Valor AS MM21,
	c.Titulos_Total / MVOL.Valor as percentual_volume_quantidade, C.Negocios_Total / MN.Valor as percentual_volume_negocios
	from Cotacao_Semanal c 
	inner join Media_Semanal m on c.Codigo = m.Codigo and c.Data = m.Data and m.Tipo = 'MMA' AND M.NumPeriodos = 21
	inner join Media_Semanal MVOL on c.Codigo = MVOL.Codigo and c.Data = MVOL.Data and MVOL.Tipo = 'VMA' AND MVOL.NumPeriodos = 21
	inner join MediaNegociosSemanal MN on c.Codigo = MN.Codigo and c.Data = MN.Data
	where c.Data = @dataInicial
	AND C.ValorMaximo >= M.Valor
) p1
inner join 
(
	select c.codigo, ValorAbertura, ValorFechamento, ValorMinimo, ValorMaximo
	, M.Valor as MM21, c.Titulos_Total, c.Negocios_Total,
	c.Titulos_Total / MVOL.Valor as percentual_volume_quantidade,
	C.Negocios_Total / MNS.Valor as percentual_volume_negocios,
	dbo.MaxValue(VD.Valor, MVD.Valor) as Volatilidade,
	((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle,
	ROUND((c.ValorMaximo  * (1 + dbo.MaxValue(VD.Valor, MVD.Valor) * 1.25 / 100) / m.Valor - 1) * 100, 3) / 10 / dbo.MaxValue(VD.Valor, MVD.Valor) as distancia_mm21
	from Cotacao_Semanal c 
	inner join Media_Semanal m on c.Codigo = m.Codigo and c.Data = m.Data and m.Tipo = 'MMA' AND M.NumPeriodos = 21
	inner join Media_Semanal MVOL on c.Codigo = MVOL.Codigo and c.Data = MVOL.Data and MVOL.Tipo = 'VMA' AND MVOL.NumPeriodos = 21
	inner join MediaNegociosSemanal MNS on c.Codigo = MNS.Codigo and c.Data = MNS.Data
	inner join IFR_Semanal IFR2 on C.Codigo = IFR2.Codigo AND C.Data = IFR2.Data AND IFR2.NumPeriodos = 2
	inner join IFR_Semanal IFR14 on C.Codigo = IFR14.Codigo AND C.Data = IFR14.Data AND IFR14.NumPeriodos = 14
	INNER JOIN VolatilidadeSemanal VD ON C.Codigo = VD.Codigo AND C.DATA = VD.Data
	LEFT JOIN MediaVolatilidadeSemanal MVD ON C.Codigo = MVD.Codigo AND C.DATA = MVD.Data
	where c.Data = @dataFinal
	AND C.Titulos_Total >= 500000
	AND IFR2.Valor < @ifr2Maximo
	AND IFR14.Valor < @ifr14Maximo
	AND C.ValorFechamento >= 1
	AND M.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo
	AND C.valorfechamento > (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2))
	--VOLUME MAIOR OU IGUAL A 80% DA M�DIA DO VOLUME
	AND dbo.MaxValue(ABS(C.Oscilacao) / 100, C.ValorMaximo / C.ValorMinimo -1 ) >= dbo.MinValue(VD.Valor, MVD.Valor) / 10

)  p2
on p1.codigo = p2.codigo
WHERE 
(p2.ValorFechamento > p2.MM21 OR P2.ValorFechamento > P1.ValorMinimo)
--evitar segundo candle com sombra acima do candle anterior
--AND NOT P1.ValorMaximo BETWEEN P2.ValorFechamento AND P2.ValorMaximo

--DISTANCIA PARA A M�DIA DE 21 NO M�XIMO 2.5 VEZES A VOLATILIDADE
and p2.distancia_mm21 <= 2.5

AND 
(
	(
		-- MAIS VOLUME QUE O ANTERIOR E VOLUME MINIMO. SOMENTE EM ALTA
		p2.MM21 > p1.MM21  
		AND (dbo.MinValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualMinimoVolume
		OR p2.ValorFechamento > p1.ValorMaximo)
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
		-- 130% DO VOLUME DO CANDLE ANTERIOR. QUALQUER TENDENCIA
		p2.percentual_candle >= 0.5 
		AND p2.Titulos_Total / p1.Titulos_Total >= 1.2
		AND p2.Negocios_Total / p1.Negocios_Total >= 1.2
	)
	OR 
	(
		-- DOIS CANDLE COM VOLUME INTERMEDIARIO E CANDLE 50%. QUALQUER TENDENCIA
		p1.percentual_candle >= 0.5 and p2.percentual_candle >= 0.5
		AND dbo.MinValue(P1.percentual_volume_quantidade, P1.percentual_volume_negocios) >= @percentualDesejadoVolume
		AND dbo.MinValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualDesejadoVolume
	)
)

) as pc21
on pc10.codigo = pc21.codigo
order by  case when pc21.Codigo is null then 0 else 1 end, pc10.Codigo, pc21.Codigo



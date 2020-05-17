----DIARIO
DECLARE @percentualMinimoVolume as float = 0.8, @percentualDesejadoVolume as float = 1.0, @percentualVolumeRompimento as float = 1.2,
@dataAnterior as datetime = '2020-5-14', @dataAtual as datetime = '2020-5-15',
@ifr2Maximo as float = 98, @ifr14Maximo as float = 75

select pc10.codigo pc10, pc10.percentual_volume_quantidade, pc10.percentual_volume_negocios, pc10.percentual_candle_anterior, 
pc10.distancia_mm21, pc10.distancia_fechamento_anterior, pc10.INCLINACAO,
pc21.codigo as pc21, pc21.percentual_volume_quantidade, pc21.percentual_volume_negocios, pc21.percentual_candle_anterior, 
pc21.distancia_mm21, pc21.distancia_fechamento_anterior, pc21.INCLINACAO
from			
(select p2.codigo, p2.percentual_volume_quantidade, p2.percentual_volume_negocios, p1.percentual_candle as percentual_candle_anterior, p2.ValorMinimo, p2.ValorMaximo, p2.MM21, 
p2.Volatilidade, p2.distancia_mm21,
ROUND((p2.ValorMaximo  * (1 + p2.Volatilidade * 1.5 / 100) / p1.ValorFechamento- 1) * 100, 3) / 10 / p2.Volatilidade as distancia_fechamento_anterior,
CASE WHEN ROUND(P2.MM21, 2) > ROUND(P1.MM21,2) THEN 'SUBINDO' WHEN ROUND(P2.MM21,2) = ROUND(P1.MM21, 2) THEN 'LATERAL' ELSE 'DESCENDO' END AS INCLINACAO
from 
(select c.codigo, C.ValorMinimo, C.ValorMaximo, C.ValorFechamento, c.Titulos_Total, c.Negocios_Total, 
((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle, MM21.Valor AS MM21, 
c.Titulos_Total / MVOL.Valor as percentual_volume_quantidade, C.Negocios_Total / MND.Valor as percentual_volume_negocios
from Cotacao c 
inner join Media_Diaria MM10 on c.Codigo = MM10.Codigo and c.Data = MM10.Data and MM10.Tipo = 'MMA' AND MM10.NumPeriodos = 10
inner join Media_Diaria MM21 on c.Codigo = MM21.Codigo and c.Data = MM21.Data and MM21.Tipo = 'MMA' AND MM21.NumPeriodos = 21
inner join Media_Diaria MVOL on c.Codigo = MVOL.Codigo and c.Data = MVOL.Data and MVOL.Tipo = 'VMA' AND MVOL.NumPeriodos = 21
inner join MediaNegociosDiaria MND on c.Codigo = MND.Codigo and c.Data = MND.Data
where c.Data = @dataAnterior
AND C.ValorMaximo >= MM10.Valor) p1
inner join 
(
	select c.codigo, ValorAbertura, ValorFechamento, ValorMinimo, ValorMaximo, m10.Valor AS MM10, c.Titulos_Total, c.Negocios_Total
	, c.Titulos_Total / MVOL.Valor as percentual_volume_quantidade, C.Negocios_Total / MND.Valor as percentual_volume_negocios,
	 M21.VALOR AS MM21, dbo.MaxValue(VD.Valor, MVD.Valor) AS Volatilidade,
	((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle,
	ROUND((c.ValorMaximo  * (1 + dbo.MaxValue(VD.Valor, MVD.Valor) * 1.5 / 100) / m21.Valor- 1) * 100, 3) / 10 / dbo.MaxValue(VD.Valor, MVD.Valor) as distancia_mm21
	from Cotacao c 
	inner join Media_Diaria m10 on c.Codigo = m10.Codigo and c.Data = m10.Data and m10.Tipo = 'MMA' AND M10.NumPeriodos = 10
	inner join Media_Diaria m21 on c.Codigo = m21.Codigo and c.Data = m21.Data and m21.Tipo = 'MMA' AND M21.NumPeriodos = 21
	inner join IFR_Diario IFR2 on C.Codigo = IFR2.Codigo AND C.Data = IFR2.Data AND IFR2.NumPeriodos = 2
	inner join IFR_Diario IFR14 on C.Codigo = IFR14.Codigo AND C.Data = IFR14.Data AND IFR14.NumPeriodos = 14
	inner join Media_Diaria MVOL on c.Codigo = MVOL.Codigo and c.Data = MVOL.Data and MVOL.Tipo = 'VMA' AND MVOL.NumPeriodos = 21
	inner join MediaNegociosDiaria MND on c.Codigo = MND.Codigo and c.Data = MND.Data
	INNER JOIN VolatilidadeDiaria VD ON C.Codigo = VD.Codigo AND C.DATA = VD.Data
	LEFT JOIN MediaVolatilidadeDiaria MVD ON C.Codigo = MVD.Codigo AND C.DATA = MVD.Data
	where c.Data = @dataAtual
	AND M10.Valor > M21.Valor
	AND IFR2.Valor < @ifr2Maximo
	AND IFR14.Valor < @ifr14Maximo
	AND C.Negocios_Total >= 100
	AND C.Titulos_Total >= 100000
	AND C.Valor_Total >= 1000000
	AND C.ValorFechamento >= 1
	AND M10.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo
	--FECHOU ACIMA DA METADE DA AMPLITUDE
	AND C.valorfechamento > (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2)) 
	--VOLUME MAIOR OU IGUAL A 80% DA MÉDIA DO VOLUME
	AND c.Titulos_Total / MVOL.Valor >= @percentualMinimoVolume
	and c.Negocios_Total / MND.Valor >= @percentualMinimoVolume
	--amplitue maior que 10% volatilidade
	AND dbo.MaxValue(ABS(C.Oscilacao) / 100, C.ValorMaximo / C.ValorMinimo -1 ) >= dbo.MinValue(VD.Valor, MVD.Valor) / 10

) p2
on p1.codigo = p2.codigo
WHERE 

--CANDLE COMPRADOR OU QUE SUPEROU A MÁXIMA
--(P2.ValorFechamento > P2.ValorAbertura  OR P2.ValorMaximo > P1.ValorMaximo ) AND  

--NÃO PERMITIR CANDLE CANTIDO NO ANTERIOR
--AND NOT ((P2.ValorMinimo BETWEEN P1.ValorMinimo AND P1.ValorMaximo) AND (P2.ValorMaximo BETWEEN P1.ValorMinimo AND P1.ValorMaximo)) 
--FECHOU ACIMA DA MÉDIA OU ACIMA DA MÁXIMA DO CANDLE ANTERIOR

(p2.ValorFechamento > p2.MM10 OR P2.ValorFechamento > P1.ValorMaximo)
--evitar segundo candle com sombra acima do candle anterior
AND NOT P1.ValorMaximo BETWEEN P2.ValorFechamento AND P2.ValorMaximo

and p2.distancia_mm21 <= 2.5

AND 
(
	(
		-- MAIS VOLUME QUE O ANTERIOR E VOLUME MINIMO. SOMENTE EM ALTA
		dbo.MinValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualMinimoVolume
		AND p2.MM21 > p1.MM21  
	)
	OR
	(
	-- 120% DA MÉDIA AND 75% CANDLE. QUALQUER TENDENCIA
		p2.percentual_candle >= 0.5 
		AND dbo.MaxValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualVolumeRompimento 
		AND dbo.MinValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualDesejadoVolume
	) 
	OR
	(
		-- 130% DO VOLUME DO CANDLE ANTERIOR. QUALQUER TENDENCIA
		p2.percentual_candle >= 0.5 
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


) AS pc10
full outer join
--PONTO CONTINUO MMA 21

(select p2.codigo, p2.percentual_volume_quantidade, p2.percentual_volume_negocios, p1.percentual_candle as percentual_candle_anterior, p2.ValorMinimo, p2.ValorMaximo, p2.MM21, p2.Volatilidade, p2.distancia_mm21,
ROUND((p2.ValorMaximo  * (1 + p2.Volatilidade * 1.5 / 100) / p1.ValorFechamento- 1) * 100, 3) / 10 / p2.Volatilidade as distancia_fechamento_anterior,
CASE WHEN ROUND(P2.MM21, 2) > ROUND(P1.MM21,2) THEN 'SUBINDO' WHEN ROUND(P2.MM21,2) = ROUND(P1.MM21, 2) THEN 'LATERAL' ELSE 'DESCENDO' END AS INCLINACAO
from 
(select c.codigo, C.ValorMinimo, C.ValorMaximo, C.ValorFechamento, c.Titulos_Total, c.Negocios_Total, 
((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle, MM21.VALOR AS MM21,
c.Titulos_Total / MVOL.Valor as percentual_volume_quantidade, C.Negocios_Total / MND.Valor as percentual_volume_negocios
from Cotacao c 
inner join Media_Diaria MM10 on c.Codigo = MM10.Codigo and c.Data = MM10.Data and MM10.Tipo = 'MMA' AND MM10.NumPeriodos = 21
inner join Media_Diaria MM21 on c.Codigo = MM21.Codigo and c.Data = MM21.Data and MM21.Tipo = 'MMA' AND MM21.NumPeriodos = 21
inner join Media_Diaria MVOL on c.Codigo = MVOL.Codigo and c.Data = MVOL.Data and MVOL.Tipo = 'VMA' AND MVOL.NumPeriodos = 21
inner join MediaNegociosDiaria MND on c.Codigo = MND.Codigo and c.Data = MND.Data

where c.Data = @dataAnterior
AND C.ValorMaximo >= MM10.Valor) p1
inner join 
(
	select c.codigo, ValorAbertura, ValorFechamento, ValorMinimo, ValorMaximo, m.Valor as MM21, dbo.MaxValue(VD.Valor, MVD.Valor) as Volatilidade,
	c.Titulos_Total, c.Negocios_Total, c.Titulos_Total / MVOL.Valor as percentual_volume_quantidade, C.Negocios_Total / MND.Valor as percentual_volume_negocios,
	((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle,
	ROUND((c.ValorMaximo  * (1 + dbo.MaxValue(VD.Valor, MVD.Valor) * 1.5 / 100) / m.Valor - 1) * 100, 3) / 10 / dbo.MaxValue(VD.Valor, MVD.Valor) as distancia_mm21
	from Cotacao c 
	inner join Media_Diaria m on c.Codigo = m.Codigo and c.Data = m.Data and m.Tipo = 'MMA' AND M.NumPeriodos = 21
	inner join Media_Diaria MVOL on c.Codigo = MVOL.Codigo and c.Data = MVOL.Data and MVOL.Tipo = 'VMA' AND MVOL.NumPeriodos = 21
	inner join IFR_Diario IFR on C.Codigo = IFR.Codigo AND C.Data = IFR.Data AND IFR.NumPeriodos = 2
	inner join IFR_Diario IFR14 on C.Codigo = IFR14.Codigo AND C.Data = IFR14.Data AND IFR14.NumPeriodos = 14
	inner join MediaNegociosDiaria MND on c.Codigo = MND.Codigo and c.Data = MND.Data
	INNER JOIN VolatilidadeDiaria VD ON C.Codigo = VD.Codigo AND C.DATA = VD.Data
	LEFT JOIN MediaVolatilidadeDiaria MVD ON C.Codigo = MVD.Codigo AND C.DATA = MVD.Data
	where c.Data = @dataAtual
	AND IFR.Valor < @ifr2Maximo
	AND IFR14.Valor < @ifr14Maximo
	AND C.Negocios_Total >= 100
	AND C.Titulos_Total >= 100000
	AND C.Valor_Total >= 1000000
	AND C.ValorFechamento >= 1
	AND M.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo
	AND C.valorfechamento > (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2)) 
	--VOLUME MAIOR OU IGUAL A 80% DA MÉDIA DO VOLUME
	AND c.Titulos_Total / MVOL.Valor >= @percentualMinimoVolume
	and c.Negocios_Total / MND.Valor >= @percentualMinimoVolume

	AND dbo.MaxValue(ABS(C.Oscilacao) / 100, C.ValorMaximo / C.ValorMinimo -1 ) >= dbo.MinValue(VD.Valor, MVD.Valor) / 10

) p2	
on p1.codigo = p2.codigo
WHERE 
--FECHOU ACIMA DA MÉDIA OU ACIMA DA MÁXIMA DO CANDLE ANTERIOR
(p2.ValorFechamento > p2.MM21 OR P2.ValorFechamento > P1.ValorMaximo)
--evitar segundo candle com sombra acima do candle anterior
AND NOT P1.ValorMaximo BETWEEN P2.ValorFechamento AND P2.ValorMaximo

and p2.distancia_mm21 <= 2.5

AND 
(
	(
		-- MAIS VOLUME QUE O ANTERIOR E VOLUME MINIMO. SOMENTE EM ALTA
		dbo.MinValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualMinimoVolume
		AND p2.MM21 > p1.MM21  
	)
	OR
	(
	-- 120% DA MÉDIA AND 75% CANDLE. QUALQUER TENDENCIA
		p2.percentual_candle >= 0.5
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


) as pc21 on pc10.codigo = pc21.codigo
order by  case when pc21.Codigo is null then 0 else 1 end, pc10.Codigo, pc21.Codigo


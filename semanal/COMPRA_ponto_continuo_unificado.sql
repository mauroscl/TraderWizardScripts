--compra
DECLARE @percentualMinimoVolume as float = 0.8, @percentualDesejadoVolume as float = 1.0, @percentualVolumeRompimento as float = 1.2,
@dataAnterior as datetime = '2020-5-4', @dataAtual as datetime = '2020-5-11',
@ifr2Maximo as float = 98, @ifr14Maximo as float = 75

(select p2.codigo, p2.percentual_volume_quantidade, p2.percentual_volume_negocios, p2.percentual_candle as percentual_candle2, p2.ValorMinimo, p2.ValorMaximo, p2.MM21, p2.Volatilidade, p2.distancia,
ROUND((p2.ValorMaximo  * (1 + p2.Volatilidade * 1.5 / 100) / p1.ValorFechamento- 1) * 100, 3) / 10 / p2.Volatilidade as distancia_fechamento_anterior,
CASE WHEN ROUND(P2.MM21, 2) > ROUND(P1.MM21,2) THEN 'SUBINDO' WHEN ROUND(P2.MM21,2) = ROUND(P1.MM21, 2) THEN 'LATERAL' ELSE 'DESCENDO' END AS INCLINACAO,
ultimo_vendedor.data as data_ultimo_vendedor

from 
(select c.codigo, C.ValorMinimo, C.ValorMaximo, C.ValorFechamento, c.Titulos_Total, c.Negocios_Total, ((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle, MM21.Valor AS MM21, 
c.Titulos_Total / MVOL.Valor as percentual_volume_quantidade, C.Negocios_Total / MND.Valor as percentual_volume_negocios
from Cotacao_Semanal c inner join Media_Semanal m10 on c.Codigo = m10.Codigo and c.Data = m10.Data and m10.Tipo = 'MMA' AND M10.NumPeriodos = 10 
inner join Media_Semanal MM21 on c.Codigo = MM21.Codigo and c.Data = MM21.Data and MM21.Tipo = 'MMA' AND MM21.NumPeriodos = 21
inner join Media_Semanal MVOL on c.Codigo = MVOL.Codigo and c.Data = MVOL.Data and MVOL.Tipo = 'VMA' AND MVOL.NumPeriodos = 21
inner join MediaNegociosSemanal MND on c.Codigo = MND.Codigo and c.Data = MND.Data
where c.Data = @dataAnterior
AND (C.ValorMaximo >= M10.Valor OR C.ValorMaximo >= MM21.Valor)
) p1
inner join 
(
	select c.codigo, ValorAbertura, ValorFechamento, ValorMinimo, ValorMaximo, m10.Valor AS MM10, c.Titulos_Total, c.Negocios_Total
	, c.Titulos_Total / MVOL.Valor as percentual_volume_quantidade, C.Negocios_Total / MND.Valor as percentual_volume_negocios,
	 M21.VALOR AS MM21, dbo.MaxValue(VD.Valor, MVD.Valor) AS Volatilidade,
	((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle,
	ABS(ROUND((c.ValorMinimo  * (1 - dbo.MaxValue(VD.Valor, MVD.Valor) * 1.5 / 100) / m21.Valor - 1) * 100, 3) / 10 / dbo.MaxValue(VD.Valor, MVD.Valor)) as distancia
	from Cotacao_Semanal c 
	inner join Media_Semanal m10 on c.Codigo = m10.Codigo and c.Data = m10.Data and m10.Tipo = 'MMA' AND M10.NumPeriodos = 10
	inner join Media_Semanal m21 on c.Codigo = m21.Codigo and c.Data = m21.Data and m21.Tipo = 'MMA' AND M21.NumPeriodos = 21
	inner join IFR_Semanal IFR2 on C.Codigo = IFR2.Codigo AND C.Data = IFR2.Data AND IFR2.NumPeriodos = 2
	inner join IFR_Semanal IFR14 on C.Codigo = IFR14.Codigo AND C.Data = IFR14.Data AND IFR14.NumPeriodos = 14
	inner join Media_Semanal MVOL on c.Codigo = MVOL.Codigo and c.Data = MVOL.Data and MVOL.Tipo = 'VMA' AND MVOL.NumPeriodos = 21
	inner join MediaNegociosSemanal MND on c.Codigo = MND.Codigo and c.Data = MND.Data
	INNER JOIN VolatilidadeSemanal VD ON C.Codigo = VD.Codigo AND C.DATA = VD.Data
	LEFT JOIN MediaVolatilidadeSemanal MVD ON C.Codigo = MVD.Codigo AND C.DATA = MVD.Data
	where c.Data = @dataAtual
--	AND M10.Valor < M21.Valor
	AND IFR2.Valor <= @ifr2Maximo
	AND IFR14.Valor <= @ifr14Maximo
	AND C.Negocios_Total >= 100
	AND C.Titulos_Total >= 100000
	AND C.Valor_Total >= 1000000
	AND C.ValorFechamento >= 1
	AND (M10.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo OR M21.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo)
	--FECHOU ACIMA DA METADE DA AMPLITUDE
	AND C.valorfechamento > (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2)) 
	--VOLUME MAIOR OU IGUAL A 80% DA MÉDIA DO VOLUME
	AND c.Titulos_Total / MVOL.Valor >= @percentualMinimoVolume
	and c.Negocios_Total / MND.Valor >= @percentualMinimoVolume

	AND dbo.MaxValue(ABS(C.Oscilacao) / 100, C.ValorMaximo / C.ValorMinimo -1 ) >= dbo.MinValue(VD.Valor, MVD.Valor) / 10

) p2
on p1.codigo = p2.codigo
INNER JOIN
(
SELECT c.Codigo,  Max(C.Data) as data
FROM Cotacao_Semanal C
INNER JOIN VolatilidadeSemanal VD ON C.Codigo = VD.Codigo AND C.DATA = VD.Data
LEFT JOIN MediaVolatilidadeSemanal MVD ON C.Codigo = MVD.Codigo AND C.DATA = MVD.Data
WHERE 
c.ValorMinimo > 0
AND dbo.MaxValue(ABS(C.Oscilacao) / 100, C.ValorMaximo / C.ValorMinimo -1 ) >= dbo.MinValue(VD.Valor, MVD.Valor) / 10
AND C.valorfechamento < (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2))
GROUP BY C.Codigo
) as ultimo_vendedor
on p2.Codigo = ultimo_vendedor.Codigo

WHERE 
(p2.ValorFechamento < p2.MM10 OR p2.ValorFechamento < p2.MM21 OR P2.ValorFechamento < P1.ValorMinimo)

--evitar segundo candle com sombra acima do candle anterior
AND NOT P1.ValorMinimo BETWEEN P2.ValorFechamento AND P2.ValorMinimo


and p2.distancia <= 2.5

AND 
(
	(
		-- MAIS VOLUME QUE O ANTERIOR E VOLUME MINIMO. SOMENTE EM ALTA
		dbo.MinValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualMinimoVolume
		AND p2.MM21 < p1.MM21  
	)
	OR
	(
	-- 120% DA MÉDIA AND 75% CANDLE. QUALQUER TENDENCIA
		p2.percentual_candle <= 0.5 
		AND dbo.MaxValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualVolumeRompimento 
		AND dbo.MinValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualDesejadoVolume
	) 
	OR
	(
		-- 130% DO VOLUME DO CANDLE ANTERIOR. QUALQUER TENDENCIA
		p2.percentual_candle <= 0.5 
		AND p2.Titulos_Total / p1.Titulos_Total >= 1.3
		AND p2.Negocios_Total / p1.Negocios_Total >= 1.3
	)
	OR 
	(
		-- DOIS CANDLE COM VOLUME INTERMEDIARIO E CANDLE 50%. QUALQUER TENDENCIA
		p1.percentual_candle <= 0.5 and p2.percentual_candle <= 0.5
		AND dbo.MinValue(P1.percentual_volume_quantidade, P1.percentual_volume_negocios) >= @percentualDesejadoVolume
		AND dbo.MinValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualDesejadoVolume
	)
)

)



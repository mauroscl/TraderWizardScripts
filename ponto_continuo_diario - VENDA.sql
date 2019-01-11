----DIARIO
DECLARE @percentualMinimoVolume as float = 0.8, @percentualIntermediarioVolume as float = 0.9, @percentualDesejadoVolume as float = 1.0, 
@dataAnterior as datetime = '2018-11-12', @dataAtual as datetime = '2018-11-13',
@ifr2Minimo as float = 2, @ifr14Minimo as float = 25
	
select pc10.codigo pc10, pc10.percentual_volume_quantidade, pc10.percentual_volume_negocios, pc10.percentual_candle2, pc10.ValorMinimo, pc10.ValorMaximo, ROUND( pc10.MM21, 2) MM21, pc10.Volatilidade,
pc10.distancia ,
pc21.codigo as pc21, pc21.percentual_volume_quantidade, pc21.percentual_volume_negocios, pc21.percentual_candle2, pc21.ValorMinimo, pc21.ValorMaximo, ROUND(pc21.MM21,2) MM21, pc21.Volatilidade,	
pc21.distancia
from			
(select p2.codigo, p2.percentual_volume_quantidade, p2.percentual_volume_negocios, p2.percentual_candle as percentual_candle2, p2.ValorMinimo, p2.ValorMaximo, p2.MM21, p2.Volatilidade, p2.distancia
from 
(select c.codigo, C.ValorMinimo, C.ValorMaximo, c.Titulos_Total, c.Negocios_Total, ((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle
from Cotacao c inner join Media_Diaria m on c.Codigo = m.Codigo and c.Data = m.Data
where c.Data = @dataAnterior
and m.Tipo = 'MMA'
AND M.NumPeriodos = 10
AND C.ValorMinimo <= M.Valor) p1
inner join 
(
	select c.codigo, ValorAbertura, ValorFechamento, ValorMinimo, ValorMaximo, m10.Valor AS MM10, c.Titulos_Total, c.Negocios_Total
	, c.Titulos_Total / MVOL.Valor as percentual_volume_quantidade, C.Negocios_Total / MND.Valor as percentual_volume_negocios,
	 M21.VALOR AS MM21, dbo.MaxValue(VD.Valor, MVD.Valor) AS Volatilidade,
	((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle,
	ABS(ROUND((c.ValorMinimo  * (1 - dbo.MaxValue(VD.Valor, MVD.Valor) * 1.5 / 100) / m21.Valor - 1) * 100, 3) / 10 / dbo.MaxValue(VD.Valor, MVD.Valor)) as distancia
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
	AND M10.Valor < M21.Valor
	AND IFR2.Valor >= @ifr2Minimo
	AND IFR14.Valor >= @ifr14Minimo
	AND C.Negocios_Total >= 100
	AND C.Titulos_Total >= 100000
	AND C.Valor_Total >= 1000000
	AND C.ValorFechamento >= 1
	AND M10.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo
	--FECHOU ABAIXO DA METADE DA AMPLITUDE
	AND C.valorfechamento < (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2)) 
	--VOLUME MAIOR OU IGUAL A 80% DA M�DIA DO VOLUME
	AND c.Titulos_Total / MVOL.Valor >= @percentualMinimoVolume
	and c.Negocios_Total / MND.Valor >= @percentualMinimoVolume

	AND (C.ValorMaximo / C.ValorMinimo -1 ) >= dbo.MinValue(VD.Valor, MVD.Valor) / 10

) p2
on p1.codigo = p2.codigo
WHERE 
(p2.ValorFechamento < p2.MM10 OR P2.ValorFechamento < P1.ValorMinimo)


and p2.distancia <= 2.5
--volume maior que o anterior, ou dois ultimos candles positivos ou fechando acima da m�xima do candle anterior
AND (
       (dbo.MinValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualMinimoVolume
       AND (
			   (p2.Titulos_Total >= p1.Titulos_Total
			   AND p2.Negocios_Total >= p1.Negocios_Total)
			   OR p1.percentual_candle < 0.5
			   OR p2.ValorFechamento < p1.ValorMinimo
			   OR dbo.MinValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualDesejadoVolume
		   )
	   )

	OR
	(
		-- 130% DO CANDLE ANTERIOR. QUALQUER TENDENCIA
		p2.Titulos_Total / p1.Titulos_Total >= 1.3
		AND p2.Negocios_Total / p1.Negocios_Total >= 1.3
	)
)
) AS pc10
full outer join
--PONTO CONTINUO MMA 21

(select p2.codigo, p2.percentual_volume_quantidade, p2.percentual_volume_negocios, p2.percentual_candle as percentual_candle2, p2.ValorMinimo, p2.ValorMaximo, p2.MM21, p2.Volatilidade, p2.distancia
from 
(select c.codigo, C.ValorMinimo, C.ValorMaximo, c.Titulos_Total, c.Negocios_Total, ((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle
from Cotacao c inner join Media_Diaria m on c.Codigo = m.Codigo and c.Data = m.Data
where c.Data = @dataAnterior
and m.Tipo = 'MMA'
AND M.NumPeriodos = 21
AND C.ValorMinimo <= M.Valor) p1
inner join 
(
	select c.codigo, ValorAbertura, ValorFechamento, ValorMinimo, ValorMaximo, m.Valor as MM21, dbo.MaxValue(VD.Valor, MVD.Valor) as Volatilidade,
	M.Valor, c.Titulos_Total, c.Negocios_Total, c.Titulos_Total / MVOL.Valor as percentual_volume_quantidade, C.Negocios_Total / MND.Valor as percentual_volume_negocios,
	((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle,
	ABS(ROUND((c.ValorMinimo  * (1 + dbo.MaxValue(VD.Valor, MVD.Valor) * 1.5 / 100) / m.Valor - 1) * 100, 3) / 10 / dbo.MaxValue(VD.Valor, MVD.Valor)) as distancia
	from Cotacao c 
	inner join Media_Diaria m on c.Codigo = m.Codigo and c.Data = m.Data and m.Tipo = 'MMA' AND M.NumPeriodos = 21
	inner join Media_Diaria MVOL on c.Codigo = MVOL.Codigo and c.Data = MVOL.Data and MVOL.Tipo = 'VMA' AND MVOL.NumPeriodos = 21
	inner join IFR_Diario IFR on C.Codigo = IFR.Codigo AND C.Data = IFR.Data AND IFR.NumPeriodos = 2
	inner join IFR_Diario IFR14 on C.Codigo = IFR14.Codigo AND C.Data = IFR14.Data AND IFR14.NumPeriodos = 14
	inner join MediaNegociosDiaria MND on c.Codigo = MND.Codigo and c.Data = MND.Data
	INNER JOIN VolatilidadeDiaria VD ON C.Codigo = VD.Codigo AND C.DATA = VD.Data
	LEFT JOIN MediaVolatilidadeDiaria MVD ON C.Codigo = MVD.Codigo AND C.DATA = MVD.Data
	where c.Data = @dataAtual
	AND IFR.Valor > @ifr2Minimo
	AND IFR14.Valor > @ifr14Minimo
	AND C.Negocios_Total >= 100
	AND C.Titulos_Total >= 100000
	AND C.Valor_Total >= 1000000
	AND C.ValorFechamento >= 1
	AND M.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo
	AND C.valorfechamento < (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2)) 
	--VOLUME MAIOR OU IGUAL A 80% DA M�DIA DO VOLUME
	AND c.Titulos_Total / MVOL.Valor >= @percentualMinimoVolume
	and c.Negocios_Total / MND.Valor >= @percentualMinimoVolume

	AND (C.ValorMaximo / C.ValorMinimo -1 ) >= dbo.MinValue(VD.Valor, MVD.Valor) / 10
	AND (C.Oscilacao / 100) / (dbo.MaxValue(VD.Valor, MVD.Valor) / 10) >= -1.5

) p2	
on p1.codigo = p2.codigo
WHERE 

(p2.ValorFechamento < p2.MM21 OR P2.ValorFechamento < P1.ValorMinimo)

and p2.distancia <= 2.5

--volume maior que o anterior, ou dois ultimos candles positivos ou fechando acima da m�xima do candle anterior
AND (
       (dbo.MinValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualMinimoVolume
       AND (
			   (p2.Titulos_Total >= p1.Titulos_Total
			   AND p2.Negocios_Total >= p1.Negocios_Total)
			   OR p1.percentual_candle < 0.5
			   OR p2.ValorFechamento < p1.ValorMinimo
			   OR dbo.MinValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualDesejadoVolume
		   )
	   )

	OR
	(
		-- 130% DO CANDLE ANTERIOR. QUALQUER TENDENCIA
		p2.Titulos_Total / p1.Titulos_Total >= 1.3
		AND p2.Negocios_Total / p1.Negocios_Total >= 1.3
	)
)

) as pc21 on pc10.codigo = pc21.codigo
order by  case when pc21.Codigo is null then 0 else 1 end, pc10.Codigo, pc21.Codigo


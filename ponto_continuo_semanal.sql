                                                        ----SEMANAL
DECLARE @percentualMinimoVolume as float = 0.8, @percentualIntermediarioVolume as float = 0.9, @percentualDesejadoVolume as float = 1.0, 
@ifr2Maximo as float = 98, @ifr14Maximo as float = 75

--PONTO CONTINIUO (10)
DECLARE @dataInicial as datetime = '2018-1-29', @dataFinal as datetime = '2018-2-5'

select pc10.codigo pc10, pc10.percentual_volume_quantidade, pc10.percentual_candle, pc10.ValorMinimo, pc10.ValorMaximo, ROUND( pc10.MM21, 2) MM21, pc10.Volatilidade,
ROUND((pc10.ValorMaximo  * (1 + pc10.Volatilidade * 1.25 / 100) / pc10.MM21 - 1) * 100, 3) / 10 / pc10.Volatilidade AS distancia,

pc21.codigo as pc21, pc21.percentual_volume_quantidade, pc21.percentual_candle, pc21.ValorMinimo, pc21.ValorMaximo, ROUND(pc21.MM21,2) MM21, pc21.Volatilidade,
ROUND((pc21.ValorMaximo  * (1 + pc21.Volatilidade * 1.25 / 100) / pc21.MM21 - 1) * 100, 3) / 10 / pc21.Volatilidade AS distancia
from			
(select p2.codigo, p2.percentual_volume_quantidade, p2.percentual_candle, p2.ValorMinimo, p2.ValorMaximo, p2.MM21, p2.Volatilidade
from 
(
	select c.codigo, C.ValorMinimo, C.ValorMaximo, c.Titulos_Total
	from Cotacao_Semanal c inner join Media_Semanal m on c.Codigo = m.Codigo and c.Data = m.Data	
	where c.Data = @dataInicial
	and m.Tipo = 'MMA'
	AND M.NumPeriodos = 10
	AND C.ValorMaximo >= M.Valor
) p1
inner join 
(	
	select c.codigo, ValorAbertura, ValorFechamento, ValorMinimo, ValorMaximo, M10.Valor, c.Titulos_Total, 
	c.Titulos_Total / MVOL.Valor as percentual_volume_quantidade, 
	C.Negocios_Total / MNS.Valor as percentual_volume_negocios,
	M21.Valor AS MM21, dbo.MaxValue(VD.Valor, MVD.Valor) AS Volatilidade,
	((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle
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
	--VOLUME MAIOR OU IGUAL A 80% DA MÉDIA DO VOLUME
	AND c.Titulos_Total / MVOL.Valor >= @percentualMinimoVolume
	and c.Negocios_Total / MNS.Valor >= @percentualMinimoVolume

	AND (C.ValorMaximo / C.ValorMinimo -1 ) >= dbo.MinValue(VD.Valor, MVD.Valor) / 10

)  p2
on p1.codigo = p2.codigo
WHERE 
(P2.ValorFechamento > P2.ValorAbertura OR P2.ValorMaximo > P1.ValorMaximo )
--NAO ESTA CONTIDO NO CANDLE ANTERIOR
AND NOT ((P2.ValorMinimo BETWEEN P1.ValorMinimo AND P1.ValorMaximo) AND (P2.ValorMaximo BETWEEN P1.ValorMinimo AND P1.ValorMaximo)) 
--FECHOU ACIMA DA MÉDIA OU ACIMA DA MÁXIMA DO CANDLE ANTERIOR
AND  (p2.ValorFechamento > p2.Valor OR P2.ValorFechamento > P1.ValorMaximo)
--SEGUNDO CANDLE TEM MAIOR VOLUME QUE O CANDLE ANTERIOR OU ESTÁ PELO MENOS NA MÉDIA DO VOLUME
AND (
	(dbo.MinValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualIntermediarioVolume
	AND dbo.MaxValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualDesejadoVolume)  
	OR p2.Titulos_Total >= p1.Titulos_Total /* OR P2.ValorMaximo > P1.ValorMaximo*/
)
) as pc10

full outer join
--PONTO CONTINIUO (21)

(select p2.codigo, p2.percentual_volume_quantidade, p2.percentual_candle, p2.ValorMinimo, p2.ValorMaximo, p2.MM21, p2.Volatilidade
from 
(
	select c.codigo, C.ValorMinimo, C.ValorMaximo, c.Titulos_Total
	from Cotacao_Semanal c 
	inner join Media_Semanal m on c.Codigo = m.Codigo and c.Data = m.Data and m.Tipo = 'MMA' AND M.NumPeriodos = 21
	where c.Data = @dataInicial
	AND C.ValorMaximo >= M.Valor
) p1
inner join 
(
	select c.codigo, ValorAbertura, ValorFechamento, ValorMinimo, ValorMaximo
	, M.Valor as MM21, c.Titulos_Total, 
	c.Titulos_Total / MVOL.Valor as percentual_volume_quantidade,
	C.Negocios_Total / MNS.Valor as percentual_volume_negocios,
	dbo.MaxValue(VD.Valor, MVD.Valor) as Volatilidade,
	((C.ValorFechamento - C.ValorMinimo) / (C.ValorMaximo - C.ValorMinimo)) as percentual_candle
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
	--VOLUME MAIOR OU IGUAL A 80% DA MÉDIA DO VOLUME
	AND c.Titulos_Total / MVOL.Valor >= @percentualMinimoVolume
	and c.Negocios_Total / MNS.Valor >= @percentualMinimoVolume
	AND (C.ValorMaximo / C.ValorMinimo -1 ) >= dbo.MinValue(VD.Valor, MVD.Valor) / 10

)  p2
on p1.codigo = p2.codigo
WHERE 
--(P2.ValorFechamento > P2.ValorAbertura  OR P2.ValorMaximo > P1.ValorMaximo ) AND 
--NAO ESTA CONTIDO NO CANDLE ANTERIOR
--NOT ((P2.ValorMinimo BETWEEN P1.ValorMinimo AND P1.ValorMaximo) AND (P2.ValorMaximo BETWEEN P1.ValorMinimo AND P1.ValorMaximo)) AND
--FECHOU ACIMA DA MÉDIA OU ACIMA DA MÁXIMA DO CANDLE ANTERIOR
  (p2.ValorFechamento > p2.MM21 OR P2.ValorFechamento > P1.ValorMaximo)
--SEGUNDO CANDLE TEM MAIOR VOLUME QUE O CANDLE ANTERIOR OU ESTÁ PELO MENOS NA MÉDIA DO VOLUME
AND (
	(dbo.MinValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualIntermediarioVolume
	AND dbo.MaxValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualDesejadoVolume)  
	OR p2.Titulos_Total >= p1.Titulos_Total /* OR P2.ValorMaximo > P1.ValorMaximo*/
)
) as pc21
on pc10.codigo = pc21.codigo
order by  case when pc21.Codigo is null then 0 else 1 end, pc10.Codigo, pc21.Codigo



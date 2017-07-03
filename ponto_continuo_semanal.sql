----SEMANAL
DECLARE @percentualMinimoVolume as float = 0.8, @percentualDesejadoVolume as float = 1.0

--PONTO CONTINIUO (10)
DECLARE @dataInicial as datetime = '2017-6-19', @dataFinal as datetime = '2017-6-26'

select pc10.codigo pc10, pc10.percentual_volume, pc10.distancia, pc21.codigo as pc21, pc21.percentual_volume, pc21.distancia
from			
(select p2.codigo, p2.percentual_volume, p2.distancia
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
	select c.codigo, ValorAbertura, ValorFechamento, ValorMinimo, ValorMaximo, M10.Valor, c.Titulos_Total, c.Titulos_Total / MVOL.Valor as percentual_volume, 
	ROUND((C.ValorMaximo / m21.Valor - 1) * 100, 3)  AS distancia
	from Cotacao_Semanal c 
	inner join Media_Semanal m10 on c.Codigo = m10.Codigo and c.Data = m10.Data and m10.Tipo = 'MMA' AND M10.NumPeriodos = 10
	inner join Media_Semanal m21 on c.Codigo = m21.Codigo and c.Data = m21.Data and m21.Tipo = 'MMA' AND M21.NumPeriodos = 21
	inner join Media_Semanal MVOL on c.Codigo = MVOL.Codigo and c.Data = MVOL.Data and MVOL.Tipo = 'VMA' AND MVOL.NumPeriodos = 21
	where c.Data = @dataFinal
	AND C.Titulos_Total >= 500000
	AND C.ValorFechamento >= 1
	AND M10.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo
	--FECHOU ACIMA DA METADE DA AMPLITUDE
	AND C.valorfechamento > (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2))
	--VOLUME MAIOR OU IGUAL A 80% DA M�DIA DO VOLUME
	AND c.Titulos_Total / MVOL.Valor >= @percentualMinimoVolume
)  p2
on p1.codigo = p2.codigo
WHERE 
(P2.ValorFechamento > P2.ValorAbertura OR P2.ValorMaximo > P1.ValorMaximo )
--NAO ESTA CONTIDO NO CANDLE ANTERIOR
AND NOT ((P2.ValorMinimo BETWEEN P1.ValorMinimo AND P1.ValorMaximo) AND (P2.ValorMaximo BETWEEN P1.ValorMinimo AND P1.ValorMaximo)) 
--FECHOU ACIMA DA M�DIA OU ACIMA DA M�XIMA DO CANDLE ANTERIOR
AND  (p2.ValorFechamento > p2.Valor OR P2.ValorFechamento > P1.ValorMaximo)
--SEGUNDO CANDLE TEM MAIOR VOLUME QUE O CANDLE ANTERIOR OU EST� PELO MENOS NA M�DIA DO VOLUME
AND (P2.percentual_volume  >= @percentualDesejadoVolume OR p2.Titulos_Total >= p1.Titulos_Total OR P2.ValorMaximo > P1.ValorMaximo)
) as pc10

full outer join
--PONTO CONTINIUO (21)

(select p2.codigo, p2.percentual_volume, p2.distancia
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
	select c.codigo, ValorAbertura, ValorFechamento, ValorMinimo, ValorMaximo, M.Valor, c.Titulos_Total, c.Titulos_Total / MVOL.Valor as percentual_volume,
	ROUND((C.ValorMaximo / m.Valor - 1) * 100, 3)  AS distancia
	from Cotacao_Semanal c 
	inner join Media_Semanal m on c.Codigo = m.Codigo and c.Data = m.Data and m.Tipo = 'MMA' AND M.NumPeriodos = 21
	inner join Media_Semanal MVOL on c.Codigo = MVOL.Codigo and c.Data = MVOL.Data and MVOL.Tipo = 'VMA' AND MVOL.NumPeriodos = 21
	where c.Data = @dataFinal
	AND C.Titulos_Total >= 500000
	AND C.ValorFechamento >= 1
	AND M.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo
	AND C.valorfechamento > (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2))
	--VOLUME MAIOR OU IGUAL A 80% DA M�DIA DO VOLUME
	AND c.Titulos_Total / MVOL.Valor >= @percentualMinimoVolume
)  p2
on p1.codigo = p2.codigo
WHERE 
--(P2.ValorFechamento > P2.ValorAbertura  OR P2.ValorMaximo > P1.ValorMaximo ) AND 
--NAO ESTA CONTIDO NO CANDLE ANTERIOR
NOT ((P2.ValorMinimo BETWEEN P1.ValorMinimo AND P1.ValorMaximo) AND (P2.ValorMaximo BETWEEN P1.ValorMinimo AND P1.ValorMaximo)) 
--FECHOU ACIMA DA M�DIA OU ACIMA DA M�XIMA DO CANDLE ANTERIOR
AND  (p2.ValorFechamento > p2.Valor OR P2.ValorFechamento > P1.ValorMaximo)
--SEGUNDO CANDLE TEM MAIOR VOLUME QUE O CANDLE ANTERIOR OU EST� PELO MENOS NA M�DIA DO VOLUME
AND (P2.percentual_volume  >= @percentualDesejadoVolume OR p2.Titulos_Total >= p1.Titulos_Total OR P2.ValorMaximo > P1.ValorMaximo)
) as pc21
on pc10.codigo = pc21.codigo
order by  case when pc21.Codigo is null then 0 else 1 end, pc10.Codigo, pc21.Codigo



----SEMANAL
DECLARE @percentualMinimoVolume as float = 0.8, @percentualDesejadoVolume as float = 1.0

--PONTO CONTINIUO (10)
DECLARE @dataInicial as datetime = '2017-4-10', @dataFinal as datetime = '2017-4-17'

select pc10.codigo pc10, pc10.percentual_volume, pc21.codigo as pc21, pc21.percentual_volume
from			
(select p2.codigo, p2.percentual_volume
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
	select c.codigo, ValorAbertura, ValorFechamento, ValorMinimo, ValorMaximo, M.Valor, c.Titulos_Total, c.Titulos_Total / MVOL.Valor as percentual_volume
	from Cotacao_Semanal c 
	inner join Media_Semanal m on c.Codigo = m.Codigo and c.Data = m.Data and m.Tipo = 'MMA' AND M.NumPeriodos = 10
	inner join Media_Semanal MVOL on c.Codigo = MVOL.Codigo and c.Data = MVOL.Data and MVOL.Tipo = 'VMA' AND MVOL.NumPeriodos = 21
	where c.Data = @dataFinal
	AND C.Titulos_Total >= 500000
	AND C.ValorFechamento >= 1
	AND M.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo
	--FECHOU ACIMA DA METADE DA AMPLITUDE
	AND C.valorfechamento > (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2))
	--VOLUME MAIOR OU IGUAL A 80% DA MÉDIA DO VOLUME
	AND c.Titulos_Total / MVOL.Valor >= @percentualMinimoVolume
)  p2
on p1.codigo = p2.codigo
WHERE 
(P2.ValorFechamento > P2.ValorAbertura  OR P2.ValorMaximo > P1.ValorMaximo )
AND NOT ((P2.ValorMinimo BETWEEN P1.ValorMinimo AND P1.ValorMaximo) AND (P2.ValorMaximo BETWEEN P1.ValorMinimo AND P1.ValorMaximo)) 
--FECHOU ACIMA DA MÉDIA OU ACIMA DA MÁXIMA DO CANDLE ANTERIOR
AND  (p2.ValorFechamento > p2.Valor OR P2.ValorFechamento > P1.ValorMaximo)
--SEGUNDO CANDLE TEM MAIOR VOLUME QUE O CANDLE ANTERIOR OU ESTÁ PELO MENOS NA MÉDIA DO VOLUME
AND (P2.percentual_volume  >= @percentualDesejadoVolume OR p2.Titulos_Total >= p1.Titulos_Total)
) as pc10

full outer join
--PONTO CONTINIUO (21)

(select p2.codigo, p2.percentual_volume
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
	select c.codigo, ValorAbertura, ValorFechamento, ValorMinimo, ValorMaximo, M.Valor, c.Titulos_Total, c.Titulos_Total / MVOL.Valor as percentual_volume
	from Cotacao_Semanal c 
	inner join Media_Semanal m on c.Codigo = m.Codigo and c.Data = m.Data and m.Tipo = 'MMA' AND M.NumPeriodos = 21
	inner join Media_Semanal MVOL on c.Codigo = MVOL.Codigo and c.Data = MVOL.Data and MVOL.Tipo = 'VMA' AND MVOL.NumPeriodos = 21
	where c.Data = @dataFinal
	AND C.Titulos_Total >= 500000
	AND C.ValorFechamento >= 1
	AND M.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo
	AND C.valorfechamento > (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2))
	--VOLUME MAIOR OU IGUAL A 80% DA MÉDIA DO VOLUME
	AND c.Titulos_Total / MVOL.Valor >= @percentualMinimoVolume
)  p2
on p1.codigo = p2.codigo
WHERE 
(P2.ValorFechamento > P2.ValorAbertura  OR P2.ValorMaximo > P1.ValorMaximo )
AND NOT ((P2.ValorMinimo BETWEEN P1.ValorMinimo AND P1.ValorMaximo) AND (P2.ValorMaximo BETWEEN P1.ValorMinimo AND P1.ValorMaximo)) 
--FECHOU ACIMA DA MÉDIA OU ACIMA DA MÁXIMA DO CANDLE ANTERIOR
AND  (p2.ValorFechamento > p2.Valor OR P2.ValorFechamento > P1.ValorMaximo)
--SEGUNDO CANDLE TEM MAIOR VOLUME QUE O CANDLE ANTERIOR OU ESTÁ PELO MENOS NA MÉDIA DO VOLUME
AND (P2.percentual_volume  >= @percentualDesejadoVolume OR p2.Titulos_Total >= p1.Titulos_Total)
) as pc21
on pc10.codigo = pc21.codigo
order by  case when pc21.Codigo is null then 0 else 1 end, pc10.Codigo, pc21.Codigo



----DIARIO


--PONTO CONTINUO MMA 10
declare @dataAnterior as datetime = '2017-1-18', @dataAtual as datetime = '2017-1-19'

select pc10.codigo pc10, pc21.codigo as pc21
from 
(select p2.codigo
from 
(select c.codigo, C.ValorMinimo, C.ValorMaximo
from Cotacao c inner join Media_Diaria m on c.Codigo = m.Codigo and c.Data = m.Data
where c.Data = @dataAnterior
and m.Tipo = 'MMA'
AND M.NumPeriodos = 10
AND C.ValorMaximo >= M.Valor) p1
inner join 
(
	select c.codigo, ValorAbertura, ValorFechamento, ValorMinimo, ValorMaximo, m.Valor
	from Cotacao c inner join Media_Diaria m on c.Codigo = m.Codigo and c.Data = m.Data and m.Tipo = 'MMA' 	AND M.NumPeriodos = 10
	inner join IFR_Diario IFR2 on C.Codigo = IFR2.Codigo AND C.Data = IFR2.Data AND IFR2.NumPeriodos = 2
--	inner join IFR_Diario IFR14 on C.Codigo = IFR14.Codigo AND C.Data = IFR14.Data AND IFR14.NumPeriodos = 14
	where c.Data = @dataAtual
	AND IFR2.Valor < 90
	--AND IFR14.Valor < 65
	AND C.Titulos_Total >= 100000
	AND C.ValorFechamento >= 1
	AND M.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo
	--FECHOU ACIMA DA METADE DA AMPLITUDE
	AND C.valorfechamento > (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2)) 
) p2
on p1.codigo = p2.codigo
WHERE 
--CANDLE COMPRADOR OU QUE SUPEROU A MÁXIMA
(P2.ValorFechamento > P2.ValorAbertura  OR P2.ValorMaximo > P1.ValorMaximo )
--NÃO PERMITIR CANDLE CANTIDO NO ANTERIOR
AND NOT ((P2.ValorMinimo BETWEEN P1.ValorMinimo AND P1.ValorMaximo) AND (P2.ValorMaximo BETWEEN P1.ValorMinimo AND P1.ValorMaximo)) 
--FECHOU ACIMA DA MÉDIA OU ACIMA DA MÁXIMA DO CANDLE ANTERIOR
AND  (p2.ValorFechamento > p2.Valor OR P2.ValorFechamento > P1.ValorMaximo)
) AS pc10
full outer join
--PONTO CONTINUO MMA 21

(select p2.codigo
from 
(select c.codigo, C.ValorMinimo, C.ValorMaximo
from Cotacao c inner join Media_Diaria m on c.Codigo = m.Codigo and c.Data = m.Data
where c.Data = @dataAnterior
and m.Tipo = 'MMA'
AND M.NumPeriodos = 21
AND C.ValorMaximo >= M.Valor) p1
inner join 
(
	select c.codigo, ValorAbertura, ValorFechamento, ValorMinimo, ValorMaximo, M.Valor
	from Cotacao c inner join Media_Diaria m on c.Codigo = m.Codigo and c.Data = m.Data and m.Tipo = 'MMA' 	AND M.NumPeriodos = 21
	inner join IFR_Diario IFR on C.Codigo = IFR.Codigo AND C.Data = IFR.Data AND IFR.NumPeriodos = 2
	--inner join IFR_Diario IFR14 on C.Codigo = IFR14.Codigo AND C.Data = IFR14.Data AND IFR14.NumPeriodos = 14
	where c.Data = @dataAtual
	AND IFR.Valor < 90
	--AND IFR14.Valor < 65
	AND C.Titulos_Total >= 100000
	AND C.ValorFechamento >= 1
	AND M.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo
	AND C.valorfechamento > (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2)) 
) p2
on p1.codigo = p2.codigo
WHERE (P2.ValorFechamento > P2.ValorAbertura  OR P2.ValorMaximo > P1.ValorMaximo )
AND NOT ((P2.ValorMinimo BETWEEN P1.ValorMinimo AND P1.ValorMaximo) AND (P2.ValorMaximo BETWEEN P1.ValorMinimo AND P1.ValorMaximo)) 
--FECHOU ACIMA DA MÉDIA OU ACIMA DA MÁXIMA DO CANDLE ANTERIOR
AND  (p2.ValorFechamento > p2.Valor OR P2.ValorFechamento > P1.ValorMaximo)

) as pc21 on pc10.codigo = pc21.codigo
order by  case when pc21.Codigo is null then 0 else 1 end, pc10.Codigo, pc21.Codigo

--entrada no ifr < 10
--select p2.codigo, 
--CASE WHEN p2.valorfechamento > (p2.valorminimo + Round((p2.valormaximo - p2.valorminimo) / 2,2)) THEN 'COMPRADOR' ELSE 'VENDEDOR' END AS VIES
--from 
--(select c.Codigo
--from cotacao c inner join IFR_Diario ifr on c.Codigo = ifr.Codigo and c.Data = ifr.Data
--where c.Data = '2016-8-16'
--and ifr.NumPeriodos = 2
--and ifr.Valor > 10) p1 
--inner join 
--(select c.Codigo, ValorFechamento, ValorMinimo, ValorMaximo
--from cotacao c inner join IFR_Diario ifr on c.Codigo = ifr.Codigo and c.Data = ifr.Data
--where c.Data = '2016-8-17'
--AND C.Titulos_Total >= 100000
--AND C.ValorFechamento >= 1
--and ifr.NumPeriodos = 2
--and ifr.Valor <= 10) p2 
--on p1.codigo = p2.codigo

----SEMANAL

--PONTO CONTINIUO (10)
DECLARE @dataInicial as datetime = '2016-12-26', @dataFinal as datetime = '2017-1-2'

select pc10.codigo pc10, pc21.codigo as pc21
from 
(select p2.codigo
from 
(
	select c.codigo, C.ValorMinimo, C.ValorMaximo
	from Cotacao_Semanal c inner join Media_Semanal m on c.Codigo = m.Codigo and c.Data = m.Data
	where c.Data = @dataInicial
	and m.Tipo = 'MMA'
	AND M.NumPeriodos = 10
	AND C.ValorMaximo >= M.Valor
) p1
inner join 
(
	select c.codigo, ValorAbertura, ValorFechamento, ValorMinimo, ValorMaximo, M.Valor
	from Cotacao_Semanal c inner join Media_Semanal m on c.Codigo = m.Codigo and c.Data = m.Data
	where c.Data = @dataFinal
	AND C.Titulos_Total >= 500000
	AND C.ValorFechamento >= 1
	and m.Tipo = 'MMA'
	AND M.NumPeriodos = 10
	AND M.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo
	AND C.valorfechamento > (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2))
)  p2
on p1.codigo = p2.codigo
WHERE 
(P2.ValorFechamento > P2.ValorAbertura  OR P2.ValorMaximo > P1.ValorMaximo )
AND NOT ((P2.ValorMinimo BETWEEN P1.ValorMinimo AND P1.ValorMaximo) AND (P2.ValorMaximo BETWEEN P1.ValorMinimo AND P1.ValorMaximo)) 
--FECHOU ACIMA DA MÉDIA OU ACIMA DA MÁXIMA DO CANDLE ANTERIOR
AND  (p2.ValorFechamento > p2.Valor OR P2.ValorFechamento > P1.ValorMaximo)

) as pc10

full outer join
--PONTO CONTINIUO (21)

(select p2.codigo
from 
(
	select c.codigo, C.ValorMinimo, C.ValorMaximo
	from Cotacao_Semanal c inner join Media_Semanal m on c.Codigo = m.Codigo and c.Data = m.Data
	where c.Data = @dataInicial
	and m.Tipo = 'MMA'
	AND M.NumPeriodos = 10
	AND C.ValorMaximo >= M.Valor
) p1
inner join (select c.codigo, ValorAbertura, ValorFechamento, ValorMinimo, ValorMaximo, M.Valor
from Cotacao_Semanal c inner join Media_Semanal m on c.Codigo = m.Codigo and c.Data = m.Data
where c.Data = @dataFinal
AND C.Titulos_Total >= 500000
AND C.ValorFechamento >= 1
and m.Tipo = 'MMA'
AND M.NumPeriodos = 21
AND M.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo
AND C.valorfechamento > (C.valorminimo + Round((C.valormaximo - C.valorminimo) / 2,2))
)  p2
on p1.codigo = p2.codigo
WHERE 
(P2.ValorFechamento > P2.ValorAbertura  OR P2.ValorMaximo > P1.ValorMaximo )
AND NOT ((P2.ValorMinimo BETWEEN P1.ValorMinimo AND P1.ValorMaximo) AND (P2.ValorMaximo BETWEEN P1.ValorMinimo AND P1.ValorMaximo)) 
--FECHOU ACIMA DA MÉDIA OU ACIMA DA MÁXIMA DO CANDLE ANTERIOR
AND  (p2.ValorFechamento > p2.Valor OR P2.ValorFechamento > P1.ValorMaximo)

) as pc21
on pc10.codigo = pc21.codigo
order by  case when pc21.Codigo is null then 0 else 1 end, pc10.Codigo, pc21.Codigo


--IFR2
--select p2.codigo, 
--CASE WHEN p2.valorfechamento > (p2.valorminimo + Round((p2.valormaximo - p2.valorminimo) / 2,2)) THEN 'COMPRADOR' ELSE 'VENDEDOR' END AS VIES
--from 
--(select c.Codigo
--from Cotacao_Semanal c inner join IFR_Semanal ifr on c.Codigo = ifr.Codigo and c.Data = ifr.Data
--where c.Data = '2016-7-25'
--and ifr.NumPeriodos = 2
--and ifr.Valor > 10) p1 
--inner join 
--(select c.Codigo, ValorFechamento, ValorMinimo, ValorMaximo
--from Cotacao_Semanal c inner join IFR_Semanal ifr on c.Codigo = ifr.Codigo and c.Data = ifr.Data
--where c.Data = '2016-8-1'
--AND C.Titulos_Total >= 500000
--AND C.ValorFechamento >= 1
--and ifr.NumPeriodos = 2
--and ifr.Valor <= 10) p2 
--on p1.codigo = p2.codigo


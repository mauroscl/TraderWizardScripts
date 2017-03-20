----SEMANAL

--PONTO CONTINIUO (10)
DECLARE @dataInicial as datetime = '2017-3-6', @dataFinal as datetime = '2017-3-13'

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


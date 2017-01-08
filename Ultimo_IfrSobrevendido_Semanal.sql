declare @dataAnterior as datetime = '2016-10-24', @dataAtual as datetime = '2016-10-31'
select sobrevendido.Codigo, Data
FROM
(SELECT IFR.CODIGO, MAX(IFR.DATA) AS DATA
FROM IFR_Semanal IFR 
INNER JOIN Cotacao_Semanal C ON IFR.CODIGO =  C.CODIGO AND IFR.DATA = C.DATA
WHERE IFR.Valor <= 10
AND IFR.CODIGO NOT LIKE '%34'
AND C.Titulos_Total >=500000
AND C.Valor_Total >= 5000000
AND C.Negocios_Total >= 500
and c.ValorFechamento >= 1
AND NOT EXISTS 
(
	select 1 
	from IFR_Semanal IfrSobreComprado 
	WHERE IFR.Codigo = IfrSobreComprado.Codigo
	AND IfrSobreComprado.[Data] > IFR.[Data]
	AND IfrSobreComprado.Valor >= 90
)
AND NOT EXISTS 
(
	SELECT 1 
	FROM IfrSobrevendidoDescartadoSemanal ISDS
	WHERE IFR.Codigo = ISDS.Codigo
	and ISDS.[Data] > IFR.[Data]
)

GROUP BY IFR.CODIGO) as sobrevendido INNER JOIN
(
	select p1.Codigo
	from
	(
		select c.Codigo, c.ValorMinimo, c.ValorMaximo
		from Cotacao_Semanal c
		where c.Data = @dataAnterior
	) as p1
	inner join
	(
		select c.Codigo, c.ValorMinimo, c.ValorMaximo
		from Cotacao_Semanal c inner join Media_Semanal mm10 on c.Codigo = mm10.Codigo and c.Data = mm10.Data
		inner join Media_Semanal mm21 on c.Codigo = mm21.Codigo and c.Data = mm21.Data
		where c.Data = @dataAtual
		--CANDLE COMPRADOR
		and (c.ValorMaximo - c.ValorFechamento) < (c.ValorFechamento - c.ValorMinimo)
		and mm10.Tipo = 'MMA'
		and mm10.NumPeriodos = 10
		--NÃO ESTÁ TOCANDO A MMA 10
		and not (mm10.Valor between c.ValorMinimo and c.ValorFechamento)
		and mm21.Tipo = 'MMA'
		and mm21.NumPeriodos = 21
		--NÃO ESTÁ TOCANDO A MMA 21
		and not (mm21.Valor between c.ValorMinimo and c.ValorFechamento)

	) as p2
	on p1.Codigo = p2.Codigo
	--NÃO ESTÁ CONTIDO NO CANDLE ANTERIOR
	where NOT ((P2.ValorMinimo BETWEEN P1.ValorMinimo AND P1.ValorMaximo) AND (P2.ValorMaximo BETWEEN P1.ValorMinimo AND P1.ValorMaximo)) 
) as atual on sobrevendido.Codigo = atual.Codigo
order by Data desc

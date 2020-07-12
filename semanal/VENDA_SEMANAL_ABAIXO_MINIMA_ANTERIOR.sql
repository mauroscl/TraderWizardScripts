DECLARE 
@percentualMinimoVolume as float = 0.8, @percentualDesejadoVolume as float = 1.0,
@data1 as date = '2020-6-8', @data2 as date = '2020-6-15', @data3 as date = '2020-6-22'
select p2.codigo, CASE WHEN P3.MM21 > P2.MM21 THEN 'SUBINDO' WHEN P3.MM21 = P2.MM21 THEN 'LATERAL' ELSE 'DESCENDO' END AS INCLINACAO,
ROUND((P3.ValorMaximo  * (1 + P3.Volatilidade * 1.5 / 100) / P2.ValorFechamento - 1) * 100, 3) / 10 / P3.Volatilidade AS distancia_fechamento_anterior
from 
(
	SELECT c.Codigo, c.ValorMinimo, c.ValorFechamento, M.Valor AS MM21
	FROM Cotacao_Semanal C
	INNER JOIN Media_Semanal M ON C.Codigo = M.Codigo AND C.Data = M.Data AND M.NumPeriodos = 21 AND M.Tipo = 'MMA'
	WHERE C.Data = @data1
) AS p1
INNER JOIN 
(
	SELECT c.Codigo, C.ValorMinimo, c.ValorMaximo, c.ValorFechamento, MM21.Valor as MM21, C.Titulos_Total, C.Negocios_Total,
	dbo.MinValue(VLT.Valor, MVLT.Valor) AS VolatilidadeMinima
	FROM Cotacao_Semanal C
	INNER JOIN Media_Semanal MM21 ON C.Codigo = MM21.Codigo AND C.Data = MM21.Data AND MM21.NumPeriodos = 21 AND MM21.Tipo = 'MMA'
	INNER JOIN Media_Semanal MM10 ON C.Codigo = MM10.Codigo AND C.Data = MM10.Data AND MM10.NumPeriodos = 10 AND MM10.Tipo = 'MMA'
	INNER JOIN VolatilidadeSemanal VLT ON C.Codigo = VLT.Codigo AND C.DATA = VLT.Data
	LEFT JOIN MediaVolatilidadeSemanal MVLT ON C.Codigo = MVLT.Codigo AND C.DATA = MVLT.Data
	WHERE C.Data = @data2
	AND (C.ValorMaximo >= MM21.Valor OR C.ValorMaximo >= MM10.Valor)
) AS p2
on p1.codigo = p2.codigo
INNER JOIN 

(
SELECT c.codigo, C.ValorFechamento, C.ValorMinimo, C.ValorMaximo, MM21.Valor as MM21, C.Titulos_Total, C.Negocios_Total,
dbo.MaxValue(VLT.Valor, MVLT.Valor) as Volatilidade,
c.Titulos_Total / MVOL.Valor as percentual_volume_quantidade, C.Negocios_Total / MN.Valor as percentual_volume_negocios
FROM Cotacao_Semanal C INNER JOIN IFR_Semanal IFR ON C.Data = IFR.Data AND C.Codigo = IFR.Codigo AND IFR.NumPeriodos = 14
INNER JOIN Media_Semanal MM10 ON C.Codigo = MM10.Codigo AND C.Data = MM10.Data AND MM10.NumPeriodos = 10 AND MM10.Tipo = 'MMA'
INNER JOIN Media_Semanal MM21 ON C.Codigo = MM21.Codigo AND C.Data = MM21.Data AND MM21.NumPeriodos = 21 AND MM21.Tipo = 'MMA'
INNER JOIN MediaNegociosSemanal MN on c.Codigo = MN.Codigo and c.Data = MN.Data
INNER JOIN Media_Semanal MVOL on c.Codigo = MVOL.Codigo and c.Data = MVOL.Data and MVOL.Tipo = 'VMA' AND MVOL.NumPeriodos = 21
INNER JOIN VolatilidadeSemanal VLT ON C.Codigo = VLT.Codigo AND C.DATA = VLT.Data
LEFT JOIN MediaVolatilidadeSemanal MVLT ON C.Codigo = MVLT.Codigo AND C.DATA = MVLT.Data

WHERE C.Data = @data3
AND IFR.Valor >= 35
and (c.ValorMaximo - c.ValorFechamento) > (c.ValorFechamento - c.ValorMinimo) --fechou abaixo da metade do candle

--distancia  entre a minima e a volatilidade
AND ABS(ROUND((c.ValorMinimo  * (1 - dbo.MaxValue(VLT.Valor, MVLT.Valor) * 1.5 / 100) / MM21.Valor - 1) * 100, 3) / 10 / dbo.MaxValue(VLT.Valor, MVLT.Valor)) <= 2.5
--remove os candles que se enquadram no ponto continuo
--AND (
--  --ABAIXO DA VOLATILIDADE
--  dbo.MaxValue(ABS(C.Oscilacao) / 100, C.ValorMaximo / C.ValorMinimo -1 ) <= dbo.MinValue(VLT.Valor, MVLT.Valor) / 10
--  --QUANDO NÃO ESTÁ TOCANDO NEM A MÉDIA DE 10 NEM A MÉDIA DE 21
--  OR (NOT MM10.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo AND NOT MM21.Valor BETWEEN C.ValorMinimo AND C.ValorMaximo)
--)
) as p3
on p2.codigo = p3.codigo
where 
(
	--SEGUNDO CANDLE FECHOU ACIMA DA MINIMA DO PRIMEIRO CANDLE
	P2.ValorFechamento > p1.ValorMinimo
	--ULTIMO CANDLE ESTÁ MAIS DA METADE ABAIXO DA MÉDIA E PENULTIMO CANDLE ESTÁ MAIS DA METADE ACIMA DA MÉDIA (A IDÉIA É PEGAR O PRIMEIRO CANDLE QUE CRUZA A MÉDIA)
	OR (P3.MM21 - P3.ValorMinimo > P3.ValorMaximo - P3.MM21  AND P2.MM21 - P2.ValorMinimo < P2.ValorMaximo - P2.MM21  ) 
)

--quando amplitude do movimento anterior (p2) for maior que a volatilidade, se o movimento for positivo, o candle de p3 deve fechar abaixo da minima de p2
AND (
P3.ValorFechamento < P2.ValorMinimo
OR (P3.ValorMinimo < P2.ValorMinimo
		AND(
		 ((P2.ValorMaximo - P2.ValorFechamento) > (P2.ValorFechamento - P2.ValorMinimo)) --fechou abaixo da metade da metadade da amplitude
		OR ((P2.ValorMaximo / P2.ValorMinimo -1 ) < P2.VolatilidadeMinima / 10) --amplitude menor que a volatilidade mínima
		))
)

AND 
(
	--media descendo
	P3.MM21 < P2.MM21 
	--nao está tocando na média e a distancia do valor minimo para  a média é maior que a amplitude do candle
	OR (NOT P3.MM21 BETWEEN P3.ValorMinimo AND P3.ValorMaximo AND (P3.ValorMinimo - p3.MM21 > P3.ValorMaximo - P3.ValorMinimo))
	-- mais da metade do candle está abaixo da média
	OR (P3.ValorMaximo - P3.MM21 < P3.MM21 - P3.ValorMinimo )
)

AND (
	   --garante que tem sempre o percentual mínimo de volume
       (dbo.MinValue(P3.percentual_volume_quantidade, P3.percentual_volume_negocios) >= @percentualMinimoVolume
       AND (
				--tem aumento de volume em titulos e negócios
			   (p3.Titulos_Total >= p2.Titulos_Total AND p3.Negocios_Total >= p2.Negocios_Total)
			   --mesmo que não tenha aumento de volume garante que o percentual está no desejado
			   OR dbo.MinValue(P3.percentual_volume_quantidade, P3.percentual_volume_negocios) >= @percentualDesejadoVolume
		   )
	   )

	OR
	(
		-- 130% DO CANDLE ANTERIOR. QUALQUER TENDENCIA
		p3.Titulos_Total / p2.Titulos_Total >= 1.3
		AND p3.Negocios_Total / p2.Negocios_Total >= 1.3
	)
)



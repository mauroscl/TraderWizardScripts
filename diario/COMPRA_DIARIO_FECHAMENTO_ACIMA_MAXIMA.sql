DECLARE			
@percentualMinimoVolume as float = 0.8, @percentualDesejadoVolume as float = 1.0,
@data1 as date = '2020-5-13', @data2 as date = '2020-5-14', @data3 as date = '2020-5-15'
select p2.codigo, CASE WHEN P3.MM21 > P2.MM21 THEN 'SUBINDO' WHEN P3.MM21 = P2.MM21 THEN 'LATERAL' ELSE 'DESCENDO' END AS INCLINACAO,
ROUND((P3.ValorMaximo  * (1 + P3.Volatilidade * 1.5 / 100) / P2.ValorFechamento - 1) * 100, 3) / 10 / P3.Volatilidade AS distancia_fechamento_anterior

from 
(	
	SELECT c.Codigo, c.ValorMaximo, c.ValorFechamento, M.Valor as MM21
	FROM Cotacao C
	INNER JOIN Media_Diaria M ON C.Codigo = M.Codigo AND C.Data = M.Data AND M.NumPeriodos = 21 AND M.Tipo = 'MMA'
	WHERE C.Data = @data1
) AS p1
INNER JOIN 
(
	SELECT c.Codigo, c.ValorMaximo, c.ValorMinimo, c.ValorFechamento, MM21.Valor as MM21, C.Titulos_Total, C.Negocios_Total
	FROM Cotacao C
	INNER JOIN Media_Diaria MM21 ON C.Codigo = MM21.Codigo AND C.Data = MM21.Data AND MM21.NumPeriodos = 21 AND MM21.Tipo = 'MMA'
	INNER JOIN Media_Diaria MM10 ON C.Codigo = MM10.Codigo AND C.Data = MM10.Data AND MM10.NumPeriodos = 10 AND MM10.Tipo = 'MMA'
	WHERE C.Data = @data2
	AND (C.ValorMinimo <= MM21.Valor OR C.ValorMinimo <= MM10.Valor)
) AS p2
on p1.codigo = p2.codigo
INNER JOIN 

(
SELECT c.codigo, C.ValorFechamento, C.ValorMinimo, C.ValorMaximo, M.Valor AS MM21, C.Titulos_Total, C.Negocios_Total,
dbo.MaxValue(VD.Valor, MVD.Valor) as Volatilidade,
c.Titulos_Total / MVOL.Valor as percentual_volume_quantidade, C.Negocios_Total / MND.Valor as percentual_volume_negocios
FROM Cotacao C INNER JOIN IFR_Diario IFR ON C.Data = IFR.Data AND C.Codigo = IFR.Codigo AND IFR.NumPeriodos = 14
INNER JOIN Media_Diaria M ON C.Codigo = M.Codigo AND C.Data = M.Data AND M.NumPeriodos = 21 AND M.Tipo = 'MMA'
INNER JOIN MediaNegociosDiaria MND on c.Codigo = MND.Codigo and c.Data = MND.Data
INNER JOIN Media_Diaria MVOL on c.Codigo = MVOL.Codigo and c.Data = MVOL.Data and MVOL.Tipo = 'VMA' AND MVOL.NumPeriodos = 21
INNER JOIN VolatilidadeDiaria VD ON C.Codigo = VD.Codigo AND C.DATA = VD.Data
LEFT JOIN MediaVolatilidadeDiaria MVD ON C.Codigo = MVD.Codigo AND C.DATA = MVD.Data

where C.Data = @data3
AND IFR.Valor <= 65
--and (c.ValorMaximo - c.ValorFechamento) < (c.ValorFechamento - c.ValorMinimo) --fechou acima da metade do candle
AND ROUND((c.ValorMaximo  * (1 + dbo.MaxValue(VD.Valor, MVD.Valor) * 1.5 / 100) / M.Valor- 1) * 100, 3) / 10 / dbo.MaxValue(VD.Valor, MVD.Valor) <= 2.5

) as p3

on p2.codigo = p3.codigo
	where 
(
	--SEGUNDO CANDLE FECHOU ABAIXO DA MÁXIMA DO PRIMEIRO CANDLE
	P2.ValorFechamento <= p1.ValorMaximo

	--ULTIMO CANDLE ESTÁ MAIS DA METADE ACIMA DA MEDIA E PENULTIMO CANDLE ESTÁ MAIS DA METADE ABAIXO DA MÉDIA (A IDÉIA É PEGAR O PRIMEIRO CANDLE QUE CRUZA A MÉDIA)
	OR (/*P2.MM21 <= P1.MM21 AND */ P3.ValorMaximo - P3.MM21 > P3.MM21 - P3.ValorMinimo AND P2.ValorMaximo - P2.MM21 < P2.MM21 - P2.ValorMinimo  ) 
)

AND P3.ValorFechamento > P2.ValorMaximo

AND 
(
	--media subindo
	P3.MM21 > P2.MM21 
	--nao está tocando na média e a distancia do valor maximo para  a média é maior que a amplitude do candle
	OR (
	NOT P3.MM21 BETWEEN P3.ValorMinimo AND P3.ValorMaximo AND (p3.MM21 - P3.ValorMaximo > P3.ValorMaximo - P3.ValorMinimo)
	)
	-- mais da metade do candle está acima da média
	OR (P3.ValorMaximo - P3.MM21 > P3.MM21 - P3.ValorMinimo )
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



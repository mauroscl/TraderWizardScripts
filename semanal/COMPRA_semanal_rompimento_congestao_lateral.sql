DECLARE	@data1 as date = '2021-9-27', @data2 as date = '2021-10-4', @percentualMinimoVolume as float = 0.8, @percentualDesejadoVolume as float = 1.0

select p1.codigo, CASE WHEN P2.MM21 > P1.MM21 THEN 'SUBINDO' WHEN P2.MM21 = P1.MM21 THEN 'LATERAL' ELSE 'DESCENDO' END AS INCLINACAO,
ROUND((P2.ValorMaximo  * (1 + P2.Volatilidade * 1.5 / 100) / P1.ValorFechamento - 1) * 100, 3) / 10 / P2.Volatilidade AS distancia_fechamento_anterior
from
(	
	SELECT c.Codigo, c.ValorMaximo, c.ValorFechamento, C.Titulos_Total, C.Negocios_Total, M.Valor as MM21
	FROM Cotacao_Semanal C
	INNER JOIN Media_Semanal M ON C.Codigo = M.Codigo AND C.Data = M.Data AND M.NumPeriodos = 21 AND M.Tipo = 'MMA'
	WHERE C.Data = @data1
) AS p1
INNER JOIN 

(
	select C1.Codigo, C1.Sequencial, C1.ValorFechamento, C1.ValorMinimo, C1.ValorMaximo, C1.Titulos_Total, C1.Negocios_Total, M.Valor as MM21, 
	dbo.MaxValue(VD.Valor, MVD.Valor) as Volatilidade,
	c1.Titulos_Total / MVOL.Valor as percentual_volume_quantidade, C1.Negocios_Total / MND.Valor as percentual_volume_negocios,
	(
		SELECT MAX(CVOL.DATA) 
		FROM Cotacao_Semanal CVOL
		INNER JOIN VolatilidadeSemanal VOL ON C1.Codigo = VOL.Codigo AND C1.DATA = VOL.Data
		LEFT JOIN MediaVolatilidadeSemanal MVOL ON C1.Codigo = MVOL.Codigo AND C1.DATA = MVOL.Data
		WHERE C1.Codigo = CVOL.Codigo
		AND C1.Sequencial - CVOL.Sequencial >= 4
		AND CVOL.ValorMinimo > 0
		--amplitue maior que 10% volatilidade
		AND dbo.MaxValue(ABS(CVOL.Oscilacao) / 100, CVOL.ValorMaximo / CVOL.ValorMinimo -1 ) >= dbo.MinValue(VOL.Valor, MVOL.Valor) / 10

	) AS DataBarraAmpla
	from Cotacao_Semanal C1
	INNER JOIN Media_Semanal M ON C1.Codigo = M.Codigo AND C1.Data = M.Data AND M.NumPeriodos = 21 AND M.Tipo = 'MMA'
	INNER JOIN MediaNegociosSemanal MND on C1.Codigo = MND.Codigo and C1.Data = MND.Data
	INNER JOIN Media_Semanal MVOL on C1.Codigo = MVOL.Codigo and C1.Data = MVOL.Data and MVOL.Tipo = 'VMA' AND MVOL.NumPeriodos = 21
	INNER JOIN VolatilidadeSemanal VD ON C1.Codigo = VD.Codigo AND C1.DATA = VD.Data
	LEFT JOIN MediaVolatilidadeSemanal MVD ON C1.Codigo = MVD.Codigo AND C1.DATA = MVD.Data
	where C1.Data = @data2
	AND ROUND((C1.ValorMaximo  * (1 + dbo.MaxValue(VD.Valor, MVD.Valor) * 1.25 / 100) / M.Valor- 1) * 100, 3) / 10 / dbo.MaxValue(VD.Valor, MVD.Valor) <= 2.5
) AS p2
ON p1.Codigo = p2.Codigo
WHERE 

	p2.ValorFechamento > 
	(
		select ValorMaximo
		from Cotacao_Semanal CBA
		where CBA.Codigo = P2.Codigo 
		AND CBA.Data = P2.DataBarraAmpla
		AND NOT EXISTS
		(
			select 1
			from Cotacao_Semanal C3
			where C3.Codigo = CBA.Codigo
			AND C3.Sequencial > CBA.Sequencial
			AND C3.Sequencial < P2.Sequencial
			AND (C3.ValorFechamento > CBA.ValorMaximo
			OR C3.ValorAbertura > CBA.ValorMaximo
			OR C3.ValorFechamento < CBA.ValorMinimo)
		)

	)


AND (
	--media subindo
	P2.MM21 > P1.MM21 
	--nao está tocando na média e a distancia do valor maximo para  a média é maior que a amplitude do candle
	OR (NOT P2.MM21 BETWEEN P2.ValorMinimo AND P2.ValorMaximo AND (p2.MM21 - P2.ValorMaximo > P2.ValorMaximo - P2.ValorMinimo))
	-- mais da metade do candle está acima da média
	OR (P2.ValorMaximo - P2.MM21 > P2.MM21 - P2.ValorMinimo )
)

AND (
	   --garante que tem sempre o percentual mínimo de volume
       (dbo.MinValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualMinimoVolume
       AND (
				--tem aumento de volume em titulos e negócios
			   (p2.Titulos_Total >= p1.Titulos_Total AND p2.Negocios_Total >= p1.Negocios_Total)
			   --mesmo que não tenha aumento de volume garante que o percentual está no desejado
			   OR dbo.MinValue(P2.percentual_volume_quantidade, P2.percentual_volume_negocios) >= @percentualDesejadoVolume
		   )
	   )

	OR
	(
		-- 130% DO CANDLE ANTERIOR. QUALQUER TENDENCIA
		p2.Titulos_Total / p1.Titulos_Total >= 1.2
		AND p2.Negocios_Total / p1.Negocios_Total >= 1.2
	)
)
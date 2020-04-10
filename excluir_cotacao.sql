declare @data as datetime = '2020-2-5', @dataAnterior as datetime = '2020-2-4'
DELETE
FROM Cotacao
WHERE DATA >= @data

DELETE
FROM IFR_Diario
WHERE DATA >= @data

DELETE
FROM Media_Diaria
WHERE DATA >= @data

DELETE
FROM VolatilidadeDiaria
WHERE DATA >= @data

DELETE
FROM MediaVolatilidadeDiaria
WHERE DATA >= @data

DELETE
FROM MediaNegociosDiaria
WHERE DATA >= @data

update resumo set Data_Ultima_Cotacao = @dataAnterior

DELETE
FROM Cotacao_Semanal
WHERE Data >= @data

DELETE
FROM IFR_Semanal
WHERE DATA >= @data

DELETE
FROM Media_Semanal
WHERE DATA >= @data

DELETE
FROM VolatilidadeSemanal
WHERE DATA >= @data

DELETE
FROM MediaVolatilidadeSemanal
WHERE DATA >= @data

DELETE
FROM MediaNegociosSemanal
WHERE DATA >= @data








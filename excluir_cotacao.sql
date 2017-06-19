
declare @data as datetime = '2017-6-15', @dataAnterior as datetime = '2017-6-14'
DELETE
FROM Cotacao
WHERE DATA = @data

DELETE
FROM IFR_Diario
WHERE DATA = @data

DELETE
FROM Media_Diaria
WHERE DATA = @data


update resumo set Data_Ultima_Cotacao = @dataAnterior


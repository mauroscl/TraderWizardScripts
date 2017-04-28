ROLLBACK
BEGIN TRAN
commit

declare @data as datetime = '2017-4-25', @dataAnterior as datetime = '2017-04-24'
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


declare @codigo AS varchar(6) = 'APER3', @data as datetime = '2018-10-15'
DELETE
FROM Cotacao
WHERE DATA >= @data
AND Codigo = @codigo

DELETE
FROM IFR_Diario
WHERE DATA >= @data
AND Codigo = @codigo

DELETE
FROM Media_Diaria
WHERE DATA >= @data
AND Codigo = @codigo

DELETE
FROM VolatilidadeDiaria
WHERE DATA >= @data
AND Codigo = @codigo

DELETE
FROM MediaVolatilidadeDiaria
WHERE DATA >= @data
AND Codigo = @codigo

DELETE
FROM MediaNegociosDiaria
WHERE DATA >= @data
AND Codigo = @codigo


DELETE
FROM Cotacao_Semanal
WHERE Data >= @data
AND Codigo = @codigo

DELETE
FROM IFR_Semanal
WHERE DATA >= @data
AND Codigo = @codigo

DELETE
FROM Media_Semanal
WHERE DATA >= @data
AND Codigo = @codigo

DELETE
FROM VolatilidadeSemanal
WHERE DATA >= @data
AND Codigo = @codigo

DELETE
FROM MediaVolatilidadeSemanal
WHERE DATA >= @data
AND Codigo = @codigo

DELETE
FROM MediaNegociosSemanal
WHERE DATA >= @data
AND Codigo = @codigo

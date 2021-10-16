--SQL SERVER
SELECT DIA1.CODIGO, DIA1.VALORFECHAMENTO As FECHAMENTO_DIA1, DIA2.VALORFECHAMENTO As FECHAMENTO_DIA2, 
DIA2.OSCILACAO, Round((DIA2.VALORFECHAMENTO / DIA1.VALORFECHAMENTO -1) * 100, 2) As OSCILACAO_ESPERADA,
DIA2.VALORFECHAMENTO / (1 + DIA2.OSCILACAO / 100) - DIA1.VALORFECHAMENTO As DIFERENCA
FROM
(SELECT CODIGO, VALORFECHAMENTO
FROM COTACAO 
WHERE DATA = '2021-10-14') As DIA1 
INNER JOIN
(SELECT CODIGO, VALORFECHAMENTO, OSCILACAO
FROM COTACAO 
WHERE DATA = '2021-10-15') As DIA2
On DIA1.CODIGO = DIA2.CODIGO
WHERE ABS(DIA2.OSCILACAO - Round((DIA2.VALORFECHAMENTO / DIA1.VALORFECHAMENTO -1) * 100, 2)) > 0.01
And DIA1.CODIGO Not Like '%11B'
And DIA1.CODIGO Not Like '%17'

--INSERT INTO ATIVOS_DESCONSIDERADOS
--VALUES
--('CCMU18')	

--INSERT INTO Feriado
--(Data, Descricao)
--VALUES
--('2021-1-1', 'Ano Novo')

--INSERT INTO Split
--(Codigo, Data, Tipo, QuantidadeAnterior, QuantidadePosterior)
--values
--('ANIM3', '2021-02-19', 'DESD', 1,3)


--INSERT INTO Ativo
--(Codigo, Descricao)
--values
--('BIDI4', 'BANCO INTER PN')

--select *
--from split
--where codigo = 'MULT3'
--ORDER BY DATA DESC

--UPDATE SPLIT SET 
--DATA = '2018-7-23'
--WHERE CODIGO = 'MULT3'
--AND DATA = '2018-7-24'

--DELETE SPLIT 
--WHERE CODIGO = 'UGPA3'
--AND DATA = '2019-3-1'

--SELECT *
--FROM COTACAO
--WHERE DATA = '2020-2-18'
--AND CODIGO NOT IN (SELECT CODIGO FROM ATIVO)

--SELECT *
--FROM Cotacao
--WHERE Codigo = 'CCMU18'



--SQL SERVER
SELECT DIA1.CODIGO, DIA1.VALORFECHAMENTO As FECHAMENTO_DIA1, DIA2.VALORFECHAMENTO As FECHAMENTO_DIA2, 
DIA2.OSCILACAO, Round((DIA2.VALORFECHAMENTO / DIA1.VALORFECHAMENTO -1) * 100, 2) As OSCILACAO_ESPERADA,
DIA2.VALORFECHAMENTO / (1 + DIA2.OSCILACAO / 100) - DIA1.VALORFECHAMENTO As DIFERENCA
FROM
(SELECT CODIGO, VALORFECHAMENTO
FROM COTACAO 
WHERE DATA = '2018-1-2') As DIA1 
INNER JOIN
(SELECT CODIGO, VALORFECHAMENTO, OSCILACAO
FROM COTACAO 
WHERE DATA = '2018-1-3') As DIA2
On DIA1.CODIGO = DIA2.CODIGO
WHERE ABS(DIA2.OSCILACAO - Round((DIA2.VALORFECHAMENTO / DIA1.VALORFECHAMENTO -1) * 100, 2)) > 0.01
And DIA1.CODIGO Not Like '%11B'
And DIA1.CODIGO Not Like '%17'



--INSERT INTO ATIVOS_DESCONSIDERADOS
--VALUES
--('FRCG18')
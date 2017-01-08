--BUSCAR A MAIOR DATA EM QUE H� COTA��O PARA O C�DIGO ANTERIOR
SELECT Max(DATA)
FROM COTACAO
WHERE CODIGO = 'STBP11'                                        
--RESULTADO: 19/08/2016

--BUSCAR A MENOR DATA EM QUE H� COTA��O PARA O NOVO C�DIGO
SELECT Min(DATA)
FROM COTACAO
WHERE CODIGO = 'STBP3' 
--RESULTADO: 22/08/2016

--EXCLUIR AS SIMULA��ES DO CODIGO ANTERIOR
DECLARE @codigoAnterior as char(6) = 'STBP11'
DELETE
FROM IFR_SIMULACAO_DIARIA_DETALHE
WHERE CODIGO = @codigoAnterior

DELETE
FROM IFR_SIMULACAO_DIARIA
WHERE CODIGO = @codigoAnterior

DELETE
FROM IFR_SIMULACAO_DIARIA_FAIXA
WHERE CODIGO = @codigoAnterior


DELETE
FROM IFR_SIMULACAO_DIARIA_FAIXA_RESUMO
WHERE CODIGO = @codigoAnterior

--VERIFICAR SE O ATIVO ANTERIOR PERTENCE A ALGUMA CARTEIRA DE ATIVO
SELECT * FROM CARTEIRA_ATIVO 
WHERE CODIGO = @codigoAnterior 
ORDER BY CODIGO

--SE EXISTIR EXCLUIR O REGISTRO EXISTENTE    
DELETE
FROM CARTEIRA_ATIVO
WHERE CODIGO = @codigoAnterior


--ATUALIZAR A TABELA "ATIVO"
UPDATE ATIVO SET
CODIGO = 'STBP3',
DESCRICAO = 'SANTOS BRP ON'
WHERE CODIGO = 'STBP11'

--INSERIR REGISTRO COM O NOVO C�DIGO DO ATIVO
INSERT INTO CARTEIRA_ATIVO
(IdCarteira, Codigo)
Values
(2, 'RADL3') 


--ATUALIZAR O CAMPO "SEQUENCIAL" DAS COTA��ES DO NOVO C�DIGO SOMANDO O SEU SEQUENCIAL
--COM O MAIOR SEQUENCIAL DO C�DIGO ANTERIOR

--PASSO 1) BUSCAR O MAIOR SEQUENCIAL DO C�DIGO ANTERIOR
SELECT Max(SEQUENCIAL)
FROM COTACAO
WHERE CODIGO = 'STBP11' 
--RESULTADO: 2143

--PASSO 2) ATUALIZAR O SEQUENCIAL DO C�DIGO NOVO
UPDATE COTACAO SET    
SEQUENCIAL = SEQUENCIAL + 2143
WHERE CODIGO = 'STBP3'

--ATUALIZAR O C�DIGO NA TABELA "COTACAO"
DECLARE @codigoAnterior as char(6) = 'STBP11'
DECLARE @codigoNovo as char(6) = 'STBP3'

UPDATE COTACAO SET
CODIGO = @codigoNovo
WHERE CODIGO = @codigoAnterior      

--ATUALIZAR O C�DIGO NA TABELA "IFR_DIARIO"
UPDATE IFR_DIARIO SET
CODIGO = @codigoNovo
WHERE CODIGO = @codigoAnterior      

--ATUALIZAR O C�DIGO NA TABELA "MEDIA_DIARIA"  
UPDATE MEDIA_DIARIA SET
CODIGO = @codigoNovo
WHERE CODIGO = @codigoAnterior      


--ATUALIZAR O CAMPO "SEQUENCIAL" DAS COTA��ES SEMANAIS DO NOVO C�DIGO SOMANDO O SEU SEQUENCIAL
--COM O MAIOR SEQUENCIAL DO C�DIGO ANTERIOR

--PASSO 1) BUSCAR O MAIOR SEQUENCIAL DO C�DIGO ANTERIOR
SELECT Max(SEQUENCIAL)
FROM COTACAO_SEMANAL
WHERE CODIGO = 'STBP11' 
--RESULTADO: 455

--PASSO 2) ATUALIZAR O SEQUENCIAL DO C�DIGO NOVO
UPDATE COTACAO_SEMANAL SET    
SEQUENCIAL = SEQUENCIAL + 455
WHERE CODIGO = 'STBP3'

DECLARE @codigoAnterior as char(6) = 'STBP11'
DECLARE @codigoNovo as char(6) = 'STBP3'

--ATUALIZAR O C�DIGO NA TABELA "COTACAO_SEMANAL"   
UPDATE COTACAO_SEMANAL SET
CODIGO = @codigoNovo
WHERE CODIGO = @codigoAnterior      

--ATUALIZAR O C�DIGO NA TABELA "IFR_SEMANAL"
UPDATE IFR_SEMANAL SET
CODIGO = @codigoNovo
WHERE CODIGO = @codigoAnterior      

--ATUALIZAR O C�DIGO NA TABELA "MEDIA_SEMANAL"     
UPDATE MEDIA_SEMANAL SET
CODIGO = @codigoNovo
WHERE CODIGO = @codigoAnterior      

--ATUALIZA OS SPLITS
UPDATE SPLIT SET 
CODIGO = @codigoNovo
WHERE CODIGO = @codigoAnterior      

--SE FOI CRIADO NOVO C�DIGO EXCLUIR O ANTERIOR
DELETE
FROM ATIVO
WHERE CODIGO = 'TBLE3'                            


--RECALCULAR OS DADOS PARA O NOVO C�DIGO A PARTIR DA PRIMEIRA DATA EM QUE H� NEGOCIA��O
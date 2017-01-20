ALTER TABLE ATIVO ALTER COLUMN Codigo nvarchar(10) not null
ALTER TABLE ativo ALTER COLUMN Descricao nvarchar(40) not null

alter table ativo add constraint PK_Ativo primary key (Codigo)

CREATE TABLE IfrSobrevendidoDescartadoDiario
( Codigo nvarchar(10) not null, 
	[Data] datetime not null,
	CONSTRAINT PK_IfrSobrevendidoDescartadoDiario PRIMARY KEY (Codigo, [Data])
)

CREATE TABLE IfrSobrevendidoDescartadoSemanal
( Codigo nvarchar(10) not null, 
	[Data] datetime not null,
	CONSTRAINT PK_IfrSobrevendidoDescartadoSemanal PRIMARY KEY (Codigo, [Data])
)


INSERT INTO IfrSobrevendidoDescartadoDiario
(Codigo, [Data])
values
('TIMP3','2017-1-6')

UPDATE IfrSobrevendidoDescartadoDiario SET [Data] = ''
WHERE Codigo = ''


INSERT INTO IfrSobrevendidoDescartadoSemanal
(Codigo, [Data])
values
('NATU3','2017-1-9')

UPDATE IfrSobrevendidoDescartadoSemanal SET [Data] = ''
WHERE Codigo = ''




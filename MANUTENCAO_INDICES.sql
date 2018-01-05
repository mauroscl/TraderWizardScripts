SELECT a.index_id, name, avg_fragmentation_in_percent  
FROM sys.dm_db_index_physical_stats (DB_ID(N'TraderWizard'), 
      OBJECT_ID(N'dbo.Split'), NULL, NULL, NULL) AS a  
    JOIN sys.indexes AS b 
      ON a.object_id = b.object_id AND a.index_id = b.index_id;   


ALTER INDEX ALL ON dbo.MediaNegociosDiaria
REORGANIZE ;   


ALTER INDEX ALL ON dbo.Split
REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON,
              STATISTICS_NORECOMPUTE = ON);
GO
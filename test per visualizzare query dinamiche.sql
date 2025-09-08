------------------
/*test preliminari*/
--declare @campi_select nvarchar(max)
--declare @MainQuery nvarchar(max)
--declare @tabella_stg nvarchar(50)
--set @tabella_stg='Tab1'

--set @campi_select= (SELECT STRING_AGG(QUOTENAME(COLUMN_NAME),',') AS Query_nella_Select
--FROM INFORMATION_SCHEMA.COLUMNS
--WHERE TABLE_SCHEMA='stg' AND TABLE_NAME='Tab1')

----select @campi_select

--set @MainQuery='SELECT ' +@campi_select+' FROM [stg].'+QUOTENAME(@tabella_stg)

--exec(@MainQuery)
/* fine test preliminari*/

declare @campi_select nvarchar(max)
declare @MainQuery nvarchar(max)
declare @tabella_stg nvarchar(50)
declare @tabella_dwh nvarchar(50)
declare @criterio_di_match nvarchar(max)
declare @campi_per_update nvarchar(max)
declare @campi_per_insert nvarchar(max)
declare @campi_per_insert2 nvarchar(max)
--da qui in poi nel cursors for
set @tabella_stg='Tab2'
set @tabella_dwh='Tab2'

--set @campi_select= (SELECT STRING_AGG(QUOTENAME(COLUMN_NAME),',') AS Query_nella_Select
--FROM INFORMATION_SCHEMA.COLUMNS
--WHERE TABLE_SCHEMA='stg' AND TABLE_NAME=@tabella_stg) --mi creo l'elenco dei campi della tabella di turno nella select

set @campi_select= (SELECT STRING_AGG(QUOTENAME(COLUMN_NAME),','+CHAR(13)+CHAR(10)) AS Query_nella_Select
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='stg' AND TABLE_NAME=@tabella_stg) --mi creo l'elenco dei campi della tabella di turno nella select

SET @criterio_di_match=(SELECT  STRING_AGG('TGT.'+k.COLUMN_NAME+'=SRC.'+k.COLUMN_NAME,' AND '+CHAR(13)+CHAR(10))
FROM    INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS tc
JOIN    INFORMATION_SCHEMA.KEY_COLUMN_USAGE  AS k
       ON  k.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
       AND k.TABLE_SCHEMA    = tc.TABLE_SCHEMA      -- accoppiamento sicuro
WHERE   tc.TABLE_SCHEMA   = 'dwh'       --schema da specificare
  AND   tc.TABLE_NAME     = @tabella_dwh
  AND   tc.CONSTRAINT_TYPE = 'PRIMARY KEY')

SET @campi_per_update=(SELECT  STRING_AGG('TGT.'+  c.name +'=SRC.'+c.name,','+CHAR(13)+CHAR(10))
        --t.name          AS TableName,
        --s.name          AS SchemaName,
        --ty.name         AS DataType,
        --c.max_length    AS MaxLen,
        --c.is_nullable   AS IsNullable
FROM    sys.columns          AS c
JOIN    sys.tables           AS t  ON t.object_id = c.object_id
JOIN    sys.schemas          AS s  ON s.schema_id = t.schema_id
JOIN    sys.types            AS ty ON ty.user_type_id = c.user_type_id
LEFT JOIN (
        /* Colonne che fanno parte della PK */
        SELECT  ic.object_id,
                ic.column_id
        FROM    sys.indexes        AS i
        JOIN    sys.index_columns  AS ic
               ON ic.object_id = i.object_id
              AND ic.index_id  = i.index_id
        WHERE   i.is_primary_key = 1
) pk ON pk.object_id = c.object_id
    AND pk.column_id = c.column_id
WHERE   s.name  = 'dwh'--@schema
  AND   t.name  = @tabella_dwh
  AND   pk.column_id IS NULL  
)

SET @campi_per_insert=(SELECT STRING_AGG(QUOTENAME(COLUMN_NAME),',') AS Query_nella_Select
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='stg' AND TABLE_NAME=@tabella_stg) --mi creo l'elenco dei campi della tabella di turno nella select

SET @campi_per_insert2=(SELECT STRING_AGG('SRC.'+QUOTENAME(COLUMN_NAME),',') AS Query_nella_Select
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='stg' AND TABLE_NAME=@tabella_stg)
--print @campi_select

--SELECT COLUMN_NAME
--FROM INFORMATION_SCHEMA.COLUMNS
--WHERE TABLE_SCHEMA='stg' AND TABLE_NAME='Tab1'

--SELECT STRING_AGG(QUOTENAME(COLUMN_NAME),',') AS Query_nella_Select
--FROM INFORMATION_SCHEMA.COLUMNS
--WHERE TABLE_SCHEMA='stg' AND TABLE_NAME='Tab1'

--query dinamica
--DECLARE 

--SET @MainQuery=N'MERGE INTO [dwh].'+QUOTENAME(@tabella_dwh)+' AS TGT USING (SELECT '+@campi_select+' FROM '+@tabella_stg
--+') AS SRC ON '
--+

--SELECT  string_agg('TGT.'+k.COLUMN_NAME+'=SRC.'+k.COLUMN_NAME,' AND ')
--FROM    INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS tc
--JOIN    INFORMATION_SCHEMA.KEY_COLUMN_USAGE  AS k
--       ON  k.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
--       AND k.TABLE_SCHEMA    = tc.TABLE_SCHEMA      -- accoppiamento sicuro
--WHERE   tc.TABLE_SCHEMA   = 'dwh'       --schema da specificare
--  AND   tc.TABLE_NAME     = 'Tab1'
--  AND   tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
----ORDER BY k.ORDINAL_POSITION;

--test andando a capo

SET @MainQuery=N'MERGE INTO [dwh].'+QUOTENAME(@tabella_dwh)+' AS TGT'+CHAR(13)+CHAR(10)+' USING (SELECT '+@campi_select+CHAR(13)+CHAR(10)+'FROM [stg].'+QUOTENAME(@tabella_stg)
+') AS SRC'+CHAR(13)+CHAR(10)+ 'ON '+@criterio_di_match
+CHAR(13)+CHAR(10)+'WHEN MATCHED THEN'+CHAR(13)+CHAR(10)+'UPDATE SET'
+CHAR(13)+CHAR(10)+@campi_per_update
+CHAR(13)+CHAR(10)+'WHEN NOT MATCHED BY TARGET THEN'
+CHAR(13)+CHAR(10)+'INSERT ('+@campi_per_insert+')'
+CHAR(13)+CHAR(10)+'VALUES('+@campi_per_insert2+');'           

PRINT @MainQuery

--EXEC(@MainQuery)


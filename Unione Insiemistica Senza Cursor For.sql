	WITH CTE AS(
	SELECT [Risorsa_id]
      ,[Data]
      ,[Inizio_Assenza]
      ,[Fine_Assenza]
	  ,MAX([Fine_Assenza]) OVER( PARTITION BY [Risorsa_id],[Data] ORDER BY [Inizio_Assenza] ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING)   AS [Massimo_Riga_Corrente]
	FROM [Vittorio].[esercitazione].[Assenze]),

 CTE2 AS (
SELECT [Risorsa_id]
      ,[Data]
      ,[Inizio_Assenza]
      ,[Fine_Assenza]
	  ,[Massimo_Riga_Corrente]
	  ,IIF([Inizio_Assenza]<=ISNULL([Massimo_Riga_Corrente],[Inizio_Assenza]),0,1) AS [Flag_Intervallo_Disgiunto]
	  FROM CTE
),

 CTE3 AS (SELECT [Risorsa_id]
      ,[Data]
      ,[Inizio_Assenza]
      ,[Fine_Assenza]
	  ,[Massimo_Riga_Corrente]
	  ,[Flag_Intervallo_Disgiunto]
	  ,SUM([Flag_Intervallo_Disgiunto])OVER( PARTITION BY  [Risorsa_id],[Data] ORDER BY [Inizio_Assenza] ROWS UNBOUNDED PRECEDING) AS [Numero_Cluster]
	  FROM CTE2
	  )

--SELECT * FROM CTE3 	  ;

SELECT [Risorsa_id]
      ,[Data]
	  ,[Numero_Cluster]
	  ,MIN([Inizio_Assenza]) AS [Inizio_Assenza]
	  ,MAX([Fine_Assenza]) AS [Fine_Assenza]
	  FROM CTE3
	  GROUP BY [Risorsa_id]
      ,[Data]
	  ,[Numero_Cluster]





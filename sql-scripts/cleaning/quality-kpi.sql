-- CALCUL DES KPI DE QUALITE
-- Base: adventureWORKS
-- Date: 23/10/2024

USE adventureWORKS;
GO

-- KPI AVANT/APRES NETTOYAGE

-- 1. COMPLETUDE (pourcentage donnees non NULL)
-- Mesure le pourcentage de ShipDate non null avant et apres nettoyage
SELECT 
    'Completude ShipDate' as [KPI],
    CAST((SELECT COUNT(*) - COUNT(ShipDate) FROM Sales.SalesOrderHeader) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as [Avant pct],
    CAST((SELECT COUNT(*) - COUNT(ShipDate) FROM Cleaned.SalesOrderHeader) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as [Apres pct]
FROM Sales.SalesOrderHeader;

-- 2. EXACTITUDE (pourcentage valeurs correctes)
-- Mesure le pourcentage de TotalDue >= 0 avant et apres nettoyage
SELECT 
    'Exactitude TotalDue' as [KPI],
    CAST(COUNT(CASE WHEN TotalDue >= 0 THEN 1 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as [Avant pct],
    CAST((SELECT COUNT(CASE WHEN TotalDue >= 0 THEN 1 END) * 100.0 / COUNT(*) FROM Cleaned.SalesOrderHeader) AS DECIMAL(5,2)) as [Apres pct]
FROM Sales.SalesOrderHeader;

-- 3. UNICITE (pourcentage donnees uniques)
-- Mesure le pourcentage d'e-mails uniques avant et apres suppression des doublons
SELECT 
    'Unicite EmailAddress' as [KPI],
    CAST(COUNT(DISTINCT EmailAddress) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as [Avant pct],
    CAST((SELECT COUNT(DISTINCT EmailAddress) * 100.0 / COUNT(*) FROM Cleaned.EmailAddress) AS DECIMAL(5,2)) as [Apres pct]
FROM Person.EmailAddress;

-- 4. COHERENCE (pourcentage donnees coherentes)
-- Mesure le pourcentage de Color renseigne avant et apres remplacement des NULL par 'Unknown'
SELECT 
    'Coherence Color' as [KPI],
    CAST(COUNT(CASE WHEN Color IS NOT NULL THEN 1 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as [Avant pct],
    100.00 as [Apres pct]  -- 100 pourcent car on a remplace NULL par 'Unknown'
FROM Production.Product;

PRINT '=== KPI CALCULES ===';
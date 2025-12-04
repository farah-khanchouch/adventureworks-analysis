-- ANALYSE DE QUALITÉ DES DONNÉES
-- Base: adventureWORKS
-- Date: 23/10/2024
-- Objectifs :Compte les valeurs NULL (ex: ShipDate manquant)
-- Trouve les doublons (ex: emails en double)
-- Détecte les erreurs (ex: prix négatifs)
-- Crée un tableau avec tous les problèmes trouvés
-- Résultat : Une table DataQualityReport qui liste TOUS les problèmes

USE adventureWORKS;
GO

-- 1. CRÉER TABLE POUR SUIVRE LA QUALITÉ On crée une nouvelle table DataQualityReport qui servira à stocker tous les résultats du contrôle de qualité des données (valeurs nulles, doublons, etc.)

IF OBJECT_ID('dbo.DataQualityReport', 'U') IS NOT NULL 
    DROP TABLE dbo.DataQualityReport;

CREATE TABLE dbo.DataQualityReport (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    TableName VARCHAR(100),
    ColumnName VARCHAR(100),
    IssueType VARCHAR(50),
    IssueCount INT,
    TotalRows INT,
    QualityScore DECIMAL(5,2),
    CheckDate DATETIME DEFAULT GETDATE()
);

PRINT 'Table DataQualityReport créée';

-- 2. VÉRIFIER LES VALEURS NULL On détecte les valeurs manquantes dans certaines colonnes et calcule leur score de qualité.

-- Sales.SalesOrderHeader - ShipDate
INSERT INTO dbo.DataQualityReport (TableName, ColumnName, IssueType, IssueCount, TotalRows, QualityScore)
SELECT 
    'Sales.SalesOrderHeader',
    'ShipDate',
    'NULL Values',
    COUNT(*),
    (SELECT COUNT(*) FROM Sales.SalesOrderHeader),
    CAST((1 - CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM Sales.SalesOrderHeader)) * 100 AS DECIMAL(5,2))
FROM Sales.SalesOrderHeader
WHERE ShipDate IS NULL;

-- Production.Product - Color
INSERT INTO dbo.DataQualityReport (TableName, ColumnName, IssueType, IssueCount, TotalRows, QualityScore)
SELECT 
    'Production.Product',
    'Color',
    'NULL Values',
    COUNT(*),
    (SELECT COUNT(*) FROM Production.Product),
    CAST((1 - CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM Production.Product)) * 100 AS DECIMAL(5,2))
FROM Production.Product
WHERE Color IS NULL;

-- Production.Product - Size
INSERT INTO dbo.DataQualityReport (TableName, ColumnName, IssueType, IssueCount, TotalRows, QualityScore)
SELECT 
    'Production.Product',
    'Size',
    'NULL Values',
    COUNT(*),
    (SELECT COUNT(*) FROM Production.Product),
    CAST((1 - CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM Production.Product)) * 100 AS DECIMAL(5,2))
FROM Production.Product
WHERE Size IS NULL;

-- Production.Product - Weight
INSERT INTO dbo.DataQualityReport (TableName, ColumnName, IssueType, IssueCount, TotalRows, QualityScore)
SELECT 
    'Production.Product',
    'Weight',
    'NULL Values',
    COUNT(*),
    (SELECT COUNT(*) FROM Production.Product),
    CAST((1 - CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM Production.Product)) * 100 AS DECIMAL(5,2))
FROM Production.Product
WHERE Weight IS NULL;

PRINT 'Analyse NULL terminée';

-- 3. VÉRIFIER LES DOUBLONS On identifie les adresses e-mail répétées pour mesurer la duplication des données.

-- Person.EmailAddress
INSERT INTO dbo.DataQualityReport (TableName, ColumnName, IssueType, IssueCount, TotalRows, QualityScore)
SELECT 
    'Person.EmailAddress',
    'EmailAddress',
    'Duplicates',
    COUNT(*) - COUNT(DISTINCT EmailAddress),
    COUNT(*),
    CAST(COUNT(DISTINCT EmailAddress) * 100.0 / COUNT(*) AS DECIMAL(5,2))
FROM Person.EmailAddress;

PRINT 'Analyse doublons terminée';

-- 4. VÉRIFIER LES VALEURS NÉGATIVES On repère les prix ou montants incohérents inférieurs à zéro.

-- Production.Product - ListPrice
INSERT INTO dbo.DataQualityReport (TableName, ColumnName, IssueType, IssueCount, TotalRows, QualityScore)
SELECT 
    'Production.Product',
    'ListPrice',
    'Negative Values',
    COUNT(*),
    (SELECT COUNT(*) FROM Production.Product),
    CAST((1 - CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM Production.Product)) * 100 AS DECIMAL(5,2))
FROM Production.Product
WHERE ListPrice < 0;

-- Sales.SalesOrderHeader - TotalDue
INSERT INTO dbo.DataQualityReport (TableName, ColumnName, IssueType, IssueCount, TotalRows, QualityScore)
SELECT 
    'Sales.SalesOrderHeader',
    'TotalDue',
    'Negative Values',
    COUNT(*),
    (SELECT COUNT(*) FROM Sales.SalesOrderHeader),
    CAST((1 - CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM Sales.SalesOrderHeader)) * 100 AS DECIMAL(5,2))
FROM Sales.SalesOrderHeader
WHERE TotalDue < 0;

PRINT 'Analyse valeurs négatives terminée';

-- 5. AFFICHER LE RAPPORT On présente les résultats détaillés avec le niveau de qualité de chaque colonne.

SELECT 
    TableName as [Table],
    ColumnName as [Colonne],
    IssueType as [Type Problème],
    IssueCount as [Nombre],
    TotalRows as [Total Lignes],
    QualityScore as [Score %],
    CASE 
        WHEN QualityScore >= 95 THEN 'Excellent'
        WHEN QualityScore >= 80 THEN 'Bon'
        WHEN QualityScore >= 60 THEN 'Moyen'
        ELSE 'Faible'
    END as [Niveau Qualité]
FROM dbo.DataQualityReport
ORDER BY QualityScore ASC;

-- 6. STATISTIQUES GLOBALES On résume la qualité globale avec le nombre total de problèmes et les scores moyens.

SELECT 
    COUNT(*) as [Nombre de Problèmes],
    AVG(QualityScore) as [Score Moyen],
    MIN(QualityScore) as [Score Min],
    MAX(QualityScore) as [Score Max]
FROM dbo.DataQualityReport;

PRINT '=== ANALYSE DE QUALITÉ TERMINÉE ===';
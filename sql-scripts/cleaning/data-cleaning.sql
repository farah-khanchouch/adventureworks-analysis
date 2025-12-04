-- ================================================================
-- NETTOYAGE COMPLET DES DONNÉES - VERSION COMPLÈTE
-- Base: adventureWORKS
-- Date: 03/12/2024
-- Inclut toutes les tables nécessaires pour le Datamart
-- ================================================================

USE adventureWORKS;
GO

-- ==============================================
-- 1. CRÉER SCHÉMA POUR DONNÉES NETTOYÉES
-- ==============================================

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Cleaned')
BEGIN
    EXEC('CREATE SCHEMA Cleaned')
    PRINT '✅ Schéma Cleaned créé';
END
ELSE
BEGIN
    PRINT '⚠️ Schéma Cleaned existe déjà';
END
GO

PRINT '';
PRINT '🧹 === DÉMARRAGE DU NETTOYAGE ===';
PRINT '';

-- ==============================================
-- 2. NETTOYER Sales.SalesOrderHeader
-- ==============================================

PRINT '📦 Nettoyage SalesOrderHeader...';

IF OBJECT_ID('Cleaned.SalesOrderHeader', 'U') IS NOT NULL 
    DROP TABLE Cleaned.SalesOrderHeader;

SELECT 
    SalesOrderID,
    RevisionNumber,
    OrderDate,
    DueDate,
    -- Remplacer ShipDate NULL par DueDate
    ISNULL(ShipDate, DueDate) as ShipDate,
    Status,
    OnlineOrderFlag,
    SalesOrderNumber,
    PurchaseOrderNumber,
    AccountNumber,
    CustomerID,
    SalesPersonID,
    TerritoryID,
    BillToAddressID,
    ShipToAddressID,
    ShipMethodID,
    CreditCardID,
    CreditCardApprovalCode,
    CurrencyRateID,
    -- Nettoyer valeurs négatives
    CASE WHEN SubTotal < 0 THEN 0 ELSE SubTotal END as SubTotal,
    CASE WHEN TaxAmt < 0 THEN 0 ELSE TaxAmt END as TaxAmt,
    CASE WHEN Freight < 0 THEN 0 ELSE Freight END as Freight,
    CASE WHEN TotalDue < 0 THEN 0 ELSE TotalDue END as TotalDue,
    Comment,
    rowguid,
    ModifiedDate
INTO Cleaned.SalesOrderHeader
FROM Sales.SalesOrderHeader;

PRINT '✅ SalesOrderHeader nettoyé : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';

-- ==============================================
-- 3. NETTOYER Sales.SalesOrderDetail (NOUVEAU)
-- ==============================================

PRINT '📋 Nettoyage SalesOrderDetail...';

IF OBJECT_ID('Cleaned.SalesOrderDetail', 'U') IS NOT NULL 
    DROP TABLE Cleaned.SalesOrderDetail;

SELECT 
    SalesOrderID,
    SalesOrderDetailID,
    CarrierTrackingNumber,
    -- Nettoyer quantités négatives
    CASE WHEN OrderQty < 0 THEN 0 ELSE OrderQty END as OrderQty,
    ProductID,
    SpecialOfferID,
    -- Corriger prix négatifs
    CASE WHEN UnitPrice < 0 THEN 0 ELSE UnitPrice END as UnitPrice,
    -- Corriger discount hors limites (0-1)
    CASE 
        WHEN UnitPriceDiscount < 0 THEN 0 
        WHEN UnitPriceDiscount > 1 THEN 1 
        ELSE UnitPriceDiscount 
    END as UnitPriceDiscount,
    -- Recalculer LineTotal si nécessaire
    CASE 
        WHEN LineTotal < 0 THEN 0 
        ELSE LineTotal 
    END as LineTotal,
    rowguid,
    ModifiedDate
INTO Cleaned.SalesOrderDetail
FROM Sales.SalesOrderDetail;

PRINT '✅ SalesOrderDetail nettoyé : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';

-- ==============================================
-- 4. NETTOYER Production.Product
-- ==============================================

PRINT '🏭 Nettoyage Product...';

IF OBJECT_ID('Cleaned.Product', 'U') IS NOT NULL 
    DROP TABLE Cleaned.Product;

SELECT 
    ProductID,
    -- Nettoyer espaces
    LTRIM(RTRIM(Name)) as Name,
    LTRIM(RTRIM(ProductNumber)) as ProductNumber,
    MakeFlag,
    FinishedGoodsFlag,
    -- Remplacer NULL par 'Unknown'
    ISNULL(Color, 'Unknown') as Color,
    SafetyStockLevel,
    ReorderPoint,
    -- Corriger prix négatifs
    CASE WHEN StandardCost < 0 THEN 0 ELSE StandardCost END as StandardCost,
    CASE WHEN ListPrice < 0 THEN 0 ELSE ListPrice END as ListPrice,
    -- Nettoyer Size (garder NULL si vide)
    CASE WHEN LTRIM(RTRIM(ISNULL(Size, ''))) = '' THEN NULL ELSE LTRIM(RTRIM(Size)) END as Size,
    SizeUnitMeasureCode,
    WeightUnitMeasureCode,
    Weight,
    DaysToManufacture,
    ProductLine,
    Class,
    Style,
    ProductSubcategoryID,
    ProductModelID,
    SellStartDate,
    SellEndDate,
    DiscontinuedDate,
    rowguid,
    ModifiedDate
INTO Cleaned.Product
FROM Production.Product;

PRINT '✅ Product nettoyé : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';

-- ==============================================
-- 5. NETTOYER Sales.SalesTerritory (NOUVEAU)
-- ==============================================

PRINT '🌍 Nettoyage SalesTerritory...';

IF OBJECT_ID('Cleaned.SalesTerritory', 'U') IS NOT NULL 
    DROP TABLE Cleaned.SalesTerritory;

SELECT 
    TerritoryID,
    -- Nettoyer espaces dans le nom
    LTRIM(RTRIM(Name)) as Name,
    CountryRegionCode,
    [Group],
    -- Corriger valeurs négatives
    CASE WHEN SalesYTD < 0 THEN 0 ELSE SalesYTD END as SalesYTD,
    CASE WHEN SalesLastYear < 0 THEN 0 ELSE SalesLastYear END as SalesLastYear,
    CASE WHEN CostYTD < 0 THEN 0 ELSE CostYTD END as CostYTD,
    CASE WHEN CostLastYear < 0 THEN 0 ELSE CostLastYear END as CostLastYear,
    rowguid,
    ModifiedDate
INTO Cleaned.SalesTerritory
FROM Sales.SalesTerritory;

PRINT '✅ SalesTerritory nettoyé : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';

-- ==============================================
-- 6. SUPPRIMER LES DOUBLONS EmailAddress
-- ==============================================

PRINT '📧 Nettoyage EmailAddress...';

IF OBJECT_ID('Cleaned.EmailAddress', 'U') IS NOT NULL 
    DROP TABLE Cleaned.EmailAddress;

WITH CTE_Duplicates AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY EmailAddress 
            ORDER BY ModifiedDate DESC
        ) as RowNum
    FROM Person.EmailAddress
)
SELECT 
    BusinessEntityID,
    EmailAddressID,
    -- Nettoyer et normaliser email
    LOWER(LTRIM(RTRIM(EmailAddress))) as EmailAddress,
    rowguid,
    ModifiedDate
INTO Cleaned.EmailAddress
FROM CTE_Duplicates
WHERE RowNum = 1;

PRINT '✅ EmailAddress nettoyé : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';

-- ==============================================
-- 7. STATISTIQUES APRÈS NETTOYAGE
-- ==============================================

PRINT '';
PRINT '📊 === STATISTIQUES DE NETTOYAGE ===';
PRINT '';

-- Comparer avant/après
SELECT 
    'SalesOrderHeader' as [Table],
    (SELECT COUNT(*) FROM Sales.SalesOrderHeader) as [Lignes Avant],
    (SELECT COUNT(*) FROM Cleaned.SalesOrderHeader) as [Lignes Après],
    (SELECT COUNT(*) FROM Sales.SalesOrderHeader WHERE ShipDate IS NULL) as [Problèmes Avant],
    (SELECT COUNT(*) FROM Cleaned.SalesOrderHeader WHERE ShipDate IS NULL) as [Problèmes Après]
UNION ALL
SELECT 
    'SalesOrderDetail',
    (SELECT COUNT(*) FROM Sales.SalesOrderDetail),
    (SELECT COUNT(*) FROM Cleaned.SalesOrderDetail),
    (SELECT COUNT(*) FROM Sales.SalesOrderDetail WHERE UnitPrice < 0),
    (SELECT COUNT(*) FROM Cleaned.SalesOrderDetail WHERE UnitPrice < 0)
UNION ALL
SELECT 
    'Product',
    (SELECT COUNT(*) FROM Production.Product),
    (SELECT COUNT(*) FROM Cleaned.Product),
    (SELECT COUNT(*) FROM Production.Product WHERE Color IS NULL),
    (SELECT COUNT(*) FROM Cleaned.Product WHERE Color = 'Unknown')
UNION ALL
SELECT 
    'SalesTerritory',
    (SELECT COUNT(*) FROM Sales.SalesTerritory),
    (SELECT COUNT(*) FROM Cleaned.SalesTerritory),
    (SELECT COUNT(*) FROM Sales.SalesTerritory WHERE SalesYTD < 0),
    (SELECT COUNT(*) FROM Cleaned.SalesTerritory WHERE SalesYTD < 0)
UNION ALL
SELECT 
    'EmailAddress',
    (SELECT COUNT(*) FROM Person.EmailAddress),
    (SELECT COUNT(*) FROM Cleaned.EmailAddress),
    (SELECT COUNT(*) - COUNT(DISTINCT EmailAddress) FROM Person.EmailAddress),
    0;

PRINT '';
PRINT '✅ === NETTOYAGE TERMINÉ ===';
PRINT '';
PRINT '📁 Tables nettoyées créées dans le schéma Cleaned:';
PRINT '   ✅ Cleaned.SalesOrderHeader';
PRINT '   ✅ Cleaned.SalesOrderDetail';
PRINT '   ✅ Cleaned.Product';
PRINT '   ✅ Cleaned.SalesTerritory';
PRINT '   ✅ Cleaned.EmailAddress';
PRINT '';
PRINT '🚀 Prêt pour la création du Datamart !';
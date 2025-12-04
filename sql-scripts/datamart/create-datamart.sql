-- ================================================================
-- CRÉATION DU DATAMART - SCHÉMA EN ÉTOILE
-- Auteur: Farah Khanchouch
-- Date: 04/11/2024
-- Base: adventureWORKS
-- ================================================================

USE adventureWORKS;
GO

-- ==============================================
-- 1. CRÉER SCHÉMA DATAMART
-- ==============================================

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'DW')
BEGIN
    EXEC('CREATE SCHEMA DW')
    PRINT '✅ Schéma DW créé';
END
ELSE
BEGIN
    PRINT '⚠️ Schéma DW existe déjà';
END
GO

PRINT '';
PRINT '🏗️ === CRÉATION DU DATAMART ===';
PRINT '';

-- ==============================================
-- 2. DIMENSION TEMPS (DimDate)
-- ==============================================

PRINT '📅 Création DimDate...';

IF OBJECT_ID('DW.DimDate', 'U') IS NOT NULL 
    DROP TABLE DW.DimDate;

CREATE TABLE DW.DimDate (
    DateKey INT PRIMARY KEY,
    FullDate DATE NOT NULL,
    DayNumberOfWeek INT,
    DayNameOfWeek VARCHAR(10),
    DayNumberOfMonth INT,
    DayNumberOfYear INT,
    WeekNumberOfYear INT,
    MonthName VARCHAR(10),
    MonthNumberOfYear INT,
    QuarterNumber INT,
    QuarterName VARCHAR(10),
    Year INT,
    IsWeekend BIT,
    FiscalYear INT,
    FiscalQuarter INT
);

-- Remplir DimDate (2011-2014)
DECLARE @StartDate DATE = '2011-01-01';
DECLARE @EndDate DATE = '2014-12-31';

WITH DateSequence AS (
    SELECT @StartDate AS DateValue
    UNION ALL
    SELECT DATEADD(DAY, 1, DateValue)
    FROM DateSequence
    WHERE DateValue < @EndDate
)
INSERT INTO DW.DimDate
SELECT 
    CAST(FORMAT(DateValue, 'yyyyMMdd') AS INT) as DateKey,
    DateValue as FullDate,
    DATEPART(WEEKDAY, DateValue) as DayNumberOfWeek,
    DATENAME(WEEKDAY, DateValue) as DayNameOfWeek,
    DAY(DateValue) as DayNumberOfMonth,
    DATEPART(DAYOFYEAR, DateValue) as DayNumberOfYear,
    DATEPART(WEEK, DateValue) as WeekNumberOfYear,
    DATENAME(MONTH, DateValue) as MonthName,
    MONTH(DateValue) as MonthNumberOfYear,
    DATEPART(QUARTER, DateValue) as QuarterNumber,
    'Q' + CAST(DATEPART(QUARTER, DateValue) AS VARCHAR(1)) as QuarterName,
    YEAR(DateValue) as Year,
    CASE WHEN DATEPART(WEEKDAY, DateValue) IN (1,7) THEN 1 ELSE 0 END as IsWeekend,
    YEAR(DateValue) as FiscalYear,
    DATEPART(QUARTER, DateValue) as FiscalQuarter
FROM DateSequence
OPTION (MAXRECURSION 0);

PRINT '✅ DimDate créée : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';

-- ==============================================
-- 3. DIMENSION PRODUIT (DimProduct)
-- ==============================================

PRINT '🏭 Création DimProduct...';

IF OBJECT_ID('DW.DimProduct', 'U') IS NOT NULL 
    DROP TABLE DW.DimProduct;

CREATE TABLE DW.DimProduct (
    ProductKey INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,
    ProductName NVARCHAR(100),
    ProductNumber NVARCHAR(50),
    Color NVARCHAR(50),
    StandardCost DECIMAL(10,2),
    ListPrice DECIMAL(10,2),
    Size NVARCHAR(10),
    Weight DECIMAL(10,2),
    ProductCategoryName NVARCHAR(100),
    ProductSubcategoryName NVARCHAR(100),
    -- Attributs pour analyse
    PriceRange VARCHAR(20),
    CostRange VARCHAR(20),
    -- Dates de validité (SCD Type 2)
    StartDate DATE,
    EndDate DATE,
    IsCurrent BIT DEFAULT 1
);

-- Remplir DimProduct
INSERT INTO DW.DimProduct (
    ProductID, ProductName, ProductNumber, Color, 
    StandardCost, ListPrice, Size, Weight,
    ProductCategoryName, ProductSubcategoryName,
    PriceRange, CostRange,
    StartDate, EndDate, IsCurrent
)
SELECT 
    p.ProductID,
    p.Name as ProductName,
    p.ProductNumber,
    p.Color,
    p.StandardCost,
    p.ListPrice,
    p.Size,
    p.Weight,
    pc.Name as ProductCategoryName,
    psc.Name as ProductSubcategoryName,
    -- Catégoriser par prix
    CASE 
        WHEN p.ListPrice < 100 THEN 'Low (<100)'
        WHEN p.ListPrice < 500 THEN 'Medium (100-500)'
        WHEN p.ListPrice < 1000 THEN 'High (500-1000)'
        ELSE 'Premium (>1000)'
    END as PriceRange,
    -- Catégoriser par coût
    CASE 
        WHEN p.StandardCost < 50 THEN 'Low (<50)'
        WHEN p.StandardCost < 200 THEN 'Medium (50-200)'
        ELSE 'High (>200)'
    END as CostRange,
    p.SellStartDate as StartDate,
    ISNULL(p.SellEndDate, '9999-12-31') as EndDate,
    CASE WHEN p.SellEndDate IS NULL THEN 1 ELSE 0 END as IsCurrent
FROM Cleaned.Product p
LEFT JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
LEFT JOIN Production.ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID;

PRINT '✅ DimProduct créée : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';

-- ==============================================
-- 4. DIMENSION TERRITOIRE (DimTerritory)
-- ==============================================

PRINT '🌍 Création DimTerritory...';

IF OBJECT_ID('DW.DimTerritory', 'U') IS NOT NULL 
    DROP TABLE DW.DimTerritory;

CREATE TABLE DW.DimTerritory (
    TerritoryKey INT IDENTITY(1,1) PRIMARY KEY,
    TerritoryID INT NOT NULL,
    TerritoryName NVARCHAR(100),
    CountryRegionCode NVARCHAR(10),
    [Group] NVARCHAR(50),
    Continent NVARCHAR(50)
);

-- Remplir DimTerritory
INSERT INTO DW.DimTerritory (TerritoryID, TerritoryName, CountryRegionCode, [Group], Continent)
SELECT 
    TerritoryID,
    Name as TerritoryName,
    CountryRegionCode,
    [Group],
    -- Ajouter le continent basé sur le groupe
    CASE 
        WHEN [Group] = 'North America' THEN 'Americas'
        WHEN [Group] = 'Europe' THEN 'Europe'
        WHEN [Group] = 'Pacific' THEN 'Asia-Pacific'
        ELSE 'Other'
    END as Continent
FROM Cleaned.SalesTerritory;

PRINT '✅ DimTerritory créée : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';

-- ==============================================
-- 5. DIMENSION CLIENT (DimCustomer)
-- ==============================================

PRINT '👥 Création DimCustomer...';

IF OBJECT_ID('DW.DimCustomer', 'U') IS NOT NULL 
    DROP TABLE DW.DimCustomer;

CREATE TABLE DW.DimCustomer (
    CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    PersonID INT,
    StoreID INT,
    CustomerType VARCHAR(20),
    FullName NVARCHAR(200),
    EmailAddress NVARCHAR(100),
    PhoneNumber NVARCHAR(50),
    City NVARCHAR(100),
    StateProvince NVARCHAR(100),
    CountryRegion NVARCHAR(100)
);

-- Remplir DimCustomer
INSERT INTO DW.DimCustomer (
    CustomerID, PersonID, StoreID, CustomerType,
    FullName, EmailAddress, PhoneNumber,
    City, StateProvince, CountryRegion
)
SELECT 
    c.CustomerID,
    c.PersonID,
    c.StoreID,
    CASE 
        WHEN c.PersonID IS NOT NULL THEN 'Individual'
        WHEN c.StoreID IS NOT NULL THEN 'Store'
        ELSE 'Unknown'
    END as CustomerType,
    ISNULL(p.FirstName + ' ' + ISNULL(p.MiddleName + ' ', '') + p.LastName, 'N/A') as FullName,
    ea.EmailAddress,
    pp.PhoneNumber,
    a.City,
    sp.Name as StateProvince,
    cr.Name as CountryRegion
FROM Sales.Customer c
LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
LEFT JOIN Cleaned.EmailAddress ea ON p.BusinessEntityID = ea.BusinessEntityID
LEFT JOIN Person.PersonPhone pp ON p.BusinessEntityID = pp.BusinessEntityID
LEFT JOIN Person.BusinessEntityAddress bea ON p.BusinessEntityID = bea.BusinessEntityID
LEFT JOIN Person.Address a ON bea.AddressID = a.AddressID
LEFT JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
LEFT JOIN Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
WHERE bea.AddressTypeID = 2 OR bea.AddressTypeID IS NULL; -- Adresse principale

PRINT '✅ DimCustomer créée : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';

-- ==============================================
-- 6. TABLE DE FAITS - VENTES (FactSales)
-- ==============================================

PRINT '📊 Création FactSales...';

IF OBJECT_ID('DW.FactSales', 'U') IS NOT NULL 
    DROP TABLE DW.FactSales;

CREATE TABLE DW.FactSales (
    SalesKey INT IDENTITY(1,1) PRIMARY KEY,
    -- Clés étrangères (dimensions)
    OrderDateKey INT FOREIGN KEY REFERENCES DW.DimDate(DateKey),
    DueDateKey INT FOREIGN KEY REFERENCES DW.DimDate(DateKey),
    ShipDateKey INT FOREIGN KEY REFERENCES DW.DimDate(DateKey),
    ProductKey INT FOREIGN KEY REFERENCES DW.DimProduct(ProductKey),
    CustomerKey INT FOREIGN KEY REFERENCES DW.DimCustomer(CustomerKey),
    TerritoryKey INT FOREIGN KEY REFERENCES DW.DimTerritory(TerritoryKey),
    -- Mesures additives
    OrderQuantity INT,
    UnitPrice DECIMAL(10,2),
    UnitPriceDiscount DECIMAL(5,2),
    LineTotal DECIMAL(15,2),
    ProductStandardCost DECIMAL(10,2),
    -- Mesures calculées
    TotalCost DECIMAL(15,2),
    GrossProfit DECIMAL(15,2),
    GrossProfitMargin DECIMAL(5,2),
    -- Clés métier (pour traçabilité)
    SalesOrderID INT,
    SalesOrderDetailID INT
);

-- Remplir FactSales
INSERT INTO DW.FactSales (
    OrderDateKey, DueDateKey, ShipDateKey,
    ProductKey, CustomerKey, TerritoryKey,
    OrderQuantity, UnitPrice, UnitPriceDiscount, LineTotal,
    ProductStandardCost, TotalCost, GrossProfit, GrossProfitMargin,
    SalesOrderID, SalesOrderDetailID
)
SELECT 
    CAST(FORMAT(soh.OrderDate, 'yyyyMMdd') AS INT) as OrderDateKey,
    CAST(FORMAT(soh.DueDate, 'yyyyMMdd') AS INT) as DueDateKey,
    CAST(FORMAT(soh.ShipDate, 'yyyyMMdd') AS INT) as ShipDateKey,
    dp.ProductKey,
    dc.CustomerKey,
    dt.TerritoryKey,
    sod.OrderQty as OrderQuantity,
    sod.UnitPrice,
    sod.UnitPriceDiscount,
    sod.LineTotal,
    dp.StandardCost as ProductStandardCost,
    -- Calculs
    sod.OrderQty * dp.StandardCost as TotalCost,
    sod.LineTotal - (sod.OrderQty * dp.StandardCost) as GrossProfit,
    CASE 
        WHEN sod.LineTotal > 0 
        THEN CAST((sod.LineTotal - (sod.OrderQty * dp.StandardCost)) * 100.0 / sod.LineTotal AS DECIMAL(5,2))
        ELSE 0 
    END as GrossProfitMargin,
    soh.SalesOrderID,
    sod.SalesOrderDetailID
FROM Cleaned.SalesOrderHeader soh
JOIN Cleaned.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN DW.DimProduct dp ON sod.ProductID = dp.ProductID AND dp.IsCurrent = 1
JOIN DW.DimCustomer dc ON soh.CustomerID = dc.CustomerID
LEFT JOIN DW.DimTerritory dt ON soh.TerritoryID = dt.TerritoryID;

PRINT '✅ FactSales créée : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';

-- ==============================================
-- 7. CRÉER DES VUES POUR POWER BI
-- ==============================================

PRINT '';
PRINT '📈 Création des vues analytiques...';

-- Vue : Ventes par Territoire
IF OBJECT_ID('DW.vw_SalesByTerritory', 'V') IS NOT NULL 
    DROP VIEW DW.vw_SalesByTerritory;
GO

CREATE VIEW DW.vw_SalesByTerritory AS
SELECT 
    dt.TerritoryName,
    dt.CountryRegionCode,
    dt.[Group],
    dt.Continent,
    dd.Year,
    dd.QuarterName,
    dd.MonthName,
    COUNT(DISTINCT fs.SalesOrderID) as NumberOfOrders,
    SUM(fs.OrderQuantity) as TotalQuantity,
    SUM(fs.LineTotal) as TotalSales,
    AVG(fs.UnitPrice) as AvgUnitPrice,
    SUM(fs.GrossProfit) as TotalProfit,
    AVG(fs.GrossProfitMargin) as AvgProfitMargin
FROM DW.FactSales fs
JOIN DW.DimDate dd ON fs.OrderDateKey = dd.DateKey
JOIN DW.DimTerritory dt ON fs.TerritoryKey = dt.TerritoryKey
GROUP BY 
    dt.TerritoryName, dt.CountryRegionCode, dt.[Group], dt.Continent,
    dd.Year, dd.QuarterName, dd.MonthName;
GO

PRINT '✅ Vue vw_SalesByTerritory créée';

-- Vue : Performance Produits
IF OBJECT_ID('DW.vw_ProductPerformance', 'V') IS NOT NULL 
    DROP VIEW DW.vw_ProductPerformance;
GO

CREATE VIEW DW.vw_ProductPerformance AS
SELECT 
    dp.ProductCategoryName,
    dp.ProductSubcategoryName,
    dp.ProductName,
    dp.Color,
    dp.PriceRange,
    dd.Year,
    SUM(fs.OrderQuantity) as TotalQuantitySold,
    SUM(fs.LineTotal) as TotalRevenue,
    SUM(fs.TotalCost) as TotalCost,
    SUM(fs.GrossProfit) as TotalProfit,
    AVG(fs.GrossProfitMargin) as AvgProfitMargin,
    COUNT(DISTINCT fs.SalesOrderID) as NumberOfOrders
FROM DW.FactSales fs
JOIN DW.DimProduct dp ON fs.ProductKey = dp.ProductKey
JOIN DW.DimDate dd ON fs.OrderDateKey = dd.DateKey
GROUP BY 
    dp.ProductCategoryName, dp.ProductSubcategoryName, 
    dp.ProductName, dp.Color, dp.PriceRange, dd.Year;
GO

PRINT '✅ Vue vw_ProductPerformance créée';

-- Vue : Analyse Clients
IF OBJECT_ID('DW.vw_CustomerAnalysis', 'V') IS NOT NULL 
    DROP VIEW DW.vw_CustomerAnalysis;
GO

CREATE VIEW DW.vw_CustomerAnalysis AS
SELECT 
    dc.CustomerType,
    dc.City,
    dc.StateProvince,
    dc.CountryRegion,
    dd.Year,
    COUNT(DISTINCT fs.SalesOrderID) as NumberOfOrders,
    SUM(fs.LineTotal) as TotalSpent,
    AVG(fs.LineTotal) as AvgOrderValue,
    COUNT(DISTINCT dc.CustomerID) as NumberOfCustomers
FROM DW.FactSales fs
JOIN DW.DimCustomer dc ON fs.CustomerKey = dc.CustomerKey
JOIN DW.DimDate dd ON fs.OrderDateKey = dd.DateKey
GROUP BY 
    dc.CustomerType, dc.City, dc.StateProvince, 
    dc.CountryRegion, dd.Year;
GO

PRINT '✅ Vue vw_CustomerAnalysis créée';

-- ==============================================
-- 8. STATISTIQUES FINALES
-- ==============================================

PRINT '';
PRINT '📊 === STATISTIQUES DU DATAMART ===';
PRINT '';

SELECT 'DimDate' as [Table], COUNT(*) as [Lignes] FROM DW.DimDate
UNION ALL
SELECT 'DimProduct', COUNT(*) FROM DW.DimProduct
UNION ALL
SELECT 'DimTerritory', COUNT(*) FROM DW.DimTerritory
UNION ALL
SELECT 'DimCustomer', COUNT(*) FROM DW.DimCustomer
UNION ALL
SELECT 'FactSales', COUNT(*) FROM DW.FactSales
ORDER BY [Table];

PRINT '';
PRINT '✅ === DATAMART CRÉÉ AVEC SUCCÈS ===';
PRINT '';
PRINT '📁 Tables créées:';
PRINT '   - DW.DimDate';
PRINT '   - DW.DimProduct';
PRINT '   - DW.DimTerritory';
PRINT '   - DW.DimCustomer';
PRINT '   - DW.FactSales';
PRINT '';
PRINT '📊 Vues créées:';
PRINT '   - DW.vw_SalesByTerritory';
PRINT '   - DW.vw_ProductPerformance';
PRINT '   - DW.vw_CustomerAnalysis';
PRINT '';
PRINT '🚀 Prêt pour Power BI !';
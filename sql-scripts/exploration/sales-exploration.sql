-- EXPLORATION DU SCHÉMA SALES (VENTES)
-- Date: 23/10/2024
-- Base: adventureWORKS

USE adventureWORKS;
GO

-- 1. LISTE DES TABLES SALES(On regarde toutes les tables qui appartiennent au schéma Sales)
SELECT TABLE_NAME, TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'Sales';

-- 2. EXPLORATION SalesOrderHeader on comprend la table des commandes et les clients

-- Structure de la table
SELECT 
    COLUMN_NAME as [Colonne],
    DATA_TYPE as [Type],
    IS_NULLABLE as [Nullable]
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'Sales' 
  AND TABLE_NAME = 'SalesOrderHeader'
ORDER BY ORDINAL_POSITION;

-- Statistiques générales
SELECT 
    COUNT(*) as [Nombre Total Commandes],
    COUNT(DISTINCT CustomerID) as [Nombre Clients],
    MIN(OrderDate) as [Première Commande],
    MAX(OrderDate) as [Dernière Commande],
    SUM(TotalDue) as [CA Total],
    AVG(TotalDue) as [Panier Moyen],
    MIN(TotalDue) as [Commande Min],
    MAX(TotalDue) as [Commande Max]
FROM Sales.SalesOrderHeader;

-- Répartition par année
SELECT 
    YEAR(OrderDate) as [Année],
    COUNT(*) as [Nb Commandes],
    SUM(TotalDue) as [CA],
    AVG(TotalDue) as [Panier Moyen]
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate)
ORDER BY YEAR(OrderDate);

-- Top 10 clients par CA
SELECT TOP 10
    CustomerID,
    COUNT(*) as [Nb Commandes],
    SUM(TotalDue) as [CA Total]
FROM Sales.SalesOrderHeader
GROUP BY CustomerID
ORDER BY SUM(TotalDue) DESC;

-- Échantillon de données
SELECT TOP 100 *
FROM Sales.SalesOrderHeader
ORDER BY OrderDate DESC;

-- 3. EXPLORATION SalesOrderDetail on analyse le détail de chaque commande  

-- Statistiques
SELECT 
    COUNT(*) as [Nombre Lignes],
    COUNT(DISTINCT SalesOrderID) as [Nombre Commandes],
    COUNT(DISTINCT ProductID) as [Nombre Produits],
    SUM(OrderQty) as [Quantité Totale],
    SUM(LineTotal) as [CA Total Détails]
FROM Sales.SalesOrderDetail;

-- Produits les plus vendus
SELECT TOP 10
    ProductID,
    COUNT(DISTINCT SalesOrderID) as [Nb Commandes],
    SUM(OrderQty) as [Quantité Vendue],
    SUM(LineTotal) as [CA]
FROM Sales.SalesOrderDetail
GROUP BY ProductID
ORDER BY SUM(LineTotal) DESC;

-- Échantillon
SELECT TOP 100 *
FROM Sales.SalesOrderDetail;

-- 4. EXPLORATION SalesTerritory on voit où se font les ventes géographiquement

-- Liste des territoires
SELECT 
    TerritoryID,
    Name as [Territoire],
    CountryRegionCode as [Pays],
    [Group] as [Région]
FROM Sales.SalesTerritory
ORDER BY [Group], Name;

-- Ventes par territoire
SELECT 
    st.Name as [Territoire],
    st.CountryRegionCode as [Pays],
    COUNT(soh.SalesOrderID) as [Nb Commandes],
    SUM(soh.TotalDue) as [CA]
FROM Sales.SalesTerritory st
LEFT JOIN Sales.SalesOrderHeader soh ON st.TerritoryID = soh.TerritoryID
GROUP BY st.Name, st.CountryRegionCode
ORDER BY SUM(soh.TotalDue) DESC;

-- 5. EXPLORATION Customer (Clients) on explore les clients de la base

-- Stats clients
SELECT 
    COUNT(*) as [Nombre Total Clients],
    COUNT(PersonID) as [Clients Personnes],
    COUNT(StoreID) as [Clients Magasins]
FROM Sales.Customer;

-- Échantillon
SELECT TOP 100 *
FROM Sales.Customer;

-- 6. ANALYSE DE QUALITÉ - SALES on contrôle la qualité et la fiabilité des données

-- Vérifier les valeurs NULL dans SalesOrderHeader
SELECT 
    'ShipDate' as [Colonne],
    COUNT(*) as [Nombre NULL]
FROM Sales.SalesOrderHeader
WHERE ShipDate IS NULL
UNION ALL
SELECT 
    'CustomerID',
    COUNT(*)
FROM Sales.SalesOrderHeader
WHERE CustomerID IS NULL
UNION ALL
SELECT 
    'TerritoryID',
    COUNT(*)
FROM Sales.SalesOrderHeader
WHERE TerritoryID IS NULL;

-- Vérifier les doublons (il ne devrait pas y en avoir)
SELECT 
    SalesOrderID,
    COUNT(*) as [Nombre]
FROM Sales.SalesOrderHeader
GROUP BY SalesOrderID
HAVING COUNT(*) > 1;

-- Valeurs aberrantes (prix négatifs)
SELECT 
    COUNT(*) as [Commandes avec montant négatif]
FROM Sales.SalesOrderHeader
WHERE TotalDue < 0;

PRINT '=== EXPLORATION SALES TERMINÉE ==='
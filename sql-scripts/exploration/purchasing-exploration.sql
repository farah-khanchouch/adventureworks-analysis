-- EXPLORATION DU SCHÉMA PURCHASING (ACHATS)
-- Date: 23/10/2024
-- Base: adventureWORKS

USE adventureWORKS;
GO

-- 1. LISTE DES TABLES PURCHASING Affiche toutes les tables qui appartiennent au schéma Purchasing (ex: Vendor, PurchaseOrderHeader…).
SELECT 
    TABLE_NAME as [Nom Table]
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'Purchasing'
ORDER BY TABLE_NAME;

-- 2. EXPLORATION PurchaseOrderHeader (Commandes achat) Analyse les commandes d’achat avec leurs montants, dates et répartition annuelle.

-- Statistiques générales
SELECT 
    COUNT(*) as [Nombre Commandes],
    COUNT(DISTINCT VendorID) as [Nombre Fournisseurs],
    MIN(OrderDate) as [Première Commande],
    MAX(OrderDate) as [Dernière Commande],
    SUM(TotalDue) as [Montant Total Achats],
    AVG(TotalDue) as [Montant Moyen]
FROM Purchasing.PurchaseOrderHeader;

-- Achats par année
SELECT 
    YEAR(OrderDate) as [Année],
    COUNT(*) as [Nb Commandes],
    SUM(TotalDue) as [Montant Total]
FROM Purchasing.PurchaseOrderHeader
GROUP BY YEAR(OrderDate)
ORDER BY YEAR(OrderDate);

-- Échantillon
SELECT TOP 100 *
FROM Purchasing.PurchaseOrderHeader
ORDER BY OrderDate DESC;

-- 3. EXPLORATION Vendor (Fournisseurs) Donne les statistiques des fournisseurs et identifie les 10 plus importants par volume d’achat.

-- Stats fournisseurs
SELECT 
    COUNT(*) as [Nombre Total Fournisseurs],
    COUNT(CASE WHEN ActiveFlag = 1 THEN 1 END) as [Fournisseurs Actifs]
FROM Purchasing.Vendor;

-- Top 10 fournisseurs par volume
SELECT TOP 10
    v.Name as [Fournisseur],
    COUNT(poh.PurchaseOrderID) as [Nb Commandes],
    SUM(poh.TotalDue) as [Montant Total]
FROM Purchasing.Vendor v
LEFT JOIN Purchasing.PurchaseOrderHeader poh ON v.BusinessEntityID = poh.VendorID
GROUP BY v.Name
ORDER BY SUM(poh.TotalDue) DESC;

-- 4. EXPLORATION PurchaseOrderDetail (Détails achats) Résume les détails d’achats et les produits les plus achetés.

-- Stats détails
SELECT 
    COUNT(*) as [Nombre Lignes],
    COUNT(DISTINCT PurchaseOrderID) as [Nombre Commandes],
    COUNT(DISTINCT ProductID) as [Nombre Produits],
    SUM(OrderQty) as [Quantité Totale],
    SUM(LineTotal) as [Montant Total]
FROM Purchasing.PurchaseOrderDetail;

-- Produits les plus achetés
SELECT TOP 10
    pod.ProductID,
    p.Name as [Produit],
    SUM(pod.OrderQty) as [Quantité],
    SUM(pod.LineTotal) as [Montant]
FROM Purchasing.PurchaseOrderDetail pod
JOIN Production.Product p ON pod.ProductID = p.ProductID
GROUP BY pod.ProductID, p.Name
ORDER BY SUM(pod.LineTotal) DESC;

-- 5. ANALYSE DE QUALITÉ - PURCHASING Vérifie les valeurs manquantes et les montants incohérents.


-- NULL
SELECT 
    'ShipDate' as [Colonne],
    COUNT(*) as [Nombre NULL]
FROM Purchasing.PurchaseOrderHeader
WHERE ShipDate IS NULL;

-- Montants négatifs
SELECT 
    COUNT(*) as [Commandes avec montant négatif]
FROM Purchasing.PurchaseOrderHeader
WHERE TotalDue < 0;

PRINT '=== EXPLORATION PURCHASING TERMINÉE ==='
-- EXPLORATION DU SCHÉMA PRODUCTION
-- Date: 23/10/2024
-- Base: adventureWORKS

USE adventureWORKS;
GO

-- 1. LISTE DES TABLES PRODUCTION Affiche toutes les tables du schéma Production.
SELECT 
    TABLE_NAME as [Nom Table]
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'Production'
ORDER BY TABLE_NAME;

-- 2. EXPLORATION Product (Produits) Analyse les produits (structure, prix, coûts, couleurs, top produits, etc.).

-- Structure
SELECT 
    COLUMN_NAME as [Colonne],
    DATA_TYPE as [Type],
    IS_NULLABLE as [Nullable]
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'Production' 
  AND TABLE_NAME = 'Product'
ORDER BY ORDINAL_POSITION;

-- Statistiques générales
SELECT 
    COUNT(*) as [Nombre Total Produits],
    COUNT(DISTINCT ProductSubcategoryID) as [Nombre Sous-catégories],
    AVG(ListPrice) as [Prix Moyen],
    MIN(ListPrice) as [Prix Min],
    MAX(ListPrice) as [Prix Max],
    AVG(StandardCost) as [Coût Moyen],
    COUNT(CASE WHEN DiscontinuedDate IS NOT NULL THEN 1 END) as [Produits Arrêtés]
FROM Production.Product;

-- Répartition par couleur
SELECT 
    ISNULL(Color, 'Non spécifié') as [Couleur],
    COUNT(*) as [Nombre Produits],
    AVG(ListPrice) as [Prix Moyen]
FROM Production.Product
GROUP BY Color
ORDER BY COUNT(*) DESC;

-- Top 20 produits les plus chers
SELECT TOP 20
    ProductID,
    Name as [Nom],
    ProductNumber as [Référence],
    ListPrice as [Prix],
    StandardCost as [Coût],
    ListPrice - StandardCost as [Marge]
FROM Production.Product
ORDER BY ListPrice DESC;

-- Échantillon
SELECT TOP 100 *
FROM Production.Product
ORDER BY ProductID;

-- 3. EXPLORATION ProductCategory (Catégories) Montre les catégories, leurs sous-catégories et le nombre total de produits par catégorie.

-- Liste des catégories
SELECT 
    ProductCategoryID,
    Name as [Catégorie]
FROM Production.ProductCategory
ORDER BY Name;

-- Nombre de produits par catégorie
SELECT 
    pc.Name as [Catégorie],
    COUNT(DISTINCT psc.ProductSubcategoryID) as [Nb Sous-catégories],
    COUNT(p.ProductID) as [Nb Produits],
    AVG(p.ListPrice) as [Prix Moyen],
    SUM(p.ListPrice) as [Valeur Stock]
FROM Production.ProductCategory pc
LEFT JOIN Production.ProductSubcategory psc ON pc.ProductCategoryID = psc.ProductCategoryID
LEFT JOIN Production.Product p ON psc.ProductSubcategoryID = p.ProductSubcategoryID
GROUP BY pc.Name
ORDER BY COUNT(p.ProductID) DESC;

-- 4. EXPLORATION ProductSubcategory (Sous-catégories) Détaille les sous-catégories avec leur nombre de produits et le prix moyen.Détaille les sous-catégories avec leur nombre de produits et le prix moyen.

-- Détail par sous-catégorie
SELECT 
    pc.Name as [Catégorie],
    psc.Name as [Sous-catégorie],
    COUNT(p.ProductID) as [Nb Produits],
    AVG(p.ListPrice) as [Prix Moyen]
FROM Production.ProductCategory pc
JOIN Production.ProductSubcategory psc ON pc.ProductCategoryID = psc.ProductCategoryID
LEFT JOIN Production.Product p ON psc.ProductSubcategoryID = p.ProductSubcategoryID
GROUP BY pc.Name, psc.Name
ORDER BY pc.Name, psc.Name;


-- 5. EXPLORATION ProductInventory (Inventaire) Étudie les stocks disponibles et identifie les produits à faible quantité.

-- Stats inventaire
SELECT 
    COUNT(DISTINCT ProductID) as [Produits en Stock],
    SUM(Quantity) as [Quantité Totale],
    AVG(Quantity) as [Quantité Moyenne]
FROM Production.ProductInventory;

-- Produits avec stock faible
SELECT TOP 20
    pi.ProductID,
    p.Name as [Produit],
    SUM(pi.Quantity) as [Stock Total],
    p.SafetyStockLevel as [Seuil Sécurité]
FROM Production.ProductInventory pi
JOIN Production.Product p ON pi.ProductID = p.ProductID
GROUP BY pi.ProductID, p.Name, p.SafetyStockLevel
HAVING SUM(pi.Quantity) < p.SafetyStockLevel
ORDER BY SUM(pi.Quantity);

-- 6. ANALYSE DE QUALITÉ - PRODUCTION  Vérifie les champs manquants et les produits avec des prix invalides.

-- NULL dans Product
SELECT 
    'Color' as [Colonne],
    COUNT(*) as [Nombre NULL]
FROM Production.Product
WHERE Color IS NULL
UNION ALL
SELECT 
    'Size',
    COUNT(*)
FROM Production.Product
WHERE Size IS NULL
UNION ALL
SELECT 
    'Weight',
    COUNT(*)
FROM Production.Product
WHERE Weight IS NULL;

-- Prix négatifs ou zéro
SELECT 
    COUNT(*) as [Produits avec prix invalide]
FROM Production.Product
WHERE ListPrice <= 0 OR StandardCost < 0;

PRINT '=== EXPLORATION PRODUCTION TERMINÉE ==='
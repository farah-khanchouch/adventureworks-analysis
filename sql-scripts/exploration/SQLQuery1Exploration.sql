-- First Exploration - Farah Khanchouch
USE adventureWORKS;
--nombre de table--

SELECT COUNT(*) as NbrTables 
FROM INFORMATION_SCHEMA.TABLES;

--Regroupe les tables par “schéma”--
SELECT TABLE_SCHEMA, COUNT(*) as NbrTables
FROM INFORMATION_SCHEMA.TABLES 
GROUP BY TABLE_SCHEMA;

--Statistiques des ventes--
SELECT COUNT(*) as NbCommandes, 
       SUM(TotalDue) as CA_Total 
FROM Sales.SalesOrderHeader;

--Top 10 produits par prix--
SELECT TOP 10 Name, ListPrice 
FROM Production.Product 
ORDER BY ListPrice DESC;
-- EXPLORATION DU SCHÉMA HUMANRESOURCES (RH)
-- Date: 23/10/2024
-- Base: adventureWORKS

USE adventureWORKS;
GO

-- 1. LISTE DES TABLES HR Affiche toutes les tables du schéma HumanResources.
SELECT 
    TABLE_NAME as [Nom Table]
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'HumanResources'
ORDER BY TABLE_NAME;


-- 2. EXPLORATION Employee (Employés) Analyse les employés (effectif, âges, ancienneté, genre, postes, etc.).

-- Statistiques générales
SELECT 
    COUNT(*) as [Nombre Total Employés],
    COUNT(DISTINCT JobTitle) as [Nombre Postes],
    MIN(HireDate) as [Plus Ancienne Embauche],
    MAX(HireDate) as [Dernière Embauche],
    AVG(DATEDIFF(YEAR, BirthDate, GETDATE())) as [Âge Moyen],
    AVG(DATEDIFF(YEAR, HireDate, GETDATE())) as [Ancienneté Moyenne]
FROM HumanResources.Employee;

-- Répartition par genre
SELECT 
    Gender as [Genre],
    COUNT(*) as [Nombre],
    AVG(DATEDIFF(YEAR, BirthDate, GETDATE())) as [Âge Moyen]
FROM HumanResources.Employee
GROUP BY Gender;

-- Répartition par statut marital
SELECT 
    MaritalStatus as [Statut],
    COUNT(*) as [Nombre]
FROM HumanResources.Employee
GROUP BY MaritalStatus;

-- Top 10 postes
SELECT TOP 10
    JobTitle as [Poste],
    COUNT(*) as [Nombre Employés]
FROM HumanResources.Employee
GROUP BY JobTitle
ORDER BY COUNT(*) DESC;

-- Échantillon
SELECT TOP 100
    BusinessEntityID,
    JobTitle,
    HireDate,
    DATEDIFF(YEAR, HireDate, GETDATE()) as [Ancienneté]
FROM HumanResources.Employee
ORDER BY HireDate;

-- 3. EXPLORATION Department (Départements) Liste les départements et le nombre d’employés actifs par département.

-- Liste des départements
SELECT 
    DepartmentID,
    Name as [Département],
    GroupName as [Groupe]
FROM HumanResources.Department
ORDER BY GroupName, Name;

-- Employés par département (actuel)
SELECT 
    d.Name as [Département],
    d.GroupName as [Groupe],
    COUNT(DISTINCT edh.BusinessEntityID) as [Nombre Employés]
FROM HumanResources.Department d
LEFT JOIN HumanResources.EmployeeDepartmentHistory edh 
    ON d.DepartmentID = edh.DepartmentID
    AND edh.EndDate IS NULL
GROUP BY d.Name, d.GroupName
ORDER BY COUNT(DISTINCT edh.BusinessEntityID) DESC;

-- 4. EXPLORATION Shift (Équipes) Montre les équipes (horaires) et combien d’employés travaillent dans chaque.

-- Liste des shifts
SELECT 
    ShiftID,
    Name as [Shift],
    StartTime as [Début],
    EndTime as [Fin]
FROM HumanResources.Shift;

-- Employés par shift
SELECT 
    s.Name as [Shift],
    COUNT(DISTINCT edh.BusinessEntityID) as [Nombre Employés]
FROM HumanResources.Shift s
LEFT JOIN HumanResources.EmployeeDepartmentHistory edh 
    ON s.ShiftID = edh.ShiftID
    AND edh.EndDate IS NULL
GROUP BY s.Name
ORDER BY COUNT(DISTINCT edh.BusinessEntityID) DESC;

-- 5. EXPLORATION EmployeePayHistory (Salaires) Analyse les salaires (moyenne, min, max, top 10 salaires).Analyse les salaires (moyenne, min, max, top 10 salaires).

-- Stats salaires
SELECT 
    COUNT(DISTINCT BusinessEntityID) as [Employés avec historique salaire],
    AVG(Rate) as [Salaire Moyen],
    MIN(Rate) as [Salaire Min],
    MAX(Rate) as [Salaire Max]
FROM HumanResources.EmployeePayHistory;

-- Top 10 salaires
SELECT TOP 10
    e.BusinessEntityID,
    e.JobTitle as [Poste],
    eph.Rate as [Salaire],
    eph.PayFrequency as [Fréquence]
FROM HumanResources.EmployeePayHistory eph
JOIN HumanResources.Employee e ON eph.BusinessEntityID = e.BusinessEntityID
WHERE eph.RateChangeDate = (
    SELECT MAX(RateChangeDate) 
    FROM HumanResources.EmployeePayHistory 
    WHERE BusinessEntityID = eph.BusinessEntityID
)
ORDER BY eph.Rate DESC;

-- 6. ANALYSE DE QUALITÉ - HR Vérifie s’il y a des employés sans niveau d’organisation.

-- NULL dans Employee
SELECT 
    COUNT(*) as [Employés sans OrganizationLevel]
FROM HumanResources.Employee
WHERE OrganizationLevel IS NULL;

PRINT '=== EXPLORATION HR TERMINÉE ==='
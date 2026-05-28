-- =============================================
-- Bartosz
-- Kozioł
-- 237382
-- =============================================

-- =============================================
-- Zadanie 1
-- =============================================

SELECT DISTINCT
    pc.Name AS CategoryName,
    MIN(p.ListPrice) OVER (PARTITION BY p.ProductCategoryID) AS MinPrice,
    MAX(p.ListPrice) OVER (PARTITION BY p.ProductCategoryID) AS MaxPrice,
    COUNT(p.ProductID) OVER (PARTITION BY p.ProductCategoryID) AS ProductCount
FROM SalesLT.Product p
JOIN SalesLT.ProductCategory pc ON p.ProductCategoryID = pc.ProductCategoryID
GO

-- =============================================
-- Zadanie 2
-- =============================================

-- Stworzenie rankingu sprzedaży dla każdego z działów osobno, aby który pokaże jak dany pracownik sobie radzi

DROP TABLE IF EXISTS dbo.Sprzedaz;
GO

CREATE TABLE dbo.Sprzedaz (
    ID INT PRIMARY KEY,
    Pracownik NVARCHAR(50),
    Dzial NVARCHAR(50),
    Kwota MONEY
);
GO

INSERT INTO dbo.Sprzedaz VALUES 
(1, 'Bartosz', 'IT', 5000),
(2, 'Anna', 'IT', 7000),
(3, 'Jan', 'HR', 4000),
(4, 'Marek', 'IT', 7000),
(5, 'Ewa', 'HR', 4500);
GO

SELECT 
    Pracownik,
    Dzial,
    Kwota,
    RANK() OVER (PARTITION BY Dzial ORDER BY Kwota DESC) AS RankingWDziale
FROM dbo.Sprzedaz;
GO


-- =============================================
-- Zadanie 3
-- =============================================

-- Zobrazowanie sprzedaży dla każdego miesiąca dla różnych produktów
-- Użycie PIVOT umożliwia miesiącom, aby były kolumnami, co jest bardzo czytelne dla człowieka pod kątem analitycznym 
-- Użycie UNPIVOT jest natomiast odwróceniem funckji PIVOT - każdy miesiąc nie jest już oddzielną kolumną, a miesiące występują wierszowo

DROP TABLE IF EXISTS dbo.MiesiecznaSprzedaz;
DROP TABLE IF EXISTS #PivotWynik;
GO

CREATE TABLE dbo.MiesiecznaSprzedaz (
    Produkt NVARCHAR(50),
    Miesiac NVARCHAR(20),
    Kwota INT
);
GO

INSERT INTO dbo.MiesiecznaSprzedaz VALUES
('Kask', 'Styczen', 100),
('Kask', 'Luty', 150),
('Rower', 'Styczen', 2000),
('Rower', 'Luty', 2500);
GO

---SELECT * FROM  dbo.MiesiecznaSprzedaz;

SELECT * INTO #PivotWynik
FROM ( SELECT Produkt, Miesiac, Kwota FROM dbo.MiesiecznaSprzedaz) 
AS src
PIVOT (
        SUM(Kwota)
        FOR Miesiac IN ([Styczen], [Luty])
        )
AS pvt;

-- SELECT * FROM #PivotWynik

SELECT Produkt, Miesiac, Kwota FROM #PivotWynik
UNPIVOT (
        Kwota FOR Miesiac IN ([Styczen], [Luty])
        )
AS unpvt;
GO

-- =============================================
-- Zadanie 4
-- =============================================

-- Mamy stan magazonowy dla sklepu rowerowego i chcemy mieć ładnie widoczne ile sztuk jest danego modelu aktualnie na stanie oraz sumy dla danych typów rowerów np. Górski, Szosowy
-- W tym celu użyjemy funkcji ROLLUP
-- Funckja ta również pokaże nam sumę całkowitą dla naszego całego stanu magazynowego

DROP TABLE IF EXISTS dbo.BazaSklepuRowerowego;
GO

CREATE TABLE dbo.BazaSklepuRowerowego (
    TypRoweru NVARCHAR(50),
    Model NVARCHAR(50),
    IloscSztuk INT
);
GO

INSERT INTO dbo.BazaSklepuRowerowego VALUES
('Gorski', 'MTB PRO', 10),
('Gorski', 'Full', 5),
('Gorski', 'Enduro', 7),
('Szosowy', 'Aero Dynamic', 9),
('Szosowy', 'Ultra Light', 5);
GO

-- SELECT * FROM dbo.BazaSklepuRowerowego

SELECT 
    TypRoweru,
    Model,
    SUM(IloscSztuk) AS LacznaIlosc
FROM dbo.BazaSklepuRowerowego
GROUP BY ROLLUP (TypRoweru, Model);
GO
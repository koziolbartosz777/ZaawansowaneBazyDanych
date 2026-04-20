-- =============================================
-- Bartosz
-- Kozioł
-- 237382
-- =============================================


-- =============================================
-- Zadanie 1
-- =============================================

CREATE TYPE dbo.B2_surname FROM NVARCHAR(50) NOT NULL
GO

ALTER TABLE SalesLT.Customer ALTER COLUMN LastName dbo.B2_surname
GO


-- =============================================
-- Zadanie 2
-- =============================================


CREATE VIEW SalesLT.v_B2_ProductPrices AS SELECT
	ProductID,
	Name as ProductName,
	ListPrice as CurrentPrice
FROM SalesLT.Product
GO

--SELECT * FROM SalesLT.Product

DECLARE @ProductInfo NVARCHAR(MAX) = N'[
	{"ProductID": 680, "NewPrice": 1500.00},
    {"ProductID": 706, "NewPrice": 1400.00},
    {"ProductID": 707, "NewPrice": 700.00},
    {"ProductID": 708, "NewPrice": 551.00},
    {"ProductID": 709, "NewPrice": 662.00}
]'


SELECT 
	v.ProductID,
	v.CurrentPrice,
	j.NewPrice,
	(j.NewPrice - v.CurrentPrice) AS PriceDiff
FROM SalesLT.v_B2_ProductPrices v
JOIN OPENJSON(@ProductInfo)
WITH(
	ProductID INT '$.ProductID',
	NewPrice DECIMAL(12,2) '$.NewPrice') 
AS j ON v.ProductID = j.ProductID
GO

-- =============================================
-- Zadanie 3
-- =============================================

CREATE VIEW SalesLT.[237382_order] AS 
SELECT TOP 100 PERCENT
	ProductID,
	Name,
	ListPrice
From SalesLT.Product ORDER BY Name ASC
GO

--SELECT * FROM SalesLT.[237382_order]

-- =============================================
-- Zadanie 4
-- =============================================


-- Opis Biznesowy
-- Widok umożliwa szybką ocenę rentowności produktu
-- Dostajemy gotowe wskazówki 'HIGH/LOW Profit Margin', co pozwala na szybszą oraz bardziej przejrzystą analize opłacalności produktów
-- Rozpatrujemy produkty, które nadal są aktywne w sprzedaży

CREATE VIEW SalesLT.[Student_2.MyLogicView] AS
SELECT
	ProductID, 
	Name as ProductName,
	StandardCost as Cost,
	ListPrice as Price,
	(ListPrice - StandardCost) as ProfitMargin,

	CASE 
		WHEN (ListPrice - StandardCost) / NULLIF(ListPrice,0) > 0.5 THEN 'HIGH Profit Margin'
		WHEN (ListPrice - StandardCost) / NULLIF(ListPrice, 0) BETWEEN 0.2 AND 0.5 THEN 'Standard'
		ELSE 'LOW Profit Margin'
	END AS SalesRating
FROM SalesLT.Product WHERE DiscontinuedDate IS NULL 
GO

SELECT * FROM SalesLT.[Student_2.MyLogicView]
GO

--SELECT * FROM SalesLT.v_TopProfits_2

-- =============================================
-- Zadanie 5
-- =============================================

CREATE VIEW SalesLT.v_TopProfits_2 AS
SELECT 
	ProductName, 
	Price,
	ProfitMargin
FROM SalesLT.[Student_2.MyLogicView]
WHERE SalesRating = 'HIGH Profit Margin'
GO

--SELECT * FROM SalesLT.v_TopProfits_2
-- =============================================
-- Bartosz
-- Kozioł
-- 237382
-- =============================================


-- =============================================
-- Zadanie 1
-- ============================================

CREATE TABLE SalesLT.ProductPriceHistory (
	HistoryID int identity(1,1) primary key,
	ProductID int not null,
	OldPrice decimal(12,2),
	NewPrice decimal(12,2),
	ChangeDate datetime default getdate()
)
GO

CREATE OR ALTER TRIGGER SalesLT.trg_Product_PriceChange
ON SalesLT.Product 
AFTER UPDATE 
AS 
BEGIN
	SET NOCOUNT ON;

	INSERT INTO SalesLT.ProductPriceHistory (ProductID, OldPrice, NewPrice)
	SELECT 
		i.ProductID,
		d.ListPrice as OldPrice,
		i.ListPrice as NewPrice
	FROM inserted i
	JOIN DELETED d ON i.ProductID = d.ProductID
	WHERE ISNULL(d.ListPrice, -1) <> ISNULL(i.ListPrice, -1);
END
GO 


-- Test

UPDATE SalesLT.Product 
SET ListPrice = ListPrice * 1.1
WHERE ProductID = 680;

select * from SalesLT.ProductPriceHistory;


-- =============================================
-- Zadanie 2
-- ============================================

CREATE TABLE SalesLT.DeletedCustomersLog (
	CustomerID int,
	FirstName nvarchar(50),
	LastName nvarchar(50)
)
GO
	
CREATE OR ALTER TRIGGER SalesLT.trg_CustomerDel
ON SalesLT.Customer
INSTEAD OF DELETE
AS
BEGIN
	SET NOCOUNT ON;

	INSERT INTO SalesLT.DeletedCustomersLog (CustomerID, FirstName, LastName)
	SELECT DISTINCT d.CustomerID, d.FirstName, d.LastName
	FROM deleted d
	JOIN SalesLT.SalesOrderHeader s ON d.CustomerID = s.CustomerID

	DELETE FROM SalesLT.Customer
	WHERE CustomerID in (
		SELECT CustomerID FROM deleted d 
		WHERE d.CustomerID not in (SELECT CustomerID FROM SalesLT.SalesOrderHeader))
END
GO

--select * from SalesLT.SalesOrderDetail
--select * from SalesLT.SalesOrderHeader



--Błąd:
--Msg 13569, Level 16, State 2, Procedure trg_CustomerDel, Line 60
--Cannot create a trigger on a system-versioned temporal table 'sql-adb-s237382-dev-pl.SalesLT.Customer'.

-- Zadanie nie może zostać wykonane na tabeli SalesLT.Customer, ponieważ jest ona tabelą temporalną
-- Triggery INSTEAD OF nie można zakładać na tabelach, które mają włączone wersjonowanie historii zmian.




-- =============================================
-- Zadanie 3
-- ============================================

WITH Category_Rel AS (
    SELECT 
        ProductCategoryID,
        CAST(Name AS NVARCHAR(MAX)) as Path
    FROM SalesLT.ProductCategory
    WHERE ParentProductCategoryID is null

    UNION ALL

    SELECT 
        c.ProductCategoryID,
        CAST(cr.Path + N' → ' + c.Name AS NVARCHAR(MAX))
    FROM SalesLT.ProductCategory c
    JOIN Category_Rel cr
    ON c.ParentProductCategoryID = cr.ProductCategoryID
)


SELECT PATH FROM Category_Rel ORDER BY PATH

GO

-- =============================================
-- Zadanie 4
-- ============================================

CREATE TABLE SalesLT.PriceLogs (
    ProductID INT,
    Text NVARCHAR(100)
)
GO


CREATE OR ALTER TRIGGER SalesLT.trg_PriceChangeBlock
ON SalesLT.Product
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN deleted d ON i.ProductID = d.ProductID
        WHERE i.ListPrice > d.ListPrice * 1.2
    )

	BEGIN 
		
		INSERT INTO SalesLT.PriceLogs (ProductID, Text)
		SELECT i.ProductID, 'Próba podwyżki > 20%'
        FROM inserted i
        JOIN deleted d ON i.ProductID = d.ProductID
        WHERE i.ListPrice > d.ListPrice * 1.2;

		ROLLBACK;

	END
END

GO


UPDATE SalesLT.Product 
SET ListPrice = ListPrice * 1.5 
WHERE ProductID = 680;

GO


-- =============================================
-- Zadanie 5
-- ============================================

CREATE TABLE dbo.DatabaseAuditLog (
	LogID INT IDENTITY(1,1) PRIMARY KEY,
    Who NVARCHAR(100),
    Changed XML
);
GO

CREATE OR ALTER TRIGGER trg_DatabaseAudit
ON DATABASE
FOR CREATE_TABLE, ALTER_TABLE, DROP_TABLE
AS
BEGIN
	INSERT INTO dbo.DatabaseAuditLog (Who, Changed)
	VALUES (
			SYSTEM_USER,
			EVENTDATA()
		)
END

GO


--CREATE TABLE dbo.TestTable (id int)
--DROP TABLE dbo.TestTable

--SELECT * FROM dbo.DatabaseAuditLog


-- =============================================
-- Zadanie 6
-- ============================================

--Logika biznesowa: Znalezienie produktów, których średnia ocen jest mniejsza niż 3 w celu wycofania ich z naszej oferty sprzedaży


CREATE TABLE SalesLT.ProductOpinions (
    OpinionID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT FOREIGN KEY REFERENCES SalesLT.Product(ProductID),
    Rate INT 
)
GO

INSERT INTO SalesLT.ProductOpinions (ProductID, Rate) 
VALUES 
	(680,5),
	(680,4),
	(706,2),
	(706,1)
GO

WITH LowRateProducts AS (
	SELECT 
		ProductID, 
		AVG(Rate) as AverageRate
	FROM SalesLT.ProductOpinions
	GROUP BY ProductID HAVING AVG(Rate) < 3
)

SELECT 
	p.Name as ProductName,
	lrp.AverageRate
FROM SalesLT.Product p 
join LowRateProducts lrp on p.ProductID = lrp.ProductID
GO


--select * from SalesLT.Product





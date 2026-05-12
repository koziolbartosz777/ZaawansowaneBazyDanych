-- =============================================
-- Bartosz
-- Kozioł
-- 237382
-- =============================================

-- =============================================
-- Zadanie 1
-- =============================================

--select * from SalesLT.[237382_order] ORDER BY ListPrice desc


CREATE FUNCTION SalesLT.ufn_GetBestRecord_237382 (
    @FilterName NVARCHAR(50) = '', 
    @MaxListPrice DECIMAL(18,2) = 4000.00, 
    @MinProductID INT = 0 
)
RETURNS INT
AS
BEGIN
    DECLARE @BestRecordID INT

    SELECT TOP 1 @BestRecordID = ProductID
    FROM SalesLT.[237382_order]
    WHERE Name LIKE '%' + @FilterName + '%'
      AND ListPrice <= @MaxListPrice
      AND ProductID >= @MinProductID
    ORDER BY ListPrice DESC

    RETURN @BestRecordID
END
GO

SELECT SalesLT.ufn_GetBestRecord_237382(DEFAULT, DEFAULT, DEFAULT) AS BestProductID



-- =============================================
-- Zadanie 2
-- =============================================

CREATE TABLE #TopProducts (
    ProductID INT,
    Name NVARCHAR(50),
    ListPrice DECIMAL(18,2)
)


INSERT INTO #TopProducts (ProductID, Name, ListPrice)
SELECT TOP 25 ProductID, Name, ListPrice
FROM SalesLT.Product
ORDER BY ListPrice DESC
GO

CREATE FUNCTION Student_2.ufn_CalcAdjustedPrices ()
RETURNS TABLE
AS
RETURN
(
    SELECT 
        ProductID, 
        Name, 
        ListPrice, 
        (ListPrice - (ListPrice * 0.02)) AS AdjustedPrice
    FROM #TopProducts
)
GO

DECLARE @Summary TABLE (
    ProductID INT,
    Name NVARCHAR(50),
    ListPrice DECIMAL(18,2),
    AdjustedPrice DECIMAL(18,2)
)

GO

-- Msg 2772, Level 16, State 1, Procedure ufn_CalcAdjustedPrices, Line 67
-- Cannot access temporary tables from within a function.
-- Nie jest możliwe wykowanie CREATE FUNCTION Student_2.ufn_CalcAdjustedPrices (), ponieważ funkcje potrzebują trwałego kontekstu, który to nie jest dostarczany
-- poprzez tabele tymczasowe, które istnieją jedynie w bieżacej sesji


-- =============================================
-- Zadanie 3
-- =============================================

CREATE FUNCTION Student_2.ufn_ProductsJsonByCategory (
    @CategoryName NVARCHAR(50)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @JsonOutput NVARCHAR(MAX)

    SET @JsonOutput = (
        SELECT 
            p.ProductID, 
            p.Name AS ProductName, 
            p.ListPrice as ProductPrice,
            p.Color,
            pc.Name AS CategoryName
       FROM SalesLT.Product p JOIN SalesLT.ProductCategory pc 
       ON p.ProductCategoryID = pc.ProductCategoryID
       WHERE pc.Name = @CategoryName
       FOR JSON PATH
    )

    RETURN @JsonOutput
END
GO

-- =============================================
-- Zadanie 4
-- =============================================

CREATE FUNCTION Student_2.ufn_IsPriceHigherThanCurrent (
    @ProductJson NVARCHAR(MAX)
)
RETURNS VARCHAR(5)
AS
BEGIN
    RETURN (
        SELECT CASE 
            WHEN CAST(JSON_VALUE(@ProductJson, '$.ListPrice') AS DECIMAL(18,2)) > ListPrice THEN 'true'
            WHEN CAST(JSON_VALUE(@ProductJson, '$.ListPrice') AS DECIMAL(18,2)) < ListPrice THEN 'false'
        END
        FROM SalesLT.Product 
        WHERE ProductID = CAST(JSON_VALUE(@ProductJson, '$.ProductID') AS INT))
END
GO


-- Gdy cena będzie równa, system zwróci wartość NULL, ponieważ instrukcja warunkowa nie definiuje zachowania dla znaku równości


-- =============================================
-- Zadanie 5
-- =============================================

CREATE FUNCTION Student_2.ufn_GetProductPriceStatus (
    @ProductJson NVARCHAR(MAX)
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        ProductID,
        Name,
        ListPrice AS CurrentPrice,
        Student_2.ufn_IsPriceHigherThanCurrent(@ProductJson) AS IsPriceHigher
    FROM SalesLT.Product
    WHERE ProductID = CAST(JSON_VALUE(@ProductJson, '$.ProductID') AS INT)
)
GO

-- SELECT * FROM Student_2.ufn_GetProductPriceStatus('{"ProductID": 749, "ListPrice": 5000.00}')
-- SELECT * FROM Student_2.ufn_GetProductPriceStatus('{"ProductID": 749, "ListPrice": 1000.00}')
-- SELECT * FROM Student_2.ufn_GetProductPriceStatus('{"ProductID": 749, "ListPrice": 3578.27}')\

-- =============================================
-- Zadanie 6
-- =============================================

-- iTVF (inline table-valued function)
-- Funkcja składająca się z jednego RETURN (SELECT ...) - jest ona bardzo szybka, więc w wypożyczalni samochodów wykorzstamy ją do szybkiego 
-- wyszukiwania dostępnych do wypożczenia przez klienta samochodów pożądanej marki w danym budżecie, określonym przez klienta 

DROP FUNCTION IF EXISTS Student_2.ufn_GetAvailableCars
GO

CREATE FUNCTION Student_2.ufn_GetAvailableCars (
    @Make NVARCHAR(50),
    @MaxPricePerDay DECIMAL(8,2)
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        CarID, 
        Model, 
        ProductionYear, 
        PricePerDay
    FROM Student_2.Cars
    WHERE Make = @Make 
      AND PricePerDay <= @MaxPricePerDay
      AND IsAvailable = 1
)
GO

CREATE TABLE Student_2.Cars (
    CarID INT PRIMARY KEY,
    Make NVARCHAR(50),
    Model NVARCHAR(50),
    ProductionYear INT,
    PricePerDay DECIMAL(8,2),
    IsAvailable BIT
)

INSERT INTO Student_2.Cars (CarID, Make, Model, ProductionYear, PricePerDay, IsAvailable)
VALUES 
(1, 'Toyota', 'Corolla', 2022, 150.00, 1),
(2, 'Toyota', 'Yaris', 2021, 100.00, 1),
(3, 'BMW', 'X5', 2023, 500.00, 1),
(4, 'Toyota', 'Camry', 2023, 250.00, 0)

SELECT * FROM Student_2.ufn_GetAvailableCars('BMW', 500.00)



-- mTVF (multi-statement table-valued function)
-- Funkcja pozwala na użycie logiki 
-- Funkcja analizuje punkty lojalnościowe klienta i zwraca tabelę wyników

CREATE TABLE Student_2.Customers (
    CustomerID INT PRIMARY KEY,
    FullName NVARCHAR(100),
    Points INT,
    IsVIP BIT
)

INSERT INTO Student_2.Customers (CustomerID, FullName, Points, IsVIP)
VALUES 
(1, 'Jan Kowalski', 150, 1),
(2, 'Anna Nowak', 50, 0),    
(3, 'Piotr Brak', -10, 0)

DROP FUNCTION IF EXISTS Student_2.ufn_GetCustomerStatus
GO

CREATE FUNCTION Student_2.ufn_GetCustomerStatus (
    @CustomerID INT
)
RETURNS @StatusTable TABLE (
    CustomerID INT,
    StatusName NVARCHAR(20),
    CanRent BIT
)
AS
BEGIN
    DECLARE @Points INT

    SELECT @Points = Points 
    FROM Student_2.Customers 
    WHERE CustomerID = @CustomerID

    IF @Points >= 100 -- VIP
    BEGIN
        INSERT INTO @StatusTable (CustomerID, StatusName, CanRent)
        VALUES (@CustomerID, 'VIP', 1)
    END
    ELSE IF @Points < 0 -- Ujemne punkty
    BEGIN
        INSERT INTO @StatusTable (CustomerID, StatusName, CanRent)
        VALUES (@CustomerID, 'Zablokowany', 0)
    END
    ELSE -- Pozostałe przypadki
    BEGIN
        INSERT INTO @StatusTable (CustomerID, StatusName, CanRent)
        VALUES (@CustomerID, 'Standard', 1)
    END
    RETURN
END
GO

SELECT * FROM Student_2.ufn_GetCustomerStatus(1)
SELECT * FROM Student_2.ufn_GetCustomerStatus(2)
SELECT * FROM Student_2.ufn_GetCustomerStatus(3)

-- WIDOK
-- Widok, który dostarcza pracownikom wypożyczalni aktualne dane na temat aktualnie wypożyczonych samochodów np. dane auta oraz klienta


CREATE TABLE Student_2.Rentals (
    RentalID INT PRIMARY KEY,
    CarID INT,
    CustomerID INT,
    RentDate DATE,
    ReturnDate DATE 
)

INSERT INTO Student_2.Rentals (RentalID, CarID, CustomerID, RentDate, ReturnDate) 
VALUES 
(1, 1, 1, '2025-05-01', NULL),         
(2, 2, 2, '2025-05-02', '2025-05-04') 

GO


DROP VIEW IF EXISTS Student_2.v_CurrentlyRentedCars
GO

CREATE VIEW Student_2.v_CurrentlyRentedCars
AS
SELECT 
    r.RentalID,
    c.Model,
    cu.FullName AS CustomerName,
    r.RentDate
FROM Student_2.Rentals r JOIN Student_2.Cars c ON r.CarID = c.CarID
JOIN Student_2.Customers cu ON r.CustomerID = cu.CustomerID
WHERE r.ReturnDate IS NULL
GO

SELECT * FROM Student_2.v_CurrentlyRentedCars


-- FUNKCJA SKALARNA
-- Stworzenie logiki obliczania należności za każdy dzień opóźnienia w zwrocie pojadu do wypożyczalni

DROP FUNCTION IF EXISTS Student_2.ufn_CalculateLateFee
GO

CREATE FUNCTION Student_2.ufn_CalculateLateFee (
    @ExpectedReturnDate DATE,
    @ActualReturnDate DATE
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Fee DECIMAL(10,2) = 0.00
    DECLARE @DaysLate INT = DATEDIFF(DAY, @ExpectedReturnDate, ISNULL(@ActualReturnDate, GETDATE()))
    
    IF @DaysLate > 0
        SET @Fee = @DaysLate * 700.00

    RETURN @Fee
END
GO

SELECT Student_2.ufn_CalculateLateFee('2026-05-01', '2026-05-03') AS LateFee_Delayed -- 2 dni opóźnienia




-- =============================================
-- Zadanie 7
-- =============================================

DROP FUNCTION IF EXISTS dbo.fn_GetCustomerCreditRisk
GO

CREATE FUNCTION dbo.fn_GetCustomerCreditRisk (@CustomerID INT)
RETURNS VARCHAR(6)
AS
BEGIN
    DECLARE @Orders TABLE (
        TotalDue DECIMAL(18,2), 
        DaysLate INT
    )

    INSERT INTO @Orders (TotalDue, DaysLate)
    SELECT 
        TotalDue, 
        DATEDIFF(DAY, DueDate, ShipDate)
    FROM SalesLT.SalesOrderHeader
    WHERE CustomerID = @CustomerID

    DECLARE @TotalSum DECIMAL(18,2) = (SELECT SUM(TotalDue) FROM @Orders)
    DECLARE @LateCount INT = (SELECT COUNT(*) FROM @Orders WHERE DaysLate > 3)

    IF @TotalSum > 100000 AND @LateCount >= 2
        RETURN 'HIGH'
        
    IF @TotalSum > 50000
        RETURN 'MEDIUM'

    RETURN 'LOW'
END
GO

-- =============================================
-- Zadanie 8
-- =============================================

DROP FUNCTION IF EXISTS Student_2.ufn_FormatCustomerData
GO

CREATE FUNCTION Student_2.ufn_FormatCustomerData (
    @FirstName NVARCHAR(50), 
    @LastName NVARCHAR(50), 
    @CompanyName NVARCHAR(128)
)
RETURNS NVARCHAR(300)
AS
BEGIN
    RETURN @FirstName + ' ' + @LastName + ' (Company: ' + ISNULL(@CompanyName, 'N/A') + ')'
END
GO

DROP VIEW IF EXISTS Student_2.v_CustomerFormatView
GO

CREATE VIEW Student_2.v_CustomerFormatView
AS
SELECT 
    CustomerID,
    Student_2.ufn_FormatCustomerData(FirstName, LastName, CompanyName) AS CustomerDetails
FROM SalesLT.Customer;
GO

SELECT * FROM Student_2.v_CustomerListWithFormat


-- =============================================
-- Zadanie 9
-- =============================================

DROP VIEW IF EXISTS Student_2.v_RecentCustomerOrders;
GO

CREATE VIEW Student_2.v_RecentCustomerOrders AS 
SELECT 
    c.CustomerID,
    c.FirstName,
    c.LastName,
    soh.SalesOrderID
FROM SalesLT.Customer c JOIN SalesLT.SalesOrderHeader soh on c.CustomerID = soh.CustomerID
WHERE soh.OrderDate >= DATEADD(DAY, -365, GETDATE())
GO

DECLARE @MinOrders INT = 3

SELECT 
    CustomerID,
    FirstName,
    LastName,
    COUNT(SalesOrderID) as OrderCount
FROM Student_2.v_RecentCustomerOrders
GROUP BY CustomerID, FirstName, LastName
HAVING COUNT(SalesOrderID) > @MinOrders
GO

-- =============================================
-- Bartosz
-- Kozioł
-- 237382
-- =============================================

-- =============================================
-- Zadanie 1
-- =============================================


--select * from SalesLT.Customer


DROP PROCEDURE IF EXISTS dbo.usp_InsertCustomer;
GO

CREATE PROCEDURE dbo.usp_InsertCustomer
	@FirstName NVARCHAR(50),
	@LastName dbo.B2_surname,
	@EmailAddress NVARCHAR(50) = NULL,
	@CompanyName NVARCHAR(100) = NULL
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON

	BEGIN TRY
		BEGIN TRAN

		INSERT INTO SalesLT.Customer(
			NameStyle,
			FirstName,
			LastName,
			CompanyName,
			EmailAddress, 
            PasswordHash, 
            PasswordSalt,
            rowguid,
            ModifiedDate
			)
			VALUES (
			0, 
            @FirstName, 
            @LastName, 
            @CompanyName, 
            @EmailAddress, 
            '3F5AE95E-B87b-4AEX-95B4-D3797AFCB74F', 
            '1KjXYs5=',                                    
            NEWID(),                                        
            GETDATE()                                       
        )
		COMMIT TRAN
	END TRY

	BEGIN CATCH 
		IF XACT_STATE() <> 0
			ROLLBACK TRAN;
		THROW;
	END CATCH;
END;
GO


-- =============================================
-- Zadanie 2
-- =============================================	

DROP PROCEDURE IF EXISTS dbo.usp_SearchCustomer;
GO

CREATE PROCEDURE dbo.usp_SearchCustomer
	@CustomerID INT = NULL,
	@FirstName NVARCHAR(50) = NULL,
	@LastName dbo.B2_surname = NULL,
	@EmailAddress NVARCHAR(100) = NULL
AS
BEGIN 
	SET NOCOUNT ON;

	SELECT 
		CustomerID,
		FirstName,
		LastName,
		EmailAddress,
		CompanyName,
		Phone
	FROM SalesLT.Customer 
	WHERE (@CustomerID IS NULL OR CustomerID = @CustomerID)
	AND (@FirstName IS NULL OR FirstName = @FirstName)
	AND (@LastName IS NULL OR LastName = @LastName)
	AND (@EmailAddress IS NULL OR EmailAddress = @EmailAddress)
END;
GO


select * from SalesLT.Customer

exec dbo.usp_SearchCustomer
	@FirstName = 'John'


-- =============================================
-- Zadanie 3
-- =============================================

DROP TYPE IF EXISTS dbo.OrderHistoryType;
GO

CREATE TYPE dbo.OrderHistoryType AS TABLE (
    Product NVARCHAR(50),
    OrderDate DATETIME,
    Quantity INT,
    TotalPrice DECIMAL(18,2)
);
GO

CREATE PROCEDURE dbo.usp_GetCustomerOrderHistory
	@CustomerID INT,
    @TableResult dbo.OrderHistoryType OUTPUT
AS 
BEGIN
	SET NOCOUNT ON;
END;
GO
-- Msg 352, Level 15, State 1, Procedure usp_GetCustomerOrderHistory, Line 114
-- The table-valued parameter "@TableResult" must be declared with the READONLY option.
-- Zmienna tabelaryczna może być przyjęta tylko jako READONLY, nie jako OUTPUT


-- =============================================
-- Zadanie 4
-- =============================================

DROP FUNCTION IF EXISTS dbo.fn_CheckIfUserExists;
GO

CREATE FUNCTION dbo.fn_CheckIfUserExists(
    @FirstName NVARCHAR(50),
    @LastName dbo.B2_surname,
	@EmailAddress NVARCHAR(50)
)
RETURNS BIT
AS 
BEGIN
	DECLARE @Exists BIT = 0;

	IF EXISTS (SELECT 1 FROM SalesLT.Customer 
	WHERE EmailAddress = @EmailAddress AND @EmailAddress IS NOT NULL
	OR (FirstName = @FirstName AND LastName = @LastName AND EmailAddress = @EmailAddress))

		SET @EXISTS = 1;
	RETURN @EXISTS;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_InsertCustomer
	@FirstName NVARCHAR(50),
	@LastName dbo.B2_surname,
	@EmailAddress NVARCHAR(50) = NULL,
	@CompanyName NVARCHAR(100) = NULL
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON

	IF dbo.fn_CheckIfUserExists(@FirstName, @LastName, @EmailAddress) = 1
	BEGIN
		PRINT 'Ten klient już istnieje w bazie';
		RETURN;
	END

	BEGIN TRY
		BEGIN TRAN

		INSERT INTO SalesLT.Customer(
			NameStyle,
			FirstName,
			LastName,
			CompanyName,
			EmailAddress, 
            PasswordHash, 
            PasswordSalt,
            rowguid,
            ModifiedDate
			)
			VALUES (
			0, 
            @FirstName, 
            @LastName, 
            @CompanyName, 
            @EmailAddress, 
            '3F5AE95E-B87b-4AEX-95B4-D3797AFCB74F', 
            '1KjXYs5=',                                    
            NEWID(),                                        
            GETDATE()                                       
        )
		COMMIT TRAN
	END TRY

	BEGIN CATCH 
		IF XACT_STATE() <> 0
			ROLLBACK TRAN;
		THROW;
	END CATCH;
END;
GO


EXEC dbo.usp_InsertCustomer 
    @FirstName = 'Jan', 
    @LastName = 'Kowalski', 
    @EmailAddress = 'jan.kowalski@mail.pl', 
    @CompanyName = 'Janex'
GO

-- =============================================
-- Zadanie 5
-- =============================================

 CREATE OR ALTER PROCEDURE dbo.usp_UpdateCustomer
	@CustomerID INT,
	@FirstName NVARCHAR(50),
	@LastName NVARCHAR(50)
AS 
BEGIN 
	SET NOCOUNT ON;

	IF EXISTS (SELECT 1 FROM SalesLT.Customer WHERE CustomerID = @CustomerID)
	BEGIN
		UPDATE SalesLT.Customer
		SET FirstName = @FirstName,
		LastName = @LastName,
		ModifiedDate = GETDATE()
		WHERE CustomerID = @CustomerID;
	END
	ELSE
	BEGIN
		RAISERROR ('Something went wrong', 16, 1);
	END
END;
GO


-- =============================================
-- Zadanie 6
-- =============================================

CREATE TABLE dbo.ProductInventory (
	ProductID INT,
	Amount INT
);
GO

CREATE OR ALTER PROCEDURE dbo.AddNewProduct
	@ProductName nvarchar(50),
	@ProductNumber nvarchar(25),
	@Category nvarchar(50),
	@StandardCost money,
	@ListPrice money,
	@Amount int
AS
BEGIN 
	IF @ListPrice <= 0 OR @Amount < 0
	BEGIN
		PRINT 'Cena musi być większa od 0 lub ilość w magazynie nie musi być większa od 0'
		RETURN 
	END

BEGIN TRY
    BEGIN TRAN;
	DECLARE @CategoryID INT
	SELECT @CategoryID = ProductCategoryID From SalesLT.ProductCategory WHERE [Name]=@Category

	INSERT INTO SalesLT.Product (ProductCategoryID, Name, ProductNumber, StandardCost, ListPrice, SellStartDate, rowguid, ModifiedDate)
	VALUES (@CategoryID, @ProductName, @ProductNumber, @StandardCost, @ListPrice, GETDATE(), NEWID(), GETDATE())

	DECLARE @ProductID INT 
	SET @ProductID = @@IDENTITY

	INSERT INTO dbo.ProductInventory (ProductID, Amount)
    VALUES (@ProductID, @Amount);

    COMMIT TRAN;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRAN;

    SELECT ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
END;
GO



-- =============================================
-- Zadanie 7
-- =============================================

-- Msg 352, Level 15, State 1
-- The table-valued parameter "@Summary" must be declared with the READONLY option.
-- The table-valued parameter nie może być użyty w przypadku OUTPUT, może służyc do wprowadzania danych
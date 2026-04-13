-- =============================================
-- Bartosz
-- Kozioł
-- 237382
-- =============================================


-- =============================================
-- Zadanie 1
-- =============================================

BEGIN TRAN;

UPDATE SalesLT.Product
SET ListPrice = ListPrice + 5
WHERE ProductID = 680;

WAITFOR DELAY '00:00:30';

UPDATE SalesLT.SalesOrderDetail
SET UnitPrice = UnitPrice + 1
WHERE ProductID = 680;

COMMIT;



BEGIN TRAN;

UPDATE SalesLT.SalesOrderDetail
SET UnitPrice = UnitPrice + 1
WHERE ProductID = 680;

WAITFOR DELAY '00:00:30';

UPDATE SalesLT.Product
SET ListPrice = ListPrice + 5
WHERE ProductID = 680;

COMMIT;
GO

-- Deadlock (Zakleszczenie): Kod wymusza sytuację, w której dwie transakcje blokują się nawzajem. Praca innych zostaje przez to wstrzymana. SQL Server musi "usunąć" jedną z transakcji, aby odblokować bazę. 

-- =============================================
-- Zadanie 2
-- =============================================

BEGIN TRAN
-- SELECT * from SalesLT.Product
UPDATE SalesLT.Product SET ListPrice = ListPrice * 1.1


INSERT INTO SalesLT.Customer (FirstName, LastName, PasswordHash, PasswordSalt, CompanyName)
    VALUES 
    ('Test1', 'User1', 'hash', 'salt', 'Firma'), 
    ('Test2', 'User2', 'hash', 'salt', 'Firma'),
    ('Test3', 'User3', 'hash', 'salt', 'Firma'), 
    ('Test4', 'User4', 'hash', 'salt', 'Firma'),
    ('Test5', 'User5', 'hash', 'salt', 'Firma'), 
    ('Test6', 'User6', 'hash', 'salt', 'Firma'),
    ('Test7', 'User7', 'hash', 'salt', 'Firma'), 
    ('Test8', 'User8', 'hash', 'salt', 'Firma'),
    ('Test9', 'User9', 'hash', 'salt', 'Firma'), 
    ('Test10', 'User10', 'hash', 'salt', 'Firma')

UPDATE TOP (10) SalesLT.ProductModel SET ModifiedDate = GETDATE()

TRUNCATE TABLE SalesLT.SalesOrderDetail

SELECT 'W trakcie' AS Status_Transakcji, COUNT(*) AS LICZBA_PRODUKTOW FROM SalesLT.Product
SELECT 'W trakcie' AS Status_Transakcji, COUNT(*) AS LICZBA_KLIENTOW FROM SalesLT.Customer
SELECT 'W trakcie' AS Status_Transakcji, COUNT(*) AS LICZBA_ZAMOWIEN FROM SalesLT.SalesOrderDetail

WAITFOR DELAY '00:05:00'

ROLLBACK TRAN

SELECT 'Po ROLLBACK' AS Status_Transakcji, COUNT(*) AS LICZBA_PRODUKTOW FROM SalesLT.Product
SELECT 'Po ROLLBACK' AS Status_Transakcji, COUNT(*) AS LICZBA_KLIENTOW FROM SalesLT.Customer
SELECT 'Po ROLLBACK' AS Status_Transakcji, COUNT(*) AS LICZBA_ZAMOWIEN FROM SalesLT.SalesOrderDetail
GO

-- Pierwsze selecty pokazują, że zmiany zostały uwzglęnione przez bazę danych - zmiana cen, zmiana liczby klientów oraz usunięcie zamówień
-- Rollback wszystko anuluje 
-- Drugie selecty pokazują, że zmiany zostały cofnięte do poprzedniego stanu 


-- Transakcja to dla bazy danych takie tymczasowe zadanie - rollback anuluje całą transakcję 



-- =============================================
-- Zadanie 3
-- =============================================

-- Dodany WAITFOR DELAY NA 5 MINUT oraz
-- W nowym query uruchamiamy Selecta 
SELECT COUNT(*) AS LICZBA_KLIENTOW FROM SalesLT.Customer WITH (NOLOCK)

-- W zadaniu 2 transakcja blokuje tabele i zamraża proces na 5 minut (WAITFOR DELAY). Zwykły select zawiesiłby się, czekając na jej zakończenie. 
-- WITH (NOLOCK) sprawia, że SQL Server ignoruje blokady i pozwala na natychmiastowy odczyt. Dzięki temu widzimy zmodyfikowaną liczbę klientów, chociaż transakcja wciąż trwa.



-- =============================================
-- Zadanie 4
-- =============================================

BEGIN TRY 
SELECT TOP 1 ListPrice / 0 FROM SalesLT.Product
END TRY

BEGIN CATCH
    SELECT ERROR_NUMBER() AS NUMBER_BLEDU
    SELECT ERROR_MESSAGE() AS TRESC_BLEDU
END CATCH
GO

-- =============================================
-- Zadanie 5 i 6 
-- =============================================

-- Opis logiki biznesowej: Dodawanie produktu do bazy z weryfikajcą opłacalności
-- Błędy: 
   -- Biznesowy: Gdy koszt produktu przewyższa cenę jego sprzedaży  -- Odpowiada za to IF THROW
   -- Bazy danych: Brak kategorii w kluczu obcym lub duplikat  -- Odpowiada za to blok TRY CATCH
DECLARE @Cena MONEY = 100
DECLARE @Koszt MONEY = 150 -- koszt wyższy od ceny
DECLARE @Kategoria int = 0 -- zmyślona kategoria, aby wywołać błąd jeśli cena byłaby zgodna

BEGIN TRY
    
    BEGIN TRAN

    IF @Koszt >= @Cena
    BEGIN
        THROW 50001, 'Błąd - Wprowadzony koszt jest większy niż cena produktu', 1;
    END

    INSERT INTO SalesLT.Product (Name, ProductNumber, StandardCost, ListPrice, ProductCategoryID) 
    VALUES ('NOWY-PRODUKT', 'NEW-PROD-123', @Koszt, @Cena, @Kategoria)

    COMMIT TRAN

END TRY

BEGIN CATCH
    IF @@TRANCOUNT>0
    BEGIN
        ROLLBACK TRAN
    END
    
    SELECT ERROR_NUMBER() AS KOD_BLEDU, 
           ERROR_MESSAGE() AS TRESC_BLEDU
END CATCH;
GO
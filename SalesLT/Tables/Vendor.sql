CREATE TABLE [SalesLT].[Vendor] (
    [VendorID]      INT            IDENTITY (1, 1) NOT NULL,
    [Name]          NVARCHAR (100) NOT NULL,
    [AccountNumber] NVARCHAR (20)  NOT NULL,
    [CreditRating]  TINYINT        NOT NULL,
    [ActiveFlag]    BIT            DEFAULT ((1)) NULL,
    PRIMARY KEY CLUSTERED ([VendorID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Vendor_ActiveFlag_Include_Name_AccountNumber]
    ON [SalesLT].[Vendor]([ActiveFlag] ASC)
    INCLUDE([Name], [AccountNumber]);


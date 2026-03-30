CREATE TABLE [SalesLT].[VendorPriceHistory] (
    [QuoteID]   BIGINT   NULL,
    [VendorID]  INT      NOT NULL,
    [ProductID] INT      NOT NULL,
    [Price]     MONEY    NOT NULL,
    [QuoteDate] DATETIME NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_VendorPriceHistory_VendorID_ProductID]
    ON [SalesLT].[VendorPriceHistory]([VendorID] ASC, [ProductID] ASC);


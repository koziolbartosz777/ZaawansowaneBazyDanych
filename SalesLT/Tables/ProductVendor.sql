CREATE TABLE [SalesLT].[ProductVendor] (
    [ProductID]       INT   NOT NULL,
    [VendorID]        INT   NOT NULL,
    [StandardPrice]   MONEY NOT NULL,
    [AverageLeadTime] INT   NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_ProductVendor_ProductID]
    ON [SalesLT].[ProductVendor]([ProductID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_ProductVendor_VendorID]
    ON [SalesLT].[ProductVendor]([VendorID] ASC);


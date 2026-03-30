CREATE TABLE [dbo].[ContactMessages] (
    [ID]          INT            NOT NULL,
    [SenderName]  NVARCHAR (100) NULL,
    [SenderEmail] NVARCHAR (100) NULL,
    [Subject]     NVARCHAR (200) NULL,
    [MessageBody] NVARCHAR (MAX) NULL,
    [ReceivedAt]  DATETIME       NULL
);


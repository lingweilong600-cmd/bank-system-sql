CREATE DATABASE BankSystem;
GO

USE BankSystem;
GO
/*客户表*/
CREATE TABLE Customer
(
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerName NVARCHAR(50) NOT NULL,
    IDCard CHAR(18) NOT NULL UNIQUE,
    Phone VARCHAR(20) NOT NULL UNIQUE,
    Address NVARCHAR(200),
    CreateTime DATETIME DEFAULT GETDATE()
);
GO
/*支行表*/
CREATE TABLE Branch
(
    BranchID INT IDENTITY(1,1) PRIMARY KEY,
    BranchName NVARCHAR(100) NOT NULL,
    Address NVARCHAR(200),
    Phone VARCHAR(20)
);
GO
/*银行账户表*/
CREATE TABLE Account
(
    AccountID INT IDENTITY(1,1) PRIMARY KEY,
    AccountNo VARCHAR(20) NOT NULL UNIQUE,
    CustomerID INT NOT NULL,
    BranchID INT NOT NULL,

    AccountType VARCHAR(20) NOT NULL
        CHECK (AccountType IN ('储蓄账户', '活期账户')),

    Balance DECIMAL(18,2) NOT NULL DEFAULT 0
        CHECK (Balance >= 0),

    Status VARCHAR(20) NOT NULL DEFAULT '正常'
        CHECK (Status IN ('正常', '冻结', '注销')),

    OpenTime DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_Account_Customer
        FOREIGN KEY (CustomerID)
        REFERENCES Customer(CustomerID),

    CONSTRAINT FK_Account_Branch
        FOREIGN KEY (BranchID)
        REFERENCES Branch(BranchID)
);
GO
/*交易表*/
USE BankSystem;
GO
CREATE TABLE BankTransaction
(
    TransactionID BIGINT IDENTITY(1,1) PRIMARY KEY,

    AccountID INT NOT NULL,

    TransactionType VARCHAR(20) NOT NULL
        CHECK (TransactionType IN ('存款', '取款', '转入', '转出')),

    Amount DECIMAL(18,2) NOT NULL
        CHECK (Amount > 0),

    RelatedAccountID INT NULL,

    TransactionTime DATETIME DEFAULT GETDATE(),

    Remark NVARCHAR(200),

    CONSTRAINT FK_Transaction_Account
        FOREIGN KEY (AccountID)
        REFERENCES Account(AccountID),

    CONSTRAINT FK_Transaction_RelatedAccount
        FOREIGN KEY (RelatedAccountID)
        REFERENCES Account(AccountID)
);
GO
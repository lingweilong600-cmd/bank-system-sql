/*=======================================================================*/
/*存款功能*/
CREATE or ALTER PROCEDURE DepositMoney

    @AccountNo VARCHAR(20),
    @Amount DECIMAL(18,2)
AS
BEGIN
    SET XACT_ABORT ON
    SET NOCOUNT ON;

    IF @Amount <= 0
    BEGIN
        RAISERROR(N'存款金额必须大于0', 16, 1);
        RETURN;
    END;

    BEGIN TRANSACTION;

    BEGIN TRY

        UPDATE Account
        SET Balance = Balance + @Amount
        WHERE AccountNo = @AccountNo
          AND Status = '正常';

        IF @@ROWCOUNT = 0
        BEGIN
            RAISERROR(N'账户不存在或账户状态异常', 16, 1);
        END;

        DECLARE @AccountID INT;

        SELECT @AccountID = AccountID
        FROM Account
        WHERE AccountNo = @AccountNo;

        INSERT INTO BankTransaction
        (
            AccountID,
            TransactionType,
            Amount,
            Remark
        )
        VALUES
        (
            @AccountID,
            '存款',
            @Amount,
            N'银行柜台存款'
        );

        COMMIT TRANSACTION;

        PRINT N'存款成功';

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        THROW;

    END CATCH
END;
GO
/*=======================================================================*/
/*取款功能*/
CREATE or ALTER PROCEDURE WithdrawMoney
    @AccountNo VARCHAR(20),
    @Amount DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON
    IF @Amount <= 0
    BEGIN
        RAISERROR(N'取款金额必须大于0', 16, 1);
        RETURN;
    END;

    BEGIN TRANSACTION;

    BEGIN TRY

        DECLARE @AccountID INT;
        DECLARE @Balance DECIMAL(18,2);

        SELECT
            @AccountID = AccountID,
            @Balance = Balance
        FROM Account
        WHERE AccountNo = @AccountNo
          AND Status = '正常';

        IF @AccountID IS NULL
        BEGIN
            RAISERROR(N'账户不存在或账户被冻结', 16, 1);
        END;

        IF @Balance < @Amount
        BEGIN
            RAISERROR(N'余额不足', 16, 1);
        END;

        UPDATE Account
        SET Balance = Balance - @Amount
        WHERE AccountID = @AccountID;

        INSERT INTO BankTransaction
        (
            AccountID,
            TransactionType,
            Amount,
            Remark
        )
        VALUES
        (
            @AccountID,
            '取款',
            @Amount,
            N'银行取款'
        );

        COMMIT TRANSACTION;

        PRINT N'取款成功';

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        THROW;

    END CATCH
END;
GO
/*=======================================================================*/
/*转账功能*/
CREATE or ALTER PROCEDURE TransferMoney
    @FromAccountNo VARCHAR(20),
    @ToAccountNo VARCHAR(20),
    @Amount DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON
    IF @Amount <= 0
    BEGIN
        RAISERROR(N'转账金额必须大于0', 16, 1);
        RETURN;
    END;

    IF @FromAccountNo = @ToAccountNo
    BEGIN
        RAISERROR(N'转出账户和转入账户不能相同', 16, 1);
        RETURN;
    END;

    BEGIN TRANSACTION;

    BEGIN TRY

        DECLARE @FromID INT;
        DECLARE @ToID INT;
        DECLARE @FromBalance DECIMAL(18,2);

        SELECT
            @FromID = AccountID,
            @FromBalance = Balance
        FROM Account
        WHERE AccountNo = @FromAccountNo
          AND Status = '正常';

        SELECT
            @ToID = AccountID
        FROM Account
        WHERE AccountNo = @ToAccountNo
          AND Status = '正常';

        IF @FromID IS NULL
        BEGIN
            RAISERROR(N'转出账户不存在或被冻结', 16, 1);
        END;

        IF @ToID IS NULL
        BEGIN
            RAISERROR(N'转入账户不存在或被冻结', 16, 1);
        END;

        IF @FromBalance < @Amount
        BEGIN
            RAISERROR(N'余额不足，无法转账', 16, 1);
        END;

        -- 转出账户扣钱
        UPDATE Account
        SET Balance = Balance - @Amount
        WHERE AccountID = @FromID;

        -- 转入账户加钱
        UPDATE Account
        SET Balance = Balance + @Amount
        WHERE AccountID = @ToID;

        -- 记录转出
        INSERT INTO BankTransaction
        (
            AccountID,
            TransactionType,
            Amount,
            RelatedAccountID,
            Remark
        )
        VALUES
        (
            @FromID,
            '转出',
            @Amount,
            @ToID,
            N'银行转账'
        );

        -- 记录转入
        INSERT INTO BankTransaction
        (
            AccountID,
            TransactionType,
            Amount,
            RelatedAccountID,
            Remark
        )
        VALUES
        (
            @ToID,
            '转入',
            @Amount,
            @FromID,
            N'银行转账'
        );

        COMMIT TRANSACTION;

        PRINT N'转账成功';

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        THROW;

    END CATCH
END;
GO
/*=======================================================================*/
/*开户*/
USE BankSystem;
GO

CREATE or ALTER PROCEDURE OpenAccount
    @AccountNo VARCHAR(20),
    @CustomerID INT,
    @BranchID INT,
    @AccountType VARCHAR(20),
    @InitialBalance DECIMAL(18,2) = 0
AS
BEGIN
    SET XACT_ABORT ON
    SET NOCOUNT ON;

    BEGIN TRANSACTION;

    BEGIN TRY

        -- ① 检查客户是否存在
        IF NOT EXISTS
        (
            SELECT 1
            FROM Customer
            WHERE CustomerID = @CustomerID
        )
        BEGIN
            RAISERROR(N'客户不存在', 16, 1);
        END;

        -- ② 检查支行是否存在
        IF NOT EXISTS
        (
            SELECT 1
            FROM Branch
            WHERE BranchID = @BranchID
        )
        BEGIN
            RAISERROR(N'支行不存在', 16, 1);
        END;

        -- ③ 检查账号是否已经存在
        IF EXISTS
        (
            SELECT 1
            FROM Account
            WHERE AccountNo = @AccountNo
        )
        BEGIN
            RAISERROR(N'该账号已经存在', 16, 1);
        END;

        -- ④ 检查账户类型
        IF @AccountType NOT IN ('储蓄账户', '活期账户')
        BEGIN
            RAISERROR(N'账户类型不正确', 16, 1);
        END;

        -- ⑤ 检查初始余额
        IF @InitialBalance < 0
        BEGIN
            RAISERROR(N'初始余额不能小于0', 16, 1);
        END;

        -- ⑥ 创建账户
        INSERT INTO Account
        (
            AccountNo,
            CustomerID,
            BranchID,
            AccountType,
            Balance,
            Status
        )
        VALUES
        (
            @AccountNo,
            @CustomerID,
            @BranchID,
            @AccountType,
            @InitialBalance,
            '正常'
        );

        COMMIT TRANSACTION;

        PRINT N'开户成功';

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        THROW;

    END CATCH
END;
GO
/*=======================================================================*/
/*销户*/
CREATE or ALTER PROCEDURE CloseAccount
    @AccountNo VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON
    BEGIN TRANSACTION;

    BEGIN TRY

        DECLARE @AccountID INT;
        DECLARE @Balance DECIMAL(18,2);
        DECLARE @Status VARCHAR(20);

        -- ① 查询账户
        SELECT
            @AccountID = AccountID,
            @Balance = Balance,
            @Status = Status
        FROM Account
        WHERE AccountNo = @AccountNo;

        -- ② 检查账户是否存在
        IF @AccountID IS NULL
        BEGIN
            RAISERROR(N'账户不存在', 16, 1);
        END;

        -- ③ 检查账户是否已经注销
        IF @Status = '注销'
        BEGIN
            RAISERROR(N'账户已经注销', 16, 1);
        END;

        -- ④ 检查余额
        IF @Balance > 0
        BEGIN
            RAISERROR(N'账户余额不为0，不能销户', 16, 1);
        END;

        -- ⑤ 修改账户状态
        UPDATE Account
        SET Status = '注销'
        WHERE AccountID = @AccountID;

        COMMIT TRANSACTION;

        PRINT N'销户成功';

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        THROW;

    END CATCH
END;
GO
/*=======================================================================*/
/*冻结账户*/
USE BankSystem;
GO

CREATE or ALTER PROCEDURE FreezeAccount
    @AccountNo VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON
    BEGIN TRANSACTION;

    BEGIN TRY

        DECLARE @Status VARCHAR(20);

        -- ① 查询账户当前状态
        SELECT @Status = Status
        FROM Account
        WHERE AccountNo = @AccountNo;

        -- ② 检查账户是否存在
        IF @Status IS NULL
        BEGIN
            RAISERROR(N'账户不存在', 16, 1);
        END;

        -- ③ 检查账户是否已经注销
        IF @Status = '注销'
        BEGIN
            RAISERROR(N'账户已经注销，不能冻结', 16, 1);
        END;

        -- ④ 检查是否已经冻结
        IF @Status = '冻结'
        BEGIN
            RAISERROR(N'账户已经处于冻结状态', 16, 1);
        END;

        -- ⑤ 冻结账户
        UPDATE Account
        SET Status = '冻结'
        WHERE AccountNo = @AccountNo;

        COMMIT TRANSACTION;

        PRINT N'账户冻结成功';

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        THROW;

    END CATCH
END;
GO
/*=======================================================================*/
/*解冻账户*/
CREATE or ALTER PROCEDURE UnfreezeAccount
    @AccountNo VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON
    BEGIN TRANSACTION;

    BEGIN TRY

        DECLARE @Status VARCHAR(20);

        -- ① 查询账户状态
        SELECT @Status = Status
        FROM Account
        WHERE AccountNo = @AccountNo;

        -- ② 检查账户是否存在
        IF @Status IS NULL
        BEGIN
            RAISERROR(N'账户不存在', 16, 1);
        END;

        -- ③ 注销账户不能解冻
        IF @Status = '注销'
        BEGIN
            RAISERROR(N'账户已经注销，不能解冻', 16, 1);
        END;

        -- ④ 已经是正常状态
        IF @Status = '正常'
        BEGIN
            RAISERROR(N'账户当前已经是正常状态', 16, 1);
        END;

        -- ⑤ 解冻账户
        UPDATE Account
        SET Status = '正常'
        WHERE AccountNo = @AccountNo;

        COMMIT TRANSACTION;

        PRINT N'账户解冻成功';

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;    

        THROW;

    END CATCH
END;
GO
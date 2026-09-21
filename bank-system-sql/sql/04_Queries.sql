use BankSystem
select * from Customer
select * from Branch
select * from Account
select * from BankTransaction


/*按时间查询交易表*/
SELECT
    a.AccountNo,
    c.CustomerName,
    b.BranchName,
    t.TransactionType,
    t.Amount,
    t.TransactionTime,
    t.Remark
FROM BankTransaction t
JOIN Account a
    ON t.AccountID = a.AccountID
JOIN Customer c
    ON a.CustomerID = c.CustomerID
JOIN Branch b
    ON a.BranchID = b.BranchID
ORDER BY t.TransactionTime DESC;

go
/*查询某人的银行流水*/
create or alter view vw_AccountStatement as
with T as(
select A.AccountNo 本方卡号,C.CustomerName 姓名,left(C.IDCard, 6) + '********' + right(C.IDCard, 4) 证件号,
       left(C.Phone, 3) + '****' + right(C.Phone, 4) 电话/*对敏感信息处理*/
       ,C.Address 地址,B.TransactionType 交易类型,B.Amount 金额,B.RelatedAccountID ,B.TransactionTime 交易时间 from Customer C
left join Account A on A.CustomerID = C.CustomerID
left join BankTransaction B on B.AccountID = A.AccountID

)
select 姓名,证件号,电话,本方卡号,地址,交易类型,金额,RA.AccountNo 对方卡号,交易时间 from T
left join Account RA on T.RelatedAccountID = RA.AccountID
go
select * from vw_AccountStatement
where 本方卡号 = '6222000000020007'/*银行卡号*/
order by 交易时间

/*查询某人的银行卡号*/
select C.CustomerName 姓名,A.AccountNo 卡号,C.Address 地址,A.AccountType 账户类型,A.Status 账户状态,A.OpenTime 开户时间 from Customer C
left join Account A on A.CustomerID = C.CustomerID
where C.CustomerName = '吴涛' /*输入姓名*/

/*查询某人的账户余额*/
select C.CustomerName 姓名,A.AccountNo 卡号,A.balance 余额,C.Address 地址,A.AccountType 账户类型,A.Status 账户状态,A.OpenTime 开户时间 from Customer C
left join Account A on A.CustomerID = C.CustomerID
where A.AccountNo = '6222000000020007' /*输入卡号*/

/*员工内部查询数据*/
go
create or alter view vw_AccountStatement_internal as
select C.CustomerName 姓名,
       C.IDCard 证件号,
       C.Phone 电话,
       A.AccountNo 本方卡号,
       C.Address 地址,
       B.TransactionType 交易类型,
       B.Amount 金额,
       RA.AccountNo 对方卡号,
       B.TransactionTime 交易时间
from Customer C
left join Account A on A.CustomerID = C.CustomerID
left join BankTransaction B on B.AccountID = A.AccountID
left join Account RA on B.RelatedAccountID = RA.AccountID;
go
select * from vw_AccountStatement_internal



/*客服权限*/
create user csuser without login;
grant select on vw_AccountStatement to csuser;

execute as user = 'csuser';
select * from vw_AccountStatement;   -- 能查，看到的是脱敏数据
select * from Customer;      -- 报错：没有权限
revert;/*回复权限*/
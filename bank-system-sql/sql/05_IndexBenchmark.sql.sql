-- 复制表结构，不带数据、约束和索引
select * into BankTransaction_Test from BankTransaction where 1 = 0;

-- 造 100 万条模拟流水，账户 ID 分散在 1~100000
;with n as (
    select top (1000000) row_number() over (order by (select null)) rn
    from sys.all_objects a cross join sys.all_objects b
)
insert into BankTransaction_Test (AccountID, TransactionType, Amount, TransactionTime, Remark)
select abs(checksum(newid()) % 100000) + 1,
       case abs(checksum(newid()) % 2) when 0 then '存款' else '取款' end,
       abs(checksum(newid()) % 5000) + 1,
       dateadd(minute, -abs(checksum(newid()) % 525600), getdate()),
       N'压测数据'
from n;

set statistics io on;
set statistics time on;

-- ① 建索引前：执行，记下"逻辑读取"和耗时
select * from BankTransaction_Test where AccountID = 12345 order by TransactionTime;

-- ② 建索引
create index IX_Test_Account_Time on BankTransaction_Test (AccountID, TransactionTime);

-- ③ 建索引后：再执行同一条，记下同样的数字
select * from BankTransaction_Test where AccountID = 12345 order by TransactionTime;
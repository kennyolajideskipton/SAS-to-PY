/*
    Quarterly vintage delinquency matrix.

    Rates returned:
      - OriginalCohort: cumulative arrears events divided by all qualifying
        accounts identified for that completion-quarter cohort.
      - Observed: cumulative arrears events divided by accounts with a snapshot
        at that exact months-on-book checkpoint.

    Cumulative events use monthly snapshots before the quarterly checkpoints
    are selected, so an arrears event that cures before the next checkpoint
    remains captured. Accounts without a later snapshot remain in the original
    cohort denominator and carry forward their last observed cumulative flag.
    Validate that missing snapshots represent account exits rather than data gaps.
*/
;WITH VintageMonthly AS
(
    SELECT
        da.AccountNumber AS PrimaryAccountNumber,
        CONCAT(compdate.CalendarYear, 'Q', compdate.CalendarQuarterNumber) AS CompHYear,
        compdate.CalendarYear AS CompletionYear,
        EOMONTH(compdate.CalendarDate) AS CompletionMonthEnd,
        EOMONTH(dm.BatchDate) AS SnapshotMonthEnd,
        DATEDIFF(MONTH, EOMONTH(compdate.CalendarDate), EOMONTH(dm.BatchDate)) AS TimeOnBook,
        CASE WHEN fmass.ContractualArrearsInMonths >= 1 THEN 1 ELSE 0 END AS MIA_1P,
        CASE WHEN fmass.ContractualArrearsInMonths >= 3 THEN 1 ELSE 0 END AS MIA_3P
    FROM P_DW.dbo.factMortgageAccountMonthSS AS fmass
    INNER JOIN P_DW.dbo.dimAccount AS da
        ON fmass.FK_Account = da.PK_Account
    INNER JOIN P_DW.dbo.dimCompany AS dc
        ON fmass.FK_Company = dc.PK_Company
    INNER JOIN P_DW.dbo.dimmonth AS dm
        ON fmass.FK_SnapshotDate = dm.PK_Month
    INNER JOIN P_DW.dbo.outriggeraccountmortgage AS oam
        ON da.PK_account = oam.PK_account
    INNER JOIN P_DW.dbo.dimproduct AS dp
        ON fmass.FK_currentmortgageproduct = dp.PK_product
    INNER JOIN P_DW.dbo.dimMortgageSecurity AS dms
        ON dms.PK_MortgageSecurity = fmass.FK_MortgageSecurity
    INNER JOIN P_DW.dbo.dimAccountStates AS das
        ON fmass.FK_AccountStates = das.PK_AccountStates
    INNER JOIN P_DW.dbo.dimDate AS compdate
        ON fmass.FK_MortgageCompletionDate = compdate.PK_Date
    INNER JOIN P_DW.dbo.dimSubPopulation AS dsp
        ON fmass.FK_SubPopulation = dsp.PK_SubPopulation
    INNER JOIN P_DW.dbo.dimPurchaseType AS dpt
        ON fmass.FK_PurchaseType = dpt.PK_PurchaseType
        AND LEFT(da.AccountPool, 3) = dpt.PurchaseTypeFunder
    INNER JOIN P_DW.dbo.dimRepaymentType AS drt
        ON fmass.FK_RepaymentType = drt.PK_RepaymentType
    INNER JOIN P_DW.dbo.dimArrangement AS arrng
        ON fmass.FK_ArrangementType = arrng.PK_ArrangementType
    WHERE dc.CompanyName = 'Skipton Building Society'
        AND da.AccountSubType = 'Primary'
        AND dc.poolID = 'SBS00001'
        AND dp.ProductCode NOT IN ('HM120', 'HM121', 'HM122', 'HM123', 'HM124', 'HM125', 'MIN01', 'HOM10')
        AND da.AccountNumber NOT IN (119613605, 119610005, 119613202, 119613801, 119621102, 119612307)
        AND da.CurrentAccountClassification <> 'Pure Commercial'
        AND compdate.CalendarYear > 2021
),
CohortAccounts AS
(
    -- One row per qualifying account and completion cohort.
    SELECT
        PrimaryAccountNumber,
        CompHYear,
        CompletionYear,
        MAX(CompletionMonthEnd) AS CompletionMonthEnd
    FROM VintageMonthly
    GROUP BY
        PrimaryAccountNumber,
        CompHYear,
        CompletionYear
),
CohortSummary AS
(
    SELECT
        CompHYear,
        CompletionYear,
        MAX(CompletionMonthEnd) AS LatestCompletionMonthEnd,
        COUNT_BIG(*) AS CohortAccounts
    FROM CohortAccounts
    GROUP BY
        CompHYear,
        CompletionYear
),
LatestSnapshot AS
(
    SELECT MAX(SnapshotMonthEnd) AS LatestSnapshotMonthEnd
    FROM VintageMonthly
),
Checkpoints AS
(
    SELECT TimeOnBook
    FROM (VALUES (3), (6), (9), (12), (15), (18), (21), (24), (27), (30), (33), (36)) AS v(TimeOnBook)
),
MatureCohortCheckpoints AS
(
    -- Do not show future ages for cohorts that have not reached that age yet.
    SELECT
        cs.CompHYear,
        cs.CompletionYear,
        cp.TimeOnBook,
        cs.CohortAccounts
    FROM CohortSummary AS cs
    CROSS JOIN Checkpoints AS cp
    CROSS JOIN LatestSnapshot AS ls
    WHERE EOMONTH(DATEADD(MONTH, cp.TimeOnBook, cs.LatestCompletionMonthEnd)) <= ls.LatestSnapshotMonthEnd
),
CumulativeMonthly AS
(
    -- Compute the cumulative event across monthly snapshots first.
    SELECT
        vm.PrimaryAccountNumber,
        vm.CompHYear,
        vm.CompletionYear,
        vm.TimeOnBook,
        MAX(vm.MIA_1P) OVER
        (
            PARTITION BY vm.PrimaryAccountNumber, vm.CompHYear
            ORDER BY vm.TimeOnBook
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS MIA1P_Cumulative,
        MAX(vm.MIA_3P) OVER
        (
            PARTITION BY vm.PrimaryAccountNumber, vm.CompHYear
            ORDER BY vm.TimeOnBook
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS MIA3P_Cumulative
    FROM VintageMonthly AS vm
    WHERE vm.TimeOnBook BETWEEN 0 AND 36
),
AccountCheckpoint AS
(
    -- Include every cohort member at every mature checkpoint. A missing
    -- checkpoint snapshot does not remove the account from the fixed cohort.
    SELECT
        mcc.CompHYear,
        mcc.CompletionYear,
        mcc.TimeOnBook,
        ca.PrimaryAccountNumber,
        MAX(CASE WHEN cm.TimeOnBook = mcc.TimeOnBook THEN 1 ELSE 0 END) AS HasCheckpointSnapshot,
        COALESCE(MAX(cm.MIA1P_Cumulative), 0) AS MIA1P_Cumulative,
        COALESCE(MAX(cm.MIA3P_Cumulative), 0) AS MIA3P_Cumulative
    FROM MatureCohortCheckpoints AS mcc
    INNER JOIN CohortAccounts AS ca
        ON ca.CompHYear = mcc.CompHYear
        AND ca.CompletionYear = mcc.CompletionYear
    LEFT JOIN CumulativeMonthly AS cm
        ON cm.PrimaryAccountNumber = ca.PrimaryAccountNumber
        AND cm.CompHYear = ca.CompHYear
        AND cm.CompletionYear = ca.CompletionYear
        AND cm.TimeOnBook <= mcc.TimeOnBook
    GROUP BY
        mcc.CompHYear,
        mcc.CompletionYear,
        mcc.TimeOnBook,
        ca.PrimaryAccountNumber
)
SELECT
    ac.CompHYear,
    ac.CompletionYear,
    ac.TimeOnBook,
    COUNT_BIG(*) AS CohortAccounts,
    SUM(CONVERT(bigint, ac.HasCheckpointSnapshot)) AS ObservedAccounts,
    COUNT_BIG(*) - SUM(CONVERT(bigint, ac.HasCheckpointSnapshot)) AS NotObservedAccounts,
    SUM(CONVERT(bigint, ac.MIA1P_Cumulative)) AS Cumulative1PlusOriginalCount,
    SUM(CONVERT(bigint, ac.MIA3P_Cumulative)) AS Cumulative3PlusOriginalCount,
    SUM(CONVERT(bigint, CASE WHEN ac.HasCheckpointSnapshot = 1 THEN ac.MIA1P_Cumulative ELSE 0 END)) AS Cumulative1PlusObservedCount,
    SUM(CONVERT(bigint, CASE WHEN ac.HasCheckpointSnapshot = 1 THEN ac.MIA3P_Cumulative ELSE 0 END)) AS Cumulative3PlusObservedCount,
    CAST(SUM(CONVERT(bigint, ac.MIA1P_Cumulative)) * 1.0 / NULLIF(COUNT_BIG(*), 0) AS decimal(9, 6)) AS Rate1PlusOriginalCohort,
    CAST(SUM(CONVERT(bigint, ac.MIA3P_Cumulative)) * 1.0 / NULLIF(COUNT_BIG(*), 0) AS decimal(9, 6)) AS Rate3PlusOriginalCohort,
    CAST(SUM(CONVERT(bigint, CASE WHEN ac.HasCheckpointSnapshot = 1 THEN ac.MIA1P_Cumulative ELSE 0 END)) * 1.0
        / NULLIF(SUM(CONVERT(bigint, ac.HasCheckpointSnapshot)), 0) AS decimal(9, 6)) AS Rate1PlusObserved,
    CAST(SUM(CONVERT(bigint, CASE WHEN ac.HasCheckpointSnapshot = 1 THEN ac.MIA3P_Cumulative ELSE 0 END)) * 1.0
        / NULLIF(SUM(CONVERT(bigint, ac.HasCheckpointSnapshot)), 0) AS decimal(9, 6)) AS Rate3PlusObserved
FROM AccountCheckpoint AS ac
GROUP BY
    ac.CompHYear,
    ac.CompletionYear,
    ac.TimeOnBook
ORDER BY
    ac.CompHYear,
    ac.TimeOnBook;




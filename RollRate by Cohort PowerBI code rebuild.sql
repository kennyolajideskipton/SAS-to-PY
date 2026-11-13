-- Rolling ten-year history through the prior calendar month.
-- Assumes the prior month's snapshot has completed loading before refresh.
DECLARE @EndDateExclusive date = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
DECLARE @StartDate date = DATEADD(YEAR, -10, @EndDateExclusive);
-- Last start month with a complete three-month follow-up.
DECLARE @LastCompleteStartMonth date = EOMONTH(DATEADD(MONTH, -4, @EndDateExclusive));

;WITH Accs AS
(
    SELECT
        EOMONTH(dm.BatchDate) AS ReportingMonthEnd,
        dm.CalendarMonthYear AS SnapshotYYYYMM,
        da.AccountNumber AS PrimaryAccountNumber,
        compdate.CalendarYear AS CompletionYear,
        CONCAT(compdate.CalendarYear, 'Q', compdate.CalendarQuarterNumber) AS CompHYear,
        DATEDIFF(MONTH, EOMONTH(compdate.CalendarDate), EOMONTH(dm.BatchDate)) AS TimeOnBook,
        IIF(fmass.ContractualArrearsInMonths >= 1, 1, 0) AS MIA_1P,
        IIF(fmass.ContractualArrearsInMonths >= 3, 1, 0) AS MIA_3P,
        IIF(fmass.ContractualArrearsInMonths > 0, FLOOR(fmass.ContractualArrearsInMonths), 0) AS MonthsinArrears,
        CASE
            WHEN das.AccountStatus = 'Possession' THEN 'Possession'
            WHEN das.AccountStatus IS NULL THEN 'Unknown'
            WHEN das.AccountStatus <> 'Live' THEN 'No longer on Book'
            WHEN fmass.ContractualArrearsInMonths IS NULL THEN 'Unknown'
            WHEN fmass.ContractualArrearsInMonths < 1 THEN 'Current'
            WHEN fmass.ContractualArrearsInMonths < 3 THEN '1-2 MIA'
            WHEN fmass.ContractualArrearsInMonths < 6 THEN '3-5 MIA'
            ELSE '6+ MIA'
        END AS ArrearsStatus
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
        AND dm.BatchDate >= @StartDate
        AND dm.BatchDate < @EndDateExclusive
),
AccsStart AS
(
    SELECT *
    FROM Accs
    WHERE ArrearsStatus IN ('1-2 MIA', '3-5 MIA', '6+ MIA')
        AND ReportingMonthEnd <= @LastCompleteStartMonth
),
RankedTransitions AS
(
    SELECT
        s.ReportingMonthEnd AS StartMonthEnd,
        EOMONTH(DATEADD(MONTH, 3, s.ReportingMonthEnd)) AS EndMonthEnd,
        s.PrimaryAccountNumber,
        s.CompletionYear,
        s.CompHYear,
        s.ArrearsStatus AS StartStatus,
        e.ReportingMonthEnd AS MatchedEndMonth,
        e.ArrearsStatus AS EndStatus,
        CASE s.ArrearsStatus
            WHEN 'Current' THEN 0
            WHEN '1-2 MIA' THEN 1
            WHEN '3-5 MIA' THEN 2
            WHEN '6+ MIA' THEN 3
        END AS StartRank,
        CASE e.ArrearsStatus
            WHEN 'Current' THEN 0
            WHEN '1-2 MIA' THEN 1
            WHEN '3-5 MIA' THEN 2
            WHEN '6+ MIA' THEN 3
        END AS EndRank
    FROM AccsStart AS s
    LEFT JOIN Accs AS e
        ON e.PrimaryAccountNumber = s.PrimaryAccountNumber
        AND e.ReportingMonthEnd = EOMONTH(DATEADD(MONTH, 3, s.ReportingMonthEnd))
),
Transitions AS
(
    SELECT
        StartMonthEnd,
        EndMonthEnd,
        PrimaryAccountNumber,
        CompletionYear,
        CompHYear,
        StartStatus,
        CASE
            WHEN MatchedEndMonth IS NULL THEN 'No end snapshot'
            WHEN EndStatus = 'Possession' THEN 'Possession'
            WHEN EndStatus = 'No longer on Book' THEN 'No longer on Book'
            WHEN EndStatus = 'Unknown' THEN 'Unknown status'
            WHEN EndRank < StartRank THEN 'Roll Back'
            WHEN EndRank = StartRank THEN 'No Roll'
            WHEN EndRank > StartRank THEN 'Roll Forward'
            ELSE 'Unknown status'
        END AS Outcome
    FROM RankedTransitions
)
SELECT
    StartMonthEnd,
    EndMonthEnd,
    CompletionYear,
    CompHYear,
    StartStatus,
    COUNT_BIG(*) AS TotalStartAccounts,
    SUM(CONVERT(bigint, CASE WHEN Outcome = 'Roll Back' THEN 1 ELSE 0 END)) AS RollBackCount,
    SUM(CONVERT(bigint, CASE WHEN Outcome = 'No Roll' THEN 1 ELSE 0 END)) AS NoRollCount,
    SUM(CONVERT(bigint, CASE WHEN Outcome = 'Roll Forward' THEN 1 ELSE 0 END)) AS RollForwardCount,
    SUM(CONVERT(bigint, CASE WHEN Outcome = 'No longer on Book' THEN 1 ELSE 0 END)) AS NoLongerOnBookCount,
    SUM(CONVERT(bigint, CASE WHEN Outcome = 'Possession' THEN 1 ELSE 0 END)) AS PossessionCount,
    SUM(CONVERT(bigint, CASE WHEN Outcome = 'No end snapshot' THEN 1 ELSE 0 END)) AS NoEndSnapshotCount,
    SUM(CONVERT(bigint, CASE WHEN Outcome = 'Unknown status' THEN 1 ELSE 0 END)) AS UnknownStatusCount
FROM Transitions
GROUP BY
    StartMonthEnd,
    EndMonthEnd,
    CompletionYear,
    CompHYear,
    StartStatus
ORDER BY
    StartMonthEnd,
    CompletionYear,
    StartStatus;
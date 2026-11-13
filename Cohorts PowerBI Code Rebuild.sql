-- Rolling 10-year window through the last completed calendar month.
-- Adjust these dates or replace them with dashboard parameters as needed.
DECLARE @EndDateExclusive date = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
DECLARE @StartDate date = DATEADD(YEAR, -10, @EndDateExclusive);

WITH accs AS
(
    SELECT
        EOMONTH(dm.BatchDate) AS ReportingMonthEnd,
        dm.CalendarMonthYear AS SnapshotYYYYMM,
        da.AccountNumber AS PrimaryAccountNumber,
        CONCAT(compdate.CalendarYear, 'Q', compdate.CalendarQuarterNumber) AS CompHYear,
        compdate.CalendarYear AS CompletionYear,
        CASE
            WHEN compdate.CalendarYear >= 2022 THEN '2022+'
            WHEN compdate.CalendarYear >= 2016 THEN '2016-2021'
            ELSE '2015 and earlier'
        END AS CompGroup,
        DATEDIFF(MONTH, EOMONTH(compdate.CalendarDate), EOMONTH(dm.BatchDate)) AS TimeOnBook,
        IIF(fmass.ContractualArrearsInMonths >= 1, 1, 0) AS MIA_1P,
        IIF(fmass.ContractualArrearsInMonths >= 3, 1, 0) AS MIA_3P,
        IIF(fmass.ContractualArrearsInMonths > 0, FLOOR(fmass.ContractualArrearsInMonths), 0) AS MonthsinArrears,
        CASE
            WHEN fmass.ContractualArrearsInMonths < 1 AND das.AccountStatus = 'Live' THEN 'Current'
            WHEN fmass.ContractualArrearsInMonths >= 1 AND fmass.ContractualArrearsInMonths < 3 THEN '1-2 MIA'
            WHEN fmass.ContractualArrearsInMonths >= 3 AND fmass.ContractualArrearsInMonths < 6 THEN '3-5 MIA'
            WHEN fmass.ContractualArrearsInMonths >= 6 THEN '6+ MIA'
            WHEN das.AccountStatus <> 'Live' THEN 'No longer on Book'
            ELSE NULL
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
        AND das.AccountStatus = 'Live'
)
SELECT
    ReportingMonthEnd,
    SnapshotYYYYMM,
    CompGroup,
    COUNT(DISTINCT PrimaryAccountNumber) AS AccountCount
FROM accs
WHERE MIA_1P = 1
GROUP BY ReportingMonthEnd, SnapshotYYYYMM, CompGroup
ORDER BY ReportingMonthEnd, CompGroup;
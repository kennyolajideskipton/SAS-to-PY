%LET filename = July26;
%LET editionno = '618450156';

%LET scorefromdt = '2026-06-30';
%LET scoretodt = '2026-07-31';

*%LET today = &sysdate;

/*------------------------------SCORE DATASET FROM ODS------------------------------*/
PROC SQL;
CONNECT TO odbc    ("server=SBSPSQLVS101\MISPSQL01;
                    driver=sql server; 
                    database=P_ods; 
                    trusted connection=yes;");
    
CREATE TABLE ScoreData AS
SELECT * FROM CONNECTION TO ODBC
(SELECT    oco.*
		/*Application*/
		, app.ID 						AS 'ID_app'
		, app.ExecutedAt 				AS 'ExecutedAt_app'
		, app.Created 					AS 'Created_app'
		, app.Updated 					AS 'Updated_app'
		, app.MortgageAccountNumber 	AS 'MortgageApplicationNumber_app'
		, app.ABAmtAllLoans 			AS 'ABAmtAllLoans_app'	
		, app.App1_CorrRegion 			AS 'App1_CorrRegion_app'
		, app.App1_EmpType 				AS 'App1_EmpType_app'
		, app.App1_GrossBasicInc 		AS 'App1_GrossBasicInc_app'
		, app.App1_GrossGuarInc 		AS 'App1_GrossGuarInc_app'
		, app.App1_GrossNonGuarInc 		AS 'App1_GrossNonGuarInc_app'
		, app.App2_EmpType 				AS 'App2_EmpType_app'
		, app.App2_GrossBasicInc 		AS 'App2_GrossBasicInc_app'
		, app.App2_GrossGuarInc 		AS 'App2_GrossGuarInc_app'
		, app.App2_GrossNonGuarInc 		AS 'App2_GrossNonGuarInc_app'
		, app.App3_GrossBasicInc 		AS 'App3_GrossBasicInc_app'
		, app.App3_GrossGuarInc 		AS 'App3_GrossGuarInc_app'
		, app.App3_GrossNonGuarInc 		AS 'App3_GrossNonGuarInc_app'
		, app.App4_GrossBasicInc 		AS 'App4_GrossBasicInc_app'
		, app.App4_GrossGuarInc 		AS 'App4_GrossGuarInc_app'
		, app.App4_GrossNonGuarInc 		AS 'App4_GrossNonGuarInc_app'	
		, app.ApplicationType 			AS 'ApplicationType_app'
		, app.AppsNonRevolveBal 		AS 'AppsNonRevolveBal_app'
		, app.AppsNonRevolveRepay 		AS 'AppsNonRevolveRepay_app'
		, app.AppsOtherExpenditure 		AS 'AppsOtherExpenditure_app'
		, app.AppsRevolveBal 			AS 'AppsRevolveBal_app'
		, app.AppsSecDebtAmt 			AS 'AppsSecDebtAmt_app'	
		, app.AppCreatedDate 			AS 'AppCreatedDate'
		, app.AppSubmitDate 			AS 'AppSubmitDate'
		, app.OfferDate 				AS 'OfferDate'
		, app.IntOnlyAmt 				AS 'IntOnlyAmt_app'
		, app.LoanType 					AS 'LoanType_app'
		, app.LTI 						AS 'LTI_app'
		, app.LTV 						AS 'LTV_app'
		, app.NbrOfAppls 				AS 'NbrOfAppls_app'
		, app.NoDependants 				AS 'NoDependants_app'
		, app.App1_BenefitIncome 		AS 'App1BenefitInc_app'
		, app.App2_BenefitIncome 		AS 'App2BenefitInc_app'
		, app.App3_BenefitIncome 		AS 'App3BenefitInc_app'
		, app.App4_BenefitIncome 		AS 'App4BenefitInc_app'
		, app.HTBEquityLoanAmt 			AS 'HTBEquityLoan_app'
		, app.AppSBSSecuredDebtBalance 	AS 'SBSNonBTLMortgagesBalance_app'
		, app.AppSBSSecuredDebtTerm 	AS 'SBSNonBTLMortgagesTerm_app'	
		, app.App1_DividendIncome 		AS 'App1DividendIncN34_app'
		, app.App2_DividendIncome 		AS 'App2DividendIncN35_app'
		, app.App3_DividendIncome 		AS 'App3DividendIncN36_app'
		, app.App4_DividendIncome 		AS 'App4DividendIncN37_app'
		, app.MortgageProductTerm 		AS 'Product_TermN40_app'	
		, app.ForcesHTBDeposit 			AS 'FHTBLoanAmountN42_app'
		, app.BTLMortgagesAtCompletion 	AS 'No_BTLsInProgressN43_app'		
		, app.SharedOwnershipRent 		AS 'SO_RentN48_app'	
		, app.App1_NonVolPension 		AS 'App1NonVolPensionN63_app'
		, app.App2_NonVolPension 		AS 'App2NonVolPensionN64_app'
		, app.App3_NonVolPension 		AS 'App3NonVolPensionN65_app'
		, app.App4_NonVolPension 		AS 'App4NonVolPensionN66_app'
		, MortgageFees 					AS 'MortgageFeesN8_app'
		, app.App1_MaintenanceIncome 	AS 'App1MaintenanceIncN80_app'
		, app.App2_MaintenanceIncome 	AS 'App2MaintenanceIncN81_app'
		, app.App3_MaintenanceIncome 	AS 'App3MaintenanceIncN82_app'
		, app.App4_MaintenanceIncome 	AS 'App4MaintenanceIncN83_app'
		, app.AddBorrowingDebtCon 		AS 'Debt_ConN152_app'
		, app.TrackRecordTotalRent 		AS 'TRRentN129_app'
		, app.InterestRate 				AS 'InterestRateN130_app'
		, app.DepositLISASBS 			AS 'LISADeposit_app'
		, app.RemoAmtRepayMtg 			AS 'RemoNum95_app'
		, app.RemoAmtHI 				AS 'RemoNum96_app'
		, app.RemoAmtRepayHI 			AS 'RemoNum97_app'
		, app.RemoAmtCapRaising 		AS 'RemoNum98_app'
		, app.RemoAmtDebtCon 			AS 'RemoNum99_app'
		, app.RemoAmtTOfE 				AS 'RemoNum100_app'
		, app.RemoAmtEquityBuyOut 		AS 'RemoNum101_app'
		, app.RemoAmtPurchaseResi 		AS 'RemoNum102_app'
		, app.RemoAmtPurchaseBTL 		AS 'RemoNum103_app'
		, app.RemoAmtStaircasing 		AS 'RemoNum104_app'
		, app.Part1_LoanAmt 			AS 'Part1_LoanAmt_app'
		, app.Part1_RepType 			AS 'Part1_RepType_app'
		, app.Part2_LoanAmt 			AS 'Part2_LoanAmt_app'
		, app.Part2_Prod 				AS 'Part2_Prod_app'
		, app.Part2_Reptype 			AS 'Part2_Reptype_app'
		, app.PortfolioBTLbalance 		AS 'PortfolioBTLbalance_app'
		, app.RemortgageReason 			AS 'RemortgageReason_app'
		, app.RentalIncome 				AS 'RentalIncome_app'	
		, app.SecRegion 				AS 'SecRegion_app'	
		, app.HelpToBuy  				AS 'HTB_FlagS1_app'	
		, app.App3_EmpType 				AS 'App3_EmpTypeS11_app'	
		, app.App4_EmpType 				AS 'App4_EmpTypeS13_app'
		, app.ThreeStageProduct 		AS 'ThreeStageProduct_FlagS14_app'	
		, app.LisaFlag 					AS 'LISA_FlagS16_app'	
		, app.ProductLongFixedTerm  	AS 'FiveYRFixed_FlagS2_app'	
		, app.ApplicationProductType 	AS 'ProductTypeS3_app'	
		, app.App1_TaxStatus  			AS 'App1TaxStatusS5_app'
		, app.App2_TaxStatus  			AS 'App2TaxStatusS6_app'
		, app.App3_TaxStatus  			AS 'App3TaxStatusS7_app'
		, app.App4_TaxStatus  			AS 'App4TaxStatusS8_app'
		, app.MainResidence  			AS 'MainResidenceS9_app'
		, app.TermInMths 				AS 'TermInMths_app'
		, app.TotalLoanAmount 			AS 'TotalLoanAmount_app'
		, app.purchaseType				AS 'PurchaseType_app'
		, app.UseOfProperty				AS 'UseOfProperty_app'
		, app.LoadID 					AS 'LoadID_app'

		
		, app.App1_NonProprietor
		, app.App2_NonProprietor
		, app.App3_NonProprietor
		, app.App4_NonProprietor
		, app.App1_RetirementAge
		, app.App2_RetirementAge
		, app.App3_RetirementAge
		, app.App4_RetirementAge
		, app.App1_DOB
		, app.App2_DOB
		, app.App3_DOB
		, app.App4_DOB

		/*App1*/
		, app1.ID 						AS 'ID_app1'
		, app1.ExecutedAt 				AS 'ExecutedAt_app1'
		, app1.Created 					AS 'Created_app1'
		, app1.Updated 					AS 'Updated_app1'
		, app1.MortgageAccountNumber	AS 'ApplicationNumber_app1'
		, app1.G4ndspcii 				AS 'App1G4NDSPCII'
		, app1.LoadID 					AS 'LoadID_app1'

		/*App2*/
		, app2.ID 						AS 'ID_app2'
		, app2.ExecutedAt 				AS 'ExecutedAt_app2'
		, app2.Created 					AS 'Created_app2'
		, app2.Updated 					AS 'Updated_app2'
		, app2.MortgageAccountNumber 	AS 'ApplicationNumber_app2'
		, app2.G4ndspcii 				AS 'App2G4NDSPCII'
		, app2.LoadID 					AS 'LoadID_app2' 

		/*App3*/
		, app3.ID 						AS 'ID_app3'
		, app3.ExecutedAt 				AS 'ExecutedAt_app3'
		, app3.Created 					AS 'Created_app3'
		, app3.Updated 					AS 'Updated_app3'
		, app3.MortgageAccountNumber 	AS 'ApplicationNumber_app3'
		, app3.G4ndspcii 				AS 'App3G4NDSPCII'
		, app3.LoadID 					AS 'LoadID_app3' 

		/*App4*/
		, app4.ID 						AS 'ID_app4'
		, app4.ExecutedAt 				AS 'ExecutedAt_app4'
		, app4.Created 					AS 'Created_app4'
		, app4.Updated 					AS 'Updated_app4'
		, app4.MortgageAccountNumber 	AS 'ApplicationNumber_app4'
		, app4.G4ndspcii 				AS 'App4G4NDSPCII'
		, app4.LoadID 					AS 'LoadID_app4' 

		/*Results*/
		, res.ID 						AS 'ID_res'
		, res.ExecutedAt 				AS 'ExecutedAt_res'
		, res.Created 					AS 'Created_res'
		, res.Updated 					AS 'Updated_res'
		, res.MortgageAccountNumber 	AS 'ApplicationNumber_res'
		, res.Af_Affordability 			AS 'Af_Affordability_res'
		, res.Af_Edi 					AS 'Af_Edi_res'
		, res.Af_Modelnetinc 			AS 'Af_Modelnetinc_res'
		, res.Af_Modeloutgoings 		AS 'Af_Modeloutgoings_res'
		, res.Af_Stressmortrepay 		AS 'Af_Stressmortrepay_res'
		, res.AF_Resistressrate 		AS 'AF_Resistressrate_res'
		, res.Af_AlternativeTerm 		AS 'AlternativeTerm_N1'
		, res.Stratcas15 				AS 'CAS15_N101'
		, res.Strathrc14 				AS 'HRC14_N104'
		, res.Strathrc18				AS 'HRC18_N105'
		, res.Strathrc26 				AS 'HRC26_N106'
		, res.Stratpid05 				AS 'PID05_N107'
		, res.Abbelowcutoff				AS 'ABDelphi_N108'
		, res.Abcii						AS 'ABCII_N109'
		, res.AF_Icr					AS 'ICRPC_N17'
		, res.Af_Backgroundicr 			AS 'BackgroundICRPC_N19'
		, res.Af_App1grossannualincome	AS 'GAIApp1_N2'
		, res.Af_App2grossannualincome 	AS 'GAIApp2_N3'
		, res.Af_App3grossannualincome	AS 'GAIApp3_N4'
		, res.Af_App4grossannualincome	AS 'GAIApp4_N5'
		, res.AF_Modelledliving1		AS 'BaseorOldMGC_N13'
		, res.AF_Modelledliving3		AS 'LivingpreRCC_N15'
		, res.AF_Modelledliving4		AS 'InflationGap_N41'
		, res.AF_Modelledliving5		AS 'Inflationforward_N42'
		, res.Numeric112				AS 'IncomeElasticity_N43'
		, res.AF_Modelledlivingamt		AS 'LivingModel_N9'
		, res.Modelledlifestyleamt		AS 'LifestyleModel_N10'
		, res.Numeric113				AS 'LifestyleModel_1a'
		, res.Numeric114				AS 'LifestyleModel_1b'
		, res.Numeric115				AS 'LifestyleModel_1c'
		, res.Numeric116				AS 'LifestyleModel_2a'
		, res.Numeric117				AS 'LifestyleModel_2b'
		, res.Numeric118				AS 'LifestyleModel_2c'
		, res.Af_AffordabilityOutcome	AS 'AffordabilityorRentResult_S3'
		, res.PipelineFlag 				AS 'PipelineStrategyResult_S4'
		, res.Topslicingflag			AS 'TopSlicingFlag_S10'
		, res.Trackrecordflag			AS 'TrackRecordFlag_S11'
		, res.Loan1 					AS 'Loan1_res'
		, res.LoanToIncome				AS 'LTIPC'
		, res.LoadID 					AS 'LoadID_res'

FROM    P_ODS._CreditScore_JSON.OCONTROL oco
LEFT JOIN    P_ODS._CreditScore_JSON.ApplicationData app
ON    oco.ID = app.ID
LEFT JOIN    P_ODS._CreditScore_JSON.BureauApp1 app1
ON    oco.ID = app1.ID
LEFT JOIN    P_ODS._CreditScore_JSON.BureauApp2 app2
ON    oco.ID = app2.ID
LEFT JOIN    P_ODS._CreditScore_JSON.BureauApp3 app3
ON    oco.ID = app3.ID
LEFT JOIN    P_ODS._CreditScore_JSON.BureauApp4 app4
ON    oco.ID = app4.ID
LEFT JOIN    P_ODS._CreditScore_JSON.Results res
ON    oco.ID = res.ID

/* >= START DATE ('YYYY-MM-DD')
   <= END DATE ('YYYY-MM-DD')*/

/*WHERE oco.Created >= '2023-05-24' AND oco.Created <= '2023-06-01' */
/*Will return 01/09/2022 results */

WHERE oco.EDITION = &editionno AND 
app.AppCreatedDate   > '2025-08-14 08:00:00.000'
/*oco.Created >= &scorefromdt AND oco.Created <= &scoretodt*/
);
DISCONNECT FROM odbc;
Quit;

/*------------------------------SCORE DATASET FROM AN EXCEL IMPORT------------------------------*/

/* UNCOMMENT IF YOU WISH TO IMPORT A EXCEL FILE*/

/*
PROC IMPORT  
datafile="H:\Anis\New SAS Aff Comparison\TemplateforTesting.xlsx"
out=ScoreData 
dbms=xlsx replace;
Run;
*/



/* Original dataset: mortgage_apps */
/* New dataset without app_type = 'D1': mortgage_apps_filtered */

DATA ScoreData;
    SET ScoreData;
    IF ApplicationType_app NE 'D1' AND ApplicationType_app NE 'CV' AND ApplicationType_app NE 'FW' AND ApplicationType_app NE 'MISSING' AND ApplicationType_app NE 'PS' AND LoanType_app NE 'string';
RUN;


/*------------------------------NUMBER OF SCORES PER EDITION------------------------------*/

title1 color="purple" underlin=1 'Number of Scores for Edition';
PROC FREQ 
Data=ScoreData;
Table Edition;
Run;

/*------------------------------FLAGS AND PIPELINES------------------------------*/
DATA Affordability;
SET ScoreData;

RealWageInflation = ((1.08455092473664/1.04887218045113)-1);
Rateplus1 = InterestRateN130_app +1;


/*Region*/
IF SecRegion_app = "MISSING" THEN SecRegion_app = App1_CorrRegion_app;
ELSE SecRegion_app = SecRegion_app;

/*HTB Equity Loan*/
IF (HTB_FlagS1_app ="Y" OR FHTBLoanAmountN42_app >0) THEN Help_To_Buy_Flag=1; 
ELSE Help_To_Buy_Flag=0;

IF HTB_FlagS1_app ="Y" THEN HTBFlag=1;

HTB_Equity_Loan_Balance=HTBEquityLoan_app;

IF Help_To_Buy_Flag=1 THEN Risk_LTV = ( TotalLoanAmount_app + HTB_Equity_Loan_Balance+FHTBLoanAmountN42_app) / ( TotalLoanAmount_app / LTV_app );
IF Risk_LTV=. THEN Risk_LTV=LTV_app;

/*Shared Ownership*/
IF Loantype_app ="O" OR SO_RentN48_app >0 THEN SOFlag=1; 
ELSE SOFlag=0;

/*Additional Borrowing*/
IF substr(ApplicationType_app,1,1)="f" OR substr(ApplicationType_app,1,1)="F" 
THEN AB_Flag=1; ELSE AB_Flag=0;

/*Buy to Let*/
IF LoanType_app IN ('A','B','C','Q')THEN BTLFlag=1;
ELSE BTLFlag=0;

/*Portfolio Buy to Let*/
IF No_BTLsInProgressN43_app => 4 THEN BTLType = "PBTL"; 
ELSE IF No_BTLsInProgressN43_app > 0 THEN BTLType = "BTL";
ELSE BTLType = "N/A";

/*Interest Only*/
IF IntOnlyAmt_app > 0 THEN IOFlag=1;
ELSE IOFlag=0;

/*Track Record*/
IF TrackRecordFlag_S11 = "Y" THEN TRFlag=1;
ELSE TRFlag=0;

/*LISA LTI*/
IF LISA_FlagS16_app = "Y" AND LISADeposit_app >4000 THEN LISAFlag = 1;
ELSE LISAFlag = 0;

/*Like for Like Remortgage*/
IF  RemoNum95_app >0 AND RemoNum96_app = 0 AND RemoNum97_app = 0 AND RemoNum98_app = 0 AND RemoNum99_app = 0 AND RemoNum100_app = 0 AND RemoNum101_app = 0 AND RemoNum102_app = 0 AND RemoNum103_app = 0 AND RemoNum104_app = 0 THEN Like4LikeFlag = 1;
ELSE Like4LikeFlag = 0;

/*3 Tier Product*/
IF ApplicationType_app = "W" AND FiveYRFixed_FlagS2_app ^= "Y" THEN Threetier = 1;
ELSE IF Loantype_app not in ("A", "B", "C", "Q") AND ApplicationType_app in ("B1", "C1", "D1", "D2", "PA","FA","FC","FW","FD","CV") AND ThreeStageProduct_FlagS14_app = "MISSING" AND FiveYRFixed_FlagS2_app ^= "Y" THEN Threetier = 1;
ELSE IF Loantype_app not in ("A", "B", "C", "Q") AND ApplicationType_app in ("B1", "C1", "D1", "D2", "PA","FA","FC","FW","FD","CV") AND ThreeStageProduct_FlagS14_app = "Y" THEN Threetier = 1;
ELSE Threetier = 0;
/*5 Year Fixed*/
IF ApplicationType_app = "W" AND FiveYRFixed_FlagS2_app = "Y"	THEN Longstress = 1;
ELSE IF Loantype_app not in ("A", "B", "C", "Q") AND FiveYRFixed_FlagS2_app = "Y" AND ApplicationType_app in ("B1", "D1", "D2") THEN Longstress = 1;
ELSE IF Loantype_app not in ("A", "B", "C", "Q") AND ApplicationType_app in ("B1","C1", "D1", "D2", "PA","FA","FC","FW","FD","CV") AND Product_TermN40_app>59 AND Product_TermN40_app<999 AND ProductTypeS3_app="FIX" THEN Longstress=1;
ELSE Longstress=0;

/*---PIPELINE---*/

/*Change from Char to Date*/
AppCreatedDate1 = input(AppCreatedDate, yymmdd8.);
format AppCreatedDate1 yymmdd10.;
drop AppCreatedDate;
AppSubmitDate1 = input(AppSubmitDate, yymmdd8.);
format AppSubmitDate1 yymmdd10.;
drop AppSubmitDate;
OfferDate1 = input(OfferDate, yymmdd8.);
format OfferDate1 yymmdd10.;
drop OfferDate;
ScoreRunAt = datepart(ExecutedAt_res);
format ScoreRunAt yymmdd10.;

/*Pipeline based on offer period*/
PipelineStrat = PipelineStrategyResult_S4;

/*Pipeline//DIP captures DIP Date or if FM checks - set to 28 as counting days inbetween*/
IF (ApplicationType_app = "D2" OR ApplicationType_app = "FD") THEN PipelineDate = AppCreatedDate1;
ELSE IF intnx('Day', AppCreatedDate1, 28) < AppSubmitDate1 THEN PipelineDate = AppSubmitDate1; 
ELSE PipelineDate = AppCreatedDate1;
format PipelineDate yymmdd10.;

/*Date of Change*/
format  BTLStressDate yymmdd10.  Afford1 yymmdd10. BTLStress1Date yymmdd10. ResiStress1 yymmdd10. LTIChange yymmdd10. Afford2Change yymmdd10. LTIChange1 yymmdd10. LTIChange2 yymmdd10. LTIChange3 yymmdd10.;

Afford1 = '03FEB25'd;
BTLStress1Date = '03FEB25'd;
ResiStress1 = '03FEB25'd;
LTIChange = '09JUN25'd;
Afford2Change = '28JUL25'd;
Afford3Change = '23OCT25'd;
LTIChange1 = '05NOV25'd;
LTIChange2 = '24Dec25'd;
LTIChange3 = '02Mar26'd;
Afford4 = '13JUL26'd;

/*Determine which pipeline applies*/

IF PipelineStrat = "Y" AND PipelineDate < Afford1 THEN Afford1Pipeline = "Y"; 
ELSE Afford1Pipeline = "N";

IF PipelineStrat = "Y" AND PipelineDate < BTLStress1Date THEN BTLStress1Pipeline = "Y"; 
ELSE BTLStress1Pipeline = "N";

IF PipelineStrat = "Y" AND PipelineDate < ResiStress1 THEN ResiStress1Pipeline = "Y"; 
ELSE ResiStress1Pipeline = "N";

IF PipelineStrat = "Y" AND PipelineDate < LTIChange THEN LTIChangePipeline = "Y"; 
ELSE LTIChangePipeline = "N";

IF PipelineStrat = "Y" AND PipelineDate < Afford2Change THEN Afford2Pipeline = "Y"; 
ELSE Afford2Pipeline = "N";

IF PipelineStrat = "Y" AND PipelineDate < Afford3Change THEN Afford3Pipeline = "Y"; 
ELSE Afford3Pipeline = "N";

IF PipelineStrat = "Y" AND PipelineDate < LTIChange1 THEN LTIChange1Pipeline = "Y"; 
ELSE LTIChange1Pipeline = "N";

IF PipelineStrat = "Y" AND PipelineDate < LTIChange2 THEN LTIChange2Pipeline = "Y"; 
ELSE LTIChange2Pipeline = "N";

IF PipelineStrat = "Y" AND PipelineDate < LTIChange3 THEN LTIChange3Pipeline = "Y"; 
ELSE LTIChange3Pipeline = "N";

IF PipelineStrat = "Y" AND PipelineDate < Afford4 THEN Afford4Pipeline = "Y"; 
ELSE Afford4Pipeline = "N";

RUN;

/*------------------------------NUMBER OF FLAGS IN DATASET------------------------------*/

title1 color="purple" underlin=1 'Number of Flags';
PROC FREQ 
Data=Affordability;
Table Help_To_Buy_Flag SOFlag BTLFlag BTLType IOFlag TRFlag ApplicationType_app SecRegion_app ;
Run;

/*------------------------------Pipeline Matches------------------------------*/

title1 color="purple" underlin=1 'Number of Pipeline Cases';
PROC FREQ 
Data=Affordability;
Table PipelineStrategyResult_S4 PipelineStrat  Afford1Pipeline BTLStress1Pipeline ResiStress1Pipeline LTIChangePipeline Afford2Pipeline LTIChange1Pipeline LTIChange2Pipeline Afford4Pipeline;
Run;
/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*------------------------------GROSS TO NET------------------------------*/
/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
DATA GrosstoNet;
SET Affordability;

Household_GAIBuild = Household_GAI/1.08455092473664;

/* Employed or not */
IF App1_EmpType_app in ("L","O","R") 		THEN app1EmpType="Not Employed";
IF App2_EmpType_app in ("L","O","R") 		THEN app2EmpType="Not Employed";
IF App3_EmpTypeS11_app 	in ("L","O","R") 	THEN app3EmpType="Not Employed";
IF App4_EmpTypeS13_app	in ("L","O","R") 	THEN app4EmpType="Not Employed";

IF App1_EmpType_app	in ("E","S") 	 		THEN app1EmpType="Employed";
IF App2_EmpType_app	in ("E","S") 	 		THEN app2EmpType="Employed";
IF App3_EmpTypeS11_app	in ("E","S") 	 	THEN app3EmpType="Employed";
IF App4_EmpTypeS13_app	in ("E","S") 	 	THEN app4EmpType="Employed";

/*----------------------------------------------------------------------------------------*/
/*------TAX TABLES------*/
/* England & Wales Income Tax Table */
EngBRT = 0.2;
EngHRT = 0.4;
EngART = 0.45;
EngTFA = 12570;
EngBasic = 37700;
EngHigher = 125140;
EngIncLimit = 100000;

/* Scotland Tax Income Table */
ScoSRT = 0.19;
ScoBRT = 0.2;
ScoIRT = 0.21;
ScoHRT = 0.42;
ScoADV = 0.45;
ScoART = 0.48;
ScoTFA = 12570;
ScoStarter = 3967;
ScoBasic = 16956;
ScoInterm = 31092;
ScoHigher = 62430;
ScoAdvanced = 125140;
ScoIncLimit = 100000;

/* Dividend Table */
DivTFA = 500;
DivBRT = 0.1075;
DivHRT = 0.3575;
DivART = 0.3935;

/*------NI TABLES------*/
/* Class 1 */
NI1Prim = 0.08;
NI1High = 0.02;
NI1PrimThres = 12570;
NI1UpperThres = 50270;

/* Class 2 */
/* NI2Prim = 179.40; */
/* NI2PrimThres = 12570; */

/* Class 4 */
NI4Prim = 0.06;
NI4High = 0.02;
NI4PrimThres = 12570;
NI4UpperThres = 50270;

/*----------------------------------------------------------------------------------------*/

/* Income to be taxed */ 
App1ITBT = App1_GrossBasicInc_app + App1_GrossGuarInc_app + (App1_GrossNonGuarInc_app*0.5);
App2ITBT = App2_GrossBasicInc_app + App2_GrossGuarInc_app + (App2_GrossNonGuarInc_app*0.5);
App3ITBT = App3_GrossBasicInc_app + App3_GrossGuarInc_app + (App3_GrossNonGuarInc_app*0.5);
App4ITBT = App4_GrossBasicInc_app + App4_GrossGuarInc_app + (App4_GrossNonGuarInc_app*0.5);

/*----------------------------------------------------------------------------------------*/
array itbt {4} App1ITBT App2ITBT App3ITBT App4ITBT;
array dtbt {4} App1DividendIncN34_app App2DividendIncN35_app App3DividendIncN36_app App4DividendIncN37_app;
array benefit {4} App1BenefitInc_app App2BenefitInc_app App3BenefitInc_app App4BenefitInc_app;
array maintenance {4} App1MaintenanceIncN80_app App2MaintenanceIncN81_app App3MaintenanceIncN82_app App4MaintenanceIncN83_app;
/*------Personal Tax Allowance------*/
array pta {4} App1pta App2pta App3pta App4pta;
/*------Taxable Inc------*/
array Taxinc {4} App1TI App2TI App3TI App4TI;
/*------Additional------*/
array additional {4} App1additional App2additional App3additional App4additional;
/*------Advanced SC ONLY-----*/
array advanced {4} App1advanced App2advanced App3advanced App4advanced;
/*------Higher------*/
array higher {4} App1higher App2higher App3higher App4higher;
/*------Intermediate SC ONLY------*/
array interm {4} App1interm App2interm App3interm App4interm;
/*------Basic------*/
array basic {4} App1basic App2basic App3basic App4basic;
/*------Starter------*/
array starter {4} App1starter App2starter App3starter App4starter;
/*------EmpType------*/
array emptype {4} app1EmpType app2EmpType app3EmpType app4EmpType;
/*------EmpType (Employed or Self Employed)------*/
array emp {4} App1_EmpType_app App2_EmpType_app App3_EmpTypeS11_app App4_EmpTypeS13_app;
/*------NI Primary Class 1------*/
array NIP1 {4} app1nip1 app2nip1 app3nip1 app4nip1;
/*------NI Higher Class 1------*/
array NIH1 {4} app1nih1 app2nih1 app3nih1 app4nih1;
/*------NI Class 2------*/
/* array NI2 {4} app1ni2 app2ni2 app3ni2 app4ni2; */
/*------NI Primary Class 4------*/
array NIP4 {4} app1nip4 app2nip4 app3nip4 app4nip4;
/*------NI Higher Class 4------*/
array NIH4 {4} app1nih4 app2nih4 app3nih4 app4nih4;
/*------Tax Band------*/
array Taxband {4} $ app1tb app2tb app3tb app4tb;
/*----------------------------------------------------------------------------------------*/
/*------Personal Tax Allowance (Deductions)------*/
array deducpta {4} deducApp1pta deducApp2pta deducApp3pta deducApp4pta;
/*------Additional------*/
array adddeduc {4} App1adddeduc App2adddeduc App3adddeduc App4adddeduc;
/*------Advanced SC ONLY------*/
array advdeduc {4} App1advdeduc App2advdeduc App3advdeduc App4advdeduc;
/*------Higher------*/
array highdeduc {4} App1highdeduc App2highdeduc App3highdeduc App4highdeduc;
/*------Intermediate SC ONLY------*/
array intdeduc {4} App1intdeduc App2intdeduc App3intdeduc App4intdeduc;
/*------Basic------*/
array basdeduc {4} App1basdeduc App2basdeduc App3basdeduc App4basdeduc;
/*------Starter------*/
array strtdeduc {4} App1strtdeduc App2strtdeduc App3strtdeduc App4strtdeduc;
/*------NI Primary Class 1------*/
array NIP1ded {4} app1nip1ded app2nip1ded app3nip1ded app4nip1ded;
/*------NI Higher Class 1------*/
array NIH1ded {4} app1nih1ded app2nih1ded app3nih1ded app4nih1ded;
/*------NI Primary Class 4------*/
array NIP4ded {4} app1nip4ded app2nip4ded app3nip4ded app4nip4ded;
/*------NI Higher Class 4------*/
array NIH4ded {4} app1nih4ded app2nih4ded app3nih4ded app4nih4ded;
/*----------------------------------------------------------------------------------------*/
/*------Additional Div Table------*/
array adddiv {4} App1adddiv App2adddiv App3adddiv App4adddiv;
/*------Higher Div Table------*/
array highdiv {4} App1highdiv App2highdiv App3highdiv App4highdiv;
/*------Basic Div Table------*/
array basediv {4} App1basediv App2basediv App3basediv App4basediv;
/*----------------------------------------------------------------------------------------*/
/*------Inc Limit Pre-Div Table------*/
array inclim {4} App1inclim App2inclim App3inclim App4inclim;
/*------PA Remaining Pre-Div Table------*/
array PARemain {4} App1PARemain App2PARemain App3PARemain App4PARemain;
/*------Additional Pre-Div Table------*/
array addprediv {4} App1addprediv App2addprediv App3addprediv App4addprediv;
/*------Higher Pre-Div Table------*/
array highprediv {4} App1highprediv App2highprediv App3highprediv App4highprediv;
/*------Basic Pre-Div Table------*/
array basprediv {4} App1basprediv App2basprediv App3basprediv App4basprediv;
/*----------------------------------------------------------------------------------------*/
/*------Net Dividend Post-Div Table------*/
array NetDiv {4} App1NetDiv App2NetDiv App3NetDiv App4NetDiv;
/*------Div Tax Post-Div Table------*/
array DivTax {4} App1DivTax App2DivTax App3DivTax App4DivTax;
/*------Additional Post-Div Table------*/
array addpostdiv {4} App1addpostdiv App2addpostdiv App3addpostdiv App4addpostdiv;
/*------Higher Post-Div Table------*/
array highpostdiv {4} App1highpostdiv App2highpostdiv App3highpostdiv App4highpostdiv;
/*------Basic Post-Div Table------*/
array baspostdiv {4} App1baspostdiv App2baspostdiv App3baspostdiv App4baspostdiv;
/*----------------------------------------------------------------------------------------*/
/*------Gross Annual Income------*/
array GAI {4} App1GAI App2GAI App3GAI App4GAI;
/*------Net Annual Income------*/
array NAI {4} App1NAI App2NAI App3NAI App4NAI;
/*------Net Monthly Income------*/
array NMI {4} App1NMI App2NMI App3NMI App4NMI;
/*----------------------------------------------------------------------------------------*/
/*------Modelled Pension Expenditure------*/
array modelpen {4} app1modelpen app2modelpen app3modelpen app4modelpen;
/*------Final Salary Pension Contributions------*/
array nonvolpen {4} App1NonVolPensionN63_app App2NonVolPensionN64_app App3NonVolPensionN65_app App4NonVolPensionN66_app;
/*------Pension Deduction------*/
array PensionDeduct {4} App1PensionDeduct App2PensionDeduct App3PensionDeduct App4PensionDeduct;
/*------Pre-Pension GAI------*/
array PrePensionGAI {4} App1PrePenGAI App2PrePenGAI App3PrePenGAI App4PrePenGAI;
/*------Pre-Pension ITBT------*/
array PrePensionITBT {4} App1PrePenITBT App2PrePenITBT App3PrePenITBT App4PrePenITBT;
/*----------------------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------------------*/
 do i=1 to 4;
PrePensionITBT[i] = itbt[i];
/*----------------------------------------------------------------------------------------*/
/*------PENSION ASSUMPTION OF 5%------*/
/*----------------------------------------------------------------------------------------*/
 /*5% assumption for Employed/Self Employed*/
IF emptype[i] ^= "Not Employed" THEN modelpen[i] = ROUND(itbt[i]*0.05, 0.01); ELSE modelpen[i] = 0;
PensionDeduct[i] = ROUND(	MAX(modelpen[i], nonvolpen[i]), 0.01);
/*------PENSION ASSUMPTION------*/
itbt[i] = itbt[i] - PensionDeduct[i];
/*----------------------------------------------------------------------------------------*/
/*------Personal Tax Allowance------*/
IF secRegion_app ^='SC' THEN 
	IF itbt[i] + dtbt[i] <= EngIncLimit THEN pta[i] = ROUND(	MIN(itbt[i],EngTFA), 0.01); 
	ELSE pta[i] = ROUND(	MAX(EngTFA-ROUND(itbt[i]+dtbt[i]-EngIncLimit,0.01)/2,0), 0.01);
ELSE IF itbt[i] + dtbt[i] <= ScoIncLimit THEN pta[i] = ROUND(	MIN(itbt[i],ScoTFA), 0.01); 
	ELSE pta[i] = ROUND(	MAX(ScoTFA-ROUND(itbt[i]+dtbt[i]-ScoIncLimit,0.01)/2,0), 0.01);

/*------Taxable Inc------*/
Taxinc[i] = ROUND(		itbt[i] - pta[i], 0.01);

/*------Additional------*/
IF secRegion_app ^='SC' THEN 
	IF Taxinc[i] > EngHigher  THEN additional[i] = 	ROUND(	Taxinc[i] - EngHigher, 0.01);
	ELSE additional[i] = 0;
ELSE IF Taxinc[i] > ScoAdvanced  THEN additional[i] = ROUND(	Taxinc[i] - ScoAdvanced, 0.01);
	ELSE additional[i] = 0;

/*------Advanced SC ONLY------*/
IF secRegion_app ^='SC' THEN advanced[i] = 0;
	ELSE IF Taxinc[i] > ScoAdvanced THEN advanced[i] = 	ROUND(		ScoAdvanced - ScoHigher, 0.01); 
	ELSE IF Taxinc[i] > ScoHigher THEN advanced[i] = 	ROUND(		Taxinc[i] - ScoHigher, 0.01); ELSE Advanced[i] = 0;

/*------Higher------*/
IF secRegion_app ^='SC' THEN
	IF Taxinc[i] > EngHigher THEN higher[i] = 		ROUND(		EngHigher - EngBasic, 0.01);
	ELSE IF Taxinc[i] > EngBasic THEN higher[i] = 	ROUND(		Taxinc[i] - EngBasic, 0.01); ELSE higher[i] = 0;
ELSE IF Taxinc[i] > ScoHigher THEN higher[i] = 		ROUND(		ScoHigher - ScoInterm, 0.01);
	ELSE IF Taxinc[i] > ScoInterm THEN higher[i] = 	ROUND(		Taxinc[i] - ScoInterm, 0.01); ELSE higher[i] = 0;

/*------Intermediate SC ONLY------*/
IF secRegion_app ^='SC' THEN interm[i] = 0;
	ELSE IF Taxinc[i] > ScoInterm THEN interm[i] = 	ROUND(		ScoInterm - ScoBasic, 0.01); 
	ELSE IF Taxinc[i] > ScoBasic THEN interm[i] = 	ROUND(		Taxinc[i] - ScoBasic, 0.01); ELSE interm[i] = 0;

/*------Basic------*/
IF secRegion_app ^='SC' THEN basic[i] = 			ROUND(		MAX(Taxinc[i] - higher[i] - additional[i],0), 0.01);
ELSE IF Taxinc[i] > ScoBasic THEN basic[i] = 		ROUND(		ScoBasic - ScoStarter, 0.01);
ELSE IF Taxinc[i] > ScoStarter THEN basic[i] = 		ROUND(		Taxinc[i] - ScoStarter, 0.01); ELSE basic[i] = 0;

/*------Starter SC ONLY------*/
starter[i] = ROUND(		MAX(Taxinc[i] - basic[i] - interm[i] - higher[i] - Advanced[i] - additional[i],0), 0.01);

/*------NI Primary Class 1------*/
IF emp[i] = "S" THEN nip1[i] = 0; 
ELSE IF itbt[i] > NI1UpperThres THEN nip1[i] = 		ROUND(		NI1UpperThres - NI1PrimThres, 0.01);
ELSE IF itbt[i] > NI1PrimThres THEN nip1[i] = 		ROUND(		itbt[i] - NI1PrimThres, 0.01); 
ELSE nip1[i] = 0;

/*------NI Higher Class 1------*/
IF emp[i] = "S" THEN nih1[i] = 0;
ELSE IF itbt[i] > NI1UpperThres THEN nih1[i] = 		ROUND(		itbt[i] - NI1UpperThres, 0.01);
ELSE nih1[i] = 0;

/*------NI Class 2------*/
/* IF emp[i] = "S" THEN 
	IF itbt[i] > NI2PrimThres THEN NI2[i] = NI2Prim; ELSE NI2[i] = 0;
ELSE NI2[i] = 0; */

/*------NI Primary Class 4------*/
IF emp[i] = "S" THEN 
	IF itbt[i] > NI4UpperThres THEN NIP4[i] = 		ROUND(		NI4UpperThres - NI4PrimThres, 0.01);
	ELSE IF itbt[i] > NI4PrimThres THEN NIP4[i] = 	ROUND(		itbt[i] - NI4PrimThres, 0.01); ELSE NIP4[i] = 0;
ELSE NIP4[i] = 0;

/*------NI Higher Class 4------*/
IF emp[i] = "S" THEN 
	IF itbt[i] > NI4UpperThres THEN NIH4[i] = 		ROUND(		ITBT[I] - NI4UpperThres, 0.01); ELSE NIH4[i] = 0;
ELSE NIH4[i] = 0;
/*----------------------------------------------------------------------------------------*/
/*------Tax Bands------*/
IF additional[i] > 0 THEN Taxband[i] = "Additional";
ELSE IF higher[i] > 0 THEN Taxband[i] = "Higher";
ELSE Taxband[i] = "Basic";
/*----------------------------------------------------------------------------------------*/
/*------Personal Tax Allowance (Deductions)------*/
IF secRegion_app ^='SC' THEN
	IF itbt[i] <= EngIncLimit THEN deducpta[i] = 	ROUND(		MIN(itbt[i],EngTFA), 0.01); 
	ELSE deducpta[i] = ROUND(	MAX(EngTFA-ROUND(itbt[i]-EngIncLimit,0.01)/2,0), 0.01);
ELSE IF itbt[i] <= ScoIncLimit THEN deducpta[i] = 	ROUND(		MIN(itbt[i],ScoTFA), 0.01); 
	ELSE deducpta[i] = ROUND(	MAX(ScoTFA-ROUND(itbt[i]-ScoIncLimit,0.01)/2,0), 0.01);

/*------Tax Due (Deductions)------*/
strtdeduc[i] = ROUND(	starter[i] * ScoSRT, 0.01);

IF secRegion_app ^='SC' THEN 
	basdeduc[i] = 		ROUND(	basic[i] * EngBRT, 0.01);
	ELSE basdeduc[i] = 	ROUND(	basic[i] * ScoBRT, 0.01);

intdeduc[i] = 			ROUND(	interm[i] * ScoIRT, 0.01);

IF secRegion_app ^='SC' THEN 
	highdeduc[i] = 		ROUND(	higher[i] * EngHRT, 0.01);
	ELSE highdeduc[i] = ROUND(	higher[i] * ScoHRT, 0.01); 

advdeduc[i] = 			ROUND(	advanced[i] * ScoADV, 0.01);

IF secRegion_app ^='SC' THEN 
	adddeduc[i] = 		ROUND(	additional[i] * EngART, 0.01);
	ELSE adddeduc[i] = 	ROUND(	additional[i] * ScoART, 0.01);

/*------NI Due (Deductions)------*/
NIP1ded[i] = 			ROUND(	NIP1[i] * NI1Prim, 0.01);
NIH1ded[i] = 			ROUND(	NIH1[i] * NI1High, 0.01);
NIP4ded[i] = 			ROUND(	NIP4[i] * NI4Prim, 0.01);
NIH4ded[i] = 			ROUND(	NIH4[i] * NI4High, 0.01);
/*----------------------------------------------------------------------------------------*/
IF Taxinc[i] > EngHigher THEN adddiv[i] = 		ROUND(	Taxinc[i] - EngHigher, 0.01);
ELSE adddiv[i] = 0;

IF Taxinc[i] > EngHigher THEN highdiv[i] = 		ROUND(	EngHigher - EngBasic, 0.01);
ELSE IF Taxinc[i] > EngBasic THEN highdiv[i] = 	ROUND(	Taxinc[i] - EngBasic, 0.01);
ELSE highdiv[i] = 0;

basediv[i] = ROUND(		MAX(Taxinc[i] - highdiv[i] - adddiv[i], 0), 0.01);
/*----------------------------------------------------------------------------------------*/
IF secRegion_app ^='SC' THEN
	IF itbt[i] + dtbt[i] <= EngIncLimit THEN inclim[i] = EngTFA;
	ELSE inclim[i] = 	ROUND( 	EngTFA - ((itbt[i]+dtbt[i]-EngIncLimit)/2), 0.01);
ELSE IF itbt[i] + dtbt[i] <= ScoIncLimit THEN inclim[i] = ScoTFA;
	ELSE inclim[i] = 	ROUND( 	ScoTFA - ((itbt[i]+dtbt[i]-ScoIncLimit)/2), 0.01);

IF dtbt[i] = 0 THEN PARemain[i] = 0;
ELSE IF itbt[i] < inclim[i] THEN PARemain[i] = 	ROUND(	inclim[i] - itbt[i], 0.01);
ELSE PARemain[i] = 0;

IF dtbt[i] = 0 THEN basprediv[i] = 0; 
ELSE IF basediv[i] = EngBasic THEN basprediv[i] = 0; 
ELSE IF dtbt[i] < PARemain[i] THEN basprediv[i] = 0;
ELSE IF dtbt[i] <= EngBasic - basediv[i] + PARemain[i] THEN basprediv[i] = ROUND(	dtbt[i] - PARemain[i], 0.01);
ELSE basprediv[i] = 	ROUND(	EngBasic - basediv[i], 0.01);

IF dtbt[i] = 0 THEN highprediv[i] = 0;
ELSE IF highdiv[i] = EngHigher - EngBasic THEN highprediv[i] = 0;
ELSE IF dtbt[i] - basprediv[i] - PARemain[i] <= 0 THEN highprediv[i] = 0;
ELSE IF dtbt[i] + Taxinc[i] > EngHigher THEN highprediv[i] = ROUND(	(dtbt[i] - (dtbt[i] + Taxinc[i] - EngHigher) - basprediv[i]), 0.01);
ELSE IF dtbt[i] - basprediv[i] <= EngHigher - highdiv[i] THEN highprediv[i] = ROUND(	dtbt[i] - basprediv[i] - PARemain[i], 0.01);
ELSE highprediv[i] = 	ROUND(	EngHigher - EngBasic - highdiv[i], 0.01);

IF dtbt[i] = 0 THEN addprediv[i] = 0;
ELSE IF itbt[i] + dtbt[i] < EngHigher THEN addprediv[i] = 0;
ELSE IF itbt[i] > EngHigher THEN addprediv[i] = dtbt[i];
ELSE addprediv[i] = 	ROUND(	dtbt[i] - highprediv[i] - basprediv[i] - PARemain[i], 0.01);
/*----------------------------------------------------------------------------------------*/
IF basprediv[i] >= DivTFA THEN baspostdiv[i] = basprediv[i] - DivTFA;
ELSE baspostdiv[i] = 0;

IF highprediv[i] = 0 THEN highpostdiv[i] = 0;
ELSE IF highprediv[i] < DivTFA THEN highpostdiv[i] = 0;
ELSE IF basprediv[i] - DivTFA < 0 THEN highpostdiv[i] = highprediv[i] - (DivTFA - basprediv[i]);
ELSE highpostdiv[i] = highprediv[i];

IF addprediv[i] ^= 0 THEN 
	IF baspostdiv[i] + highpostdiv[i] = 0 THEN addpostdiv[i] = addprediv[i] + highprediv[i] - DivTFA;
	ELSE addpostdiv[i] = addprediv[i];
ELSE addpostdiv[i] = 0;

DivTax[i] = (baspostdiv[i]*DivBRT) + (highpostdiv[i]*DivHRT) + (addpostdiv[i]*DivART);

NetDiv[i] = ROUND(	dtbt[i] - DivTax[i], 0.01);
/*----------------------------------------------------------------------------------------*/
GAI[i] = ROUND(SUM(itbt[i], dtbt[i], benefit[i], maintenance[i]),0.01);
PrePensionGAI[i] = ROUND(SUM(PrePensionitbt[i], dtbt[i], benefit[i], maintenance[i]),0.01);

NAI[i] = ROUND(itbt[i] - ROUND(SUM(strtdeduc[i], basdeduc[i], intdeduc[i], highdeduc[i], advdeduc [i], adddeduc[i]),0.01) - 
ROUND(SUM(NIP1ded[i], NIH1ded[i], NIP4ded[i], NIH4ded[i]),0.01) + 
ROUND(NetDiv[i],0.01) + 
ROUND(SUM(benefit[i], maintenance[i]),0.01),0.01);

NMI[i] = ROUND(NAI[i]/12,0.01);
end;

Household_NAI = ROUND(SUM(App1NAI, App2NAI, App3NAI, App4NAI), 0.01);

Household_NMI = ROUND(SUM(App1NMI, App2NMI, App3NMI, App4NMI),0.01);

PrePensionHousehold_GAI = round(Sum(App1PrePenGAI, App2PrePenGAI, App3PrePenGAI, App4PrePenGAI),0.01);

/*------VALIDATION CHECK------*/
DifferencePCvsSASnet = Af_Modelnetinc_res-Household_NMI;

RUN;
title1 color="purple" underlin=1 'COMPARISON CHECK: Gross to Net';
title2 italic 'Difference between PC and SAS';
PROC FREQ 
Data=GrosstoNet;
Table DifferencePCvsSASnet;
Run;
/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*------------------------------EXPENDITURE ITEMS------------------------------*/
/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*------------------------------LIVING EXPENDITURE------------------------------*/
Data GrosstoNet2;
SET GrosstoNet;
/*Gross Incomes*/
Household_GAI = round(Sum(App1GAI, App2GAI, App3GAI, App4GAI),0.01);
Household_GAIBuild = Household_GAI/1.08455092473664;
Household_GMI = round(Household_GAI/12,0.01);

run;


DATA LivingExpenditure;
SET GrosstoNet2;



/*Single or Couple*/
IF nbrOfAppls_app > 1 			 	THEN S_C = 'Couple';
IF nbrOfAppls_app = 1 AND S_C = '' 	THEN S_C = 'Single';

/*Household Compositions*/
IF nbrOfAppls_app=1 AND noDependants_app = 0 THEN HouseholdComp = 'A1D0';
ELSE IF nbrOfAppls_app= 1 AND noDependants_app = 1 THEN HouseholdComp = 'A1D1';
ELSE IF nbrOfAppls_app= 1 AND noDependants_app = 2 THEN HouseholdComp = 'A1D2';
ELSE IF nbrOfAppls_app= 1 AND noDependants_app > 2 THEN HouseholdComp = 'A1D3_';

ELSE IF nbrOfAppls_app = 2 AND noDependants_app = 0 THEN HouseholdComp = 'A2D0';
ELSE IF nbrOfAppls_app = 2 AND noDependants_app = 1 THEN HouseholdComp = 'A2D1';
ELSE IF nbrOfAppls_app = 2 AND noDependants_app = 2 THEN HouseholdComp = 'A2D2';
ELSE IF nbrOfAppls_app = 2 AND noDependants_app > 2 THEN HouseholdComp = 'A2D3_';

ELSE IF nbrOfAppls_app = 3 AND noDependants_app = 0 THEN HouseholdComp = 'A3D0';
ELSE IF nbrOfAppls_app = 3 AND noDependants_app = 1 THEN HouseholdComp = 'A3D1';
ELSE IF nbrOfAppls_app = 3 AND noDependants_app > 1 THEN HouseholdComp = 'A3D2_';

ELSE IF nbrOfAppls_app = 4 AND noDependants_app = 0 THEN HouseholdComp = 'A4D0';
ELSE IF nbrOfAppls_app = 4 AND noDependants_app > 0 THEN HouseholdComp = 'A4D1_';

/*Living Setter - Coefficients for Modelled Expenditure Polynomials*/


IF HouseholdComp = 'A1D0' 	and Afford4Pipeline = "Y"	THEN DO; 
LivingSetter1 = -0.000000870244898510266; 
LivingSetter2 = 0.21813609552101; 
LivingSetter3 = 3647.66361885504; 
LivingSetter4 = 0.105004258714675;
LivingSetter5 = 7215.66770274713;
Collar = 815.24007726464; 
Cap = 1761.57140114513;
END;

ELSE IF HouseholdComp = 'A1D1' and Afford4Pipeline = "Y"		THEN DO; 
LivingSetter1 = -0.000000967332258643185; 
LivingSetter2 = 0.242472070026682; 
LivingSetter3 = 4054.60887301713; 
LivingSetter4 = 0.116718876403068;
LivingSetter5 = 8020.67113345419;
Collar = 906.19092008104; 
Cap = 1958.09805394781; 
END;

ELSE IF HouseholdComp = 'A1D2'  and Afford4Pipeline = "Y"	 	THEN DO; 
LivingSetter1 = -0.0000010644196187761; 
LivingSetter2 = 0.266808044532354; 
LivingSetter3 = 4461.55412717922; 
LivingSetter4 = 0.128433494091461;
LivingSetter5 = 8825.67456416125;
Collar = 997.141762897439; 
Cap = 2154.62470675048; 
END;

ELSE IF HouseholdComp = 'A1D3'  and Afford4Pipeline = "Y"		THEN DO; 
LivingSetter1 = -0.00000116150697890902; 
LivingSetter2 = 0.291144019038026; 
LivingSetter3 = 4868.49938134131; 
LivingSetter4 = 0.140148111779853;
LivingSetter5 = 9630.6779948683;
Collar = 1088.09260571384; 
Cap = 2351.15135955316; 
END;

ELSE IF HouseholdComp = 'A2D0' and Afford4Pipeline = "Y"		THEN DO; 
LivingSetter1 = -0.00000110540746894908; 
LivingSetter2 = 0.277082083042478; 
LivingSetter3 = 4633.35621432388; 
LivingSetter4 = 0.133379112079098;
LivingSetter5 = 9165.5268370151;
Collar = 1035.53892925731; 
Cap = 2237.59333406762; 
END;

ELSE IF (HouseholdComp = 'A2D1' OR HouseholdComp = 'A3D0') and Afford4Pipeline = "Y" THEN DO; 
LivingSetter1 = -0.00000122873033267996; 
LivingSetter2 = 0.307994264232825; 
LivingSetter3 = 5150.26855035045; 
LivingSetter4 = 0.14825932098443;
LivingSetter5 = 10188.0629143383;
Collar = 1151.06703074756; 
Cap = 2487.22654677306; 
END;

ELSE IF (HouseholdComp = 'A2D2' OR HouseholdComp = 'A3D1' OR HouseholdComp = 'A4D0')and Afford4Pipeline = "Y"	 THEN DO; 
LivingSetter1 = -0.00000135205319641085; 
LivingSetter2 = 0.338906445423171; 
LivingSetter3 = 5667.18088637703; 
LivingSetter4 = 0.163139529889761;
LivingSetter5 = 11210.5989916615;
Collar = 1266.5951322378; 
Cap = 2736.8597594785; 
END;

ELSE IF (HouseholdComp = 'A2D3' OR HouseholdComp = 'A3D2' OR  HouseholdComp = 'A4D1')	 and Afford4Pipeline = "Y"	THEN DO; 
LivingSetter1 = -0.00000147537606014173; 
LivingSetter2 = 0.369818626613518; 
LivingSetter3 = 6184.09322240362; 
LivingSetter4 = 0.178019738795093;
LivingSetter5 = 12233.1350689847;
Collar = 1382.12323372804; 
Cap = 2986.49297218395; 
END;




IF HouseholdComp = 'A1D0' 	AND Afford4Pipeline = "N" 	THEN DO; 
LivingSetter1 = -0.000000548517748107402; 
LivingSetter2 = 0.187771158981794000000; 
LivingSetter3 = 4427.104930397730000000000; 
Collar = 811.7334926; 
Cap = 1574.867274;
END;

ELSE IF HouseholdComp = 'A1D1'  AND Afford4Pipeline = "N" 		THEN DO; 
LivingSetter1 = -0.000000596716675177778; 
LivingSetter2 = 0.204270840949990000000; 
LivingSetter3 = 4816.120068758130000000000;
Collar = 883.0615099; 
Cap = 1713.252792; 
END;

ELSE IF HouseholdComp = 'A1D2'  AND Afford4Pipeline = "N" 	 	THEN DO; 
LivingSetter1 = -0.000000644915602248152; 
LivingSetter2 = 0.220770522918186000000; 
LivingSetter3 = 5205.135207118540000000000;
Collar = 954.3895271; 
Cap = 1851.638311; 
END;

ELSE IF HouseholdComp = 'A1D3'  AND Afford4Pipeline = "N" 		THEN DO; 
LivingSetter1 = -0.000000693114529318527; 
LivingSetter2 = 0.237270204886383000000; 
LivingSetter3 = 5594.150345478940000000000;
Collar = 1025.717544; 
Cap = 1990.023829; 
END;

ELSE IF HouseholdComp = 'A2D0'  AND Afford4Pipeline = "N" 		THEN DO; 
LivingSetter1 = -0.000000693698849750767; 
LivingSetter2 = 0.237470232187517000000; 
LivingSetter3 = 5598.866415059960000000000; 
Collar = 1026.582261; 
Cap = 1991.70149; 
END;

ELSE IF (HouseholdComp = 'A2D1' OR HouseholdComp = 'A3D0')	 AND Afford4Pipeline = "N"  THEN DO; 
LivingSetter1 = -0.000000754655018230831; 
LivingSetter2 = 0.258337032654929000000; 
LivingSetter3 = 6090.845671788420000000000;
Collar = 1116.789303; 
Cap = 2166.714742; 
END;

ELSE IF (HouseholdComp = 'A2D2' OR HouseholdComp = 'A3D1' OR HouseholdComp = 'A4D0') AND Afford4Pipeline = "N" 	 THEN DO; 
LivingSetter1 = -0.000000815611186710895;
 LivingSetter2 = 0.279203833122341000000; 
LivingSetter3 = 6582.824928516870000000000; 
Collar = 1206.996345; 
Cap = 2341.727994; 
END;

ELSE IF (HouseholdComp = 'A2D3' OR HouseholdComp = 'A3D2' OR  HouseholdComp = 'A4D1') AND Afford4Pipeline = "N" 		THEN DO; 
LivingSetter1 = -0.000000876567355190958; 
LivingSetter2 = 0.300070633589752000000; 
LivingSetter3 = 7074.804185245330000000000; 
Collar = 1297.203387; 
Cap = 2516.741246; 
END;




/*Living Output Calculation*/
IF Household_GAI > 80000 AND Afford4Pipeline = "Y" THEN
Living_output = ((LivingSetter4*Household_GAI)+LivingSetter5)/12;
ELSE IF Afford4Pipeline = "Y" THEN
Living_output = ((LivingSetter1*Household_GAI*Household_GAI)+(LivingSetter2*Household_GAI)+(LivingSetter3))/12;
ELSE IF Afford4Pipeline = "N" THEN
Living_output = ((LivingSetter1*Household_GAIBuild*Household_GAIBuild)
+(LivingSetter2*Household_GAIBuild)+(LivingSetter3))/12;


/*----------------------------------------------------*/
		RealWageInflation = 0.0340162938349307000;

IF Afford4Pipeline = "N" THEN DO;
	/*Monthly Living Base*/
		SAS_MonthlyLiving = round(Living_output, 0.01);
	/*N13*/

	/*Monthly Living (RCC Factor Inflation Gap)*/
    	SAS_MonthlyLiving2 = round(SAS_MonthlyLiving*1.04887218045113,0.01);
	/*N41*/

	/*Monthly Living (RCC Factor Forward Inflation)*/
		IF Household_GAI <= 30000 THEN 
		SAS_MonthlyLiving3 = round(SAS_MonthlyLiving2*1.02,0.01);
		ELSE
		SAS_MonthlyLiving3 = round(SAS_MonthlyLiving2,0.01);
	/*N42*/

		SAS_MonthlyLiving4 = round(SAS_MonthlyLiving3*
((RealWageInflation*0.4)+1),0.01);

END;


IF Afford1Pipeline = "N" AND Afford2Pipeline = "N" AND Afford4Pipeline = "Y" THEN DO;
	/*Monthly Living Base*/
		SAS_MonthlyLiving = round(Living_output, 0.01);
	/*N13*/

	/*Monthly Living (RCC Factor Inflation Gap)*/
    	SAS_MonthlyLiving3 = round(SAS_MonthlyLiving*1.047,0.01);
	/*N41*/

	/*Monthly Living (RCC Factor Forward Inflation)*/
		IF Household_GAI <= 50000 THEN 
		SAS_MonthlyLiving4 = round(SAS_MonthlyLiving3*1.02,0.01);
		ELSE
		SAS_MonthlyLiving4 = round(SAS_MonthlyLiving3,0.01);
	/*N42*/

END;

IF Afford1Pipeline = "N" AND Afford2Pipeline = "Y" AND Afford4Pipeline = "Y" THEN DO;
	/*Monthly Living Base*/
		SAS_MonthlyLiving = round(Living_output, 0.01);
	/*N13*/

	/*Monthly Living (RCC FACTOR 10% Retired Reduction)*/
	 	/*SAS_MonthlyLiving1=round(SAS_MonthlyLiving,0.01);*/
	/*N14*/

	/*Monthly Living (RCC Factor 10% Reduction DEC21)*/
	/*	SAS_MonthlyLiving2 = round(round(SAS_MonthlyLiving1*0.9,0.01),0.01);*/
	/*N15*/

	/*Monthly Living (RCC Factor Inflation Gap)*/
    	SAS_MonthlyLiving3 = round(SAS_MonthlyLiving*1.047,0.01);
	/*N41*/

	/*Monthly Living (RCC Factor Forward Inflation)*/
		IF Household_GAI <= 30000 THEN 
		SAS_MonthlyLiving4 = round(SAS_MonthlyLiving3*1.02,0.01);
		ELSE
		SAS_MonthlyLiving4 = round(SAS_MonthlyLiving3,0.01);

	/*N42*/
END;

IF Afford1Pipeline = "Y" AND Afford4Pipeline = "Y" THEN DO;
	/*Monthly Living Base*/
		SAS_MonthlyLiving = round(Living_output, 0.01);
	/*N13*/

	/*Monthly Living (RCC Factor 10% Reduction DEC21)*/
		SAS_MonthlyLiving2 = round(round(SAS_MonthlyLiving*0.9,0.01),0.01);
	/*N15*/

	/*Monthly Living (RCC Factor Inflation Gap)*/
    	IF Household_GAI <= 30000 THEN 
    	SAS_MonthlyLiving3 = round(SAS_MonthlyLiving2*1.08,0.01);
    	ELSE IF Household_GAI > 30000 AND Household_GAI <= 60000 THEN 
    	SAS_MonthlyLiving3 = round(SAS_MonthlyLiving2*1.07,0.01);
    	ELSE IF Household_GAI > 60000 THEN 
    	SAS_MonthlyLiving3 = round(SAS_MonthlyLiving2*1.06,0.01);
	/*N41*/

	/*Monthly Living (RCC Factor Forward Inflation)*/
		IF Household_GAI <= 30000 THEN 
		SAS_MonthlyLiving4 = round(SAS_MonthlyLiving3*1.02,0.01);
		ELSE
		SAS_MonthlyLiving4 = round(SAS_MonthlyLiving3,0.01);
	/*N42*/
END;
/*----------------------------------------------------*/

	/*Cap and Collar*/
	SAS_MonthlyLiving5 = MAX(MIN(SAS_MonthlyLiving4, Cap), Collar);

/*Main Residence Uplift Y/N - AUG19*/
IF MainResidenceS9_app="N" THEN	SAS_MonthlyLiving6=round(SAS_MonthlyLiving5*1.2,0.01);
ELSE SAS_MonthlyLiving6=round(SAS_MonthlyLiving5,0.01);

/*------VALIDATION CHECK------*/
DifferencePCvsSASN13 = BaseorOldMGC_N13 - round(SAS_MonthlyLiving); 			/*DataWarehouse Rounds*/
DifferencePCvsSASN15 = LivingpreRCC_N15 - round(SAS_MonthlyLiving2); 			/*DataWarehouse Rounds*/
DifferencePCvsSASN41 = InflationGap_N41 - SAS_MonthlyLiving3;	
DifferencePCvsSASN42 = Inflationforward_N42 - SAS_MonthlyLiving4;	
DifferencePCvsSASN9 = LivingModel_N9 - SAS_MonthlyLiving6;

RUN;

title1 color="purple" underlin=1 'COMPARISON CHECK: Living Expenditure';
title2 italic 'Difference between PC and SAS - Base Living Expenditure';
PROC FREQ 
Data=LivingExpenditure;
Table DifferencePCvsSASN13;
Run;
title1;
title2 italic 'Difference between PC and SAS - PreRCC';
PROC FREQ 
Data=LivingExpenditure;
Table DifferencePCvsSASN15;
Run;
title2 italic 'Difference between PC and SAS - InflationGap';
PROC FREQ 
Data=LivingExpenditure;
Table DifferencePCvsSASN41;
Run;
title2 italic 'Difference between PC and SAS - InflationForward';
PROC FREQ 
Data=LivingExpenditure;
Table DifferencePCvsSASN42;
Run;
title2 italic 'Difference between PC and SAS - Monthly Living Expenditure';
PROC FREQ 
Data=LivingExpenditure;
Table DifferencePCvsSASN9;
Run;

/*------------------------------MONTHLY CREDIT COMMITMENTS (MCC)------------------------------*/
DATA MCC;
SET LivingExpenditure;

/*MCC*/

RevBalPaymt		=MAX((.05*AppsRevolveBal_app),0);

NonrevBalPaymt	=MAX(AppsNonRevolveRepay_app,0);
	
IF SecRegion_app ='SC' THEN HTBPymt=0;
ELSE IF Afford3Pipeline="Y" THEN HTBPymt=MAX((HTBEquityLoan_app*.03)/12, 0);
ELSE HTBPymt=MAX((HTBEquityLoan_app*.0375)/12, 0);

IF AB_Flag=1 AND Debt_ConN152_app >0 THEN DCDebt= (Debt_ConN152_app*0.5)*0.05;
ELSE DCDebt=0;


SAS_MCC=round(RevBalPaymt+NonrevBalPaymt+HTBPymt+DCDebt,.01);

IF Af_Modelnetinc_res <= 0 THEN SAS_DTI = 1;
ELSE SAS_DTI=round((RevBalPaymt+NonrevBalPaymt)/Af_Modelnetinc_res,.0001);

RUN;

/*------------------------------LIFESTYLE EXPENDITURE------------------------------*/
DATA LifestyleExpenditure;
SET MCC;

RealWageInflation = ((1.08455092473664/1.04887218045113)-1);

/*Lifestyle Setter - Coefficients for Lifestyle Expenditure Polynomials*/

IF HouseholdComp = 'A1D0' AND Afford1Pipeline = "Y" AND Afford4Pipeline = "Y"	THEN DO; 
LifeSetter1 = -0.00000048; 
LifeSetter2 = 0.17113736; 
LifeSetter3 = 910.57259708; 
LifeSetter4 = 0.10809119;
LifeSetter5 = 2898.95182279;
END;

ELSE IF HouseholdComp = 'A1D1' AND Afford1Pipeline = "Y" AND Afford4Pipeline = "Y"	THEN DO; 
LifeSetter1 = -0.00000053; 
LifeSetter2 = 0.18796017; 
LifeSetter3 = 1000.08188337; 
LifeSetter4 = 0.11871656;
LifeSetter5 = 3183.91878697;
END;

ELSE IF HouseholdComp = 'A1D2' AND Afford1Pipeline = "Y" AND Afford4Pipeline = "Y"	THEN DO; 
LifeSetter1 = -0.00000056; 
LifeSetter2 = 0.19918678; 
LifeSetter3 = 1059.81544574; 
LifeSetter4 = 0.12580734;
LifeSetter5 = 3374.09002655;
END;

ELSE IF HouseholdComp = 'A1D3' AND Afford1Pipeline = "Y" AND Afford4Pipeline = "Y"	THEN DO; 
LifeSetter1 = -0.0000006; 
LifeSetter2 = 0.21041339; 
LifeSetter3 = 1119.54900811; 
LifeSetter4 = 0.13289812;
LifeSetter5 = 3564.26126612;
END;

ELSE IF HouseholdComp = 'A2D0' AND Afford1Pipeline = "Y" AND Afford4Pipeline = "Y"	THEN DO; 
LifeSetter1 = -0.0000006; 
LifeSetter2 = 0.21099525; 
LifeSetter3 = 1122.64495494; 
LifeSetter4 = 0.13326563;
LifeSetter5 = 3574.11770232;
END;

ELSE IF (HouseholdComp = 'A2D1' OR HouseholdComp = 'A3D0') AND Afford1Pipeline = "Y"  AND Afford4Pipeline = "Y"	THEN DO; 
LifeSetter1 = -0.00000066; 
LifeSetter2 = 0.23173609; 
LifeSetter3 = 1233.00095401;
LifeSetter4 = 0.14636564;
LifeSetter5 = 3925.45347246;
END;

ELSE IF (HouseholdComp = 'A2D2' OR HouseholdComp = 'A3D1' OR HouseholdComp = 'A4D0')AND Afford1Pipeline = "Y" AND Afford4Pipeline = "Y"	THEN DO; 
LifeSetter1 = -0.0000007; 
LifeSetter2 = 0.24557738; 
LifeSetter3 = 1306.64646305; 
LifeSetter4 = 0.15510787;
LifeSetter5 = 4159.91559373;
END;

ELSE IF (HouseholdComp = 'A2D3' OR HouseholdComp = 'A3D2' OR HouseholdComp = 'A4D1')AND Afford1Pipeline = "Y" AND Afford4Pipeline = "Y"	THEN DO; 
LifeSetter1 = -0.00000074; 
LifeSetter2 = 0.25941867; 
LifeSetter3 = 1380.2919721; 
LifeSetter4 = 0.16385009;
LifeSetter5 = 4394.377715;
END;

IF HouseholdComp = 'A1D0' AND Afford1Pipeline = "N" AND Afford4Pipeline = "Y"	THEN DO; 
LifeSetter1 = -0.000000768652645834977; 
LifeSetter2 = 0.217411098458371; 
LifeSetter3 = 1641.75975015675; 
LifeSetter4 = 0.117486254499824;
LifeSetter5 = 4793.23559808016;
END;

ELSE IF HouseholdComp = 'A1D1' AND Afford1Pipeline = "N" AND Afford4Pipeline = "Y"	THEN DO; 
LifeSetter1 = -0.000000854406042805243; 
LifeSetter2 = 0.241666189926364; 
LifeSetter3 = 1824.91982427848; 
LifeSetter4 = 0.130593404361683;
LifeSetter5 = 5327.98459977997;
END;

ELSE IF HouseholdComp = 'A1D2' AND Afford1Pipeline = "N" AND Afford4Pipeline = "Y"	THEN DO; 
LifeSetter1 = -0.000000940159439775509; 
LifeSetter2 = 0.265921281394358; 
LifeSetter3 = 2008.07989840021; 
LifeSetter4 = 0.143700554223541;
LifeSetter5 = 5862.73360147979;
END;

ELSE IF HouseholdComp = 'A1D3' AND Afford1Pipeline = "N" AND Afford4Pipeline = "Y"	THEN DO; 
LifeSetter1 = -0.00000102591283674578; 
LifeSetter2 = 0.290176372862351; 
LifeSetter3 = 2191.23997252194; 
LifeSetter4 = 0.1568077040854;
LifeSetter5 = 6397.48260317962;
END;

ELSE IF HouseholdComp = 'A2D0' AND Afford1Pipeline = "N" AND Afford4Pipeline = "Y"	THEN DO; 
LifeSetter1 = -0.000000913526368313494; 
LifeSetter2 = 0.258388196907818; 
LifeSetter3 = 1951.19450941949; 
LifeSetter4 = 0.139629769027064;
LifeSetter5 = 5696.65261950482;
END;

ELSE IF (HouseholdComp = 'A2D1' OR HouseholdComp = 'A3D0') AND Afford1Pipeline = "N" AND Afford4Pipeline = "Y"	THEN DO; 
LifeSetter1 = -0.00000101544235042749; 
LifeSetter2 = 0.287214827170436; 
LifeSetter3 = 2168.87613484432;
LifeSetter4 = 0.155207321614862;
LifeSetter5 = 6332.18977159704;
END;

ELSE IF (HouseholdComp = 'A2D2' OR HouseholdComp = 'A3D1' OR HouseholdComp = 'A4D0')AND Afford1Pipeline = "N" AND Afford4Pipeline = "Y"	THEN DO; 
LifeSetter1 = -0.00000111735833254149; 
LifeSetter2 = 0.316041457433053; 
LifeSetter3 = 2386.55776026915; 
LifeSetter4 = 0.17078487420266;
LifeSetter5 = 6967.72692368924;
END;

ELSE IF (HouseholdComp = 'A2D3' OR HouseholdComp = 'A3D2' OR HouseholdComp = 'A4D1')AND Afford1Pipeline = "N" AND Afford4Pipeline = "Y"	THEN DO; 
LifeSetter1 = -0.00000121927431465548; 
LifeSetter2 = 0.344868087695671; 
LifeSetter3 = 2604.23938569398; 
LifeSetter4 = 0.186362426790458;
LifeSetter5 = 7603.26407578147;
END;

/*New equations*/

IF HouseholdComp = 'A1D0' AND Afford1Pipeline = "N" AND Afford4Pipeline = "N"	THEN DO; 
LifeSetter1 = -0.000000252229529725610; 
LifeSetter2 = 0.139788138510789000000; 
LifeSetter3 = 1730.950379024350000000000; 
LifeSetterCap 		 = 234.8274532;
LifeSetterCollar 	 = 92.67335067;
LifeSetterCapHDTI    = 410.9480431;
LifeSetterCollarHDTI = 162.1783637;
END;

ELSE IF HouseholdComp = 'A1D1' AND Afford1Pipeline = "N" AND Afford4Pipeline = "N" 	THEN DO; 
LifeSetter1 = -0.000000274393247764245; 
LifeSetter2 = 0.152071493637642000000; 
LifeSetter3 = 1883.051111168200000000000; 
LifeSetterCap = 255.4620295;
LifeSetterCollar = 100.8166716;
LifeSetterCapHDTI = 447.0585516;
LifeSetterCollarHDTI = 176.4291753;
END;

ELSE IF HouseholdComp = 'A1D2' AND Afford1Pipeline = "N" AND Afford4Pipeline = "N" 	THEN DO; 
LifeSetter1 = -0.000000296556965802880; 
LifeSetter2 = 0.164354848764495000000; 
LifeSetter3 = 2035.151843312050000000000; 
LifeSetterCap = 276.0966057;
LifeSetterCollar = 108.9599926;
LifeSetterCapHDTI = 483.16906;
LifeSetterCollarHDTI = 190.679987;
END;

ELSE IF HouseholdComp = 'A1D3' AND Afford1Pipeline = "N" AND Afford4Pipeline = "N" 	THEN DO; 
LifeSetter1 = -0.000000318720683841515; 
LifeSetter2 = 0.176638203891348000000; 
LifeSetter3 = 2187.252575455910000000000; 
LifeSetterCap = 296.7311819;
LifeSetterCollar = 117.1033135;
LifeSetterCapHDTI = 519.2795684;
LifeSetterCollarHDTI = 204.9307987;
END;

ELSE IF HouseholdComp = 'A2D0' AND Afford1Pipeline = "N" AND Afford4Pipeline = "N" 	THEN DO; 
LifeSetter1 = -0.000000304807345848889; 
LifeSetter2 = 0.168927292244419000000; 
LifeSetter3 = 2091.770901688250000000000; 
LifeSetterCap 		 = 283.7777671;
LifeSetterCollar 	 = 111.9913203;
LifeSetterCapHDTI 	 = 496.6110925;
LifeSetterCollarHDTI = 195.9848105;
END;

ELSE IF (HouseholdComp = 'A2D1' OR HouseholdComp = 'A3D0') AND Afford1Pipeline = "N"  AND Afford4Pipeline = "N"	THEN DO; 
LifeSetter1 = -0.000000331591141056567; 
LifeSetter2 = 0.183771140537711000000; 
LifeSetter3 = 2275.577375564930000000000;
LifeSetterCap 		 = 308.7136675;
LifeSetterCollar 	 = 121.8321349;
LifeSetterCapHDTI 	 = 213.2062361;
LifeSetterCollarHDTI = 540.2489181;
END;

ELSE IF (HouseholdComp = 'A2D2' OR HouseholdComp = 'A3D1' OR HouseholdComp = 'A4D0')AND Afford1Pipeline = "N" AND Afford4Pipeline = "N"	THEN DO; 
LifeSetter1 = -0.000000358374936264244; 
LifeSetter2 = 0.198614988831004000000; 
LifeSetter3 = 2459.383849441620000000000;
LifeSetterCap 		 = 333.6495678;
LifeSetterCollar 	 = 131.6729495;
LifeSetterCapHDTI 	 = 230.4276617;
LifeSetterCollarHDTI = 583.8867437;
END;

ELSE IF (HouseholdComp = 'A2D3' OR HouseholdComp = 'A3D2' OR HouseholdComp = 'A4D1')AND Afford1Pipeline = "N" AND Afford4Pipeline = "N"	THEN DO; 
LifeSetter1 = -0.000000385158731471921; 
LifeSetter2 = 0.213458837124296000000; 
LifeSetter3 = 2643.190323318310000000000; 
LifeSetterCap 		 = 358.5854681;
LifeSetterCollar 	 = 141.5137642;
LifeSetterCapHDTI 	 = 247.6490873;
LifeSetterCollarHDTI = 627.5245693;
END;





/*Living Output Calculation*/
IF  Afford1Pipeline = "Y" AND Afford4Pipeline = "Y" AND Household_GAI > 80000 THEN 
Lifestyle_output = (((LifeSetter4*Household_GAI)+LifeSetter5)/12)*.10;
ELSE 
Lifestyle_output = (((LifeSetter1*Household_GAI*Household_GAI)+(LifeSetter2*Household_GAI)+LifeSetter3)/12)*.10;


IF  Afford1Pipeline = "N" AND Afford4Pipeline = "Y" AND Household_GAI > 80000 THEN 
Lifestyle_output1 = (((LifeSetter4*Household_GAI)+LifeSetter5)/12)*.05;
ELSE 
Lifestyle_output1 = (((LifeSetter1*Household_GAI*Household_GAI)+(LifeSetter2*Household_GAI)+LifeSetter3)/12)*.05;


IF  Afford1Pipeline = "N" AND Afford4Pipeline = "Y"  AND Household_GAI > 80000 THEN 
Lifestyle_output2 = (((LifeSetter4*Household_GAI)+LifeSetter5)/12)*.15;
ELSE 
Lifestyle_output2 = (((LifeSetter1*Household_GAI*Household_GAI)+(LifeSetter2*Household_GAI)+LifeSetter3)/12)*.15;

IF Afford4Pipeline = "N" THEN
Lifestyle_output2 = (((LifeSetter1*Household_GAIBuild*Household_GAIBuild)
+(LifeSetter2*Household_GAIBuild)+LifeSetter3)/12)*.35;
IF Afford4Pipeline = "N" THEN
Lifestyle_output3 = (((LifeSetter1*Household_GAIBuild*Household_GAIBuild)
+(LifeSetter2*Household_GAIBuild)+LifeSetter3)/12)*.20;

Lifestyle_output2_1 = round(Lifestyle_output2*1.049,0.01);
Lifestyle_output3_1 = round(Lifestyle_output3*1.049,0.01);

Lifestyle_output2_2 = round(Lifestyle_output2_1*((RealWageInflation*0.4)+1),0.01);
Lifestyle_output3_2 = round(Lifestyle_output3_1*((RealWageInflation*0.4)+1),0.01);


Lifestyle_output2_3 = MAX(MIN(Lifestyle_output2_2, LifeSetterCapHDTI), LifeSetterCollarHDTI);
Lifestyle_output3_3 = MAX(MIN(Lifestyle_output3_2, LifeSetterCap), LifeSetterCollar);


IF SAS_DTI < 0.15 and Afford1Pipeline = "Y" THEN
    Lifestyle_output4 = 0;
ELSE IF Afford1Pipeline = "Y" AND Afford4Pipeline = "Y" AND SAS_DTI >= 0.205 THEN
    Lifestyle_output4 = Lifestyle_output;
ELSE IF Afford1Pipeline = "N" AND Afford4Pipeline = "Y" AND SAS_DTI > 0.205 THEN
    Lifestyle_output4 = Lifestyle_output2;
ELSE IF Afford1Pipeline = "N" AND Afford4Pipeline = "Y" AND SAS_DTI >= 0.15 THEN
    Lifestyle_output4 = Lifestyle_output1;
ELSE IF Afford1Pipeline = "N" AND Afford4Pipeline = "Y" THEN
    Lifestyle_output4 = 0;
/*else IF Afford1Pipeline = "Y" AND Afford4Pipeline = "N"  THEN*/
/*    Lifestyle_output4 = Lifestyle_output;*/
ELSE IF Afford4Pipeline = "N" AND SAS_DTI > 0.205 THEN
    Lifestyle_output4 = Lifestyle_output2_3;
ELSE 
    Lifestyle_output4 = Lifestyle_output3_3;

/*Modelled Lifestyle*/
SAS_MonthlyLife = round(Lifestyle_output4,0.01);


/*------VALIDATION CHECK------*/
DifferencePCvsSASN10 = LifestyleModel_N10 - SAS_MonthlyLife;

RUN;
title1 color="purple" underlin=1 'COMPARISON CHECK: Lifestyle Expenditure';
title2 italic 'Difference between PC and SAS';
PROC FREQ 
Data=LifestyleExpenditure;
Table DifferencePCvsSASN10;
Run;
/*------------------------------MODELLED OUTGOINGS------------------------------*/
DATA ModelledOutgoings;
SET LifestyleExpenditure;

SAS_ModelledOutgoings = sum(AppsOtherExpenditure_app,SO_RentN48_app,SAS_MCC,SAS_MonthlyLiving6,SAS_MonthlyLife);

/*------VALIDATION CHECK------*/
DiffPCvsSASModelledOutgoings = ROUND(	Af_Modeloutgoings_res - SAS_ModelledOutgoings, 0.01);

RUN;
title1 color="purple" underlin=1 'COMPARISON CHECK: Modelled Outgoings';
title2 italic 'Difference between PC and SAS';
PROC FREQ 
Data=ModelledOutgoings;
Table DiffPCvsSASModelledOutgoings;
Run;
/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*------------------------------EFFECTIVE DISPOSABLE INCOME (EDI)------------------------------*/
/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
DATA EDI;
SET ModelledOutgoings;

/*SAS EDI*/
SAS_EDI = round(Household_NMI - SAS_ModelledOutgoings, 0.01);

/*------VALIDATION CHECK------*/
DiffPCvsSASEDI = Af_Edi_res - SAS_EDI;

RUN;
title1 color="purple" underlin=1 'COMPARISON CHECK: Effective Disposable Income (EDI)';
title2 italic 'Difference between PC and SAS';
PROC FREQ 
Data=EDI;
Table DiffPCvsSASEDI;
Run;
/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*------------------------------STRESSED MORTGAGE AMOUNT------------------------------*/
/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
DATA StressedMortgage;
SET EDI;

/*Terms*/
NewTerm1=Ceil(TermInMths_app/12);
NewTerm=MIN(NewTerm1, 40);
PrimTerm1=Ceil(SBSNonBTLMortgagesTerm_app/12);
PrimTerm=MIN(PrimTerm1, 40);

IF TrackRecordFlag_S11 = "Y" AND NewTerm > 40 THEN NewTerm = 40;

/*Repayment Amount 1*/
IF part1_reptype_app= 1 OR part1_reptype_app= 0 THEN SAS_Rep1 = part1_LoanAmt_app;
ELSE IF part1_reptype_app=3 THEN 
	IF part2_reptype_app=0 OR part2_reptype_app=1 THEN SAS_Rep1 = part1_LoanAmt_app - IntOnlyAmt_app;
	ELSE IF part2_reptype_app=2 THEN SAS_Rep1 = part1_LoanAmt_app + part2_LoanAmt_app - IntOnlyAmt_app;
	ELSE IF part2_reptype_app=3 THEN SAS_Rep1 = (part1_LoanAmt_app - IntOnlyAmt_app * part1_LoanAmt_app)/SUM(part1_LoanAmt_app, part2_LoanAmt_app);
	ELSE SAS_Rep1 = 0;
ELSE SAS_Rep1 = 0;
/*Repayment Amount 2*/
IF part2_reptype_app= 1 OR part2_reptype_app= 0 THEN SAS_Rep2 = part2_LoanAmt_app;
ELSE IF part2_reptype_app=3 THEN 
	IF part1_reptype_app=0 OR part1_reptype_app=1 THEN SAS_Rep2 = part2_LoanAmt_app - IntOnlyAmt_app;
	ELSE IF part1_reptype_app=2 THEN SAS_Rep2 = part2_LoanAmt_app + part1_LoanAmt_app - IntOnlyAmt_app;
	ELSE IF part1_reptype_app=3 THEN SAS_Rep2 = (part2_LoanAmt_app - IntOnlyAmt_app * part2_LoanAmt_app)/SUM(part1_LoanAmt_app, part2_LoanAmt_app);
	ELSE SAS_Rep2 = 0;
ELSE SAS_Rep2 = 0;

/*Interest Only Amount 1*/
IF part1_reptype_app = 2 THEN SAS_Io1 = part1_LoanAmt_app;
	ELSE IF part1_reptype_app=3 THEN 
	IF part2_reptype_app=0 OR part2_reptype_app=1 THEN SAS_Io1 = IntOnlyAmt_app;
	ELSE IF part2_reptype_app=2 THEN SAS_Io1 = IntOnlyAmt_app - part2_LoanAmt_app;
	ELSE IF part2_reptype_app=3 THEN SAS_Io1 = (IntOnlyAmt_app * part1_LoanAmt_app)/SUM(part1_LoanAmt_app, part2_LoanAmt_app);
	ELSE SAS_Io1 = 0;
ELSE SAS_Io1 = 0;
/*Interest Only Amount 2*/
IF part2_reptype_app = 2 THEN SAS_Io2 = part2_LoanAmt_app;
	ELSE IF part2_reptype_app=3 THEN 
	IF part1_reptype_app=0 OR part1_reptype_app=1 THEN SAS_Io2 = IntOnlyAmt_app;
	ELSE IF part1_reptype_app=2 THEN SAS_Io2 = IntOnlyAmt_app - part1_LoanAmt_app;
	ELSE IF part1_reptype_app=3 THEN SAS_Io2 = (IntOnlyAmt_app * part2_LoanAmt_app)/SUM(part1_LoanAmt_app, part2_LoanAmt_app);
	ELSE SAS_Io2 = 0;
ELSE SAS_Io2 = 0;

/*Totals*/
SAS_Ioamt = SUM(SAS_Io1, SAS_Io2);
SAS_Repamt = SUM(SAS_Rep1, SAS_Rep2);
/*//*MortgageFeesN8_app*/
SAS_Secdebtamt = AppsSecDebtAmt_app;
SAS_SBSPrimamt = SBSNonBTLMortgagesBalance_app;

/*Stresses to apply*/
IF Afford4Pipeline = 'N' THEN SBSPrimStressRate = 7.1;
IF Afford4Pipeline = 'N' THEN OtherStressRate 	= 7.1;

IF (Afford4Pipeline = 'N' and LTV_app<=60) THEN ResiStressRate = 6.4;
ELSE IF (Afford4Pipeline = 'N' and LTV_app<=85) THEN ResiStressRate = 6.6;
ELSE IF (Afford4Pipeline = 'N' and LTV_app<=95) THEN ResiStressRate = 6.9;
ELSE IF (Afford4Pipeline = 'N' and LTV_app>95)  THEN ResiStressRate = 7.1;

IF (Afford4Pipeline = 'N' and LTV_app<=60) THEN IOStressRate = 6.4;
ELSE IF (Afford4Pipeline = 'N' and LTV_app<=85) THEN IOStressRate = 6.6;
ELSE IF (Afford4Pipeline = 'N' and LTV_app<=95) THEN IOStressRate = 6.9;
ELSE IF (Afford4Pipeline = 'N' and LTV_app>95) THEN 	IOStressRate = 7.1;

ResiStressRate     = max(Rateplus1,ResiStressRate);   
IOStressRate       = max(Rateplus1,IOStressRate);     
SBSPrimStressRate  = max(Rateplus1,SBSPrimStressRate);
OtherStressRate    = max(Rateplus1,OtherStressRate); 

IF (Afford4Pipeline = 'Y' AND ResiStress1Pipeline = "N") THEN ResiStressRate = 7.54;
IF (Afford4Pipeline = 'Y' AND ResiStress1Pipeline = "N") THEN IOStressRate = 7.54;
IF (Afford4Pipeline = 'Y' AND ResiStress1Pipeline = "N") THEN SBSPrimStressRate = 7.54;
IF (Afford4Pipeline = 'Y' AND ResiStress1Pipeline = "N") THEN OtherStressRate = 7.54;

IF (Afford4Pipeline = 'Y' AND Longstress = 1 AND ResiStress1Pipeline = "N")  THEN ResiStressRate = 7.54;
IF (Afford4Pipeline = 'Y' AND Longstress = 1 AND ResiStress1Pipeline = "N") THEN IOStressRate = 7.54;
IF (Afford4Pipeline = 'Y' AND Longstress = 1 AND ResiStress1Pipeline = "N") THEN SBSPrimStressRate = 7.54;
IF (Afford4Pipeline = 'Y' AND Longstress = 1 AND ResiStress1Pipeline = "N") THEN OtherStressRate = 7.54;


IF (Afford4Pipeline = 'Y' AND ResiStress1Pipeline = "Y") THEN ResiStressRate = 7.54;
IF (Afford4Pipeline = 'Y' AND ResiStress1Pipeline = "Y") THEN IOStressRate = 7.54;
IF (Afford4Pipeline = 'Y' AND ResiStress1Pipeline = "Y") THEN SBSPrimStressRate = 7.54;
IF (Afford4Pipeline = 'Y' AND ResiStress1Pipeline = "Y") THEN OtherStressRate = 7.54;

/*IF (Afford4Pipeline = 'Y' AND Threetier = 1 AND Longstress = 0 AND ResiStress1Pipeline = "Y") THEN */
/*ResiStressRate = 7.24;*/
/*IF (Afford4Pipeline = 'Y' AND Threetier = 1 AND Longstress = 0 AND ResiStress1Pipeline = "Y")  THEN */
/*IOStressRate = 7.24;*/
/*IF (Afford4Pipeline = 'Y' AND Threetier = 1 AND Longstress = 0 AND ResiStress1Pipeline = "Y")   THEN */
/*SBSPrimStressRate = 7.24;*/
/*IF (Afford4Pipeline = 'Y' AND Threetier = 1 AND Longstress = 0 AND ResiStress1Pipeline = "Y")   THEN */
/*OtherStressRate = 7.24; */
/**/
/*IF (Afford4Pipeline = 'Y' AND Threetier = 0 AND Longstress = 1 AND ResiStress1Pipeline = "Y")  THEN */
/*ResiStressRate = 6.79;*/
/*IF (Afford4Pipeline = 'Y' AND Threetier = 0 AND Longstress = 1 AND ResiStress1Pipeline = "Y")   THEN */
/*IOStressRate = 6.79;*/
/*IF (Afford4Pipeline = 'Y' AND Threetier = 0 AND Longstress = 1 AND ResiStress1Pipeline = "Y")   THEN */
/*SBSPrimStressRate = 6.79;*/
/*IF (Afford4Pipeline = 'Y' AND Threetier = 0 AND Longstress = 1 AND ResiStress1Pipeline = "Y")  THEN */
/*OtherStressRate = 6.79;*/
/**/
/*IF (Afford4Pipeline = 'Y' AND Threetier = 1 AND Longstress = 1 AND ResiStress1Pipeline = "Y")   THEN */
/*ResiStressRate = 6.79;*/
/*IF (Afford4Pipeline = 'Y' AND Threetier = 1 AND Longstress = 1 AND ResiStress1Pipeline = "Y")   THEN */
/*IOStressRate = 6.79;*/
/*IF (Afford4Pipeline = 'Y' AND Threetier = 1 AND Longstress = 1 AND ResiStress1Pipeline = "Y")   THEN */
/*SBSPrimStressRate = 6.79;*/
/*IF (Afford4Pipeline = 'Y' AND Threetier = 1 AND Longstress = 1 AND ResiStress1Pipeline = "Y")   THEN */
/*OtherStressRate = 6.79;*/




/*Coefficient Calc (Resi)*/
ResiRateFreq = INT((ResiStressRate/1200)*1000000)/1000000;
ResiCoX = INT((1+(ResiStressRate/1200))*1000000)/1000000;
ResiCoY = INT(NewTerm*12*1000000)/1000000;
ResiCoZ = INT((ResiCoX**(ResiCoY))*1000000)/1000000;
ResiCoQ = INT((1/ResiCoZ)*1000000)/1000000;
ResiCoP = INT((1-ResiCoQ)*1000000)/1000000;

ResiCoeff = INT(((ResiStressRate/1200)/ResiCoP)*1000000)/1000000;

/*Coefficient Calc (Interest Only)*/
IoRateFreq = INT((IOStressRate/1200)*1000000)/1000000;
IoCoX = INT((1+(IOStressRate/1200))*1000000)/1000000;				
IoCoY = INT(300*1000000)/1000000;									/*<------------------------Fixed at 25 Years*/
IoCoZ = INT((IoCoX**(IoCoY))*1000000)/1000000;
IoCoQ = INT((1/IoCoZ)*1000000)/1000000;
IoCoP = INT((1-IoCoQ)*1000000)/1000000;

IoCoeff = INT(((IOStressRate/1200)/IoCoP)*1000000)/1000000;

/*Coefficient Calc (Fees)*/
IF SAS_Repamt > 0 THEN Termfee = NewTerm; 
ELSE Termfee = 25;

FeeRateFreq = INT((ResiStressRate/1200)*1000000)/1000000;
FeeCoX = INT((1+(ResiStressRate/1200))*1000000)/1000000;
FeeCoY = INT(Termfee*12*1000000)/1000000;
FeeCoZ = INT((FeeCoX**(FeeCoY))*1000000)/1000000;
FeeCoQ = INT((1/FeeCoZ)*1000000)/1000000;
FeeCoP = INT((1-FeeCoQ)*1000000)/1000000;

FeeCoeff = INT(((ResiStressRate/1200)/FeeCoP)*1000000)/1000000;

/*Coefficient Calc (OtherMort)*/
OthRateFreq = INT((OtherStressRate/1200)*1000000)/1000000;
OthCoX = INT((1+(OtherStressRate/1200))*1000000)/1000000;
OthCoY = INT(300*1000000)/1000000;									/*<------------------------Fixed at 25 Years, Used for AHL/NYM*/
OthCoZ = INT((OthCoX**(OthCoY))*1000000)/1000000;
OthCoQ = INT((1/OthCoZ)*1000000)/1000000;
OthCoP = INT((1-OthCoQ)*1000000)/1000000;

OthCoeff = INT(((OtherStressRate/1200)/OthCoP)*1000000)/1000000;

/*Coefficient Calc (SBSPrim)*/
IF SAS_Repamt = 0 OR ApplicationType_app IN ('B1', 'D2', 'PA') THEN TermPrim = 25;
ELSE IF PrimTerm > 0 THEN TermPrim = PrimTerm;
ELSE IF PrimTerm = 0 THEN TermPrim = 1;
ELSE TermPrim = 25;

PrimRateFreq = INT((SBSPrimStressRate/1200)*1000000)/1000000;
PrimCoX = INT((1+(SBSPrimStressRate/1200))*1000000)/1000000;
PrimCoY = INT(TermPrim*12*1000000)/1000000;							/*<------------------------Fixed at 25 Years or Primary Loan Term if non-IO*/
PrimCoZ = INT((PrimCoX**(PrimCoY))*1000000)/1000000;
PrimCoQ = INT((1/PrimCoZ)*1000000)/1000000;
PrimCoP = INT((1-PrimCoQ)*1000000)/1000000;

/*IF ApplicationType_app = 'CV' AND BTLFlag = 1 AND PrimTerm = 0 AND ABAmtAllLoans_app = SAS_SBSPrimamt AND part1_reptype_app ^= 2 THEN PrimCoeff = 0;
ELSE */PrimCoeff = INT(((SBSPrimStressRate/1200)/PrimCoP)*1000000)/1000000; /*<------------------------Consent to Let work around*/

/*Stressed Mortgage Sum*/
SAS_StressedMort = 	round((SAS_Ioamt*IoCoeff) + 
					(SAS_Repamt*ResiCoeff) + 
					(MortgageFeesN8_app*FeeCoeff) +
					(SAS_Secdebtamt*OthCoeff) + 
					(SAS_SBSPrimamt*PrimCoeff),0.01);

/*------VALIDATION CHECK------*/
DiffPCvsSASStressedMort = round(Af_Stressmortrepay_res - SAS_StressedMort, 0.01);

/*------RESET MISSING REPAYMENT VALS/TYPES/TERMS------*/
IF SAS_StressedMort = . THEN SAS_StressedMort = ABAmtAllLoans_app;
ELSE SAS_StressedMort = SAS_StressedMort;

RUN;
title1 color="purple" underlin=1 'COMPARISON CHECK: Stressed Mortgages';
title2 italic 'Difference between PC and SAS';
PROC FREQ 
Data=StressedMortgage;
Table DiffPCvsSASStressedMort;
Run;
/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*------------------------------AFFORDABILITY------------------------------*/
/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
DATA TotalAffordability;
SET StressedMortgage;

IF SAS_EDI < 0 THEN SAS_Affordability = 999.99;
ELSE IF SAS_StressedMort = 0 THEN SAS_Affordability = 0;
ELSE SAS_Affordability = round(100*(SAS_StressedMort/SAS_EDI), 0.01);

/*------VALIDATION CHECK------*/
DiffPCvsSASAff = round(Af_Affordability_res - SAS_Affordability, 0.01);

/*Resetting Parabolic Affordability scores*/
IF DiffPCvsSASAff > 5 AND Af_Affordability_res > 5000 AND SAS_Affordability > 5000 THEN DiffPCvsSASAff = 0;
ELSE IF DiffPCvsSASAff < -5 AND Af_Affordability_res > 5000 AND SAS_Affordability > 5000 THEN DiffPCvsSASAff = 0;
ELSE DiffPCvsSASAff = DiffPCvsSASAff;


App1_RetirementAge = Min(71,App1_RetirementAge);
App2_RetirementAge = Min(71,App2_RetirementAge);
App3_RetirementAge = Min(71,App3_RetirementAge);
App4_RetirementAge = Min(71,App4_RetirementAge);

/*CONVERT DATA INTO DOB DATE FORMAT*/

if not missing(App1_DOB) then App1_DOB_DT = input(substr(App1_DOB,1,8), yymmdd8.);
format App1_DOB_DT date9.;


if not missing(App1_DOB) then App2_DOB_DT = input(substr(App2_DOB,1,8), yymmdd8.);
format App2_DOB_DT date9.;


if not missing(App1_DOB) then App4_DOB_DT = input(substr(App3_DOB,1,8), yymmdd8.);
format App3_DOB_DT date9.;


if not missing(App1_DOB) then App4_DOB_DT = input(substr(App4_DOB,1,8), yymmdd8.);
format App4_DOB_DT date9.;


IF AB_Flag=1 OR ApplicationType_app = "C1" OR ApplicationType_app = "B1" OR ApplicationType_app = "CV" THEN
App_Date = AppCreatedDate1; 
ELSE App_Date = PipelineDate;

FORMAT App_Date yymmdd10.;

/*WORK OUT AGE AT TERM END FOR ALL APPLICANTS*/

IF App1PrePenGAI > 0 THEN
App1_Age_Te = yrdif(App1_DOB_DT, App_Date, 'AGE') + TermInMths_app/12;
ELSE App1_Age_Te = 0;

IF App2PrePenGAI > 0 THEN
App2_Age_Te = yrdif(App2_DOB_DT, App_Date, 'AGE') + TermInMths_app/12;
ELSE App2_Age_Te = 0;

IF App3PrePenGAI > 0 THEN
App3_Age_Te = yrdif(App3_DOB_DT, App_Date, 'AGE') + TermInMths_app/12;
ELSE App3_Age_Te = 0;

IF App4PrePenGAI > 0 THEN
App4_Age_Te = yrdif(App4_DOB_DT, App_Date, 'AGE') + TermInMths_app/12;
ELSE App4_Age_Te = 0;



IF (UseOfProperty_app = 5 OR PurchaseType_app = "JBSPP" OR PurchaseType_app = "JBSPR") THEN isJBSP ="Y";
ELSE isJBSP = "N";

IF
(App1_NonProprietor = "Y" AND App1_Age_Te>=76 AND App1_EmpType_app ne "R")OR
(App2_NonProprietor= "Y" AND App2_Age_Te>=76 AND App2_EmpType_app ne "R")OR
(App3_NonProprietor= "Y" AND App3_Age_Te>=76 AND App3_EmpTypeS11_app ne "R")OR
(App4_NonProprietor= "Y" AND App4_Age_Te>=76 AND App4_EmpTypeS13_app ne "R")
then 
isJBSP_Old_Non_Proprietor = "Y";
ELSE isJBSP_Old_Non_Proprietor = "N";


JBSP_LTI_Income1 = 0;
JBSP_LTI_Income2 = 0;
JBSP_LTI_Income3 = 0;
JBSP_LTI_Income4 = 0;


IF isJBSP = "Y"   AND  isJBSP_Old_Non_Proprietor="Y"  AND App1_NonProprietor = "N"    
THEN JBSP_LTI_Income1 =  App1PrePenGAI;

IF isJBSP = "Y"  AND  isJBSP_Old_Non_Proprietor="Y" AND  App2_NonProprietor = "N"   
THEN JBSP_LTI_Income2 =  App2PrePenGAI; 

IF isJBSP = "Y"   AND  isJBSP_Old_Non_Proprietor="Y"  AND  App3_NonProprietor = "N"   
THEN JBSP_LTI_Income3 =  App3PrePenGAI; 

IF isJBSP = "Y"   AND  isJBSP_Old_Non_Proprietor="Y" AND  App4_NonProprietor = "N"   
THEN JBSP_LTI_Income4 =  App4PrePenGAI ;


JBSP_LTI_Income = sum(
    JBSP_LTI_Income1,
    JBSP_LTI_Income2,
    JBSP_LTI_Income3,
    JBSP_LTI_Income4);


Max_JBSP_LTI_Loan  = 6.5 *  JBSP_LTI_Income;

IF JBSP_LTI_Income>0 THEN JBSP_LTI = TotalLoanAmount_app/JBSP_LTI_Income;
ELSE JBSP_LTI =0;


RUN;
title1 color="purple" underlin=1 'COMPARISON CHECK: Affordability';
title2 italic 'Difference between PC and SAS';
PROC FREQ 
Data=TotalAffordability;
Table DiffPCvsSASAff;
Run;
/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*------------------------------MAX LOAN/TERM/LTI OPTIONS------------------------------*/
/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
DATA Alternatives;
SET TotalAffordability;

/*Affordability Cut-Off*/
IF TrackRecordFlag_S11 = "Y" THEN AffCutoff = 0.95;
ELSE AffCutoff = 1;

/*Max LTI*/


/* LISA */
IF LISAFlag = 1 THEN SAS_MaxLTI = 6;

/* LTV */
IF ROUND(LTV_app,0.01) <= 90 THEN SAS_MaxLTI = 5.5;

IF ROUND(LTV_app,0.01) > 90 THEN SAS_MaxLTI = 5;

IF ROUND(LTV_app,0.01) > 95 THEN SAS_MaxLTI = 4.49;

IF LTIChangePipeline = "N"
AND LTIChange1Pipeline = "N"
AND LTIChange2Pipeline = "N"
AND LTIChange3Pipeline = "Y"
AND ROUND(LTV_app,0.01) > 95
THEN SAS_MaxLTI = 5;

/* Income */
IF LTIChange1Pipeline = "N"
AND NbrOfAppls_app > 1
AND PrePensionHousehold_GAI < 60000
THEN SAS_MaxLTI = 4.49;

IF NbrOfAppls_app = 1
AND PrePensionHousehold_GAI < 40000
THEN SAS_MaxLTI = 4.49;

IF LTIChange1Pipeline = "Y"
AND PrePensionHousehold_GAI < 40000
THEN SAS_MaxLTI = 4.49;

/* DTI */
IF LTIChangePipeline = "N"
AND SAS_DTI > 0.10
THEN SAS_MaxLTI = 4.49;


/*IF 		LISAFlag = 0 AND LTIChangePipeline = "N" AND SAS_DTI >0.10 THEN SAS_MaxLTI = 4.49;
ELSE IF LISAFlag = 0 AND LTIChange1Pipeline = "Y"  AND PrePensionHousehold_GAI <40000 THEN SAS_MaxLTI = 4.49;
ELSE IF LISAFlag = 0 AND LTIChange1Pipeline = "N" AND LTIChange2Pipeline = "Y"  AND NbrOfAppls_app = 1 AND PrePensionHousehold_GAI <40000 THEN SAS_MaxLTI = 4.49;
ELSE IF LISAFlag = 0 AND Afford4Pipeline    = "Y"  AND NbrOfAppls_app = 1 AND PrePensionHousehold_GAI <50000 THEN SAS_MaxLTI = 4.49;
ELSE IF LISAFlag = 0 AND Afford4Pipeline    = "N"  AND NbrOfAppls_app = 1 AND PrePensionHousehold_GAI <40000 THEN SAS_MaxLTI = 4.49;
ELSE IF LISAFlag = 0 AND LTIChange1Pipeline = "N" AND NbrOfAppls_app > 1 AND PrePensionHousehold_GAI <60000 THEN SAS_MaxLTI = 4.49;
/*ELSE IF LISAFlag = 0 AND LTIChange1Pipeline = "N" AND Afford4Pipeline = "Y" AND NbrOfAppls_app = 1 AND PrePensionHousehold_GAI <50000 THEN SAS_MaxLTI = 4.49;*/
/*ELSE IF LISAFlag = 0 AND ROUND(LTV_app, 0.01) > 95 THEN SAS_MaxLTI = 4.49;
ELSE IF LISAFlag = 0 AND ROUND(LTV_app, 0.01) > 90 And Afford4Pipeline    = "Y" THEN SAS_MaxLTI = 4.49; 
ELSE IF LISAFlag = 0 AND ROUND(LTV_app, 0.01) > 90 AND ROUND(LTV_app, 0.01) <= 95 And Afford4Pipeline    = "N"  THEN SAS_MaxLTI = 5;
ELSE IF LISAFlag = 0 AND ROUND(LTV_app, 0.01) <= 90 THEN SAS_MaxLTI = 5.5;
ELSE SAS_MaxLTI = 6;*/

/*LTIMaxLoan = floor((SAS_MaxLTI*PrePensionHousehold_GAI)/100)*100;*/
LTIMaxLoan = SAS_MaxLTI*PrePensionHousehold_GAI;

/*Affordability Max Loan*/
/*OtherMortRepay = floor(((SAS_Secdebtamt*OthCoeff) + (SAS_SBSPrimamt*PrimCoeff))/100)*100;*/

OtherMortRepay = (SAS_Secdebtamt*OthCoeff) + (SAS_SBSPrimamt*PrimCoeff);

/*New Mtg*/

IF SAS_Repamt=0 THEN AffordMaxLoan = floor((((AffCutoff*SAS_EDI-OtherMortRepay)/IoCoeff)-MortgageFeesN8_app)/100)*100;
ELSE AffordMaxLoan = floor((((AffCutoff*SAS_EDI-OtherMortRepay)/ResiCoeff)-MortgageFeesN8_app)/100)*100;

IF AffordMaxLoan <0 THEN
AffordMaxLoan = 0;


/*Max Loan*/


/*RawMaxLoan_PreRound =
    (((AffCutoff*SAS_EDI-OtherMortRepay)/IoCoeff)-MortgageFeesN8_app);*/


IF (AB_Flag = 1 OR ApplicationType_app = "FW") AND isJBSP_Old_Non_Proprietor = "N" THEN
    RawMaxLoanAB = floor((LTIMaxLoan - (ABAmtAllLoans_app - TotalLoanAmount_app)) / 100) * 100;

IF AB_Flag=0 AND isJBSP_Old_Non_Proprietor = "N" THEN
RawMaxLoan = floor(min( LTIMaxLoan, AffordMaxLoan)/100)*100;

IF AB_Flag=1 AND isJBSP_Old_Non_Proprietor = "N" THEN
RawMaxLoan = floor(min( AffordMaxLoan,RawMaxLoanAB)/100)*100;

/*JBSP*/


IF (AB_Flag = 1 OR ApplicationType_app = "FW") AND isJBSP = "Y" and isJBSP_Old_Non_Proprietor = "Y" THEN
    RawMaxLoanAB = floor( (min(LTIMaxLoan,Max_JBSP_LTI_Loan) - (ABAmtAllLoans_app - TotalLoanAmount_app)) / 100) * 100;

IF AB_Flag = 0  AND isJBSP = "Y" and isJBSP_Old_Non_Proprietor = "Y" THEN
    RawMaxLoan = floor( (min(LTIMaxLoan,Max_JBSP_LTI_Loan,AffordMaxLoan)) / 100) * 100;

IF AB_Flag = 1 AND isJBSP = "Y" and isJBSP_Old_Non_Proprietor = "Y" THEN
RawMaxLoan = floor(min(AffordMaxLoan,RawMaxLoanAB,Max_JBSP_LTI_Loan)/100)*100;


IF TrackRecordFlag_S11 = "Y" AND InterestRateN130_app >0 AND SOFlag=1 THEN
TRMaxLoan = floor(((TRRentN129_app*1.50-SO_RentN48_app)*(1-(1+((InterestRateN130_app/100)/12))**- TermInMths_app))/((InterestRateN130_app/100)/12)/100)*100;
IF TrackRecordFlag_S11 = "Y" AND InterestRateN130_app >0 AND SOFlag=0 THEN
TRMaxLoan = floor(((TRRentN129_app*1.50)*(1-(1+((InterestRateN130_app/100)/12))**- TermInMths_app))/((InterestRateN130_app/100)/12)/100)*100;



IF TrackRecordFlag_S11 = "Y" AND InterestRateN130_app >0 THEN
RawMaxLoan = min( RawMaxLoan,TRMaxLoan);

IF SAS_EDI =<0 THEN
RawMaxLoan = 0;

IF RawMaxLoan <0 THEN
RawMaxLoan = 0;

/*IF RawMaxLoan > LTIMaxLoan THEN
RawMaxLoan = floor(LTIMaxLoan/100)*100;*/

IF ApplicationType_app in ("CV","D1") THEN
RawMaxLoan = floor(TotalLoanAmount_app);

IF BTLFlag=1 THEN
RawMaxLoan = Loan1_res;





/*------VALIDATION CHECK------*/
DiffPCvsMaxLoan = round(Loan1_res - RawMaxLoan, 0.01);
/*DiffPCvsMaxLoan_PreOther= round(Loan1_res - RawMaxLoan1, 0.01);*/

DiffPCvsLTISAS = LTIPC - SAS_MaxLTI;


/*Alternative Term*/

/*Coefficient*/
/*IF BTLFlag=0 OR ApplicationType_app not in ("CV","D1")  THEN*/
AltMortRepay	 = 	round((SAS_Ioamt*IoCoeff) + 
					(SAS_Secdebtamt*OthCoeff) + 
					(SAS_SBSPrimamt*PrimCoeff),0.01);

/*Alternative Term Coeff*/
IF BTLFlag=0 OR ApplicationType_app not in ("CV","D1")  THEN
IF SAS_Repamt >0 THEN
altcoeff = (AffCutoff*SAS_EDI-AltMortRepay)/(SAS_Repamt+MortgageFeesN8_app);
ELSE
altcoeff = 0;

altcoeff = FLOOR(altcoeff*1000000)/1000000;

IF BTLFlag=0 OR ApplicationType_app not in ("CV","D1")  THEN
IF SAS_Repamt >0 THEN
altterm1 = (log(1/(1-((ResiStressRate/1200)/altcoeff)))/log(ResiCoX))/12;
ELSE
altterm1 = 0;
rawdiff = round(AlternativeTerm_N1 - altterm1, 0.00001);
IF round(AlternativeTerm_N1 - altterm1, 0.00001) < 0 THEN altterm = FLOOR(altterm1);
ELSE altterm = CEIL(altterm1);




/* Term greater than 10years */
IF altterm > (NewTerm+10) AND ApplicationType_app not in ("W","FW") THEN
altterm = 0;




/* Not exceeded LTI on ABs*/
IF ABAmtAllLoans_app > LTIMaxLoan THEN
altterm = 0;





IF RawMaxLoan >= LTIMaxLoan THEN   /*ERROR IS HERE*/
altterm = 0;


/*Part & Part limited to 25 years*/
IF SAS_Repamt > 0 AND SAS_Ioamt > 0 AND AffordabilityorRentResult_S3 = "AF Fail" AND altterm > 25 THEN 
altterm = 0;

/*Track Record and over 40*/
IF TrackRecordFlag_S11 = "Y" AND altterm > 40 THEN
altterm = 0;
ELSE altterm = altterm;

/* if max loan for rent*/
IF TrackRecordFlag_S11 = "Y" AND (RawMaxLoan = TRMaxLoan) AND (RawMaxLoan < TotalLoanAmount_app) THEN
altterm = 0;





IF altterm > 40 THEN
altterm = 0;


/*EDI 0 or less*/
ELSE IF SAS_EDI =< 0 THEN
altterm = 0;


ELSE IF altterm1 < 0 THEN
altterm = 0;
ELSE altterm = altterm;


/* BTL, CV & D1*/
IF BTLFlag=1 OR ApplicationType_app in ("CV","D1")  THEN
altterm = NewTerm;












/*------VALIDATION CHECK------*/
DiffPCvsAltTerm = round(AlternativeTerm_N1 - altterm, 0.01);

RUN;
data altterm;
set alternatives (keep= MortgageAccountNumber ApplicationType_app AlternativeTerm_N1 altterm altterm1 AffordabilityorRentResult_S3 SAS_Ioamt SAS_Repamt DiffPCvsAltTerm altcoeff LTIMaxLoan AffordMaxLoan RawMaxLoan rawdiff DiffPCvsLTISAS NewTerm ABAmtAllLoans_app TrackRecordFlag_S11 SAS_EDI BTLFlag);
run;

title1 color="purple" underlin=1 'COMPARISON CHECK: Max Loan';
title2 italic 'Difference between PC and SAS';
PROC FREQ 
Data=Alternatives;
Table DiffPCvsMaxLoan;
Run;
title1 color="purple" underlin=1 'COMPARISON CHECK: LTI';
title2 italic 'Difference between PC and SAS';
PROC FREQ 
Data=Alternatives;
Table DiffPCvsLTISAS;
Run;
title1 color="purple" underlin=1 'COMPARISON CHECK: Alt Term';
title2 italic 'Difference between PC and SAS';
PROC FREQ 
Data=Alternatives;
Table DiffPCvsAltTerm;
Run;
data testaltterm;
set Alternatives;
where DiffPCvsAltTerm<>0;
run;

/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*------------------------------BUY TO LET------------------------------*/
/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
DATA BTL;
SET Alternatives;

/*5yr or not*/
IF (LoanType_app in ('A','B','C','Q'))AND 
Product_TermN40_app>59 AND Product_TermN40_app<999 AND 
(part2_prod_app="MISSING" OR part2_prod_app="") AND 
ProductTypeS3_app="FIX" AND AB_Flag=0 
THEN fiveyrBTLProd="Y";

ELSE IF (LoanType_app in ('A','B','C','Q')) AND 
FiveYRFixed_FlagS2_app="Y" AND 
AB_Flag=0 
THEN fiveyrBTLProd="Y";

ELSE fiveyrBTLProd="N";

InterestRate = InterestRateN130_app;

/*Stress Rates*/

IF BTLStress1Pipeline = "Y" THEN DO;
IF fiveyrBTLProd="Y" AND AB_Flag=0  THEN BTLStress2 = 6.04; ELSE
IF fiveyrBTLProd="N"  				THEN BTLStress2 = 7.94; ELSE
IF fiveyrBTLProd="Y" AND AB_Flag=1  THEN BTLStress2 = 7.94; ELSE
BTLStress2 = 0;
END;

IF BTLStress1Pipeline = "N" THEN BTLStress2 = 99.99;


IF InterestRate >0 THEN DO;
IF fiveyrBTLProd="Y" AND AB_Flag=0  THEN BTLStress3 = MAX((InterestRate + 1.00),5.5); ELSE
IF Like4LikeFlag = 1 AND AB_Flag=0  THEN BTLStress3 = MAX((InterestRate + 1.00),5.5); ELSE
IF fiveyrBTLProd="N"  				THEN BTLStress3 = MAX((InterestRate + 2.00),5.5); ELSE
IF fiveyrBTLProd="Y" AND AB_Flag=1  THEN BTLStress3 = MAX((InterestRate + 2.00),5.5); ELSE
BTLStress3 = 99.99;
END;

IF InterestRate =0 THEN DO;
IF fiveyrBTLProd="Y" AND AB_Flag=0  THEN BTLStress3 = 6.29; ELSE
IF fiveyrBTLProd="N"  				THEN BTLStress3 = 7.94; ELSE
IF fiveyrBTLProd="Y" AND AB_Flag=1  THEN BTLStress3 = 7.94; ELSE
BTLStress3 = 99.99;
END;

BTLStress = MIN(BTLStress2,BTLStress3);



/*ICR*/
IF LoanType_app in ('A','B','C','Q') AND RentalIncome_app>0 THEN DO;
	typical_monthly_payment = ((ABAmtAllLoans_app/100)*BTLStress)/12;
END;


IF (LoanType_app not in ('A','B','C','Q'))  THEN rental_cover=0;

IF rental_cover = 0 OR RentalIncome_app = 0 THEN rental_cover = 0; ELSE 
rental_cover = FLOOR(ROUND(RentalIncome_app/typical_monthly_payment, 0.0001)*100)/100;

/*------VALIDATION CHECK------*/
DiffPCvsSASSecICR = 'ICRPC_N17'n - rental_cover;

/*BTL Tax Status*/

IF LoanType_app in ('A','B','C','Q')THEN DO;
IF 	App1TaxStatusS5_app = "HIGHER RATE" OR App1TaxStatusS5_app = "ADDITIONAL/TOP RATE" OR
	App2TaxStatusS6_app = "HIGHER RATE" OR App2TaxStatusS6_app = "ADDITIONAL/TOP RATE" OR
	App3TaxStatusS7_app = "HIGHER RATE" OR App3TaxStatusS7_app = "ADDITIONAL/TOP RATE" OR
	App4TaxStatusS8_app = "HIGHER RATE" OR App4TaxStatusS8_app = "ADDITIONAL/TOP RATE" THEN
	TaxStatus = "Higher"; ELSE TaxStatus = "Std";
END;

/*Like for Like Remortgage*/
IF (LoanType_app = "B" AND RemortgageReason_app = "N" AND rental_cover>=1.25) THEN RentPass = "Rent Pass"; 
ELSE IF (BTLType = "PBTL" AND rental_cover>=1.45) 							  THEN RentPass = "Rent Pass"; 
ELSE IF (BTLType = "BTL" AND TaxStatus = "Higher" AND rental_cover>=1.45)     THEN RentPass = "Rent Pass"; 
ELSE IF (BTLType = "BTL" AND TaxStatus = "Std" AND rental_cover>=1.25)        THEN RentPass = "Rent Pass"; 
ELSE RentPass = "Rent Fail";

/*Top Slicing*/
/*Indebtedness Flag*/
IF MAX(App1G4NDSPCII, App2G4NDSPCII, App3G4NDSPCII, App4G4NDSPCII) > 8 THEN btlindebtflag = 'Y';
ELSE btlindebtflag = 'N';

/*Available*/
IF BTLFlag=1 AND 
RentPass = "Rent Fail" AND 
CAS15_N101 = 0 AND 
HRC14_N104 = 0 AND 
HRC18_N105 = 0 AND 
HRC26_N106 = 0 AND 
PID05_N107 = 0 AND 
ABDelphi_N108 = 0 AND 
ABCII_N109 = 0 AND 
(
(App1ITBT + App1DividendIncN34_app + 
App2ITBT + App2DividendIncN35_app + 
App3ITBT + App3DividendIncN36_app + 
App4ITBT + App4DividendIncN37_app) >= 60000 OR 
MAX(App1ITBT + App1DividendIncN34_app, App2ITBT + App2DividendIncN35_app, App3ITBT + App3DividendIncN36_app, App4ITBT + App4DividendIncN37_app) >= 45000
) AND 
(
PortfolioBTLbalance_app = 0 OR 
'BackgroundICRPC_N19'n >= 1.35 
) AND 
rental_cover >= 1.1 AND 
rental_cover < 1.45 AND 
btlindebtflag = 'N' 
THEN TopSlicingAvailable = 'Y'; ELSE TopSlicingAvailable = 'N';

/*------VALIDATION CHECK------*/
IF TopSlicingAvailable <> TopSlicingFlag_S10 THEN DiffPCvsSASTopSlicingFlag = 1;
ELSE DiffPCvsSASTopSlicingFlag = 0;

RUN;
title1 color="purple" underlin=1 'COMPARISON CHECK: BTLChecks';
title2 italic 'Difference between PC and SAS';
PROC FREQ 
Data=BTL;
Table DiffPCvsSASSecICR DiffPCvsSASTopSlicingFlag;
Run;
/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*------------------------------OUTPUT------------------------------*/
/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
Data Output;
Retain MortgageAccountNumber  ExecutedAt_app Edition ApplicationType_app BTLFlag 

App1_GrossBasicInc_app App1_GrossGuarInc_app App1_GrossNonGuarInc_app App1DividendIncN34_app App1BenefitInc_app App1MaintenanceIncN80_app 
App2_GrossBasicInc_app App2_GrossGuarInc_app App2_GrossNonGuarInc_app App2DividendIncN35_app App2BenefitInc_app App2MaintenanceIncN81_app 
App3_GrossBasicInc_app App3_GrossGuarInc_app App3_GrossNonGuarInc_app App3DividendIncN36_app App3BenefitInc_app App3MaintenanceIncN82_app 
App4_GrossBasicInc_app App4_GrossGuarInc_app App4_GrossNonGuarInc_app App4DividendIncN37_app App4BenefitInc_app App4MaintenanceIncN83_app 
App1ITBT App2ITBT App3ITBT App4ITBT 
/*App1GAI App2GAI App3GAI App4GAI 
GAIApp1_N2 GAIApp2_N3 GAIApp3_N4 GAIApp4_N5 */
Household_GAIBuild Household_GAI  Household_NAI Af_Modelnetinc_res Household_NMI DifferencePCvsSASnet 



App1_EmpType_app App2_EmpType_app App3_EmpTypeS11_app App4_EmpTypeS13_app 
NbrOfAppls_app noDependants_app SecRegion_app MainResidenceS9_app TrackRecordFlag_S11 

part1_LoanAmt_app part1_reptype_app 
part2_LoanAmt_app part2_reptype_app 
IntOnlyAmt_app 

ABAmtAllLoans_app LTV_app ThreeStageProduct_FlagS14_app Product_TermN40_app ProductTypeS3_app TermInMths_app MortgageFeesN8_app 

AppsRevolveBal_app RevBalPaymt 
AppsNonRevolveBal_app AppsNonRevolveRepay_app 
HTBEquityLoan_app HTBPymt 

SBSNonBTLMortgagesBalance_app SBSNonBTLMortgagesTerm_app AppsSecDebtAmt_app 

AppsOtherExpenditure_app SO_RentN48_app SAS_MCC SAS_MonthlyLiving6 LivingModel_N9 DifferencePCvsSASN9 
SAS_MonthlyLife LifestyleModel_N10 DifferencePCvsSASN10 
SAS_DTI Af_Modeloutgoings_res SAS_ModelledOutgoings DiffPCvsSASModelledOutgoings

Af_Edi_res SAS_EDI DiffPCvsSASEDI 
/*
SAS_Ioamt IoCoeff 
SAS_Repamt ResiCoeff 
MortgageFeesN8_app FeeCoeff
SAS_Secdebtamt OthCoeff 
SAS_SBSPrimamt PrimCoeff 
*/ 
Af_Stressmortrepay_res SAS_StressedMort DiffPCvsSASStressedMort  

Af_Affordability_res SAS_Affordability DiffPCvsSASAff 

RawMaxLoan SAS_MaxLTI LTI_app TopSlicingFlag_S10;

set BTL (keep= MortgageAccountNumber  ExecutedAt_app Edition ApplicationType_app BTLFlag 

App1_GrossBasicInc_app App1_GrossGuarInc_app App1_GrossNonGuarInc_app App1DividendIncN34_app App1BenefitInc_app App1MaintenanceIncN80_app 
App2_GrossBasicInc_app App2_GrossGuarInc_app App2_GrossNonGuarInc_app App2DividendIncN35_app App2BenefitInc_app App2MaintenanceIncN81_app 
App3_GrossBasicInc_app App3_GrossGuarInc_app App3_GrossNonGuarInc_app App3DividendIncN36_app App3BenefitInc_app App3MaintenanceIncN82_app 
App4_GrossBasicInc_app App4_GrossGuarInc_app App4_GrossNonGuarInc_app App4DividendIncN37_app App4BenefitInc_app App4MaintenanceIncN83_app 
App1ITBT App2ITBT App3ITBT App4ITBT 
/*App1GAI App2GAI App3GAI App4GAI 
GAIApp1_N2 GAIApp2_N3 GAIApp3_N4 GAIApp4_N5 */
Household_GAI  Household_GAIBuild Household_NAI Af_Modelnetinc_res Household_NMI DifferencePCvsSASnet 

App1_EmpType_app App2_EmpType_app App3_EmpTypeS11_app App4_EmpTypeS13_app 
NbrOfAppls_app noDependants_app SecRegion_app MainResidenceS9_app TrackRecordFlag_S11 

part1_LoanAmt_app part1_reptype_app 
part2_LoanAmt_app part2_reptype_app 
IntOnlyAmt_app 

ABAmtAllLoans_app LTV_app ThreeStageProduct_FlagS14_app Product_TermN40_app ProductTypeS3_app TermInMths_app MortgageFeesN8_app 

AppsRevolveBal_app RevBalPaymt 
AppsNonRevolveBal_app AppsNonRevolveRepay_app 
HTBEquityLoan_app HTBPymt 

SBSNonBTLMortgagesBalance_app SBSNonBTLMortgagesTerm_app AppsSecDebtAmt_app 

AppsOtherExpenditure_app SO_RentN48_app SAS_MCC SAS_MonthlyLiving6 LivingModel_N9 DifferencePCvsSASN9 
SAS_MonthlyLife LifestyleModel_N10 DifferencePCvsSASN10 
SAS_DTI Af_Modeloutgoings_res SAS_ModelledOutgoings DiffPCvsSASModelledOutgoings

Af_Edi_res SAS_EDI DiffPCvsSASEDI 
/*
SAS_Ioamt IoCoeff 
SAS_Repamt ResiCoeff 
MortgageFeesN8_app FeeCoeff
SAS_Secdebtamt OthCoeff 
SAS_SBSPrimamt PrimCoeff 
*/
Af_Stressmortrepay_res SAS_StressedMort DiffPCvsSASStressedMort 

Af_Affordability_res SAS_Affordability DiffPCvsSASAff 

RawMaxLoan SAS_MaxLTI LTI_app TopSlicingFlag_S10
);

Run; 
/*------------------------------DEDUPE FOR UNIQUE SCORES------------------------------*/

proc sort data=Output (drop=ExecutedAt_app) out=Outputs2 nodupkey;
    by _all_;
run;

/*------------------------------SCORE DATASET EXPORT TO EXCEL------------------------------*/
/*First Sheet*/

PROC EXPORT
Data=Outputs2
outfile= "H:\Decisioning\Decision System\05 - Powercurve Comparison\UAT Output\New SAS Comparison Outputs\SASAffordability&filenamex..xlsx"
dbms=xlsx replace;
sheet="DeDupedSummary";
Run;

/*Second Sheet*/
/*
PROC EXPORT
Data=Output
outfile= "H:\New SAS\SDS\05 - Powercurve Comparison\UAT Output\New SAS Comparison Outputs\SASAffordability&filename..xlsx"
dbms=xlsx replace;
sheet="AllScoresSummary";
Run;

/*Third Sheet*/
/*
PROC EXPORT
Data=BTL
outfile= "H:\New SAS\SDS\05 - Powercurve Comparison\UAT Output\New SAS Comparison Outputs\SASAffordability&filename..xlsx"
dbms=xlsx replace;
sheet="AllData";
Run;

/*Fourth Sheet*/
/*
PROC EXPORT
Data=ScoreData
outfile= "H:\New SAS\SDS\05 - Powercurve Comparison\UAT Output\New SAS Comparison Outputs\SASAffordability&filename..xlsx"
dbms=xlsx replace;
sheet="InputData";
Run;
*/
/*Fourth Sheet*/

/*PROC EXPORT
Data=Alternatives
outfile= "H:\New SAS\SDS\05 - Powercurve Comparison\UAT Output\New SAS Comparison Outputs\SASAffordabilityAlternatives555.xlsx"
dbms=xlsx replace;
sheet="InputData";
Run;
*/


/*Libraries and Macro Variables*/ 
libname	p_dw	odbc  noprompt="server=SBSPSQLVS101\MISPSQL01;
                  			driver=sql server;
                  			database=P_DW;
                  			trusted connection=yes;"
                  			schema=dbo
                  			ACCESS=READONLY;

libname out 'H:\Portfolio Management\Long Term Arrears\Detailed MIA Report\Out';

%let monthend='01Oct2026'd; /*Change for the latest snapshot available*/
%let max=48; /*Do not change*/


/*Step 1: Arrears cases at month end with last 6 months' balance and arrears amount*/
%macro step1;
%let yyyymm1=%sysfunc(intnx(month,&monthend,0),yymmn6.);
proc sql;
CONNECT TO odbc	("server=SBSPSQLVS101\MISPSQL01;
				driver=sql server; 
                database=p_dw; 
                trusted connection=yes;");
CREATE TABLE core AS 
SELECT * FROM CONNECTION TO ODBC
(
SELECT	CASE	WHEN lu.Allocated_AccountNumber IS NOT NULL THEN lu.Allocated_AccountNumber ELSE da.AccountNumber END AS 'AccountNumber' 
		, CONVERT(DATE,da.AccountStartDate) AS 'CompDate'
		, CASE	WHEN da.AccountStartDate IS NULL OR da.AccountStartDate>dm.BatchDate THEN 0 ELSE DATEDIFF(DAY,da.AccountStartDate,dm.BatchDate) END AS 'AgeDays'
		, CASE	WHEN da.AccountStartDate IS NULL OR da.AccountStartDate>dm.BatchDate THEN 0 ELSE ROUND(CONVERT(FLOAT,(DATEDIFF(DAY,da.AccountStartDate,dm.BatchDate)))/365,2) 
				END AS 'AgeYears'
		, CASE	WHEN da.AccountStartDate IS NOT NULL AND da.AccountStartDate<=dm.BatchDate AND ROUND(CONVERT(FLOAT,(DATEDIFF(DAY,da.AccountStartDate,dm.BatchDate)))/365,2)>=3 
				AND	fma.CapitalBalanceLive>0 THEN 1 ELSE 0 END AS 'Mature' 
		, CASE	WHEN da.AccountStartDate IS NOT NULL AND da.AccountStartDate<=dm.BatchDate AND ROUND(CONVERT(FLOAT,(DATEDIFF(DAY,da.AccountStartDate,dm.BatchDate)))/365,2)>=3 
				AND	fma.CapitalBalanceLive>0 THEN fma.CapitalBalanceLive ELSE 0 END AS 'MatureBal' 
		, CASE	WHEN dc.CompanyName IN ('Amber Homeloans Ltd','North Yorkshire Mortgages') AND fma.StandardArrearsAmount>0 AND fma.CapitalBalanceLive>0 
					 THEN ROUND((fma.StandardArrearsAmount/fma.CapitalBalanceLive)*100,6) 
				WHEN dc.CompanyName IN ('Skipton Building Society') AND fma.ContractualArrearsAmount>0 AND fma.CapitalBalanceLive>0 
					 THEN ROUND((fma.ContractualArrearsAmount/fma.CapitalBalanceLive)*100,6)
				ELSE 0 END AS 'ATBR'
		, CASE	WHEN dc.CompanyName IN ('Amber Homeloans Ltd','North Yorkshire Mortgages') AND fma.StandardArrearsInMonths>0 THEN ROUND(fma.StandardArrearsInMonths,3)
				WHEN dc.CompanyName IN ('Skipton Building Society') AND fma.ContractualArrearsInMonths>0 THEN ROUND(fma.ContractualArrearsInMonths,3)
				ELSE 0 END AS 'MIA'
		, CASE	WHEN das.AccountStatus='Possession' THEN 1 ELSE 0 END AS 'Repossessed'
		, CASE	WHEN dpd.CalendarYear*100+dpd.CalendarMonthNumber=dm.CalendarMonthYear THEN 1 ELSE 0 END AS 'RepLM'
		, CASE	WHEN YEAR(da.AccountEndDate)*100+MONTH(da.AccountEndDate)=dm.CalendarMonthYear THEN 1 ELSE 0 END AS 'RedLM'

FROM	P_DW.dbo.factMortgageAccountMonthSS fma

INNER JOIN	P_DW.dbo.dimAccount da
ON	fma.FK_Account = da.PK_Account
INNER JOIN	P_DW.dbo.dimCompany dc
ON	fma.FK_Company = dc.PK_Company
INNER JOIN	P_DW.dbo.dimAccountStates das
ON	fma.FK_AccountStates = das.PK_AccountStates
INNER JOIN	P_DW.dbo.dimProduct dp
ON	fma.FK_CurrentMortgageProduct = dp.PK_Product
INNER JOIN	P_DW.dbo.dimMonth dm
ON	fma.FK_SnapshotDate = dm.PK_Month
INNER JOIN	P_DW.dbo.dimDate dpd
ON	fma.FK_PossessionDate = dpd.PK_Date
LEFT JOIN	P_ODS.reference.AHLNYMMigratedAccounts lu
ON	da.AccountPool = lu.AHLNYM_PoolID
AND	da.AccountNumber = lu.AHLNYM_AccountNumber

WHERE	dc.CompanyName IN ('Skipton Building Society','Amber Homeloans Ltd','North Yorkshire Mortgages')
AND		da.AccountPool<>'DRC00001'
AND		dm.CalendarMonthYear=CONVERT(VARCHAR,&yyyymm1)
AND		da.AccountSubType='Primary'
AND		da.CurrentAccountClassification<>'Pure Commercial'
AND		da.AccountStartDate IS NOT NULL /*Removes Delayed Completions*/
AND		dp.ProductCode NOT IN ('MIN01','HOM10','HM120','HM121','HM122','HM123','HM124','HM125') /*SBS deed accounts + Holmesdale deed and fair value accounts*/
AND		(das.AccountStatus IN ('Live','Possession') OR
		(da.AccountEndDate IS NOT NULL AND YEAR(da.AccountEndDate)*100+MONTH(da.AccountEndDate)=dm.CalendarMonthYear)) /*Includes month end redemptions*/

ORDER BY (CASE	WHEN lu.Allocated_AccountNumber IS NOT NULL THEN lu.Allocated_AccountNumber ELSE da.AccountNumber END)
)
;
DISCONNECT FROM odbc;
;
quit;  


%do i=1 %to 7;
%let	yyyymm2=%sysfunc(intnx(month,&monthend,(&i-1)*-1),yymmn6.);
proc sql;
CONNECT TO odbc	("server=SBSPSQLVS101\MISPSQL01;
				driver=sql server; 
                database=p_dw; 
                trusted connection=yes;");
CREATE TABLE m&i AS 
SELECT * FROM CONNECTION TO ODBC
(
SELECT	CASE	WHEN lu.Allocated_AccountNumber IS NOT NULL THEN lu.Allocated_AccountNumber ELSE da.AccountNumber END AS 'AccountNumber' 
		, CASE	WHEN fma.CapitalBalanceLive<=0 THEN 0 ELSE fma.CapitalBalanceLive END AS Bal&i
		, CASE	WHEN dc.CompanyName IN ('Amber Homeloans Ltd','North Yorkshire Mortgages') AND fma.StandardArrearsAmount>0 THEN fma.StandardArrearsAmount
				WHEN dc.CompanyName IN ('Skipton Building Society') AND fma.ContractualArrearsAmount>0 THEN fma.ContractualArrearsAmount
				ELSE 0 END AS Arr&i
		, CASE	WHEN das.AccountStatus='Possession' THEN 1 ELSE 0 END AS Pos&i

FROM	P_DW.dbo.factMortgageAccountMonthSS fma

INNER JOIN	P_DW.dbo.dimAccount da
ON	fma.FK_Account = da.PK_Account
INNER JOIN	P_DW.dbo.dimCompany dc
ON	fma.FK_Company = dc.PK_Company
INNER JOIN	P_DW.dbo.dimAccountStates das
ON	fma.FK_AccountStates = das.PK_AccountStates
INNER JOIN	P_DW.dbo.dimProduct dp
ON	fma.FK_CurrentMortgageProduct = dp.PK_Product
INNER JOIN	P_DW.dbo.dimMonth dm
ON	fma.FK_SnapshotDate = dm.PK_Month
LEFT JOIN	P_ODS.reference.AHLNYMMigratedAccounts lu
ON	da.AccountPool = lu.AHLNYM_PoolID
AND	da.AccountNumber = lu.AHLNYM_AccountNumber

WHERE	dc.CompanyName IN ('Skipton Building Society','Amber Homeloans Ltd','North Yorkshire Mortgages')
AND		da.AccountPool<>'DRC00001'
AND		dm.CalendarMonthYear=CONVERT(VARCHAR,&yyyymm2)
AND		da.AccountSubType='Primary'
AND		da.CurrentAccountClassification<>'Pure Commercial'
AND		da.AccountStartDate IS NOT NULL /*Removes Delayed Completions*/
AND		dp.ProductCode NOT IN ('MIN01','HOM10','HM120','HM121','HM122','HM123','HM124','HM125') /*SBS deed accounts + Holmesdale deed and fair value accounts*/
AND		(das.AccountStatus IN ('Live','Possession') OR
		(da.AccountEndDate IS NOT NULL AND YEAR(da.AccountEndDate)*100+MONTH(da.AccountEndDate)=dm.CalendarMonthYear)) /*Includes month end redemptions*/

ORDER BY (CASE	WHEN lu.Allocated_AccountNumber IS NOT NULL THEN lu.Allocated_AccountNumber ELSE da.AccountNumber END)
)
;
DISCONNECT FROM odbc;
;
quit;  
%end;
data perf; set m1; run;
proc delete data=m1; run;
%do i=2 %to 7;
data	perf;
merge	perf (in=a) m&i (in=b);
by		AccountNumber; 	if	a; run;
proc delete data=m&i; run;
%end;
proc sort data=perf; by AccountNumber; run;
data	core; 
merge	core (in=a) perf (in=b);
by		AccountNumber;
run;
proc delete data=perf; run;
%mend step1;
%step1;


/*Step 2: MIA and ATBR history*/
%macro step2;
%do i=1 %to &max;
%let yyyymm=%sysfunc(intnx(month,&monthend,(&i-1)*-1),yymmn6.);
proc sql;
CONNECT TO odbc	("server=SBSPSQLVS101\MISPSQL01;
				driver=sql server; 
                database=p_dw; 
                trusted connection=yes;");
CREATE TABLE M&i AS 
SELECT * FROM CONNECTION TO ODBC
(
SELECT	CASE	WHEN lu.Allocated_AccountNumber IS NOT NULL THEN lu.Allocated_AccountNumber ELSE da.AccountNumber END AS 'AccountNumber'
		/*MIA*/
		, CASE	WHEN dc.CompanyName IN ('Amber Homeloans Ltd','North Yorkshire Mortgages') AND fma.StandardArrearsInMonths>=1 THEN 'Y'
				WHEN dc.CompanyName IN ('Skipton Building Society') AND fma.ContractualArrearsInMonths>=1 THEN 'Y'
				ELSE 'N' END AS M_1P&i
		, CASE	WHEN dc.CompanyName IN ('Amber Homeloans Ltd','North Yorkshire Mortgages') AND fma.StandardArrearsInMonths>=3 THEN 'Y'
				WHEN dc.CompanyName IN ('Skipton Building Society') AND fma.ContractualArrearsInMonths>=3 THEN 'Y'
				ELSE 'N' END AS M_3P&i
		, CASE	WHEN dc.CompanyName IN ('Amber Homeloans Ltd','North Yorkshire Mortgages') AND fma.StandardArrearsInMonths>=6 THEN 'Y'
				WHEN dc.CompanyName IN ('Skipton Building Society') AND fma.ContractualArrearsInMonths>=6 THEN 'Y'
				ELSE 'N' END AS M_6P&i
		/*ATBR*/
		, CASE	WHEN fma.CapitalBalanceLive<=0 THEN 'N' 
				WHEN dc.CompanyName IN ('Amber Homeloans Ltd','North Yorkshire Mortgages') AND fma.StandardArrearsAmount>0 AND fma.CapitalBalanceLive>0 
					 AND ROUND((fma.StandardArrearsAmount/fma.CapitalBalanceLive)*100,6)>=0.8333 THEN 'Y' 
				WHEN dc.CompanyName IN ('Skipton Building Society') AND fma.ContractualArrearsAmount>0 AND fma.CapitalBalanceLive>0 
					 AND ROUND((fma.ContractualArrearsAmount/fma.CapitalBalanceLive)*100,6)>=0.8333 THEN 'Y'
				ELSE 'N' END AS R_1P&i
		, CASE	WHEN fma.CapitalBalanceLive<=0 THEN 'N' 
				WHEN dc.CompanyName IN ('Amber Homeloans Ltd','North Yorkshire Mortgages') AND fma.StandardArrearsAmount>0 AND fma.CapitalBalanceLive>0 
					 AND ROUND((fma.StandardArrearsAmount/fma.CapitalBalanceLive)*100,6)>=2.4999 THEN 'Y' 
				WHEN dc.CompanyName IN ('Skipton Building Society') AND fma.ContractualArrearsAmount>0 AND fma.CapitalBalanceLive>0 
					 AND ROUND((fma.ContractualArrearsAmount/fma.CapitalBalanceLive)*100,6)>=2.4999 THEN 'Y'
				ELSE 'N' END AS R_3P&i
		, CASE	WHEN fma.CapitalBalanceLive<=0 THEN 'N' 
				WHEN dc.CompanyName IN ('Amber Homeloans Ltd','North Yorkshire Mortgages') AND fma.StandardArrearsAmount>0 AND fma.CapitalBalanceLive>0 
					 AND ROUND((fma.StandardArrearsAmount/fma.CapitalBalanceLive)*100,6)>=4.9998 THEN 'Y' 
				WHEN dc.CompanyName IN ('Skipton Building Society') AND fma.ContractualArrearsAmount>0 AND fma.CapitalBalanceLive>0 
					 AND ROUND((fma.ContractualArrearsAmount/fma.CapitalBalanceLive)*100,6)>=4.9998 THEN 'Y'
				ELSE 'N' END AS R_6P&i

FROM	P_DW.dbo.factMortgageAccountMonthSS fma

INNER JOIN	P_DW.dbo.dimAccount da
ON	fma.FK_Account = da.PK_Account
INNER JOIN	P_DW.dbo.dimCompany dc
ON	fma.FK_Company = dc.PK_Company
INNER JOIN	P_DW.dbo.dimAccountStates das
ON	fma.FK_AccountStates = das.PK_AccountStates
INNER JOIN	P_DW.dbo.dimProduct dp
ON	fma.FK_CurrentMortgageProduct = dp.PK_Product
INNER JOIN	P_DW.dbo.dimMonth dm
ON	fma.FK_SnapshotDate = dm.PK_Month
LEFT JOIN	P_ODS.reference.AHLNYMMigratedAccounts lu
ON	da.AccountPool = lu.AHLNYM_PoolID
AND	da.AccountNumber = lu.AHLNYM_AccountNumber

WHERE	dc.CompanyName IN ('Skipton Building Society','Amber Homeloans Ltd','North Yorkshire Mortgages')
AND		da.AccountPool<>'DRC00001'
AND		dm.CalendarMonthYear=CONVERT(VARCHAR,&yyyymm)
AND		da.AccountSubType='Primary'
AND		da.CurrentAccountClassification<>'Pure Commercial'
AND		da.AccountStartDate IS NOT NULL /*Removes Delayed Completions*/
AND		dp.ProductCode NOT IN ('MIN01','HOM10','HM120','HM121','HM122','HM123','HM124','HM125') /*SBS deed accounts + Holmesdale deed and fair value accounts*/
AND		(das.AccountStatus IN ('Live','Possession') OR
		(da.AccountEndDate IS NOT NULL AND YEAR(da.AccountEndDate)*100+MONTH(da.AccountEndDate)=dm.CalendarMonthYear)) /*Includes month end redemptions*/

ORDER BY (CASE	WHEN lu.Allocated_AccountNumber IS NOT NULL THEN lu.Allocated_AccountNumber ELSE da.AccountNumber END)	
)
;
DISCONNECT FROM odbc;
;
quit;  
%end;
%mend step2;
%step2;


/*Step 3: Data merge and MIA/ATBR duration by definition*/
%macro	step3;
%do		i=1 %to &max;
data	core;
merge	core (in=a) m&i (in=b);
by		AccountNumber;
if		a;
run;
proc delete data=m&i; run;
%end;
%do		i=1 %to &max;
data	core;
set		core;
if		M_1P&i=" " then M_1P&i="N"; else  M_1P&i= M_1P&i;
if		M_3P&i=" " then M_3P&i="N"; else  M_3P&i= M_3P&i;
if		M_6P&i=" " then M_6P&i="N"; else  M_6P&i= M_6P&i;
if		R_1P&i=" " then R_1P&i="N"; else  R_1P&i= R_1P&i;
if		R_3P&i=" " then R_3P&i="N"; else  R_3P&i= R_3P&i;
if		R_6P&i=" " then R_6P&i="N"; else  R_6P&i= R_6P&i;
run;
%end;
data	core;
set		core;
M1PString=cat(of M_1P1-M_1P&max);
M3PString=cat(of M_3P1-M_3P&max);
M6PString=cat(of M_6P1-M_6P&max);
R1PString=cat(of R_1P1-R_1P&max);
R3PString=cat(of R_3P1-R_3P&max);
R6PString=cat(of R_6P1-R_6P&max);
if	index(M1PString,"N")=0 then M1PDur=&max; else M1PDur=index(M1PString,"N")-1;
if	index(M3PString,"N")=0 then M3PDur=&max; else M3PDur=index(M3PString,"N")-1;
if	index(M6PString,"N")=0 then M6PDur=&max; else M6PDur=index(M6PString,"N")-1;
if	index(R1PString,"N")=0 then R1PDur=&max; else R1PDur=index(R1PString,"N")-1;
if	index(R3PString,"N")=0 then R3PDur=&max; else R3PDur=index(R3PString,"N")-1;
if	index(R6PString,"N")=0 then R6PDur=&max; else R6PDur=index(R6PString,"N")-1;
format 	M1PDur M3PDur M6PDur R1PDur R3PDur R6PDur best3.;
keep	AccountNumber CompDate AgeDays AgeYears Mature MatureBal ATBR MIA Repossessed RepLM RedLM Bal1 Bal2 Bal3 Bal4 Bal5 Bal6 Bal7 Arr1 Arr2 Arr3 Arr4 Arr5 Arr6 Arr7 Pos2
		M1PString M3PString M6PString R1PString R3PString R6PString	M1PDur M3PDur M6PDur R1PDur R3PDur R6PDur;
run;
%mend	step3;
%step3;


/*Step 4: MIA and ATBR outcomes by definition and next months expected roll in cases*/  
%macro	step4;
data core; set core;
if	substr(M6PString,1,12)="YYYYYYYYYYYY" 	and M6PDur=12 and Repossessed=0						then do; 	MLTAIn=1;		MLTAIn_Bal=		Bal1; end;
if	substr(M6PString,1,12)="YYYYYYYYYYYY" 	and (M6PDur>12 and M6PDur<=24) and Repossessed=0 	then do; 	MLTAHeld1=1;	MLTAHeld1_Bal=	Bal1; end;
if	substr(M6PString,1,12)="YYYYYYYYYYYY" 	and (M6PDur>24 and M6PDur<=36) and Repossessed=0	then do; 	MLTAHeld2=1;	MLTAHeld2_Bal=	Bal1; end;
if	substr(M6PString,1,12)="YYYYYYYYYYYY" 	and (M6PDur>36) and Repossessed=0					then do; 	MLTAHeld3=1;	MLTAHeld3_Bal=	Bal1; end;
if	substr(M6PString,2,12)="YYYYYYYYYYYY" 	and ((M6PDur=0 and Pos2=0) or RepLM=1)				then do; 	MLTAOut=-1;		MLTAOut_Bal=	Bal2; end;
if	substr(R6PString,1,12)="YYYYYYYYYYYY" 	and R6PDur=12 and Repossessed=0 					then do; 	RLTAIn=1;		RLTAIn_Bal=		Bal1; end;
if	substr(R6PString,1,12)="YYYYYYYYYYYY" 	and (R6PDur>12 and R6PDur<=24) and Repossessed=0	then do; 	RLTAHeld1=1;	RLTAHeld1_Bal=	Bal1; end;
if	substr(R6PString,1,12)="YYYYYYYYYYYY" 	and (R6PDur>24 and R6PDur<=36) and Repossessed=0	then do; 	RLTAHeld2=1;	RLTAHeld2_Bal=	Bal1; end;
if	substr(R6PString,1,12)="YYYYYYYYYYYY" 	and (R6PDur>36) and Repossessed=0					then do; 	RLTAHeld3=1;	RLTAHeld3_Bal=	Bal1; end;
if	substr(R6PString,2,12)="YYYYYYYYYYYY" 	and ((R6PDur=0 and Pos2=0) or RepLM=1)				then do; 	RLTAOut=-1;		RLTAOut_Bal=	Bal2; end;
if	substr(M1PString,1,3)="YYY" 						and M1PDur=3 and Repossessed=0			then 		M1P3In=1;
if	substr(M1PString,1,3)="YYY" 						and M1PDur>3 and Repossessed=0			then 		M1P3Held=1;
if	substr(M1PString,2,3)="YYY"							and ((M1PDur=0 and Pos2=0) or RepLM=1)	then		M1P3Out=-1;
if	substr(M1PString,1,6)="YYYYYY" 						and M1PDur=6 and Repossessed=0			then 		M1P6In=1;
if	substr(M1PString,1,6)="YYYYYY" 						and M1PDur>6 and Repossessed=0			then 		M1P6Held=1;
if	substr(M1PString,2,6)="YYYYYY"						and ((M1PDur=0 and Pos2=0) or RepLM=1)	then		M1P6Out=-1;
if	substr(M1PString,1,12)="YYYYYYYYYYYY" 				and M1PDur=12 and Repossessed=0			then 		M1P12In=1;
if	substr(M1PString,1,12)="YYYYYYYYYYYY" 				and M1PDur>12 and Repossessed=0			then 		M1P12Held=1;
if	substr(M1PString,2,12)="YYYYYYYYYYYY"				and ((M1PDur=0 and Pos2=0) or RepLM=1)	then		M1P12Out=-1;
if	substr(M1PString,1,24)="YYYYYYYYYYYYYYYYYYYYYYYY" 	and M1PDur=24 and Repossessed=0			then 		M1P24In=1;
if	substr(M1PString,1,24)="YYYYYYYYYYYYYYYYYYYYYYYY" 	and M1PDur>24 and Repossessed=0			then 		M1P24Held=1;
if	substr(M1PString,2,24)="YYYYYYYYYYYYYYYYYYYYYYYY"	and ((M1PDur=0 and Pos2=0) or RepLM=1)	then		M1P24Out=-1;
if	substr(M3PString,1,3)="YYY" 						and M3PDur=3 and Repossessed=0			then 		M3P3In=1;
if	substr(M3PString,1,3)="YYY" 						and M3PDur>3 and Repossessed=0			then 		M3P3Held=1;
if	substr(M3PString,2,3)="YYY"							and ((M3PDur=0 and Pos2=0) or RepLM=1)	then		M3P3Out=-1;
if	substr(M3PString,1,6)="YYYYYY" 						and M3PDur=6 and Repossessed=0			then 		M3P6In=1;
if	substr(M3PString,1,6)="YYYYYY" 						and M3PDur>6 and Repossessed=0			then 		M3P6Held=1;
if	substr(M3PString,2,6)="YYYYYY"						and ((M3PDur=0 and Pos2=0) or RepLM=1)	then		M3P6Out=-1;
if	substr(M3PString,1,12)="YYYYYYYYYYYY" 				and M3PDur=12 and Repossessed=0			then 		M3P12In=1;
if	substr(M3PString,1,12)="YYYYYYYYYYYY" 				and M3PDur>12 and Repossessed=0			then 		M3P12Held=1;
if	substr(M3PString,2,12)="YYYYYYYYYYYY"				and ((M3PDur=0 and Pos2=0) or RepLM=1)	then		M3P12Out=-1;
if	substr(M3PString,1,24)="YYYYYYYYYYYYYYYYYYYYYYYY" 	and M3PDur=24 and Repossessed=0			then 		M3P24In=1;
if	substr(M3PString,1,24)="YYYYYYYYYYYYYYYYYYYYYYYY" 	and M3PDur>24 and Repossessed=0			then 		M3P24Held=1;
if	substr(M3PString,2,24)="YYYYYYYYYYYYYYYYYYYYYYYY"	and ((M3PDur=0 and Pos2=0) or RepLM=1)	then		M3P24Out=-1;
if	substr(M6PString,1,3)="YYY" 						and M6PDur=3 and Repossessed=0			then 		M6P3In=1;
if	substr(M6PString,1,3)="YYY" 						and M6PDur>3 and Repossessed=0			then 		M6P3Held=1;
if	substr(M6PString,2,3)="YYY"							and ((M6PDur=0 and Pos2=0) or RepLM=1)	then		M6P3Out=-1;
if	substr(M6PString,1,6)="YYYYYY" 						and M6PDur=6 and Repossessed=0			then 		M6P6In=1;
if	substr(M6PString,1,6)="YYYYYY" 						and M6PDur>6 and Repossessed=0			then 		M6P6Held=1;
if	substr(M6PString,2,6)="YYYYYY"						and ((M6PDur=0 and Pos2=0) or RepLM=1)	then		M6P6Out=-1;
if	substr(M6PString,1,12)="YYYYYYYYYYYY" 				and M6PDur=12 and Repossessed=0			then 		M6P12In=1;
if	substr(M6PString,1,12)="YYYYYYYYYYYY" 				and M6PDur>12 and Repossessed=0			then 		M6P12Held=1;
if	substr(M6PString,2,12)="YYYYYYYYYYYY"				and ((M6PDur=0 and Pos2=0) or RepLM=1)	then		M6P12Out=-1;
if	substr(M6PString,1,24)="YYYYYYYYYYYYYYYYYYYYYYYY" 	and M6PDur=24 and Repossessed=0			then 		M6P24In=1;
if	substr(M6PString,1,24)="YYYYYYYYYYYYYYYYYYYYYYYY" 	and M6PDur>24 and Repossessed=0			then 		M6P24Held=1;
if	substr(M6PString,2,24)="YYYYYYYYYYYYYYYYYYYYYYYY"	and ((M6PDur=0 and Pos2=0) or RepLM=1)	then		M6P24Out=-1;
if	substr(R1PString,1,3)="YYY" 						and R1PDur=3 and Repossessed=0			then 		R1P3In=1;
if	substr(R1PString,1,3)="YYY" 						and R1PDur>3 and Repossessed=0			then 		R1P3Held=1;
if	substr(R1PString,2,3)="YYY"							and ((R1PDur=0 and Pos2=0) or RepLM=1)	then		R1P3Out=-1;
if	substr(R1PString,1,6)="YYYYYY" 						and R1PDur=6 and Repossessed=0			then 		R1P6In=1;
if	substr(R1PString,1,6)="YYYYYY" 						and R1PDur>6 and Repossessed=0			then 		R1P6Held=1;
if	substr(R1PString,2,6)="YYYYYY"						and ((R1PDur=0 and Pos2=0) or RepLM=1)	then		R1P6Out=-1;
if	substr(R1PString,1,12)="YYYYYYYYYYYY" 				and R1PDur=12 and Repossessed=0			then 		R1P12In=1;
if	substr(R1PString,1,12)="YYYYYYYYYYYY" 				and R1PDur>12 and Repossessed=0			then 		R1P12Held=1;
if	substr(R1PString,2,12)="YYYYYYYYYYYY"				and ((R1PDur=0 and Pos2=0) or RepLM=1)	then		R1P12Out=-1;
if	substr(R1PString,1,24)="YYYYYYYYYYYYYYYYYYYYYYYY" 	and R1PDur=24 and Repossessed=0			then 		R1P24In=1;
if	substr(R1PString,1,24)="YYYYYYYYYYYYYYYYYYYYYYYY" 	and R1PDur>24 and Repossessed=0			then 		R1P24Held=1;
if	substr(R1PString,2,24)="YYYYYYYYYYYYYYYYYYYYYYYY"	and ((R1PDur=0 and Pos2=0) or RepLM=1)	then		R1P24Out=-1;
if	substr(R3PString,1,3)="YYY" 						and R3PDur=3 and Repossessed=0			then 		R3P3In=1;
if	substr(R3PString,1,3)="YYY" 						and R3PDur>3 and Repossessed=0			then 		R3P3Held=1;
if	substr(R3PString,2,3)="YYY"							and ((R3PDur=0 and Pos2=0) or RepLM=1)	then		R3P3Out=-1;
if	substr(R3PString,1,6)="YYYYYY" 						and R3PDur=6 and Repossessed=0			then 		R3P6In=1;
if	substr(R3PString,1,6)="YYYYYY" 						and R3PDur>6 and Repossessed=0			then 		R3P6Held=1;
if	substr(R3PString,2,6)="YYYYYY"						and ((R3PDur=0 and Pos2=0) or RepLM=1)	then		R3P6Out=-1;
if	substr(R3PString,1,12)="YYYYYYYYYYYY" 				and R3PDur=12 and Repossessed=0			then 		R3P12In=1;
if	substr(R3PString,1,12)="YYYYYYYYYYYY" 				and R3PDur>12 and Repossessed=0			then 		R3P12Held=1;
if	substr(R3PString,2,12)="YYYYYYYYYYYY"				and ((R3PDur=0 and Pos2=0) or RepLM=1)	then		R3P12Out=-1;
if	substr(R3PString,1,24)="YYYYYYYYYYYYYYYYYYYYYYYY" 	and R3PDur=24 and Repossessed=0			then 		R3P24In=1;
if	substr(R3PString,1,24)="YYYYYYYYYYYYYYYYYYYYYYYY" 	and R3PDur>24 and Repossessed=0			then 		R3P24Held=1;
if	substr(R3PString,2,24)="YYYYYYYYYYYYYYYYYYYYYYYY"	and ((R3PDur=0 and Pos2=0) or RepLM=1)	then		R3P24Out=-1;
if	substr(R6PString,1,3)="YYY" 						and R6PDur=3 and Repossessed=0			then 		R6P3In=1;
if	substr(R6PString,1,3)="YYY" 						and R6PDur>3 and Repossessed=0			then 		R6P3Held=1;
if	substr(R6PString,2,3)="YYY"							and ((R6PDur=0 and Pos2=0) or RepLM=1)	then		R6P3Out=-1;
if	substr(R6PString,1,6)="YYYYYY" 						and R6PDur=6 and Repossessed=0			then 		R6P6In=1;
if	substr(R6PString,1,6)="YYYYYY" 						and R6PDur>6 and Repossessed=0			then 		R6P6Held=1;
if	substr(R6PString,2,6)="YYYYYY"						and ((R6PDur=0 and Pos2=0) or RepLM=1)	then		R6P6Out=-1;
if	substr(R6PString,1,12)="YYYYYYYYYYYY" 				and R6PDur=12 and Repossessed=0			then 		R6P12In=1;
if	substr(R6PString,1,12)="YYYYYYYYYYYY" 				and R6PDur>12 and Repossessed=0			then 		R6P12Held=1;
if	substr(R6PString,2,12)="YYYYYYYYYYYY"				and ((R6PDur=0 and Pos2=0) or RepLM=1)	then		R6P12Out=-1;
if	substr(R6PString,1,24)="YYYYYYYYYYYYYYYYYYYYYYYY" 	and R6PDur=24 and Repossessed=0			then 		R6P24In=1;
if	substr(R6PString,1,24)="YYYYYYYYYYYYYYYYYYYYYYYY" 	and R6PDur>24 and Repossessed=0			then 		R6P24Held=1;
if	substr(R6PString,2,24)="YYYYYYYYYYYYYYYYYYYYYYYY"	and ((R6PDur=0 and Pos2=0) or RepLM=1)	then		R6P24Out=-1;

/*Cases that will roll in within the next few months*/
if	substr(M6PString,1,12)="YYYYYYYYYYYN" 	and M6PDur=11	and Repossessed=0	then	NextIn_1M=1; else NextIn_1M=0;
if	substr(M6PString,1,11)="YYYYYYYYYYN" 	and M6PDur=10	and Repossessed=0 	then	NextIn_2M=1; else NextIn_2M=0;
if	substr(M6PString,1,10)="YYYYYYYYYN" 	and M6PDur=9	and Repossessed=0 	then	NextIn_3M=1; else NextIn_3M=0;
run;

proc summary data=core nway;
var		Mature MatureBal
		MLTAOut MLTAHeld1 MLTAHeld2 MLTAHeld3 MLTAIn
		MLTAOut_Bal MLTAHeld1_Bal MLTAHeld2_Bal MLTAHeld3_Bal MLTAIn_Bal
		RLTAOut RLTAHeld1 RLTAHeld2 RLTAHeld3 RLTAIn
		RLTAOut_Bal RLTAHeld1_Bal RLTAHeld2_Bal RLTAHeld3_Bal RLTAIn_Bal
		M1P3Out M1P3Held M1P3In
		M1P6Out M1P6Held M1P6In
		M1P12Out M1P12Held M1P12In
		M1P24Out M1P24Held M1P24In
		M3P3Out M3P3Held M3P3In
		M3P6Out M3P6Held M3P6In
		M3P12Out M3P12Held M3P12In
		M3P24Out M3P24Held M3P24In
		M6P3Out M6P3Held M6P3In
		M6P6Out M6P6Held M6P6In
		M6P12Out M6P12Held M6P12In
		M6P24Out M6P24Held M6P24In
		NextIn_1M NextIn_2M NextIn_3M 
		;
output	out=summary sum=;
run;
%mend;
%step4;


/*Step 5: RAG payment rating and average arrears reduction*/
%macro	step5;
%let	yymm=%sysfunc(intnx(month,&monthend,0),yymmn4.);
data	core; set core;
if		Arr1 > Arr2	then Det1=1; else Det1=0;
if		Arr2 > Arr3	then Det2=1; else Det2=0;
if		Arr3 > Arr4	then Det3=1; else Det3=0;
if		Arr4 > Arr5	then Det4=1; else Det4=0;
if		Arr5 > Arr6	then Det5=1; else Det5=0;
if		Arr6 > Arr7	then Det6=1; else Det6=0;
if		Arr1 < Arr2	then Imp1=1; else Imp1=0;
if		Arr2 < Arr3	then Imp2=1; else Imp2=0;
if		Arr3 < Arr4	then Imp3=1; else Imp3=0;
if		Arr4 < Arr5	then Imp4=1; else Imp4=0;
if		Arr5 < Arr6	then Imp5=1; else Imp5=0;
if		Arr6 < Arr7	then Imp6=1; else Imp6=0;
if		Arr1 = Arr2	then Same1=1; else Same1=0;
if		Arr2 = Arr3	then Same2=1; else Same2=0;
if		Arr3 = Arr4	then Same3=1; else Same3=0;
if		Arr4 = Arr5	then Same4=1; else Same4=0;
if		Arr5 = Arr6	then Same5=1; else Same5=0;
if		Arr6 = Arr7	then Same6=1; else Same6=0;
if			Det1=1 or sum(Det2,Det3,Det4)>=2	then 	Rating='Red  ';
else if 	(Imp1=1 and Imp2=1 and Imp3=1)		then	Rating='Green';
else 													Rating='Amber';		
if		Rating="Red" 	then	Red=1;
if		Rating="Green"	then 	Green=1;
if		Rating="Amber"	then 	Amber=1;
format red amber green best5.;

/*Average arrears reduction during last three months and expected arrears balance for the next three months*/
Red1=max(0,Arr2-Arr1);
Red2=max(0,Arr3-Arr2);
Red3=max(0,Arr4-Arr3);
/*AvArrRed=round(mean(Red1,Red2,Red3),1);*/ 
AvArrRed=round(median(Red1,Red2,Red3),1); 
if	Rating='Green' or (Rating='Amber' and AvArrRed>0) then ExpAB1=Arr1-(AvArrRed*1); else ExpAB1=Arr1;
if	Rating='Green' or (Rating='Amber' and AvArrRed>0) then ExpAB2=Arr1-(AvArrRed*2); else ExpAB2=Arr1;
if	Rating='Green' or (Rating='Amber' and AvArrRed>0) then ExpAB3=Arr1-(AvArrRed*3); else ExpAB3=Arr1;

if		MLTAHeld1 =1 then HeldGroup="LT12M		";
else if MLTAHeld2 =1 then HeldGroup="12_23M		";
else if MLTAHeld3 =1 then HeldGroup="24M_Plus	";
run;	

proc summary data=core nway;
where 	sum(MLTAHeld1,MLTAHeld2,MLTAHeld3)>0;
class	HeldGroup;
var		Red Amber Green;
output	out=rag_rating_lta sum=;
run;
%mend	step5;
%step5;


/*Step 6: Creating datasets with actuals and expected movements plus additional data*/
data in; set core; LTADur=max(0,(M6PDur-12)); where MLTAIn=1;	
keep AccountNumber AgeYears Rating HeldGroup LTADur Bal1 Arr1 MIA; run;
proc sort data=in;	by AccountNumber; run;

data out; set core; LTADur=max(0,(M6PDur-12)); where MLTAOut=-1;		
keep AccountNumber AgeYears Rating HeldGroup LTADur Bal1 Arr1 MIA; run;
proc sort data=out;	by AccountNumber; run;

data held; set core; LTADur=max(0,(M6PDur-12)); where (MLTAHeld1=1 or MLTAHeld2=1 or MLTAHeld3=1); 	
keep AccountNumber AgeYears Rating HeldGroup LTADur Bal1 Arr1 MIA; run;
proc sort  data=held; by AccountNumber; run;

/*Dataset with Next Rolls In*/
data NextRoll_In; set core; where NextIn_1M=1 or NextIn_2M=1 or NextIn_3M=1;
keep AccountNumber AgeYears M6PDur Rating Bal1 Arr1 MIA NextIn_1M NextIn_2M NextIn_3M AvArrRed ExpAB1 ExpAB2 ExpAB3; run;
proc sort data=NextRoll_In; by AccountNumber; run;

/*Dataset with Expected Rolls Out*/
data NextRoll_Out; set core; where M6P12In=1 or M6P12Held=1;
keep AccountNumber AgeYears M6PDur Rating Bal1 Arr1 MIA AvArrRed ExpAB1 ExpAB2 ExpAB3; run;
proc sort data=NextRoll_Out; by AccountNumber; run;


%let yyyymm=%sysfunc(intnx(month,&monthend,0),yymmn6.);
proc sql;
CONNECT TO odbc	("server=SBSPSQLVS101\MISPSQL01;
				driver=sql server; 
                database=p_dw; 
                trusted connection=yes;");
/*Account Data*/
CREATE TABLE accounts AS 
SELECT * FROM CONNECTION TO ODBC
(
SELECT	CASE	WHEN lu.Allocated_AccountNumber IS NOT NULL THEN lu.Allocated_AccountNumber ELSE da.AccountNumber END AS 'AccountNumber'
		, CASE	WHEN dc.CompanyName='Amber Homeloans Ltd' OR da.AccountOrigin='Amber Homeloans Ltd' THEN 'AHL'
				WHEN dc.CompanyName='North Yorkshire Mortgages' OR da.AccountOrigin='North Yorkshire Mortgages Ltd' THEN 'NYM'
				ELSE 'SBS' END AS 'Lender'
		, da.AccountNumber AS 'AccountOriginal'
		, da.CurrentAccountClassification
		, dsp.SubPopulationCode
		, CASE	WHEN dc.CompanyName IN ('Amber Homeloans Ltd','North Yorkshire Mortgages') AND fma.StandardArrearsInMonths>0 THEN fma.StandardArrearsInMonths
				WHEN dc.CompanyName IN ('Skipton Building Society') AND fma.ContractualArrearsInMonths>0 THEN fma.ContractualArrearsInMonths
				ELSE 0 END AS 'Contractual_MIA'
		, CASE	WHEN dc.CompanyName IN ('Amber Homeloans Ltd','North Yorkshire Mortgages') AND fma.StandardArrearsAmount>0 THEN fma.StandardArrearsAmount
				WHEN dc.CompanyName IN ('Skipton Building Society') AND fma.ContractualArrearsAmount>0 THEN fma.ContractualArrearsAmount
				ELSE 0 END AS 'Contractual_Arrears'
		, fma.HalifaxValuation AS 'HPI_Val'
		, ROUND(fma.[HPI LTV],1) AS 'LTV'
		, CASE	WHEN drt.RepaymentTypeGroup='Capital & Interest' THEN 'C&I' WHEN drt.RepaymentTypeGroup='Part & Part' THEN 'P&P' ELSE 'I/O' END AS 'Rep_Type'
		, dms.ONSRegionCode AS 'HPI_Region'
		/*, CASE	WHEN dms.HPIRegion<=0 THEN 0 ELSE dms.HPIRegion END AS 'HPI_Region'*/
		, YEAR(da.AccountStartDate) AS 'CompletionYear'
		, CASE	WHEN darr.ArrangementTypeCode<1 THEN 'N' ELSE 'Y' END AS 'ArrangementLive'
		, CASE	WHEN da.AccountEndDate IS NULL AND a97.dc_ins_o_dt IS NOT NULL 
					AND (a97.dc_wdrwn_o_dt IS NULL OR a97.dc_wdrwn_o_dt < a97.dc_ins_o_dt)	
					AND (a97.dc_poses_o_dt IS NULL OR a97.dc_poses_o_dt < a97.dc_ins_o_dt)	THEN 'Y' ELSE 'N' END AS 'Litigation'
		, CONVERT(DATE, a97.dc_evict_o_dt) AS 'EvictionDate'
		, CONVERT(DATE, a97.dc_poses_o_dt) AS 'PossessionDate'
		, CONVERT(DATE, a97.dc_wdrwn_o_dt) AS 'ProceedingsWithdrawnDate' 
		, CASE	WHEN da.AccountEndDate IS NOT NULL AND da.AccountEndDate<dm.ReportingMonth THEN 1 ELSE 0 END AS 'RedeemedFlag'
		, CASE	WHEN das.AccountStatus='Possession' THEN 'Y' ELSE 'N' END AS 'Repossessed_Ind'

FROM	P_DW.dbo.factMortgageAccountMonthSS fma

INNER JOIN	P_DW.dbo.dimAccount da
ON	fma.FK_Account = PK_Account
INNER JOIN	P_DW.dbo.dimCompany dc
ON	fma.FK_Company = dc.PK_Company
INNER JOIN	P_DW.dbo.dimRepaymentType drt
ON	fma.FK_RepaymentType = drt.PK_RepaymentType
INNER JOIN	P_DW.dbo.dimMortgageSecurity dms
ON	fma.FK_MortgageSecurity = dms.PK_MortgageSecurity
INNER JOIN	P_DW.dbo.dimProduct dp
ON	fma.FK_CurrentMortgageProduct = dp.PK_Product
INNER JOIN	P_DW.dbo.dimMonth dm
ON	fma.FK_SnapshotDate = dm.PK_Month
INNER JOIN	P_DW.dbo.dimAccountStates das
ON	fma.FK_AccountStates = das.PK_AccountStates
INNER JOIN	P_DW.dbo.dimSubPopulation dsp
ON	fma.FK_SubPopulation = dsp.PK_SubPopulation
INNER JOIN	P_DW.dbo.dimArrangement darr
ON	fma.FK_ArrangementType = darr.PK_ArrangementType 
LEFT JOIN	P_ODS.reference.AHLNYMMigratedAccounts lu
ON	da.AccountPool = lu.AHLNYM_PoolID
AND	da.AccountNumber = lu.AHLNYM_AccountNumber
LEFT JOIN	(SELECT b.* 
			FROM	(
					SELECT	a.*
					, RANK() OVER(PARTITION BY a.accnbr_o ORDER BY a.oid DESC, a._timestamp DESC) AS LatestRecord   
					FROM P_ODS.SKIPCORE.ARR97 a
					WHERE a.pool_id_o='SBS00001'
					)b
			WHERE LatestRecord=1
			)a97
ON	da.AccountNumber = a97.accnbr_o

WHERE	dc.CompanyName IN ('Skipton Building Society','Amber Homeloans Ltd','North Yorkshire Mortgages')
AND		da.AccountPool<>'DRC00001'
AND		dm.CalendarMonthYear=CONVERT(VARCHAR,&yyyymm)
AND		da.AccountSubType='Primary'
AND		da.CurrentAccountClassification<>'Pure Commercial'
AND		da.AccountStartDate IS NOT NULL /*Removes Delayed Completions*/
AND		dp.ProductCode NOT IN ('MIN01','HOM10','HM120','HM121','HM122','HM123','HM124','HM125') /*SBS deed accounts + Holmesdale deed and fair value accounts*/
AND		(das.AccountStatus IN ('Live','Possession') OR
		(da.AccountEndDate IS NOT NULL AND YEAR(da.AccountEndDate)*100+MONTH(da.AccountEndDate)=dm.CalendarMonthYear)) /*Includes month end redemptions*/

ORDER BY (CASE	WHEN lu.Allocated_AccountNumber IS NOT NULL THEN lu.Allocated_AccountNumber ELSE da.AccountNumber END)
);

/*Account CMS*/
CREATE TABLE CMS AS
SELECT * FROM CONNECTION TO ODBC
(
SELECT	CASE	WHEN lu.Allocated_PrimaryAccount IS NOT NULL THEN lu.Allocated_PrimaryAccount ELSE dpa.AccountNumber END AS 'AccountNumber' 
		, SUM(fma.AccountCMSCurrent) AS 'CMS_Current'
		, SUM(fma.AccountCMSNextMonth) AS 'CMS_Next'

FROM	P_DW.dbo.factMortgageAccountMonthSS fma

INNER JOIN	P_DW.dbo.dimAccount da
ON	fma.FK_Account = da.PK_Account
INNER JOIN	P_DW.dbo.dimAccount dpa
ON	fma.FK_PrimaryAccount = dpa.PK_Account
INNER JOIN	P_DW.dbo.dimCompany dc
ON	fma.FK_Company = dc.PK_Company
INNER JOIN	P_DW.dbo.dimMonth dm
ON	fma.FK_SnapshotDate = dm.PK_Month
INNER JOIN	P_DW.dbo.dimAccountStates das
ON	fma.FK_AccountStates = das.PK_AccountStates
LEFT JOIN	P_ODS.reference.AHLNYMMigratedAccounts lu
ON	da.AccountPool = lu.AHLNYM_PoolID
AND	da.AccountNumber = lu.AHLNYM_AccountNumber

WHERE	dc.CompanyName IN ('Skipton Building Society','Amber Homeloans Ltd','North Yorkshire Mortgages')
AND		da.AccountPool<>'DRC00001'
AND		dm.CalendarMonthYear=CONVERT(VARCHAR,&yyyymm)
AND		das.AccountStatus IN ('Live','Possession')
AND		da.CurrentAccountClassification<>'Pure Commercial'
AND		da.AccountStartDate IS NOT NULL /*Removes Delayed Completions*/

GROUP BY	(CASE	WHEN lu.Allocated_PrimaryAccount IS NOT NULL THEN lu.Allocated_PrimaryAccount ELSE dpa.AccountNumber END)

ORDER BY	(CASE	WHEN lu.Allocated_PrimaryAccount IS NOT NULL THEN lu.Allocated_PrimaryAccount ELSE dpa.AccountNumber END)
);

/*Deceased */
CREATE TABLE Dec AS
SELECT * FROM CONNECTION TO ODBC
(
SELECT	DISTINCT	CASE	WHEN lu.Allocated_AccountNumber IS NOT NULL THEN lu.Allocated_AccountNumber ELSE da.AccountNumber END AS 'AccountNumber'
					, 1 AS 'Deceased'

FROM	P_DW.dbo.factMortgageAccountMonthSS fma

INNER JOIN	P_DW.dbo.dimAccount da
ON	fma.FK_Account = da.PK_Account
INNER JOIN	P_DW.dbo.dimCompany dc
ON	fma.FK_Company = dc.PK_Company
INNER JOIN	P_DW.dbo.dimMonth dm
ON	fma.FK_SnapshotDate = dm.PK_Month
INNER JOIN	P_DW.dbo.dimAccountStates das
ON	fma.FK_AccountStates = das.PK_AccountStates
INNER JOIN	P_DW.dbo.bridgeAccountCustomer bac
ON	da.PK_Account = bac.FK_Account
INNER JOIN	P_DW.dbo.dimCustomer dcu
ON	bac.FK_Customer = dcu.PK_Customer
INNER JOIN	P_DW.dbo.dimMortgageSecurity dms
ON	fma.FK_MortgageSecurity = dms.PK_MortgageSecurity
LEFT JOIN	P_ODS.reference.AHLNYMMigratedAccounts lu
ON	da.AccountPool = lu.AHLNYM_PoolID
AND	da.AccountNumber = lu.AHLNYM_AccountNumber

WHERE	dc.CompanyName IN ('Skipton Building Society','Amber Homeloans Ltd','North Yorkshire Mortgages')
AND		da.AccountPool<>'DRC00001'
AND		dm.CalendarMonthYear=CONVERT(VARCHAR,&yyyymm)
AND		da.AccountSubType='Primary'
AND		das.AccountStatus IN ('Live','Possession')
AND		da.CurrentAccountClassification<>'Pure Commercial'
AND		(CASE	WHEN dc.CompanyName IN ('Amber Homeloans Ltd','North Yorkshire Mortgages') AND fma.StandardArrearsAmount>0 THEN fma.StandardArrearsAmount
				WHEN dc.CompanyName IN ('Skipton Building Society') AND fma.ContractualArrearsAmount>0 THEN fma.ContractualArrearsAmount
				ELSE 0 END)>0
AND		da.AccountStartDate IS NOT NULL /*Removes Delayed Completions*/
AND		(dcu.CustomerDateofDeath IS NOT NULL
		OR dms.PostalName LIKE ('%DECD%') 
		OR dms.PostalName LIKE ('%PERS REPS%'))

ORDER BY (CASE	WHEN lu.Allocated_AccountNumber IS NOT NULL THEN lu.Allocated_AccountNumber ELSE da.AccountNumber END)
);

/*Redemption statement requested between first and last day of previous month*/
CREATE TABLE redsta AS
SELECT * FROM CONNECTION TO ODBC
(
SELECT	b.AccountNumber, b. Red_Letter_Sent, 1 AS RedStaInd
FROM	(
		SELECT	a.*, RANK() OVER(PARTITION BY a.AccountNumber ORDER BY a.Red_Letter_Sent DESC, a.oid DESC) AS 'LastSent'
		FROM	( 
				SELECT	a98.accnbr_o AS 'AccountNumber'
						, a98.lettcode_o AS 'Letter_Code'
						, CONVERT(DATE,a98.dc_creat_o_dt) AS 'Red_Letter_Sent'
						, a98.oid
		
				FROM	P_ODS.SKIPCORE.ADM98 a98

				WHERE	a98.pool_id_o='SBS00001'
				AND		a98.lettcode_o IN ('RED001','RED01F','RED01E') 
				AND		a98.dc_creat_o_dt BETWEEN DATEADD(MONTH,DATEDIFF(MONTH,0,GETDATE())-1,0) AND DATEADD(MONTH,DATEDIFF(MONTH,-1,GETDATE())-1,-1)
				)a
		)b
WHERE		b.LastSent=1
ORDER BY	b.AccountNumber
);
DISCONNECT FROM odbc;
;
quit; 


/*Step 7: Data merge*/
data	in;
merge	in(in=a) accounts(in=b) Dec(in=c) redsta(in=d);
by		AccountNumber; 
if		a;
run;

data	out;
merge	out(in=a) accounts(in=b) Dec(in=c) redsta(in=d);
by		AccountNumber; 
if		a;
run;

data	held;
merge	held(in=a) accounts(in=b) Dec(in=c) redsta(in=d);
by		AccountNumber; 
if		a;
run;

data	NextRoll_In;
merge	NextRoll_In(in=a) accounts(in=b) CMS(in=c);
by		AccountNumber; 
if		a;

%let	yymm=%sysfunc(intnx(month,&monthend,0),yymmn4.);

ExpMIA1=round(ExpAB1/CMS_Next,0.00001);
ExpMIA2=round(ExpAB2/CMS_Next,0.00001);
ExpMIA3=round(ExpAB3/CMS_Next,0.00001);

if		EvictionDate='' then EvFlag=0; 
else if EvictionDate ne '' and substr(EvictionDate,3,2)||substr(EvictionDate,6,2)=put(intnx('month',&monthend,0,'e'),yymmn4.) then EvFlag=1;
else if EvictionDate ne '' and substr(EvictionDate,3,2)||substr(EvictionDate,6,2)=put(intnx('month',&monthend,1,'e'),yymmn4.) then EvFlag=2;
else if EvictionDate ne '' and substr(EvictionDate,3,2)||substr(EvictionDate,6,2)=put(intnx('month',&monthend,2,'e'),yymmn4.) then EvFlag=3;
else	EvFlag=0;	

if	NextIn_1M=1 and ExpMIA1>=6 and EvFlag ne 1 then Group1=1; else Group1=0; 
if	NextIn_2M=1 and ExpMIA2>=6 and EvFlag ne 2 then Group2=1; else Group2=0; 
if	NextIn_3M=1 and ExpMIA3>=6 and EvFlag ne 3 then Group3=1; else Group3=0; 

if	Group1=1 then Group=1; else if Group1=0 and Group2=1 then Group=2; else if Group1=0 and Group2=0 and Group3=1 then Group=3; else Group=0;
if	Group1=1 then Group=1; else if Group1=0 and Group2=1 then Group=2; else if Group1=0 and Group2=0 and Group3=1 then Group=3; else Group=0;

drop	CurrentAccountClassification NextIn_1M NextIn_2M NextIn_3M;
run;

data	NextRoll_In;
merge	NextRoll_In(in=a) Dec(in=b) redsta(in=c);
by		AccountNumber;
if		a;
run;


data	NextRoll_Out;
merge	NextRoll_Out(in=a) accounts(in=b) CMS(in=c);
by		AccountNumber; 
if		a;

ExpMIA1=round(ExpAB1/CMS_Next,0.00001);
ExpMIA2=round(ExpAB2/CMS_Next,0.00001);
ExpMIA3=round(ExpAB3/CMS_Next,0.00001);

if		EvictionDate='' then EvFlag=0; 
else if EvictionDate ne '' and substr(EvictionDate,3,2)||substr(EvictionDate,6,2)=put(intnx('month',&monthend,1,'e'),yymmn4.) then EvFlag=1;
else if EvictionDate ne '' and substr(EvictionDate,3,2)||substr(EvictionDate,6,2)=put(intnx('month',&monthend,2,'e'),yymmn4.) then EvFlag=2;
else if EvictionDate ne '' and substr(EvictionDate,3,2)||substr(EvictionDate,6,2)=put(intnx('month',&monthend,3,'e'),yymmn4.) then EvFlag=3;
else	EvFlag=0;	

if	(AvArrRed>0 and Rating IN ('Green' 'Amber') and ExpMIA1<6) or EvFlag=1 then Group1=1; else Group1=0; 
if	(AvArrRed>0 and Rating IN ('Green' 'Amber') and ExpMIA2<6) or EvFlag=2 then Group2=1; else Group2=0; 
if	(AvArrRed>0 and Rating IN ('Green' 'Amber') and ExpMIA3<6) or EvFlag=3 then Group3=1; else Group3=0; 

if	Group1=1 then Group=1; else if Group1=0 and Group2=1 then Group=2; else if Group1=0 and Group2=0 and Group3=1 then Group=3; else Group=0;
if	Group1=1 then Group=1; else if Group1=0 and Group2=1 then Group=2; else if Group1=0 and Group2=0 and Group3=1 then Group=3; else Group=0;

drop	CurrentAccountClassification;

run;

data	NextRoll_Out;
merge	NextRoll_Out(in=a) Dec(in=b) redsta(in=c);
by		AccountNumber;
if		a;
run;


proc sort data=in;				by descending bal1;			run;
proc sort data=held;			by descending ltv;			run;
proc sort data=out;				by descending bal1;			run;
proc sort data=NextRoll_In;		by Group descending bal1;	run;
proc sort data=NextRoll_Out;	by Group descending bal1;	run;


/*Data Exports*/
data out.core;			set core;			run;
data out.accounts;		set accounts;		run;
data out.in;			set in;				run;
data out.out;			set out;			run;
data out.held;			set held; 			run;
data out.NextRoll_In;	set NextRoll_In;	run;
data out.NextRoll_Out;	set NextRoll_Out;	run;


/*Removing not qualifying Roll In & Roll Out cases*/
data NextRoll_Out;	set NextRoll_Out;	if Group ne 0; run;
data NextRoll_In;	set NextRoll_In;	if Group ne 0; run;


/*Step 8: Proc exports*/
proc export data=summary 
outfile="H:\Portfolio Management\Long Term Arrears\Detailed MIA Report\Report Summary.xlsx"
dbms=xlsx replace;
sheet="&yymm";
proc export data=rag_rating_lta 
outfile="H:\Portfolio Management\Long Term Arrears\Detailed MIA Report\Report Summary.xlsx"
dbms=xlsx replace;
sheet="RAG&yymm";
proc export data=in
outfile="H:\Portfolio Management\Long Term Arrears\Detailed MIA Report\Report Summary.xlsx"
dbms=xlsx replace;
sheet="LTA_In";
proc export data=out
outfile="H:\Portfolio Management\Long Term Arrears\Detailed MIA Report\Report Summary.xlsx"
dbms=xlsx replace;
sheet="LTA_Out";
proc export data=held
outfile="H:\Portfolio Management\Long Term Arrears\Detailed MIA Report\Report Summary.xlsx"
dbms=xlsx replace;
sheet="Held";
proc export data=NextRoll_In
outfile="H:\Portfolio Management\Long Term Arrears\Detailed MIA Report\Report Summary.xlsx"
dbms=xlsx replace;
sheet="NextRoll_In";
proc export data=NextRoll_Out
outfile="H:\Portfolio Management\Long Term Arrears\Detailed MIA Report\Report Summary.xlsx"
dbms=xlsx replace;
sheet="NextRoll_Out";
run;

/*Step 9: Additional LTA data*/
data	In2;
set		In;
AccType='    ';
if SubPopulationCode='BTL' then AccType='BTL'; else AccType='Resi';
LTAType='             ';
LTAType='RolledIn';
keep AccountNumber MIA Lender Rating ArrangementLive Litigation EvictionDate AccType LTAType;
run;

data	Out2;
set		Out;
AccType='    ';
if SubPopulationCode='BTL' then AccType='BTL'; else AccType='Resi';
LTAType='             ';
LTAType='RolledOut';
if RedeemedFlag=0 and Repossessed_Ind='N';
keep AccountNumber MIA Lender Rating ArrangementLive Litigation EvictionDate AccType LTAType;
run;

data	Held2;
set		Held;
AccType='    ';
if SubPopulationCode='BTL' then AccType='BTL'; else AccType='Resi';
LTAType='             ';
if		HeldGroup='LT12M' then LTAType='Held<12M';
else if	HeldGroup='12_23M' then LTAType='12M<=Held<23M';
else 							LTAType='Held>=24M';
keep AccountNumber MIA Lender Rating ArrangementLive Litigation EvictionDate AccType LTAType;
run;

data	NextRoll_In2;
set		NextRoll_In;
AccType='    ';
if SubPopulationCode='BTL' then AccType='BTL'; else AccType='Resi';
LTAType='             ';
if		Group=1 then LTAType='NextRollIn1M';
else if	Group=2 then LTAType='NextRollIn2M';
else	LTAType='NextRollIn3M';
keep AccountNumber MIA Lender Rating ArrangementLive Litigation EvictionDate AccType LTAType;
run;

data	NextRoll_Out2;
set		NextRoll_Out;
AccType='    ';
if SubPopulationCode='BTL' then AccType='BTL'; else AccType='Resi';
LTAType='             ';
if		Group=1 then LTAType='NextRollOut1M';
else if	Group=2 then LTAType='NextRollOut2M';
else	LTAType='NextRollOut3M';
keep AccountNumber MIA Lender Rating ArrangementLive Litigation EvictionDate AccType LTAType;
run;

data	New;
set		In2 Held2 NextRoll_In2;
run;
proc sort data=New; by AccountNumber; run;


proc sql;
CONNECT TO odbc	("server=SBSPSQLVS101\MISPSQL01;
				driver=sql server; 
                database=p_dw; 
                trusted connection=yes;");
CREATE TABLE Arrang AS 
SELECT * FROM CONNECTION TO ODBC
(
WITH CTE_AP AS
(
SELECT	CASE	WHEN lu.Allocated_PrimaryAccount IS NOT NULL THEN lu.Allocated_PrimaryAccount ELSE dpa.AccountNumber END AS 'AccountNumber' 
		, COUNT(da.AccountNumber) AS 'NoAcc'
		, SUM(fma.AccountCMSCurrent) AS 'CMS'
		, SUM(fma.AccountContractualPaymentArrangement) AS 'ArrAmn'
		, SUM(fma.AccountPaymentThisMonth) AS 'Paid'
	
FROM	P_DW.dbo.factMortgageAccountMonthSS fma

INNER JOIN	P_DW.dbo.dimAccount da
ON	fma.FK_Account = da.PK_Account
INNER JOIN	P_DW.dbo.dimAccount dpa
ON	fma.FK_PrimaryAccount = dpa.PK_Account
INNER JOIN	P_DW.dbo.dimCompany dc
ON	fma.FK_Company = dc.PK_Company
INNER JOIN	P_DW.dbo.dimProduct dp
ON	fma.FK_CurrentMortgageProduct = dp.PK_Product
INNER JOIN	P_DW.dbo.dimMonth dm
ON	FK_SnapshotDate = dm.PK_Month
INNER JOIN	P_DW.dbo.dimAccountStates das
ON	FK_AccountStates = das.PK_AccountStates
INNER JOIN	P_DW.dbo.dimArrangement dar
ON	fma.FK_ArrangementType = dar.PK_ArrangementType
INNER JOIN	P_DW.dbo.dimDate darrd
ON	fma.FK_DatePaymentArrangementEnd = darrd.PK_Date
LEFT JOIN	P_ODS.reference.AHLNYMMigratedAccounts lu
ON	da.AccountPool = lu.AHLNYM_PoolID
AND	da.AccountNumber = lu.AHLNYM_AccountNumber

WHERE	dc.CompanyName IN ('Skipton Building Society','Amber Homeloans Ltd','North Yorkshire Mortgages')
AND		da.AccountPool<>'DRC00001'
AND		dm.CalendarMonthYear=CONVERT(VARCHAR,&yyyymm)
AND		das.AccountStatus IN ('Live')
AND		da.CurrentAccountClassification<>'Pure Commercial'
AND		dp.ProductCode NOT IN ('MIN01','HOM10','HM120','HM121','HM122','HM123','HM124','HM125')

GROUP BY (CASE	WHEN lu.Allocated_PrimaryAccount IS NOT NULL THEN lu.Allocated_PrimaryAccount ELSE dpa.AccountNumber END)
),

CTE_AR AS 
(
SELECT	DISTINCT da.AccountNumber, 1 AS 'ARFlag'
FROM	P_DW.dbo.factMortgageAccount fma

INNER JOIN	P_DW.dbo.dimAccount da
ON	fma.FK_Account = da.PK_Account
INNER JOIN	P_DW.dbo.bridgeAccountCustomer bac
ON	da.PK_Account = bac.FK_Account
AND	bac.DeLinkDate IS NULL
AND	bac.relationshipTypeCode=19
INNER JOIN	P_DW.dbo.dimCustomer dc
ON	bac.FK_Customer = dc.PK_Customer

WHERE	da.AccountPool='SBS00001'
AND		da.AccountSubType='Primary'
AND		da.CurrentAccountClassification='Residential'
AND		da.CurrentAccountStatus='Live' 
AND		dc.CustomerNumber IN	(SELECT DISTINCT a.CustomerNumber 
								FROM	(SELECT	c01.custnbr_u AS 'CustomerNumber'
												, dcv.changeToService AS 'ChangeOfService'
												, ISNULL(dcv.additionalRequirements,'') AS 'ChangeOfServiceNotes'
												, ISNULL(dcv.notes,'') AS 'CustomerCircumstances'
												, IIF(dcv.consent=1,'Y','N') AS 'ConsentReceived'
												, ISNULL(sncr.[description],'Unknown') AS 'ReasonNoConsent'
												, ISNULL(dcv.thirdPartyDiscloser,'Unknown') AS 'ThirdPartyName'
												, ISNULL(svd.[description],'Unknown') AS 'DisclosureMethod'
												, dvc.value+': '+dvc.categoryDescription AS 'Category'
												, IIF(dcv.marketCustomer=1,'Y','N') AS 'ContinueToMarket'
												, CONVERT(DATE,dcv.reviewDate) AS 'NextReviewDate'
												, dcv.reasonForReview AS 'ReviewReason'
												, CONVERT(DATE,dcv.dateFirstRecorded) AS 'FirstRecorded'
												, CONVERT(DATE,dcv.dateLastChanged) AS 'LastUpdated'
												, CONVERT(DATE,dcv.removalDate) AS 'RemovalDate'
												, ISNULL(svrr.[description],'Unknown') AS 'RemovalReason'

										FROM	P_ODS.SKIPCORE.DatCustomerVulnerability dcv
										INNER JOIN	P_ODS.SKIPCORE.CUS01 c01
										ON	dcv.myCustomer = c01.oid
										AND	c01.fndr_id_o='SBS'
										INNER JOIN	P_ODS.SKIPCORE.DatCustomerVulnerability_allMyCategories dvac
										ON	dcv.oid = dvac.DatCustomerVulnerability_oid
										INNER JOIN	P_ODS.SKIPCORE.StcVulnerabilityCategory dvc
										ON	dvac.StcVulnerabilityCategory_oid = dvc.oid
										LEFT JOIN	P_ODS.SKIPCORE.StcVulnerabilityDisclosure svd
										ON	dcv.myDisclosureMethod = svd.oid
										LEFT JOIN	P_ODS.SKIPCORE.StcVulnerabilityRemovalReason svrr
										ON	dcv.myRemovalReason = svrr.oid
										LEFT JOIN	P_ODS.SKIPCORE.StcNoConsentReason sncr
										ON	dcv.myNoConsentReason = sncr.oid

										WHERE	dcv.removalDate IS NULL

										/*ORDER BY c01.custnbr_u, dvc.value*/
										)a
								)
)

SELECT	CASE	WHEN lu.Allocated_AccountNumber IS NOT NULL THEN lu.Allocated_AccountNumber ELSE da.AccountNumber END AS 'AccountNumber' 
		, dar.ArrangementTypeCode 'ArrangementCode'
		, dar.ArrangementDescription 'ArrangementDesc'
		, CONVERT(DATE,darrd.CalendarDate) 'ArrangementEndDate'
		, ap.NoAcc
		, ap.CMS
		, CASE	WHEN dar.ArrangementTypeCode=-1 THEN 0 ELSE ap.ArrAmn END AS 'ArrangementAmn' 
		, ap.Paid
		, CASE	WHEN dar.ArrangementTypeCode=5 AND ap.Paid<ap.CMS THEN 1 /*DD arrangements*/  
				WHEN dar.ArrangementTypeCode IN ('63','65','68') AND ap.ArrAmn IN ('0','1') AND ap.Paid<ap.CMS THEN 1 /*DWP Arrangements*/
				WHEN dar.ArrangementTypeCode IN ('63','65','68') AND ap.ArrAmn>1 AND ap.Paid<ap.ArrAmn THEN 1 /*DWP Arrangements*/ 
				WHEN dar.ArrangementTypeCode=6 AND ap.Paid<ap.ArrAmn THEN 1 /*Concessions*/
				WHEN dar.ArrangementTypeCode=-1 THEN 0 /*No arrangements in place*/
				WHEN dar.ArrangementTypeCode NOT IN ('-1','5','6','63','65','68') AND ap.Paid<ap.ArrAmn AND ap.ArrAmn-ap.Paid>5 THEN 1 /*Other arrangements - Shortfalls>£5*/
				ELSE 0 END AS 'BrokenArrangement'
		, ISNULL(ar.ARFlag,0) AS 'ARFlag'
	
FROM	P_DW.dbo.factMortgageAccountMonthSS fma

INNER JOIN	P_DW.dbo.dimAccount da
ON	fma.FK_Account = da.PK_Account
INNER JOIN	P_DW.dbo.dimAccount dpa
ON	fma.FK_PrimaryAccount = dpa.PK_Account
INNER JOIN	P_DW.dbo.dimCompany dc
ON	fma.FK_Company = dc.PK_Company
INNER JOIN	P_DW.dbo.dimProduct dp
ON	fma.FK_CurrentMortgageProduct = dp.PK_Product
INNER JOIN	P_DW.dbo.dimMonth dm
ON	FK_SnapshotDate = dm.PK_Month
INNER JOIN	P_DW.dbo.dimAccountStates das
ON	FK_AccountStates = das.PK_AccountStates
INNER JOIN	P_DW.dbo.dimArrangement dar
ON	fma.FK_ArrangementType = dar.PK_ArrangementType
INNER JOIN	P_DW.dbo.dimDate darrd
ON	fma.FK_DatePaymentArrangementEnd = darrd.PK_Date
INNER JOIN	CTE_AP ap
ON	da.AccountNumber = ap.AccountNumber
LEFT JOIN	CTE_AR ar
ON	da.AccountNumber = ar.AccountNumber
LEFT JOIN	P_ODS.reference.AHLNYMMigratedAccounts lu
ON	da.AccountPool = lu.AHLNYM_PoolID
AND	da.AccountNumber = lu.AHLNYM_AccountNumber

WHERE	dc.CompanyName IN ('Skipton Building Society','Amber Homeloans Ltd','North Yorkshire Mortgages')
AND		da.AccountPool<>'DRC00001'
AND		dm.CalendarMonthYear=CONVERT(VARCHAR,&yyyymm)
AND		da.AccountSubType='Primary'
AND		das.AccountStatus IN ('Live')
AND		da.CurrentAccountClassification<>'Pure Commercial'
AND		dp.ProductCode NOT IN ('MIN01','HOM10','HM120','HM121','HM122','HM123','HM124','HM125')
AND		fma.ContractualArrearsInMonths>=1

ORDER BY (CASE	WHEN lu.Allocated_AccountNumber IS NOT NULL THEN lu.Allocated_AccountNumber ELSE da.AccountNumber END)  
)
;
DISCONNECT FROM odbc;
;
quit;

data	AddLTAdata;
merge	New(in=a) Arrang(in=b);
by		AccountNumber;
if		a;
run;


proc export data=AddLTAdata
outfile="H:\Portfolio Management\Long Term Arrears\Detailed MIA Report\AdditionalLTAData.xlsx"
dbms=xlsx replace;
run;


data	lta;
set		new;
if		LTAType in ('RolledIn' 'Held<12M' '12M<=Held<23M' 'Held>=24M');
keep	AccountNumber Lender LTAType;
run;

proc export data=lta
outfile="H:\Portfolio Management\Long Term Arrears\Detailed MIA Report\LTA List.xlsx"
dbms=xlsx replace;
run;

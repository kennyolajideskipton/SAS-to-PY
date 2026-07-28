"""
affordability_check_final.py

End-to-end Python affordability simulation engine converted from the supplied SAS code.

This final version merges the parameter-table-driven Living and Lifestyle expenditure
engine into the wider affordability flow. It DOES NOT use LivingModel_N9 or
LifestyleModel_N10 as inputs. Those fields are only used, if present, to calculate
validation differences against existing Powercurve/SAS outputs.

Required files in the same folder by default:
- affordability_check_final.py
- affordability_parameter_tables.xlsx

Basic command-line usage:
    python affordability_check_final.py --input sample_input.xlsx --output simulation_output.xlsx

Optional:
    python affordability_check_final.py --input sample_input.csv --output simulation_output.xlsx --params affordability_parameter_tables.xlsx
"""

from __future__ import annotations

import argparse
import math
from pathlib import Path
from typing import Any, Dict, Tuple

import numpy as np
import pandas as pd


# =============================================================================
# SAS behaviour helpers
# =============================================================================

def n(value: Any, default: float = 0.0) -> float:
    """Numeric coalesce. Mirrors SAS SUM-style handling where missing values are ignored."""
    if value is None:
        return default
    try:
        if pd.isna(value):
            return default
    except TypeError:
        pass
    try:
        return float(value)
    except Exception:
        return default


def s(value: Any, default: str = "") -> str:
    """String coalesce."""
    if value is None:
        return default
    try:
        if pd.isna(value):
            return default
    except TypeError:
        pass
    return str(value)


def sas_sum(*values: Any) -> float:
    return sum(n(v) for v in values)


def sas_round(value: Any, unit: float = 1.0) -> float:
    value = n(value)
    if unit == 0:
        return value
    return round(value / unit) * unit


def sas_int(value: Any) -> float:
    return float(math.trunc(n(value)))


def trunc6(value: Any) -> float:
    return sas_int(n(value) * 1_000_000) / 1_000_000


def floor_to(value: Any, base: float = 100.0) -> float:
    return math.floor(n(value) / base) * base


def parse_date(value: Any) -> pd.Timestamp:
    if value is None:
        return pd.NaT
    try:
        if pd.isna(value):
            return pd.NaT
    except TypeError:
        pass
    return pd.to_datetime(str(value)[:10], errors="coerce")


def yrdif_age(dob: Any, as_at: Any) -> float:
    dob_dt = parse_date(dob)
    as_at_dt = parse_date(as_at)
    if pd.isna(dob_dt) or pd.isna(as_at_dt):
        return 0.0
    years = as_at_dt.year - dob_dt.year
    if (as_at_dt.month, as_at_dt.day) < (dob_dt.month, dob_dt.day):
        years -= 1
    return float(years)


def get_value(row: pd.Series, col: str, default: Any = 0) -> Any:
    return row[col] if col in row.index else default


# =============================================================================
# Input / output
# =============================================================================

def load_input(path: str | Path, sheet_name: str | int = 0) -> pd.DataFrame:
    path = Path(path)
    if path.suffix.lower() in [".xlsx", ".xlsm"]:
        return pd.read_excel(path, sheet_name=sheet_name, engine="openpyxl")
    if path.suffix.lower() == ".csv":
        return pd.read_csv(path)
    if path.suffix.lower() in [".txt", ".tsv"]:
        return pd.read_csv(path, sep="\t")
    raise ValueError(f"Unsupported input file type: {path.suffix}")


def export_results(df: pd.DataFrame, output_path: str | Path) -> None:
    output_path = Path(output_path)

    validation_cols = [c for c in df.columns if c.startswith("Diff") or c.startswith("Difference")]
    key_cols = [
        "MortgageAccountNumber", "Edition", "ApplicationType_app", "LoanType_app", "BTLFlag",
        "HouseholdComp", "Household_GAI", "Household_NMI", "SAS_MCC",
        "SAS_MonthlyLiving6", "SAS_MonthlyLife", "SAS_ModelledOutgoings", "SAS_EDI",
        "SAS_StressedMort", "SAS_Affordability", "RawMaxLoan", "SAS_MaxLTI",
        "altterm", "rental_cover", "TopSlicingAvailable",
    ]
    cols = [c for c in key_cols if c in df.columns] + [c for c in validation_cols if c in df.columns]

    with pd.ExcelWriter(output_path, engine="openpyxl") as writer:
        df[[c for c in cols if c in df.columns]].drop_duplicates().to_excel(writer, index=False, sheet_name="DeDupedSummary")
        df.to_excel(writer, index=False, sheet_name="AllData")
        if validation_cols:
            summary = []
            for c in validation_cols:
                vals = pd.to_numeric(df[c], errors="coerce")
                summary.append({
                    "ValidationField": c,
                    "Rows": int(vals.notna().sum()),
                    "ZeroDiffRows": int((vals.fillna(0).round(6) == 0).sum()),
                    "NonZeroDiffRows": int((vals.fillna(0).round(6) != 0).sum()),
                    "MinDiff": vals.min(),
                    "MaxDiff": vals.max(),
                    "MeanDiff": vals.mean(),
                })
            pd.DataFrame(summary).to_excel(writer, index=False, sheet_name="ValidationSummary")


# =============================================================================
# Initial filtering and flags / pipeline
# =============================================================================

def filter_score_data(df: pd.DataFrame) -> pd.DataFrame:
    out = df.copy()
    if "ApplicationType_app" in out.columns:
        excluded_app_types = {"D1", "CV", "FW", "MISSING", "PS"}
        out = out[~out["ApplicationType_app"].astype(str).isin(excluded_app_types)]
    if "LoanType_app" in out.columns:
        out = out[out["LoanType_app"].astype(str) != "string"]
    return out.reset_index(drop=True)


def derive_flags(row: pd.Series) -> pd.Series:
    r = row.copy()
    r["RealWageInflation"] = (1.08455092473664 / 1.04887218045113) - 1
    r["Rateplus1"] = n(get_value(r, "InterestRateN130_app")) + 1

    if s(get_value(r, "SecRegion_app", "")) == "MISSING":
        r["SecRegion_app"] = get_value(r, "App1_CorrRegion_app", "")

    r["Help_To_Buy_Flag"] = int(s(get_value(r, "HTB_FlagS1_app")) == "Y" or n(get_value(r, "FHTBLoanAmountN42_app")) > 0)
    r["HTBFlag"] = int(s(get_value(r, "HTB_FlagS1_app")) == "Y")
    r["HTB_Equity_Loan_Balance"] = n(get_value(r, "HTBEquityLoan_app"))

    if r["Help_To_Buy_Flag"] == 1 and n(get_value(r, "LTV_app")) != 0:
        denom = n(get_value(r, "TotalLoanAmount_app")) / n(get_value(r, "LTV_app"))
        r["Risk_LTV"] = (n(get_value(r, "TotalLoanAmount_app")) + r["HTB_Equity_Loan_Balance"] + n(get_value(r, "FHTBLoanAmountN42_app"))) / denom if denom else n(get_value(r, "LTV_app"))
    else:
        r["Risk_LTV"] = n(get_value(r, "LTV_app"))

    r["SOFlag"] = int(s(get_value(r, "LoanType_app")) == "O" or n(get_value(r, "SO_RentN48_app")) > 0)
    r["AB_Flag"] = int(s(get_value(r, "ApplicationType_app")).upper().startswith("F"))
    r["BTLFlag"] = int(s(get_value(r, "LoanType_app")) in {"A", "B", "C", "Q"})

    if n(get_value(r, "No_BTLsInProgressN43_app")) >= 4:
        r["BTLType"] = "PBTL"
    elif n(get_value(r, "No_BTLsInProgressN43_app")) > 0:
        r["BTLType"] = "BTL"
    else:
        r["BTLType"] = "N/A"

    r["IOFlag"] = int(n(get_value(r, "IntOnlyAmt_app")) > 0)
    r["TRFlag"] = int(s(get_value(r, "TrackRecordFlag_S11")) == "Y")
    r["LISAFlag"] = int(s(get_value(r, "LISA_FlagS16_app")) == "Y" and n(get_value(r, "LISADeposit_app")) > 4000)

    remo = [f"RemoNum{i}_app" for i in range(95, 105)]
    r["Like4LikeFlag"] = int(n(get_value(r, "RemoNum95_app")) > 0 and all(n(get_value(r, c)) == 0 for c in remo[1:]))

    loan_type = s(get_value(r, "LoanType_app"))
    app_type = s(get_value(r, "ApplicationType_app"))
    five_year = s(get_value(r, "FiveYRFixed_FlagS2_app")) == "Y"
    three_stage = s(get_value(r, "ThreeStageProduct_FlagS14_app"))
    product_term = n(get_value(r, "Product_TermN40_app"))
    product_type = s(get_value(r, "ProductTypeS3_app"))
    resi_app_types = {"B1", "C1", "D1", "D2", "PA", "FA", "FC", "FW", "FD", "CV"}

    r["Threetier"] = int(
        (app_type == "W" and not five_year)
        or (loan_type not in {"A", "B", "C", "Q"} and app_type in resi_app_types and three_stage == "MISSING" and not five_year)
        or (loan_type not in {"A", "B", "C", "Q"} and app_type in resi_app_types and three_stage == "Y")
    )
    r["Longstress"] = int(
        (app_type == "W" and five_year)
        or (loan_type not in {"A", "B", "C", "Q"} and five_year and app_type in {"B1", "D1", "D2"})
        or (loan_type not in {"A", "B", "C", "Q"} and app_type in resi_app_types and 59 < product_term < 999 and product_type == "FIX")
    )

    app_created = parse_date(get_value(r, "AppCreatedDate"))
    app_submit = parse_date(get_value(r, "AppSubmitDate"))
    r["AppCreatedDate1"] = app_created
    r["AppSubmitDate1"] = app_submit
    r["OfferDate1"] = parse_date(get_value(r, "OfferDate"))
    r["ScoreRunAt"] = parse_date(get_value(r, "ExecutedAt_res"))
    r["PipelineStrat"] = get_value(r, "PipelineStrategyResult_S4", "")

    if app_type in {"D2", "FD"}:
        pipeline_date = app_created
    elif pd.notna(app_created) and pd.notna(app_submit) and app_created + pd.Timedelta(days=28) < app_submit:
        pipeline_date = app_submit
    else:
        pipeline_date = app_created
    r["PipelineDate"] = pipeline_date

    gates = {
        "Afford1Pipeline": "2025-02-03",
        "BTLStress1Pipeline": "2025-02-03",
        "ResiStress1Pipeline": "2025-02-03",
        "LTIChangePipeline": "2025-06-09",
        "Afford2Pipeline": "2025-07-28",
        "Afford3Pipeline": "2025-10-23",
        "LTIChange1Pipeline": "2025-11-05",
        "LTIChange2Pipeline": "2025-12-24",
        "LTIChange3Pipeline": "2026-03-02",
        "Afford4Pipeline": "2026-07-13",
    }
    for out_col, date_str in gates.items():
        gate = parse_date(date_str)
        r[out_col] = "Y" if s(r.get("PipelineStrat")) == "Y" and pd.notna(pipeline_date) and pipeline_date < gate else "N"
    return r


# =============================================================================
# Gross-to-net income
# =============================================================================
TAX = {
    "EngBRT": 0.20, "EngHRT": 0.40, "EngART": 0.45, "EngTFA": 12570, "EngBasic": 37700,
    "EngHigher": 125140, "EngIncLimit": 100000,
    "ScoSRT": 0.19, "ScoBRT": 0.20, "ScoIRT": 0.21, "ScoHRT": 0.42, "ScoADV": 0.45,
    "ScoART": 0.48, "ScoTFA": 12570, "ScoStarter": 3967, "ScoBasic": 16956,
    "ScoInterm": 31092, "ScoHigher": 62430, "ScoAdvanced": 125140, "ScoIncLimit": 100000,
    "DivTFA": 500, "DivBRT": 0.1075, "DivHRT": 0.3575, "DivART": 0.3935,
    "NI1Prim": 0.08, "NI1High": 0.02, "NI1PrimThres": 12570, "NI1UpperThres": 50270,
    "NI4Prim": 0.06, "NI4High": 0.02, "NI4PrimThres": 12570, "NI4UpperThres": 50270,
}


def applicant_net_income(row: pd.Series, i: int) -> Dict[str, Any]:
    emp_type_field = f"App{i}_EmpType_app" if i in (1, 2) else f"App{i}_EmpTypeS{11 if i == 3 else 13}_app"
    emp_code = s(get_value(row, emp_type_field))
    emp_type = "Not Employed" if emp_code in {"L", "O", "R"} else "Employed" if emp_code in {"E", "S"} else ""

    itbt = n(get_value(row, f"App{i}_GrossBasicInc_app")) + n(get_value(row, f"App{i}_GrossGuarInc_app")) + 0.5 * n(get_value(row, f"App{i}_GrossNonGuarInc_app"))
    pre_pension_itbt = itbt
    div = n(get_value(row, f"App{i}DividendIncN{33 + i}_app"))
    benefit = n(get_value(row, f"App{i}BenefitInc_app"))
    maintenance = n(get_value(row, f"App{i}MaintenanceIncN{79 + i}_app"))
    nonvolpen = n(get_value(row, f"App{i}NonVolPensionN{62 + i}_app"))

    modelpen = sas_round(itbt * 0.05, 0.01) if emp_type != "Not Employed" else 0.0
    pension_deduct = sas_round(max(modelpen, nonvolpen), 0.01)
    itbt = itbt - pension_deduct

    is_scot = s(get_value(row, "SecRegion_app")) == "SC"
    inc_limit = TAX["ScoIncLimit"] if is_scot else TAX["EngIncLimit"]
    tfa = TAX["ScoTFA"] if is_scot else TAX["EngTFA"]

    if itbt + div <= inc_limit:
        pta = sas_round(min(itbt, tfa), 0.01)
    else:
        pta = sas_round(max(tfa - sas_round(itbt + div - inc_limit, 0.01) / 2, 0), 0.01)
    taxinc = sas_round(itbt - pta, 0.01)

    if not is_scot:
        additional = sas_round(taxinc - TAX["EngHigher"], 0.01) if taxinc > TAX["EngHigher"] else 0
        advanced = interm = starter = 0
        higher = sas_round(TAX["EngHigher"] - TAX["EngBasic"], 0.01) if taxinc > TAX["EngHigher"] else sas_round(taxinc - TAX["EngBasic"], 0.01) if taxinc > TAX["EngBasic"] else 0
        basic = sas_round(max(taxinc - higher - additional, 0), 0.01)
    else:
        additional = sas_round(taxinc - TAX["ScoAdvanced"], 0.01) if taxinc > TAX["ScoAdvanced"] else 0
        advanced = sas_round(TAX["ScoAdvanced"] - TAX["ScoHigher"], 0.01) if taxinc > TAX["ScoAdvanced"] else sas_round(taxinc - TAX["ScoHigher"], 0.01) if taxinc > TAX["ScoHigher"] else 0
        higher = sas_round(TAX["ScoHigher"] - TAX["ScoInterm"], 0.01) if taxinc > TAX["ScoHigher"] else sas_round(taxinc - TAX["ScoInterm"], 0.01) if taxinc > TAX["ScoInterm"] else 0
        interm = sas_round(TAX["ScoInterm"] - TAX["ScoBasic"], 0.01) if taxinc > TAX["ScoInterm"] else sas_round(taxinc - TAX["ScoBasic"], 0.01) if taxinc > TAX["ScoBasic"] else 0
        basic = sas_round(TAX["ScoBasic"] - TAX["ScoStarter"], 0.01) if taxinc > TAX["ScoBasic"] else sas_round(taxinc - TAX["ScoStarter"], 0.01) if taxinc > TAX["ScoStarter"] else 0
        starter = sas_round(max(taxinc - basic - interm - higher - advanced - additional, 0), 0.01)

    if emp_code == "S":
        nip1 = nih1 = 0
        nip4 = sas_round(TAX["NI4UpperThres"] - TAX["NI4PrimThres"], 0.01) if itbt > TAX["NI4UpperThres"] else sas_round(itbt - TAX["NI4PrimThres"], 0.01) if itbt > TAX["NI4PrimThres"] else 0
        nih4 = sas_round(itbt - TAX["NI4UpperThres"], 0.01) if itbt > TAX["NI4UpperThres"] else 0
    else:
        nip1 = sas_round(TAX["NI1UpperThres"] - TAX["NI1PrimThres"], 0.01) if itbt > TAX["NI1UpperThres"] else sas_round(itbt - TAX["NI1PrimThres"], 0.01) if itbt > TAX["NI1PrimThres"] else 0
        nih1 = sas_round(itbt - TAX["NI1UpperThres"], 0.01) if itbt > TAX["NI1UpperThres"] else 0
        nip4 = nih4 = 0

    tax_due = sas_round(starter * TAX["ScoSRT"], 0.01)
    tax_due += sas_round(basic * (TAX["ScoBRT"] if is_scot else TAX["EngBRT"]), 0.01)
    tax_due += sas_round(interm * TAX["ScoIRT"], 0.01)
    tax_due += sas_round(higher * (TAX["ScoHRT"] if is_scot else TAX["EngHRT"]), 0.01)
    tax_due += sas_round(advanced * TAX["ScoADV"], 0.01)
    tax_due += sas_round(additional * (TAX["ScoART"] if is_scot else TAX["EngART"]), 0.01)

    ni_due = sas_round(nip1 * TAX["NI1Prim"], 0.01) + sas_round(nih1 * TAX["NI1High"], 0.01) + sas_round(nip4 * TAX["NI4Prim"], 0.01) + sas_round(nih4 * TAX["NI4High"], 0.01)

    # Dividend calculation based on supplied SAS logic. It uses English thresholds in the dividend banding section.
    adddiv = sas_round(taxinc - TAX["EngHigher"], 0.01) if taxinc > TAX["EngHigher"] else 0
    highdiv = sas_round(TAX["EngHigher"] - TAX["EngBasic"], 0.01) if taxinc > TAX["EngHigher"] else sas_round(taxinc - TAX["EngBasic"], 0.01) if taxinc > TAX["EngBasic"] else 0
    basediv = sas_round(max(taxinc - highdiv - adddiv, 0), 0.01)

    if div == 0:
        basprediv = highprediv = addprediv = 0
    else:
        inclim = tfa if itbt + div <= inc_limit else sas_round(tfa - ((itbt + div - inc_limit) / 2), 0.01)
        par_remain = sas_round(inclim - itbt, 0.01) if itbt < inclim else 0
        if basediv == TAX["EngBasic"] or div < par_remain:
            basprediv = 0
        elif div <= TAX["EngBasic"] - basediv + par_remain:
            basprediv = sas_round(div - par_remain, 0.01)
        else:
            basprediv = sas_round(TAX["EngBasic"] - basediv, 0.01)
        if highdiv == TAX["EngHigher"] - TAX["EngBasic"] or div - basprediv - par_remain <= 0:
            highprediv = 0
        elif div + taxinc > TAX["EngHigher"]:
            highprediv = sas_round(div - (div + taxinc - TAX["EngHigher"]) - basprediv, 0.01)
        elif div - basprediv <= TAX["EngHigher"] - highdiv:
            highprediv = sas_round(div - basprediv - par_remain, 0.01)
        else:
            highprediv = sas_round(TAX["EngHigher"] - TAX["EngBasic"] - highdiv, 0.01)
        if itbt + div < TAX["EngHigher"]:
            addprediv = 0
        elif itbt > TAX["EngHigher"]:
            addprediv = div
        else:
            addprediv = sas_round(div - highprediv - basprediv - par_remain, 0.01)

    baspostdiv = basprediv - TAX["DivTFA"] if basprediv >= TAX["DivTFA"] else 0
    if highprediv == 0 or highprediv < TAX["DivTFA"]:
        highpostdiv = 0
    elif basprediv - TAX["DivTFA"] < 0:
        highpostdiv = highprediv - (TAX["DivTFA"] - basprediv)
    else:
        highpostdiv = highprediv
    if addprediv != 0:
        addpostdiv = addprediv + highprediv - TAX["DivTFA"] if baspostdiv + highpostdiv == 0 else addprediv
    else:
        addpostdiv = 0
    div_tax = baspostdiv * TAX["DivBRT"] + highpostdiv * TAX["DivHRT"] + addpostdiv * TAX["DivART"]
    net_div = sas_round(div - div_tax, 0.01)

    gai = sas_round(sas_sum(itbt, div, benefit, maintenance), 0.01)
    pre_pen_gai = sas_round(sas_sum(pre_pension_itbt, div, benefit, maintenance), 0.01)
    nai = sas_round(itbt - sas_round(tax_due, 0.01) - sas_round(ni_due, 0.01) + sas_round(net_div, 0.01) + sas_round(sas_sum(benefit, maintenance), 0.01), 0.01)
    nmi = sas_round(nai / 12, 0.01)

    return {
        f"App{i}ITBT": itbt,
        f"App{i}PrePenITBT": pre_pension_itbt,
        f"App{i}PensionDeduct": pension_deduct,
        f"App{i}GAI": gai,
        f"App{i}PrePenGAI": pre_pen_gai,
        f"App{i}NAI": nai,
        f"App{i}NMI": nmi,
        f"app{i}EmpType": emp_type,
    }


def gross_to_net(row: pd.Series) -> pd.Series:
    r = row.copy()
    for i in range(1, 5):
        for k, v in applicant_net_income(r, i).items():
            r[k] = v
    r["Household_NAI"] = sas_round(sas_sum(r.get("App1NAI"), r.get("App2NAI"), r.get("App3NAI"), r.get("App4NAI")), 0.01)
    r["Household_NMI"] = sas_round(sas_sum(r.get("App1NMI"), r.get("App2NMI"), r.get("App3NMI"), r.get("App4NMI")), 0.01)
    r["PrePensionHousehold_GAI"] = sas_round(sas_sum(r.get("App1PrePenGAI"), r.get("App2PrePenGAI"), r.get("App3PrePenGAI"), r.get("App4PrePenGAI")), 0.01)
    r["Household_GAI"] = sas_round(sas_sum(r.get("App1GAI"), r.get("App2GAI"), r.get("App3GAI"), r.get("App4GAI")), 0.01)
    r["Household_GAIBuild"] = n(r.get("Household_GAI")) / 1.08455092473664
    r["Household_GMI"] = sas_round(n(r.get("Household_GAI")) / 12, 0.01)
    if "Af_Modelnetinc_res" in r.index:
        r["DifferencePCvsSASnet"] = n(r.get("Af_Modelnetinc_res")) - n(r.get("Household_NMI"))
    return r


# =============================================================================
# Living and lifestyle parameter-table engine
# =============================================================================

def household_composition(row: pd.Series) -> str:
    apps = int(n(get_value(row, "NbrOfAppls_app")))
    deps = int(n(get_value(row, "NoDependants_app")))
    if apps == 1 and deps == 0: return "A1D0"
    if apps == 1 and deps == 1: return "A1D1"
    if apps == 1 and deps == 2: return "A1D2"
    if apps == 1 and deps > 2: return "A1D3"
    if apps == 2 and deps == 0: return "A2D0"
    if apps == 2 and deps == 1: return "A2D1"
    if apps == 2 and deps == 2: return "A2D2"
    if apps == 2 and deps > 2: return "A2D3"
    if apps == 3 and deps == 0: return "A3D0"
    if apps == 3 and deps == 1: return "A3D1"
    if apps == 3 and deps > 1: return "A3D2"
    if apps == 4 and deps == 0: return "A4D0"
    if apps == 4 and deps > 0: return "A4D1"
    return ""


def canonical_household_comp(comp: str) -> str:
    comp = comp.replace("_", "")
    return {"A3D0": "A2D1", "A3D1": "A2D2", "A4D0": "A2D2", "A3D2": "A2D3", "A4D1": "A2D3"}.get(comp, comp)


def load_parameter_tables(parameter_workbook: str | Path) -> Tuple[pd.DataFrame, pd.DataFrame, Dict[str, float]]:
    living = pd.read_excel(parameter_workbook, sheet_name="LivingCoefficients", engine="openpyxl")
    lifestyle = pd.read_excel(parameter_workbook, sheet_name="LifestyleCoefficients", engine="openpyxl")
    control_df = pd.read_excel(parameter_workbook, sheet_name="Control", engine="openpyxl")
    living["HouseholdComp"] = living["HouseholdComp"].astype(str).str.replace("_", "", regex=False)
    lifestyle["HouseholdComp"] = lifestyle["HouseholdComp"].astype(str).str.replace("_", "", regex=False)
    living["Afford4Pipeline"] = living["Afford4Pipeline"].astype(str)
    lifestyle["Afford1Pipeline"] = lifestyle["Afford1Pipeline"].astype(str)
    lifestyle["Afford4Pipeline"] = lifestyle["Afford4Pipeline"].astype(str)
    control = {str(row["Parameter"]): float(row["Value"]) for _, row in control_df.iterrows() if pd.notna(row.get("Parameter")) and pd.notna(row.get("Value"))}
    return living, lifestyle, control


def lookup_living_params(row: pd.Series, living_params: pd.DataFrame) -> pd.Series:
    comp = canonical_household_comp(s(row.get("HouseholdComp")))
    aff4 = s(row.get("Afford4Pipeline"))
    match = living_params[(living_params["HouseholdComp"] == comp) & (living_params["Afford4Pipeline"] == aff4)]
    if match.empty:
        raise ValueError(f"No living coefficient match for HouseholdComp={comp}, Afford4Pipeline={aff4}")
    return match.iloc[0]


def lookup_lifestyle_params(row: pd.Series, lifestyle_params: pd.DataFrame) -> pd.Series:
    comp = canonical_household_comp(s(row.get("HouseholdComp")))
    aff1 = s(row.get("Afford1Pipeline"))
    aff4 = s(row.get("Afford4Pipeline"))
    match = lifestyle_params[(lifestyle_params["HouseholdComp"] == comp) & (lifestyle_params["Afford1Pipeline"] == aff1) & (lifestyle_params["Afford4Pipeline"] == aff4)]
    if match.empty:
        raise ValueError(f"No lifestyle coefficient match for HouseholdComp={comp}, Afford1Pipeline={aff1}, Afford4Pipeline={aff4}")
    return match.iloc[0]


def calculate_living_expenditure(row: pd.Series, living_params: pd.DataFrame, control: Dict[str, float]) -> pd.Series:
    r = row.copy()
    r["HouseholdComp"] = household_composition(r)
    coeffs = lookup_living_params(r, living_params)
    gai = n(r.get("Household_GAI"))
    gai_build = n(r.get("Household_GAIBuild"))
    aff1, aff2, aff4 = s(r.get("Afford1Pipeline")), s(r.get("Afford2Pipeline")), s(r.get("Afford4Pipeline"))
    ls1, ls2, ls3 = n(coeffs.get("LivingSetter1")), n(coeffs.get("LivingSetter2")), n(coeffs.get("LivingSetter3"))
    ls4, ls5 = n(coeffs.get("LivingSetter4")), n(coeffs.get("LivingSetter5"))
    collar, cap = n(coeffs.get("Collar")), n(coeffs.get("Cap"))

    if aff4 == "Y" and gai > 80000:
        living_output = ((ls4 * gai) + ls5) / 12
    elif aff4 == "Y":
        living_output = ((ls1 * gai * gai) + (ls2 * gai) + ls3) / 12
    else:
        living_output = ((ls1 * gai_build * gai_build) + (ls2 * gai_build) + ls3) / 12

    real_wage = control.get("RealWageInflation", 0.0340162938349307)
    m1 = sas_round(living_output, 0.01)
    m2 = np.nan
    m3 = np.nan
    m4 = np.nan

    if aff4 == "N":
        m2 = sas_round(m1 * control.get("LivingInflationGap_PreAfford4", 1.04887218045113), 0.01)
        m3 = sas_round(m2 * 1.02, 0.01) if gai <= 30000 else sas_round(m2, 0.01)
        m4 = sas_round(m3 * ((real_wage * 0.4) + 1), 0.01)
    elif aff1 == "N" and aff2 == "N" and aff4 == "Y":
        m3 = sas_round(m1 * control.get("LivingInflationGap_Afford4", 1.047), 0.01)
        m4 = sas_round(m3 * 1.02, 0.01) if gai <= 50000 else sas_round(m3, 0.01)
    elif aff1 == "N" and aff2 == "Y" and aff4 == "Y":
        m3 = sas_round(m1 * control.get("LivingInflationGap_Afford4", 1.047), 0.01)
        m4 = sas_round(m3 * 1.02, 0.01) if gai <= 30000 else sas_round(m3, 0.01)
    elif aff1 == "Y" and aff4 == "Y":
        m2 = sas_round(sas_round(m1 * 0.9, 0.01), 0.01)
        if gai <= 30000:
            m3 = sas_round(m2 * 1.08, 0.01)
        elif gai <= 60000:
            m3 = sas_round(m2 * 1.07, 0.01)
        else:
            m3 = sas_round(m2 * 1.06, 0.01)
        m4 = sas_round(m3 * 1.02, 0.01) if gai <= 30000 else sas_round(m3, 0.01)
    else:
        raise ValueError(f"Unhandled living pipeline combination: Afford1={aff1}, Afford2={aff2}, Afford4={aff4}")

    m5 = max(min(m4, cap), collar)
    m6 = sas_round(m5 * control.get("MainResidenceUplift", 1.2), 0.01) if s(get_value(r, "MainResidenceS9_app")) == "N" else sas_round(m5, 0.01)

    r["Living_output"] = living_output
    r["SAS_MonthlyLiving"] = m1
    r["SAS_MonthlyLiving2"] = m2
    r["SAS_MonthlyLiving3"] = m3
    r["SAS_MonthlyLiving4"] = m4
    r["SAS_MonthlyLiving5"] = m5
    r["SAS_MonthlyLiving6"] = m6
    if "LivingModel_N9" in r.index:
        r["DifferencePCvsSASN9"] = n(r.get("LivingModel_N9")) - m6
    return r


def calculate_mcc(row: pd.Series) -> pd.Series:
    r = row.copy()
    r["RevBalPaymt"] = max(0.05 * n(get_value(r, "AppsRevolveBal_app")), 0)
    r["NonrevBalPaymt"] = max(n(get_value(r, "AppsNonRevolveRepay_app")), 0)
    if s(get_value(r, "SecRegion_app")) == "SC":
        r["HTBPymt"] = 0
    elif s(get_value(r, "Afford3Pipeline")) == "Y":
        r["HTBPymt"] = max((n(get_value(r, "HTBEquityLoan_app")) * 0.03) / 12, 0)
    else:
        r["HTBPymt"] = max((n(get_value(r, "HTBEquityLoan_app")) * 0.0375) / 12, 0)
    r["DCDebt"] = (n(get_value(r, "Debt_ConN152_app")) * 0.5) * 0.05 if n(r.get("AB_Flag")) == 1 and n(get_value(r, "Debt_ConN152_app")) > 0 else 0
    r["SAS_MCC"] = sas_round(r["RevBalPaymt"] + r["NonrevBalPaymt"] + r["HTBPymt"] + r["DCDebt"], 0.01)
    net_income_for_dti = n(get_value(r, "Af_Modelnetinc_res", r.get("Household_NMI")))
    r["SAS_DTI"] = 1 if net_income_for_dti <= 0 else sas_round((r["RevBalPaymt"] + r["NonrevBalPaymt"]) / net_income_for_dti, 0.0001)
    return r


def calculate_lifestyle_expenditure(row: pd.Series, lifestyle_params: pd.DataFrame, control: Dict[str, float]) -> pd.Series:
    r = row.copy()
    if not s(r.get("HouseholdComp")):
        r["HouseholdComp"] = household_composition(r)
    coeffs = lookup_lifestyle_params(r, lifestyle_params)
    gai, gai_build, dti = n(r.get("Household_GAI")), n(r.get("Household_GAIBuild")), n(r.get("SAS_DTI"))
    aff1, aff4 = s(r.get("Afford1Pipeline")), s(r.get("Afford4Pipeline"))
    lf1, lf2, lf3 = n(coeffs.get("LifeSetter1")), n(coeffs.get("LifeSetter2")), n(coeffs.get("LifeSetter3"))
    lf4, lf5 = n(coeffs.get("LifeSetter4")), n(coeffs.get("LifeSetter5"))

    def poly(base_gai: float, multiplier: float) -> float:
        return (((lf1 * base_gai * base_gai) + (lf2 * base_gai) + lf3) / 12) * multiplier

    def linear_or_poly(multiplier: float) -> float:
        return (((lf4 * gai) + lf5) / 12) * multiplier if gai > 80000 and lf4 != 0 else poly(gai, multiplier)

    out = linear_or_poly(0.10)
    out1 = linear_or_poly(0.05)
    out2 = linear_or_poly(0.15)
    out3 = np.nan
    out2_3 = np.nan
    out3_3 = np.nan

    if aff4 == "N":
        out2 = poly(gai_build, 0.35)
        out3 = poly(gai_build, 0.20)
        rw = control.get("RealWageInflation", 0.0340162938349307)
        out2_1 = sas_round(out2 * control.get("LifestyleInflationGap_Afford4N", 1.049), 0.01)
        out3_1 = sas_round(out3 * control.get("LifestyleInflationGap_Afford4N", 1.049), 0.01)
        out2_2 = sas_round(out2_1 * ((rw * 0.4) + 1), 0.01)
        out3_2 = sas_round(out3_1 * ((rw * 0.4) + 1), 0.01)
        out2_3 = max(min(out2_2, n(coeffs.get("LifeSetterCapHDTI"))), n(coeffs.get("LifeSetterCollarHDTI")))
        out3_3 = max(min(out3_2, n(coeffs.get("LifeSetterCap"))), n(coeffs.get("LifeSetterCollar")))

    if dti < 0.15 and aff1 == "Y":
        out4 = 0
    elif aff1 == "Y" and aff4 == "Y" and dti >= 0.205:
        out4 = out
    elif aff1 == "N" and aff4 == "Y" and dti > 0.205:
        out4 = out2
    elif aff1 == "N" and aff4 == "Y" and dti >= 0.15:
        out4 = out1
    elif aff1 == "N" and aff4 == "Y":
        out4 = 0
    elif aff4 == "N" and dti > 0.205:
        out4 = out2_3
    else:
        out4 = out3_3

    r["Lifestyle_output"] = out
    r["Lifestyle_output1"] = out1
    r["Lifestyle_output2"] = out2
    r["Lifestyle_output3"] = out3
    r["Lifestyle_output2_3"] = out2_3
    r["Lifestyle_output3_3"] = out3_3
    r["Lifestyle_output4"] = out4
    r["SAS_MonthlyLife"] = sas_round(out4, 0.01)
    if "LifestyleModel_N10" in r.index:
        r["DifferencePCvsSASN10"] = n(r.get("LifestyleModel_N10")) - n(r.get("SAS_MonthlyLife"))
    return r


def calculate_modelled_outgoings_and_edi(row: pd.Series) -> pd.Series:
    r = row.copy()
    r["SAS_ModelledOutgoings"] = sas_sum(get_value(r, "AppsOtherExpenditure_app"), get_value(r, "SO_RentN48_app"), r.get("SAS_MCC"), r.get("SAS_MonthlyLiving6"), r.get("SAS_MonthlyLife"))
    if "Af_Modeloutgoings_res" in r.index:
        r["DiffPCvsSASModelledOutgoings"] = sas_round(n(r.get("Af_Modeloutgoings_res")) - n(r.get("SAS_ModelledOutgoings")), 0.01)
    r["SAS_EDI"] = sas_round(n(r.get("Household_NMI")) - n(r.get("SAS_ModelledOutgoings")), 0.01)
    if "Af_Edi_res" in r.index:
        r["DiffPCvsSASEDI"] = n(r.get("Af_Edi_res")) - n(r.get("SAS_EDI"))
    return r


# =============================================================================
# Stressed mortgage / affordability / alternatives / BTL
# =============================================================================

def mortgage_coeff(rate_percent: float, months: float) -> float:
    co_x = trunc6(1 + rate_percent / 1200)
    co_y = trunc6(months)
    co_z = trunc6(co_x ** co_y) if co_x and co_y else 0
    co_q = trunc6(1 / co_z) if co_z else 0
    co_p = trunc6(1 - co_q)
    return trunc6((rate_percent / 1200) / co_p) if co_p else 0


def stressed_mortgage(row: pd.Series) -> pd.Series:
    r = row.copy()
    new_term = min(math.ceil(n(get_value(r, "TermInMths_app")) / 12), 40) if n(get_value(r, "TermInMths_app")) else 0
    prim_term = min(math.ceil(n(get_value(r, "SBSNonBTLMortgagesTerm_app")) / 12), 40) if n(get_value(r, "SBSNonBTLMortgagesTerm_app")) else 0
    r["NewTerm"], r["PrimTerm"] = new_term, prim_term
    p1_rt, p2_rt = n(get_value(r, "part1_reptype_app")), n(get_value(r, "part2_reptype_app"))
    p1_amt, p2_amt = n(get_value(r, "part1_LoanAmt_app")), n(get_value(r, "part2_LoanAmt_app"))
    io_amt = n(get_value(r, "IntOnlyAmt_app"))
    total_parts = sas_sum(p1_amt, p2_amt)

    if p1_rt in {0, 1}: rep1 = p1_amt
    elif p1_rt == 3:
        rep1 = p1_amt - io_amt if p2_rt in {0, 1} else p1_amt + p2_amt - io_amt if p2_rt == 2 else (p1_amt - io_amt * p1_amt) / total_parts if p2_rt == 3 and total_parts else 0
    else: rep1 = 0
    if p2_rt in {0, 1}: rep2 = p2_amt
    elif p2_rt == 3:
        rep2 = p2_amt - io_amt if p1_rt in {0, 1} else p2_amt + p1_amt - io_amt if p1_rt == 2 else (p2_amt - io_amt * p2_amt) / total_parts if p1_rt == 3 and total_parts else 0
    else: rep2 = 0
    if p1_rt == 2: io1 = p1_amt
    elif p1_rt == 3:
        io1 = io_amt if p2_rt in {0, 1} else io_amt - p2_amt if p2_rt == 2 else (io_amt * p1_amt) / total_parts if p2_rt == 3 and total_parts else 0
    else: io1 = 0
    if p2_rt == 2: io2 = p2_amt
    elif p2_rt == 3:
        io2 = io_amt if p1_rt in {0, 1} else io_amt - p1_amt if p1_rt == 2 else (io_amt * p2_amt) / total_parts if p1_rt == 3 and total_parts else 0
    else: io2 = 0

    r["SAS_Ioamt"] = sas_sum(io1, io2)
    r["SAS_Repamt"] = sas_sum(rep1, rep2)
    r["SAS_Secdebtamt"] = n(get_value(r, "AppsSecDebtAmt_app"))
    r["SAS_SBSPrimamt"] = n(get_value(r, "SBSNonBTLMortgagesBalance_app"))

    if s(r.get("Afford4Pipeline")) == "N":
        ltv = n(get_value(r, "LTV_app"))
        base = 6.4 if ltv <= 60 else 6.6 if ltv <= 85 else 6.9 if ltv <= 95 else 7.1
        resi_rate = io_rate = max(n(r.get("Rateplus1")), base)
        sbs_rate = other_rate = max(n(r.get("Rateplus1")), 7.1)
    else:
        resi_rate = io_rate = sbs_rate = other_rate = 7.54

    r["ResiStressRate"], r["IOStressRate"], r["SBSPrimStressRate"], r["OtherStressRate"] = resi_rate, io_rate, sbs_rate, other_rate
    r["ResiCoeff"] = mortgage_coeff(resi_rate, new_term * 12)
    r["IoCoeff"] = mortgage_coeff(io_rate, 300)
    termfee = new_term if r["SAS_Repamt"] > 0 else 25
    r["FeeCoeff"] = mortgage_coeff(resi_rate, termfee * 12)
    r["OthCoeff"] = mortgage_coeff(other_rate, 300)
    if r["SAS_Repamt"] == 0 or s(get_value(r, "ApplicationType_app")) in {"B1", "D2", "PA"}:
        term_prim = 25
    elif prim_term > 0:
        term_prim = prim_term
    elif prim_term == 0:
        term_prim = 1
    else:
        term_prim = 25
    r["PrimCoeff"] = mortgage_coeff(sbs_rate, term_prim * 12)
    r["SAS_StressedMort"] = sas_round(r["SAS_Ioamt"] * r["IoCoeff"] + r["SAS_Repamt"] * r["ResiCoeff"] + n(get_value(r, "MortgageFeesN8_app")) * r["FeeCoeff"] + r["SAS_Secdebtamt"] * r["OthCoeff"] + r["SAS_SBSPrimamt"] * r["PrimCoeff"], 0.01)
    if "Af_Stressmortrepay_res" in r.index:
        r["DiffPCvsSASStressedMort"] = sas_round(n(r.get("Af_Stressmortrepay_res")) - r["SAS_StressedMort"], 0.01)
    return r


def total_affordability(row: pd.Series) -> pd.Series:
    r = row.copy()
    if n(r.get("SAS_EDI")) < 0:
        r["SAS_Affordability"] = 999.99
    elif n(r.get("SAS_StressedMort")) == 0:
        r["SAS_Affordability"] = 0
    else:
        r["SAS_Affordability"] = sas_round(100 * n(r.get("SAS_StressedMort")) / n(r.get("SAS_EDI")), 0.01)
    if "Af_Affordability_res" in r.index:
        diff = sas_round(n(r.get("Af_Affordability_res")) - n(r.get("SAS_Affordability")), 0.01)
        if abs(diff) > 5 and n(r.get("Af_Affordability_res")) > 5000 and n(r.get("SAS_Affordability")) > 5000:
            diff = 0
        r["DiffPCvsSASAff"] = diff
    return r


def alternatives(row: pd.Series) -> pd.Series:
    r = row.copy()
    aff_cutoff = 0.95 if s(get_value(r, "TrackRecordFlag_S11")) == "Y" else 1
    ltv_round = sas_round(n(get_value(r, "LTV_app")), 0.01)
    if n(r.get("LISAFlag")) == 1: max_lti = 6
    elif ltv_round <= 90: max_lti = 5.5
    elif ltv_round > 95: max_lti = 4.49
    else: max_lti = 5
    if s(r.get("LTIChangePipeline")) == "N" and s(r.get("LTIChange1Pipeline")) == "N" and s(r.get("LTIChange2Pipeline")) == "N" and s(r.get("LTIChange3Pipeline")) == "Y" and ltv_round > 95:
        max_lti = 5
    if s(r.get("LTIChange1Pipeline")) == "N" and n(get_value(r, "NbrOfAppls_app")) > 1 and n(r.get("PrePensionHousehold_GAI")) < 60000:
        max_lti = 4.49
    if n(get_value(r, "NbrOfAppls_app")) == 1 and n(r.get("PrePensionHousehold_GAI")) < 40000:
        max_lti = 4.49
    if s(r.get("LTIChange1Pipeline")) == "Y" and n(r.get("PrePensionHousehold_GAI")) < 40000:
        max_lti = 4.49
    if s(r.get("LTIChangePipeline")) == "N" and n(r.get("SAS_DTI")) > 0.10:
        max_lti = 4.49
    r["SAS_MaxLTI"] = max_lti
    r["LTIMaxLoan"] = max_lti * n(r.get("PrePensionHousehold_GAI"))
    other_mort = n(r.get("SAS_Secdebtamt")) * n(r.get("OthCoeff")) + n(r.get("SAS_SBSPrimamt")) * n(r.get("PrimCoeff"))
    r["OtherMortRepay"] = other_mort
    coeff = n(r.get("IoCoeff")) if n(r.get("SAS_Repamt")) == 0 else n(r.get("ResiCoeff"))
    afford_max = floor_to(((aff_cutoff * n(r.get("SAS_EDI")) - other_mort) / coeff) - n(get_value(r, "MortgageFeesN8_app")), 100) if coeff else 0
    r["AffordMaxLoan"] = max(afford_max, 0)
    if n(r.get("AB_Flag")) == 1:
        raw_ab = floor_to(r["LTIMaxLoan"] - (n(get_value(r, "ABAmtAllLoans_app")) - n(get_value(r, "TotalLoanAmount_app"))), 100)
        raw = floor_to(min(r["AffordMaxLoan"], raw_ab), 100)
    else:
        raw = floor_to(min(r["LTIMaxLoan"], r["AffordMaxLoan"]), 100)
    if n(r.get("SAS_EDI")) <= 0 or raw < 0:
        raw = 0
    if s(get_value(r, "ApplicationType_app")) in {"CV", "D1"}:
        raw = math.floor(n(get_value(r, "TotalLoanAmount_app")))
    if n(r.get("BTLFlag")) == 1:
        raw = n(get_value(r, "Loan1_res"))
    r["RawMaxLoan"] = raw
    if "Loan1_res" in r.index:
        r["DiffPCvsMaxLoan"] = sas_round(n(r.get("Loan1_res")) - raw, 0.01)
    if "LTIPC" in r.index:
        r["DiffPCvsLTISAS"] = n(r.get("LTIPC")) - max_lti

    # Alternative term - simplified from supplied SAS logic, using calculated coefficients.
    alt_mort_repay = sas_round(n(r.get("SAS_Ioamt")) * n(r.get("IoCoeff")) + n(r.get("SAS_Secdebtamt")) * n(r.get("OthCoeff")) + n(r.get("SAS_SBSPrimamt")) * n(r.get("PrimCoeff")), 0.01)
    if n(r.get("BTLFlag")) == 0 and s(get_value(r, "ApplicationType_app")) not in {"CV", "D1"} and n(r.get("SAS_Repamt")) > 0:
        altcoeff = trunc6((aff_cutoff * n(r.get("SAS_EDI")) - alt_mort_repay) / (n(r.get("SAS_Repamt")) + n(get_value(r, "MortgageFeesN8_app"))))
        try:
            altterm1 = (math.log(1 / (1 - ((n(r.get("ResiStressRate")) / 1200) / altcoeff))) / math.log(trunc6(1 + n(r.get("ResiStressRate")) / 1200))) / 12
        except Exception:
            altterm1 = 0
        altterm = math.ceil(altterm1) if altterm1 > 0 else 0
        if altterm > n(r.get("NewTerm")) + 10 and s(get_value(r, "ApplicationType_app")) not in {"W", "FW"}: altterm = 0
        if n(get_value(r, "ABAmtAllLoans_app")) > n(r.get("LTIMaxLoan")): altterm = 0
        if n(r.get("RawMaxLoan")) >= n(r.get("LTIMaxLoan")): altterm = 0
        if altterm > 40 or n(r.get("SAS_EDI")) <= 0: altterm = 0
    else:
        altcoeff = 0
        altterm1 = 0
        altterm = n(r.get("NewTerm")) if n(r.get("BTLFlag")) == 1 or s(get_value(r, "ApplicationType_app")) in {"CV", "D1"} else 0
    r["altcoeff"], r["altterm1"], r["altterm"] = altcoeff, altterm1, altterm
    if "AlternativeTerm_N1" in r.index:
        r["DiffPCvsAltTerm"] = sas_round(n(r.get("AlternativeTerm_N1")) - n(r.get("altterm")), 0.01)
    return r


def btl_checks(row: pd.Series) -> pd.Series:
    r = row.copy()
    lt = s(get_value(r, "LoanType_app"))
    fiveyr = "Y" if (lt in {"A", "B", "C", "Q"} and 59 < n(get_value(r, "Product_TermN40_app")) < 999 and s(get_value(r, "part2_prod_app")) in {"MISSING", ""} and s(get_value(r, "ProductTypeS3_app")) == "FIX" and n(r.get("AB_Flag")) == 0) or (lt in {"A", "B", "C", "Q"} and s(get_value(r, "FiveYRFixed_FlagS2_app")) == "Y" and n(r.get("AB_Flag")) == 0) else "N"
    r["fiveyrBTLProd"] = fiveyr
    interest = n(get_value(r, "InterestRateN130_app"))
    btl_stress2 = 6.04 if s(r.get("BTLStress1Pipeline")) == "Y" and fiveyr == "Y" and n(r.get("AB_Flag")) == 0 else 7.94 if s(r.get("BTLStress1Pipeline")) == "Y" else 99.99
    if interest > 0:
        btl_stress3 = max(interest + 1.0, 5.5) if (fiveyr == "Y" and n(r.get("AB_Flag")) == 0) or (n(r.get("Like4LikeFlag")) == 1 and n(r.get("AB_Flag")) == 0) else max(interest + 2.0, 5.5)
    else:
        btl_stress3 = 6.29 if fiveyr == "Y" and n(r.get("AB_Flag")) == 0 else 7.94
    r["BTLStress"] = min(btl_stress2, btl_stress3)
    if lt in {"A", "B", "C", "Q"} and n(get_value(r, "RentalIncome_app")) > 0:
        tmp = ((n(get_value(r, "ABAmtAllLoans_app")) / 100) * r["BTLStress"]) / 12
        rental_cover = math.floor(sas_round(n(get_value(r, "RentalIncome_app")) / tmp, 0.0001) * 100) / 100 if tmp else 0
    else:
        rental_cover = 0
    r["rental_cover"] = rental_cover
    if "ICRPC_N17" in r.index:
        r["DiffPCvsSASSecICR"] = n(r.get("ICRPC_N17")) - rental_cover
    higher_tax = any(s(get_value(r, f"App{i}TaxStatusS{4+i}_app")) in {"HIGHER RATE", "ADDITIONAL/TOP RATE"} for i in range(1, 5))
    r["TaxStatus"] = "Higher" if higher_tax else "Std"
    if lt == "B" and s(get_value(r, "RemortgageReason_app")) == "N" and rental_cover >= 1.25:
        rent_pass = "Rent Pass"
    elif s(r.get("BTLType")) == "PBTL" and rental_cover >= 1.45:
        rent_pass = "Rent Pass"
    elif s(r.get("BTLType")) == "BTL" and higher_tax and rental_cover >= 1.45:
        rent_pass = "Rent Pass"
    elif s(r.get("BTLType")) == "BTL" and not higher_tax and rental_cover >= 1.25:
        rent_pass = "Rent Pass"
    else:
        rent_pass = "Rent Fail"
    r["RentPass"] = rent_pass
    top_available = n(r.get("BTLFlag")) == 1 and rent_pass == "Rent Fail" and 1.1 <= rental_cover < 1.45
    r["TopSlicingAvailable"] = "Y" if top_available else "N"
    if "TopSlicingFlag_S10" in r.index:
        r["DiffPCvsSASTopSlicingFlag"] = 0 if s(r.get("TopSlicingAvailable")) == s(r.get("TopSlicingFlag_S10")) else 1
    return r


# =============================================================================
# Pipeline runner
# =============================================================================

def run_affordability_pipeline(score_data: pd.DataFrame, parameter_workbook: str | Path) -> pd.DataFrame:
    living_params, lifestyle_params, control = load_parameter_tables(parameter_workbook)
    df = filter_score_data(score_data)

    # Normalise known column-name case differences between the CSV extract and
    # the field names referenced in the calculation code.
    df = df.rename(columns={
        "Part1_LoanAmt_app":  "part1_LoanAmt_app",
        "Part1_RepType_app":  "part1_reptype_app",
        "Part2_LoanAmt_app":  "part2_LoanAmt_app",
        "Part2_Reptype_app":  "part2_reptype_app",
        "Part2_Prod_app":     "part2_prod_app",
    })
    df = df.apply(derive_flags, axis=1)
    df = df.apply(gross_to_net, axis=1)
    df = df.apply(calculate_mcc, axis=1)
    df = df.apply(lambda row: calculate_living_expenditure(row, living_params, control), axis=1)
    df = df.apply(lambda row: calculate_lifestyle_expenditure(row, lifestyle_params, control), axis=1)
    df = df.apply(calculate_modelled_outgoings_and_edi, axis=1)
    df = df.apply(stressed_mortgage, axis=1)
    df = df.apply(total_affordability, axis=1)
    df = df.apply(alternatives, axis=1)
    df = df.apply(btl_checks, axis=1)
    return df


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Run the Python affordability simulation engine.")
    parser.add_argument("--input", required=True, help="Input Excel/CSV file containing score/application data")
    parser.add_argument("--output", required=True, help="Output Excel file")
    parser.add_argument("--params", default="affordability_parameter_tables.xlsx", help="Parameter workbook path")
    parser.add_argument("--sheet", default=0, help="Input sheet name or index for Excel inputs")
    return parser


def main() -> None:
    args = build_arg_parser().parse_args()
    input_path = Path(args.input)
    output_path = Path(args.output)
    params_path = Path(args.params)
    sheet: str | int = int(args.sheet) if str(args.sheet).isdigit() else args.sheet

    df = load_input(input_path, sheet_name=sheet)
    results = run_affordability_pipeline(df, params_path)
    export_results(results, output_path)
    print(f"Rows processed: {len(results):,}")
    print(f"Output written to: {output_path}")


if __name__ == "__main__":
    main()

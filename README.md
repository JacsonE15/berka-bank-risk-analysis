# berka-bank-risk-analysis
Loan default risk analysis using SQL, Python, and Tableau on the Berka Czech banking dataset
# Berka Bank: Loan Default Risk Analysis

A end-to-end data analytics project analyzing loan default risk 
using a real Czech banking dataset.

## Business Question
Which accounts have loan default risk, and which customer segments 
should the bank prioritize for risk intervention?

## Tools & Skills
- **SQL** — Multi-table joins, CTEs, window functions (DBeaver + SQLite)
- **Python** — Data visualization, EDA (Pandas, Matplotlib, Seaborn)
- **Tableau** — Interactive dashboard and Story

## Dataset
[Berka Dataset](https://sorry.vse.cz/~berka/challenge/pkdd1999/) — 
Real anonymized Czech banking data (1993–1998), 8 related tables, 
~1M transaction rows.

## Key Findings
- 65% of loans show default risk (Status C or D)
- North Moravia has the highest combined risk: 117 loans at 15.4% default rate
- Low-value customers default at 2x the rate of high-value customers
- Low account balance is a stronger predictor of default than transaction frequency

## Project Structure

## Project Structure
```
├── data/                 # Berka Dataset
├── sql/                  # SQL queries for EDA and segment analysis
├── notebook/             # Jupyter notebooks for Python analysis
├── output/
│   ├── charts/           # Python visualizations
    └── tableau/          # Tableau Story screenshots

```

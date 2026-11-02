# Analyze Hospital Patient Encounters and Costs with MySQL

## Project Overview
This project uses SQL (MySQL) to analyze hospital data. It looks at patient encounters, procedure costs, insurance coverage, patient demographics, and readmissions. The goal is to answer business questions a hospital manager might ask about patient volume, costs, and patient behavior.

## Tools Used
- MySQL
- SQL techniques: aggregation, `CASE WHEN`, `JOIN`, date functions, CTEs, subqueries, window functions (`LEAD`, `LAG`, `RANK`)

## Dataset
The database `hospital_db` has four tables:

| Table | Description |
|---|---|
| `encounters` | Each patient visit: start/end time, encounter class, payer, costs, coverage, reason for visit |
| `patients` | Patient details such as birth date and gender |
| `payers` | Insurance companies (payers) |
| `procedures` | Procedures performed and their base cost |

## Business Questions

### Objective 1: Encounters Overview
1. How many total encounters occurred each year?
2. For each year, what percentage of encounters belonged to each encounter class (ambulatory, outpatient, wellness, urgent care, emergency, inpatient)?
3. What percentage of encounters lasted over 24 hours versus under 24 hours?
4. What was the year-over-year change in total encounters?

### Objective 2: Cost & Coverage Insights
1. How many encounters had zero payer coverage, and what percentage of all encounters is this?
2. What are the top 10 most frequent procedures and their average base cost?
3. What are the top 10 procedures with the highest average base cost, and how often were they performed?
4. What is the average total claim cost per encounter, broken down by payer?
5. Which encounter class has the highest average claim cost?
6. What percentage of total claim costs did each payer cover?
7. How much did patients pay out of pocket each year?
8. How do payers rank by total coverage each year?

### Objective 3: Patient Behavior & Demographics
1. How many unique patients were admitted each quarter?
2. How many patients were readmitted within 30 days of a previous encounter?
3. Which patients had the most readmissions?
4. Which age groups account for the most encounters?
5. How do encounters and claim costs compare between male and female patients?
6. What are the top 10 reasons for hospital visits?

## SQL Skills Demonstrated
- **Conditional aggregation** with `SUM(CASE WHEN ...)` to calculate encounter-class percentages
- **Date and time functions** (`YEAR`, `QUARTER`, `TIMESTAMPDIFF`, `DATEDIFF`) for time-based and age analysis
- **JOINs** to combine encounters with payer and patient details
- **Window functions**:
  - `LEAD()` to find each patient's next visit (readmissions)
  - `LAG()` to compare each year with the previous year
  - `RANK()` with `PARTITION BY` to rank payers within each year
- **CTEs** (`WITH`) to break complex analysis into clear steps
- **Subqueries** to calculate percentages of a total

## Key Findings

**Patient volume**
- Encounters peaked in 2014 (3,885) and again in 2021 (3,530).
- 2022 has only 220 encounters, so it appears to be a partial year. The −93.8% drop reflects incomplete data, not a real decline.

**Costs by encounter type**
- Ambulatory visits are the most common (12,537 encounters, about 45% of all visits).
- Inpatient stays are the most expensive, with an average claim of about $7,761, around 3.5 times the outpatient average ($2,237).

**Insurance coverage**
- Government programs covered most of their claim costs: Medicaid 94%, Dual Eligible 89%, Medicare 78%.
- Private insurers such as UnitedHealthcare, Humana, Aetna, Cigna and Anthem covered less than 1% of claim costs, which is unusually low and worth investigating.
- Medicare ranked #1 in total coverage in both 2011 and 2022, followed by Medicaid.
- Uninsured patients had the largest total claim cost of any group (about $49.3M) with no coverage.

**Out-of-pocket costs**
- Patients paid roughly $6M–$8.5M out of pocket each full year, with an average of about $2,700–$2,900 per encounter in most years.

**Patient demographics and visit reasons**
- Patients aged 65+ account for 67.7% of all encounters.
- Female patients had more encounters per patient (31.1 vs 26.2), while male patients had a higher average claim cost ($4,085 vs $3,254).
- The top reasons for visits were chronic congestive heart failure (1,738), hyperlipidemia (1,565) and normal pregnancy (1,341).

## Files
- `hospital_analysis.sql` – all SQL queries, organized by objective

## Acknowledgment
Based on a LinkedIn Learning guided project.

## Author
**Rimsha Ibrahim**

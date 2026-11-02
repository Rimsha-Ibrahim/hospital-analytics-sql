-- =====================================================
-- Analyze Hospital Patient Encounters and Costs with MySQL
-- =====================================================

USE hospital_db;

-- =====================================================
-- OBJECTIVE 1: ENCOUNTERS OVERVIEW
-- =====================================================

-- 1a. How many total encounters occurred each year?
SELECT YEAR(start) AS yr,
       COUNT(id) AS total_encounters
FROM encounters
GROUP BY yr
ORDER BY yr;

-- 1b. For each year, what percentage of encounters belonged to each encounter class?
SELECT YEAR(start) AS yr,
       COUNT(*) AS total_encounters,
       ROUND(SUM(CASE WHEN encounterclass = 'ambulatory' THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS ambulatory,
       ROUND(SUM(CASE WHEN encounterclass = 'outpatient' THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS outpatient,
       ROUND(SUM(CASE WHEN encounterclass = 'wellness'   THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS wellness,
       ROUND(SUM(CASE WHEN encounterclass = 'urgentcare' THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS urgent_care,
       ROUND(SUM(CASE WHEN encounterclass = 'emergency'  THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS emergency,
       ROUND(SUM(CASE WHEN encounterclass = 'inpatient'  THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS inpatient
FROM encounters
GROUP BY yr
ORDER BY yr;

-- 1c. What percentage of encounters were over 24 hours versus under 24 hours?
SELECT ROUND(COUNT(CASE WHEN TIMESTAMPDIFF(HOUR, start, stop) >= 24 THEN 1 END) / COUNT(*) * 100, 1) AS above_24_hrs_pct,
       ROUND(COUNT(CASE WHEN TIMESTAMPDIFF(HOUR, start, stop) <  24 THEN 1 END) / COUNT(*) * 100, 1) AS below_24_hrs_pct
FROM encounters;

-- Count of encounters lasting 24 hours or more
SELECT COUNT(*) AS encounters_24_hrs_or_more
FROM encounters
WHERE TIMESTAMPDIFF(HOUR, start, stop) >= 24;

-- Count of encounters lasting less than 24 hours
SELECT COUNT(*) AS encounters_under_24_hrs
FROM encounters
WHERE TIMESTAMPDIFF(HOUR, start, stop) < 24;

-- 1d. What was the year-over-year change in total encounters?
WITH yearly AS (
    SELECT YEAR(start) AS yr,
           COUNT(*) AS total_encounters
    FROM encounters
    GROUP BY yr
)
SELECT yr,
       total_encounters,
       LAG(total_encounters) OVER (ORDER BY yr) AS prev_year_encounters,
       ROUND((total_encounters - LAG(total_encounters) OVER (ORDER BY yr))
             / LAG(total_encounters) OVER (ORDER BY yr) * 100, 1) AS yoy_change_pct
FROM yearly
ORDER BY yr;

-- =====================================================
-- OBJECTIVE 2: COST & COVERAGE INSIGHTS
-- =====================================================

-- 2a. How many encounters had zero payer coverage, and what percentage is this?
SELECT COUNT(CASE WHEN payer_coverage = 0 THEN 1 END) AS zero_coverage_encounters,
       ROUND(COUNT(CASE WHEN payer_coverage = 0 THEN 1 END) / COUNT(*) * 100, 1) AS zero_coverage_pct
FROM encounters;

-- 2b. Top 10 most frequent procedures and their average base cost
SELECT code,
       description,
       COUNT(*) AS procedure_frequency,
       ROUND(AVG(base_cost), 1) AS avg_base_cost
FROM procedures
GROUP BY code, description
ORDER BY procedure_frequency DESC
LIMIT 10;

-- 2c. Top 10 procedures with the highest average base cost and how often they were performed
SELECT code,
       description,
       COUNT(*) AS procedure_frequency,
       ROUND(AVG(base_cost), 1) AS avg_base_cost
FROM procedures
GROUP BY code, description
ORDER BY avg_base_cost DESC
LIMIT 10;

-- 2d. Average total claim cost per encounter, broken down by payer
SELECT p.name AS payer_name,
       ROUND(AVG(e.total_claim_cost), 1) AS avg_total_claim_cost
FROM payers p
LEFT JOIN encounters e
       ON e.payer = p.id
GROUP BY p.name
ORDER BY avg_total_claim_cost DESC;

-- 2e. Which encounter class has the highest average claim cost?
SELECT encounterclass,
       COUNT(*) AS total_encounters,
       ROUND(AVG(total_claim_cost), 1) AS avg_claim_cost
FROM encounters
GROUP BY encounterclass
ORDER BY avg_claim_cost DESC;

-- 2f. What percentage of total claim costs did each payer cover?
SELECT p.name AS payer_name,
       ROUND(SUM(e.total_claim_cost), 0) AS total_claim_cost,
       ROUND(SUM(e.payer_coverage), 0) AS total_coverage,
       ROUND(SUM(e.payer_coverage) / SUM(e.total_claim_cost) * 100, 1) AS coverage_pct
FROM encounters e
JOIN payers p
     ON e.payer = p.id
GROUP BY p.name
ORDER BY coverage_pct DESC;

-- 2g. How much did patients pay out of pocket each year?
-- Out of pocket = total claim cost - amount covered by payer
SELECT YEAR(start) AS yr,
       ROUND(SUM(total_claim_cost - payer_coverage), 0) AS total_out_of_pocket,
       ROUND(AVG(total_claim_cost - payer_coverage), 1) AS avg_out_of_pocket_per_encounter
FROM encounters
GROUP BY yr
ORDER BY yr;

-- 2h. How do payers rank by total coverage each year?
WITH payer_year AS (
    SELECT YEAR(e.start) AS yr,
           p.name AS payer_name,
           SUM(e.payer_coverage) AS total_coverage
    FROM encounters e
    JOIN payers p
         ON e.payer = p.id
    GROUP BY yr, p.name
)
SELECT yr,
       payer_name,
       ROUND(total_coverage, 0) AS total_coverage,
       RANK() OVER (PARTITION BY yr ORDER BY total_coverage DESC) AS coverage_rank
FROM payer_year
ORDER BY yr, coverage_rank;

-- =====================================================
-- OBJECTIVE 3: PATIENT BEHAVIOR & DEMOGRAPHICS
-- =====================================================

-- 3a. How many unique patients were admitted each quarter?
SELECT YEAR(start) AS yr,
       QUARTER(start) AS qtr,
       COUNT(DISTINCT patient) AS unique_patients
FROM encounters
GROUP BY yr, qtr
ORDER BY yr, qtr;

-- 3b. How many patients were readmitted within 30 days of a previous encounter?
WITH next_visits AS (
    SELECT patient,
           start,
           stop,
           LEAD(start) OVER (PARTITION BY patient ORDER BY start) AS next_start_date
    FROM encounters
)
SELECT COUNT(DISTINCT patient) AS readmitted_patients
FROM next_visits
WHERE DATEDIFF(next_start_date, stop) < 30;

-- 3c. Which patients had the most readmissions?
WITH next_visits AS (
    SELECT patient,
           start,
           stop,
           LEAD(start) OVER (PARTITION BY patient ORDER BY start) AS next_start_date
    FROM encounters
)
SELECT patient,
       COUNT(*) AS readmission_count
FROM next_visits
WHERE DATEDIFF(next_start_date, stop) < 30
GROUP BY patient
ORDER BY readmission_count DESC
LIMIT 10;

-- 3d. Which age groups account for the most encounters?
-- Age is calculated at the time of each encounter
WITH encounter_ages AS (
    SELECT e.id,
           TIMESTAMPDIFF(YEAR, p.birthdate, e.start) AS age
    FROM encounters e
    JOIN patients p
         ON e.patient = p.id
)
SELECT CASE
           WHEN age < 18 THEN '0-17'
           WHEN age < 35 THEN '18-34'
           WHEN age < 50 THEN '35-49'
           WHEN age < 65 THEN '50-64'
           ELSE '65+'
       END AS age_group,
       COUNT(*) AS total_encounters,
       ROUND(COUNT(*) / (SELECT COUNT(*) FROM encounter_ages) * 100, 1) AS pct_of_encounters
FROM encounter_ages
GROUP BY age_group
ORDER BY age_group;

-- 3e. How do encounters and claim costs compare between male and female patients?
SELECT p.gender,
       COUNT(DISTINCT e.patient) AS unique_patients,
       COUNT(*) AS total_encounters,
       ROUND(COUNT(*) / COUNT(DISTINCT e.patient), 1) AS encounters_per_patient,
       ROUND(AVG(e.total_claim_cost), 1) AS avg_claim_cost
FROM encounters e
JOIN patients p
     ON e.patient = p.id
GROUP BY p.gender;

-- 3f. What are the top 10 reasons for hospital visits?
SELECT reasondescription,
       COUNT(*) AS total_encounters
FROM encounters
WHERE reasondescription IS NOT NULL
  AND reasondescription <> ''
GROUP BY reasondescription
ORDER BY total_encounters DESC
LIMIT 10;

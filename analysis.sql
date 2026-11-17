-- Project: Where should hospitals focus to improve patient experience?
-- Analysis of the clean ratings table

-- Step 1: Average star rating for each survey measure, lowest first
SELECT measure_id, question, ROUND(AVG(star_rating), 2) AS avg_rating, COUNT(star_rating) AS hospitals_rated
FROM ratings GROUP BY measure_id, question ORDER BY avg_rating;
-- 3,181 of 4,787 hospitals have star ratings
-- Result: lowest areas are communication about medicines (2.77), restfulness of environment (2.88)
-- and care coordination (2.98); highest are nurse communication (3.42), cleanliness (3.56)
-- Summary, overall hospital rating and recommend hospital are overall scores, not specific areas

-- Step 2: Compare each area in hospitals rated highly overall (4-5 stars) vs poorly (1-2 stars)
WITH overall AS (
  SELECT facility_id, star_rating AS overall_rating
  FROM ratings
  WHERE measure_id = 'H_HSP_RATING_STAR_RATING'
)
SELECT r.question,
       ROUND(AVG(CASE WHEN o.overall_rating >= 4 THEN r.star_rating END), 2) AS high_rated,
       ROUND(AVG(CASE WHEN o.overall_rating <= 2 THEN r.star_rating END), 2) AS low_rated,
       ROUND(AVG(CASE WHEN o.overall_rating >= 4 THEN r.star_rating END)
           - AVG(CASE WHEN o.overall_rating <= 2 THEN r.star_rating END), 2) AS gap
FROM ratings r
JOIN overall o ON r.facility_id = o.facility_id
GROUP BY r.question
ORDER BY gap DESC;
-- Result (overall scores excluded): biggest gaps are nurse communication (2.08),
-- staff responsiveness (1.98), restfulness of environment (1.88) and care coordination (1.83).
-- Low and separate good from poor hospitals: restfulness of environment, care coordination and staff responsiveness
-- (low on average AND big gaps between good and poor hospitals).
-- Nurse communication has the biggest gap: poorly rated hospitals fall furthest behind here,
-- but it is a strength on average.
-- Communication about medicines is low even in top hospitals (3.49): a system-wide issue.
-- Note: shows association with overall rating, not cause.

-- Step 3: Average rating on the four priority areas by state (states with 10+ rated hospitals)
SELECT state,
       COUNT(DISTINCT facility_id) AS hospitals,
       ROUND(AVG(CASE WHEN question LIKE '%medicines%' THEN star_rating END), 2) AS medicines,
       ROUND(AVG(CASE WHEN question LIKE '%restfulness%' THEN star_rating END), 2) AS restfulness,
       ROUND(AVG(CASE WHEN question LIKE '%coordination%' THEN star_rating END), 2) AS care_coordination,
       ROUND(AVG(CASE WHEN question LIKE '%responsiveness%' THEN star_rating END), 2) AS staff_responsiveness
FROM ratings
WHERE star_rating IS NOT NULL
GROUP BY state
HAVING COUNT(DISTINCT facility_id) >= 10
ORDER BY medicines;
-- Result: weakest on medicines communication are Puerto Rico (1.3, only 10 hospitals),
-- Florida (2.19, 166 hospitals) and Maryland (2.21, 42 hospitals).
-- Strongest are Maine (3.8, 25 hospitals), Vermont (3.69, 13 hospitals) and Wisconsin (3.68, 96 hospitals, high on all four areas).
-- Large regional differences; may partly reflect patient mix and expectations, not only hospital quality.
-- States with few hospitals (e.g. Puerto Rico 10, Vermont 13) are less reliable; Florida and Wisconsin are the strongest evidence.

-- Step 4: Communication about medicines in detail
-- Why: lowest-rated area overall (2.77) and low even in top hospitals (3.49), so a system-wide issue
-- How patients answered the medicines question: average % always / usually / sometimes or never across hospitals
SELECT "HCAHPS Measure ID" AS measure_id,
       ROUND(AVG(CAST("HCAHPS Answer Percent" AS INTEGER)), 1) AS avg_percent,
       COUNT(*) AS hospitals
FROM hcahps_clean
WHERE "HCAHPS Measure ID" IN ('H_COMP_5_A_P', 'H_COMP_5_U_P', 'H_COMP_5_SN_P')
  AND "HCAHPS Answer Percent" GLOB '[0-9]*'
GROUP BY "HCAHPS Measure ID";
-- Result: on average, 62.1% of patients said staff always explained medicines,
-- 19.0% said usually and 18.9% said sometimes or never (nearly 1 in 5).
-- So about 4 in 10 patients did not get an explanation every time.
-- 3,940 hospitals report percentages, more than the 3,181 with star ratings,
-- because star ratings need at least 100 completed surveys.

-- Step 5: Share of patients saying staff sometimes or never explained medicines, by overall hospital rating
WITH overall AS (
  SELECT facility_id, star_rating AS overall_rating
  FROM ratings
  WHERE measure_id = 'H_HSP_RATING_STAR_RATING'
)
SELECT o.overall_rating,
       COUNT(*) AS hospitals,
       ROUND(AVG(CAST(h."HCAHPS Answer Percent" AS INTEGER)), 1) AS avg_sometimes_never
FROM hcahps_clean h
JOIN overall o ON h."Facility ID" = o.facility_id
WHERE h."HCAHPS Measure ID" = 'H_COMP_5_SN_P'
  AND h."HCAHPS Answer Percent" GLOB '[0-9]*'
  AND o.overall_rating IS NOT NULL
GROUP BY o.overall_rating
ORDER BY o.overall_rating;
-- Result: the share saying sometimes or never falls steadily with each overall star:
-- 1 star 29.9%, 2 stars 24.7%, 3 stars 21.0%, 4 stars 17.3%, 5 stars 12.1% (3,181 hospitals).
-- About 3 in 10 patients in 1-star hospitals vs about 1 in 8 in 5-star hospitals.
-- Even in 5-star hospitals are not consistent, so it is a system-wide issue.
-- Shows association, not cause.

-- Step 6: Is nurse communication linked to communication about medicines?
-- Nurse communication is high on average with the biggest gap; medicines is lowest even in top hospitals.
-- Group hospitals by nurse communication rating and compare their average medicines rating.
SELECT n.star_rating AS nurse_stars,
       ROUND(AVG(m.star_rating), 2) AS avg_medicine_stars,
       COUNT(*) AS hospitals
FROM ratings n
JOIN ratings m ON n.facility_id = m.facility_id
WHERE n.question LIKE '%Nurse communication%'
  AND m.question LIKE '%medicine%'
GROUP BY n.star_rating
ORDER BY n.star_rating;
-- Result: nurse 1 star = medicines 1.22 (121 hospitals); 2 = 1.89 (569); 3 = 2.36 (926);
-- 4 = 3.08 (992); 5 = 4.11 (573). Total 3,181 hospitals.
-- Medicines rises with nurse rating but stays almost a star lower in top hospitals.

-- Step 7: Check the weakest areas using "always" percentages
-- (CMS sets star cut-offs separately for each area, so percentages compare areas more fairly)
SELECT "HCAHPS Question",
       ROUND(AVG(CAST("HCAHPS Answer Percent" AS REAL)), 1) AS avg_pct,
       COUNT(*) AS hospitals
FROM hcahps_clean
WHERE "HCAHPS Measure ID" LIKE '%_A_P'
  AND "HCAHPS Answer Percent" GLOB '[0-9]*'
GROUP BY "HCAHPS Question"
ORDER BY avg_pct;
-- Result (overall areas, 3,940 hospitals): restfulness 59.1%, medicines 62.1%, staff responsiveness 63.9%,
-- cleanliness 73.3%, care coordination 73.9%, doctors 79.5%, nurses 79.7%.
-- Confirms medicines and restfulness as the weakest areas; care coordination is not low in percentage terms.
-- Medicines detail (3,615 hospitals): what the medication was for 74.5% vs side effects 48.2%.
-- The medicines gap is mainly about side effects.

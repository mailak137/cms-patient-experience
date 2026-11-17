--Question: Where should hospitals focus to improve patient experience?

-- STEP 1: Make a working copy of the raw data
CREATE TABLE hcahps_clean AS SELECT * FROM raw_hcahps;

-- STEP 2: Check for duplicate hospital-measure rows: none found
SELECT "Facility ID", "HCAHPS Measure ID", COUNT(*) FROM hcahps_clean GROUP BY "Facility ID", "HCAHPS Measure ID" HAVING COUNT(*) > 1;

-- STEP 3:List the star rating measures (one per area of care)
SELECT DISTINCT "HCAHPS Measure ID", "HCAHPS Question" FROM hcahps_clean WHERE "HCAHPS Measure ID" LIKE '%STAR_RATING';

-- STEP 4: Make a smaller table with only the star ratings: 57,444 rows
CREATE TABLE star_ratings AS SELECT "Facility ID", "Facility Name", "State", "HCAHPS Measure ID", "HCAHPS Question", "Patient Survey Star Rating" FROM hcahps_clean WHERE "HCAHPS Measure ID" LIKE '%STAR_RATING';

-- STEP 5: Number of hospitals: 4,787 (12 star rating each)
SELECT COUNT(DISTINCT "Facility ID") FROM star_ratings;

-- STEP 6: Check star rating values: 1 = 1,889; 2 = 7,978; 3 = 13,096; 4 = 11,270; 5 = 3,939; Not Available = 19,272
SELECT "Patient Survey Star Rating", COUNT(*) FROM star_ratings GROUP BY "Patient Survey Star Rating";

-- STEP 7: Turn 'Not Available' ratings into NULL: 19,272 rows
-- 'Not Available' usually means the hospital had too few completed surveys for a star rating
UPDATE star_ratings SET "Patient Survey Star Rating" = NULL WHERE "Patient Survey Star Rating" = 'Not Available';

-- STEP 8: Check: 19,272 NULL ratings
SELECT COUNT(*) FROM star_ratings WHERE "Patient Survey Star Rating" IS NULL;

--Step 9: clean ratings table (short column names, ratings as numbers, NULLS removed): 38,172 rows
CREATE TABLE ratings AS SELECT "Facility ID" AS facility_id, "Facility Name" AS facility_name, "STATE" AS state, "HCAHPS Measure ID" AS measure_id, "HCAHPS Question" AS question, CAST)("Patient Survey Star Rating AS INTEGER) AS star_rating FROM star_ratings WHERE "Patient Survey Star Rating" IS NOT NULL;

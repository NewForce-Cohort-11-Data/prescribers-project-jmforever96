-- *********************************README_MVP.md:********************************************
-- 1. 
-- a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
-- b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.
SELECT npi AS prescriber_number, p2.total_claim_count
FROM prescriber AS p1
INNER JOIN prescription AS p2
USING (npi)
ORDER BY p2.total_claim_count DESC NULLS LAST
LIMIT 1;

SELECT 
	nppes_provider_last_org_name AS last_name, 
	nppes_provider_first_name AS first_name, 
	specialty_description AS specialty, 
	SUM(p2.total_claim_count) AS total_claims
FROM prescriber AS p1
INNER JOIN prescription AS p2
USING (npi)
GROUP BY last_name, 
	first_name, 
	specialty
ORDER BY total_claims DESC NULLS LAST;

-- 2. 
-- a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT DISTINCT specialty_description AS specialty, SUM(p2.total_claim_count) AS total_claims
FROM prescriber AS p1
INNER JOIN prescription AS p2
USING (npi)
GROUP BY specialty
ORDER BY total_claims DESC;

-- b. Which specialty had the most total number of claims for opioids?
SELECT specialty_description, 
		SUM(total_claim_count) AS total_opioid_claims
FROM prescription
INNER JOIN prescriber
USING (npi)
INNER JOIN drug
USING (drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY total_opioid_claims DESC;

-- c. Challenge Question: Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber
LEFT JOIN prescription
USING (npi)
GROUP BY specialty_description
-- ORDER BY total_claims ASC NULLS FIRST
HAVING SUM(total_claim_count) IS NULL;

--Note to self: Having is when there is a GROUP BY present
-- HAVING groups the RESULTS and GROUP BY groups BEFORE the results are presented



-- d. Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty, report the percentage of total claims by that specialty which are for opioids. 
-- Which specialties have a high percentage of opioids?

SELECT
	specialty_description,
	ROUND(SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count END) / SUM(total_claim_count), 2) * 100 AS percent_opioid
FROM prescriber
LEFT JOIN prescription
USING (npi)
LEFT JOIN drug
USING (drug_name)
GROUP BY specialty_description
ORDER BY percent_opioid DESC NULLS LAST;

-- 3. 
-- a. Which drug (generic_name) had the highest total drug cost?
SELECT DISTINCT generic_name, SUM(ROUND(total_drug_cost, 2)) AS total_drug_cost
FROM drug AS T1
LEFT JOIN prescription AS T2
USING (drug_name)
GROUP BY generic_name
ORDER BY total_drug_cost DESC NULLS LAST
LIMIT 10;

-- b. Which drug (generic_name) has the hightest total cost per day? Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.
SELECT DISTINCT generic_name, SUM(ROUND(total_day_supply, 2)) AS total_day_supply
FROM drug
LEFT JOIN prescription
USING (drug_name)
GROUP BY generic_name
ORDER BY total_day_supply DESC NULLS LAST
LIMIT 10;

-- 4. 
-- a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', 
-- .says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. 
-- Hint: You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/
SELECT drug_name,
	CASE 	
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		WHEN opioid_drug_flag = 'N' OR antibiotic_drug_flag = 'N' THEN 'neither'
	END AS drug_type
FROM drug;

-- b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. 
-- Hint: Format the total costs as MONEY for easier comparision.
SELECT 
	CASE 	
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		WHEN opioid_drug_flag = 'N' OR antibiotic_drug_flag = 'N' THEN 'neither'
	END AS drug_type, 
	SUM(total_drug_cost::MONEY) AS total_drug_cost
FROM drug
INNER JOIN prescription
USING (drug_name)
GROUP BY drug_type
ORDER BY total_drug_cost DESC;


-- 5.
-- a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.
SELECT COUNT(DISTINCT cbsa) AS total_cbsa_tn
FROM cbsa
WHERE cbsaname ILIKE '%TN';

-- ****TOMMY REVIEW****
SELECT 
	COUNT(DISTINCT cbsa)
FROM cbsa
INNER JOIN fips_county
USING (fipscounty)
WHERE state = 'TN';

-- b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT cbsaname, SUM(population) AS county_population
FROM cbsa
INNER JOIN population
USING (fipscounty)
GROUP BY cbsaname
ORDER BY county_population DESC;

SELECT cbsaname, SUM(population) AS county_population
FROM cbsa
INNER JOIN population
USING (fipscounty)
GROUP BY cbsaname
ORDER BY county_population;

-- c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT county, MAX(population) AS max_pop
FROM cbsa
RIGHT JOIN fips_county
USING (fipscounty)
INNER JOIN population
USING (fipscounty)
WHERE cbsa IS NULL
GROUP BY county
ORDER BY max_pop DESC;

-- 6. 
-- a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC;

-- b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
-- CTE:
WITH drug_type_and_claims AS 
	(SELECT drug_name, total_claim_count
	FROM prescription
	WHERE total_claim_count >= 3000
	ORDER BY total_claim_count DESC)

SELECT drug_name, total_claim_count,
	CASE 	
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		WHEN opioid_drug_flag = 'N' OR antibiotic_drug_flag = 'N' THEN 'neither'
	END AS drug_type
FROM drug
RIGHT JOIN drug_type_and_claims
USING (drug_name)
ORDER BY total_claim_count DESC;

-- c. Add another column to your answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT 
	CONCAT(nppes_provider_last_org_name, ', ', nppes_provider_first_name) AS prescriber_name, 
	drug_name, 
	total_claim_count,
CASE 
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		WHEN opioid_drug_flag = 'N' OR antibiotic_drug_flag = 'N' THEN 'neither'
	END AS drug_type
FROM prescription
LEFT JOIN prescriber
USING (npi)
INNER JOIN drug
USING (drug_name)
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC;

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. 
SELECT T1.npi, T3.generic_name, SUM(T1.total_claim_count)
FROM prescription AS T1
INNER JOIN prescriber AS T2
USING (npi)
INNER JOIN drug AS T3
USING (drug_name)
WHERE T2.nppes_provider_city = 'NASHVILLE'
	AND T3.opioid_drug_flag = 'Y'
	AND T2.specialty_description = 'Pain Management'
GROUP BY T1.npi, T3.generic_name;




-- Hint: The results from all 3 parts will have 637 rows.
-- a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) 
-- in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y').
-- Warning: Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT T1.npi, drug_name
FROM prescriber AS T1
CROSS JOIN drug AS T2
WHERE T1.nppes_provider_city = 'NASHVILLE'
	AND T2.opioid_drug_flag = 'Y'
	AND T1.specialty_description = 'Pain Management';


-- b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. 
-- You should report the npi, the drug name, and the number of claims (total_claim_count).
-- c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
SELECT 
	T1.npi, 
	drug_name, 
	COALESCE(total_claim_count, 0) AS total_claims
FROM prescriber AS T1
CROSS JOIN drug AS T2
LEFT JOIN prescription AS T3
USING (npi, drug_name)
WHERE T1.nppes_provider_city = 'NASHVILLE'
	AND T2.opioid_drug_flag = 'Y'
	AND T1.specialty_description = 'Pain Management'
ORDER BY total_claims DESC;







-- ******************************************************README_grouping_sets.md************************************************************
-- 1. Write a query which returns the total number of claims for these two groups.
SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE specialty_description ILIKE '%pain%'
GROUP BY specialty_description
ORDER BY total_claims;

-- 2. Now, let's say that we want our output to also include the total number of claims between these two groups. 
-- Combine two queries with the UNION keyword to accomplish this.
WITH pain_count AS ((SELECT SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE specialty_description = 'Pain Management')
UNION
(SELECT SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE specialty_description = 'Interventional Pain Management'))

SELECT SUM(total_claims) total_claims_per_pain_mgmt_drug
FROM pain_count;

-- 3. Now, instead of using UNION, make use of GROUPING SETS to achieve the same output.
SELECT COALESCE (specialty_description, 'Grand Total') AS category, SUM(total_claim_count) AS total_claims
FROM prescriber
LEFT JOIN prescription
USING (npi)
WHERE specialty_description ILIKE '%Pain Management'
GROUP BY 
	ROLLUP(specialty_description)
ORDER BY total_claims;

-- 4. In addition to comparing the total number of prescriptions by specialty, let's also bring in information about the number of opioid vs. non-opioid claims by these two specialties. 
-- Modify your query (still making use of GROUPING SETS so that your output also shows the total number of opioid claims vs. non-opioid claims by these two specialites:
SELECT specialty_description, COUNT(opioid_drug_flag) AS opioid_flags, SUM(total_claim_count) AS total_claims
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
USING (npi)
WHERE specialty_description ILIKE '%Pain Management'
	AND opioid_drug_flag = 'Y'
GROUP BY 
	ROLLUP(specialty_description);

-- 5. Modify your query by replacing the GROUPING SETS with ROLLUP(opioid_drug_flag, specialty_description). 
-- How is the result different from the output from the previous query?
SELECT specialty_description, COUNT(opioid_drug_flag) AS opioid_flags, SUM(total_claim_count) AS total_claims
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
USING (npi)
WHERE specialty_description ILIKE '%Pain Management'
	AND opioid_drug_flag = 'Y'
GROUP BY 
	ROLLUP(opioid_drug_flag, specialty_description);


-- 6. Switch the order of the variables inside the ROLLUP. That is, use ROLLUP(specialty_description, opioid_drug_flag). 
-- How does this change the result?
SELECT specialty_description, COUNT(opioid_drug_flag) AS opioid_flags, SUM(total_claim_count) AS total_claims
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
USING (npi)
WHERE specialty_description ILIKE '%Pain Management'
	AND opioid_drug_flag = 'Y'
GROUP BY 
	ROLLUP(specialty_description, opioid_drug_flag);

-- 7. Finally, change your query to use the CUBE function instead of ROLLUP. 
-- How does this impact the output?
SELECT specialty_description, COUNT(opioid_drug_flag) AS opioid_flags, SUM(total_claim_count) AS total_claims
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
USING (npi)
WHERE specialty_description ILIKE '%Pain Management'
	AND opioid_drug_flag = 'Y'
GROUP BY 
	CUBE(specialty_description, opioid_drug_flag);

	
-- 8. In this question, your goal is to create a pivot table showing for each of the 4 largest cities in Tennessee (Nashville, Memphis, Knoxville, and Chattanooga), 
-- the total claim count for each of six common types of opioids: Hydrocodone, Oxycodone, Oxymorphone, Morphine, Codeine, and Fentanyl. 
-- For the purpose of this question, we will put a drug into one of the six listed categories if it has the category name as part of its generic name. 
-- For example, we could count both of "ACETAMINOPHEN WITH CODEINE" and "CODEINE SULFATE" as being "CODEINE" for the purposes of this question.

WITH classification AS 
(SELECT drug_name,
	CASE 
		WHEN drug_name ILIKE '%hydrocod%' THEN 'Hydrocodone'
			WHEN drug_name ILIKE '%oxycod%' THEN 'Oxycodone'
			WHEN drug_name ILIKE '%oxymorph%' THEN 'Oxymorphone'
			WHEN drug_name ILIKE '%morphine%' THEN 'Morphine'
			WHEN drug_name ILIKE '%codeine%' THEN 'Codeine'
			WHEN drug_name ILIKE '%fent%' THEN 'Fentanyl'
	END AS opioid_type,
	CASE
		WHEN nppes_provider_city ILIKE 'NASH%' THEN 'Nashville'
			WHEN nppes_provider_city ILIKE 'MEMP%' THEN 'Memphis'
			WHEN nppes_provider_city ILIKE 'KNOX%' THEN 'Knoxville'
			WHEN nppes_provider_city ILIKE 'CHAT%' THEN 'Chattanooga'
	END AS city,
	total_claim_count
FROM prescription
INNER JOIN prescriber
USING (npi)
WHERE
		LEFT(nppes_provider_city, 4) IN ('CHAT', 'KNOX', 'MEMP', 'NASH')
		AND (drug_name ILIKE '%code%' 
		OR drug_name ILIKE '%hydrocodone%' 
		OR drug_name ILIKE '%oxycodone%'
		OR drug_name ILIKE '%oxymorphone%' 
		OR drug_name ILIKE '%morphine%' 
		OR drug_name ILIKE '%fentanyl%'))

SELECT DISTINCT drug_name, city, SUM(total_claim_count) AS total_claims
FROM classification
GROUP BY city, drug_name
ORDER BY total_claims DESC;

SELECT *
FROM crosstab($$SELECT city, codeine, fentanyl, hydrocodone, morphine, oxycodone, oxymorphone FROM classification$$)

-- NEED TO REVISIT FOR MODIFICATIONS TO QUERY****

-- ******************************************************README_bonus.md************************************************************


-- 1. How many npi numbers appear in the prescriber table but not in the prescription table?
SELECT COUNT(DISTINCT npi)
FROM prescriber
WHERE npi NOT IN 
		(SELECT npi
		FROM prescription);


SELECT *
FROM prescriber;

SELECT * 
FROM prescription;


-- 2.
-- a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.
SELECT DISTINCT generic_name, specialty_description
FROM drug
LEFT JOIN prescription
USING (drug_name)
LEFT JOIN prescriber
USING (npi)
WHERE specialty_description ILIKE '%Family Practice%'
LIMIT 5;

-- b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.
SELECT DISTINCT generic_name, specialty_description
FROM drug
LEFT JOIN prescription
USING (drug_name)
LEFT JOIN prescriber
USING (npi)
WHERE specialty_description ILIKE 'Cardiology%'
LIMIT 5;

-- c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.
SELECT DISTINCT generic_name, specialty_description
FROM drug
LEFT JOIN prescription
USING (drug_name)
LEFT JOIN prescriber
USING (npi)
WHERE specialty_description ILIKE '%Family Practice%'
UNION
SELECT DISTINCT generic_name, specialty_description
FROM drug
LEFT JOIN prescription
USING (drug_name)
LEFT JOIN prescriber
USING (npi)
WHERE specialty_description ILIKE 'Cardiology%';

-- 3. 
-- Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee. 
-- a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. 
-- Report the npi, the total number of claims, and include a column showing the city.
SELECT DISTINCT prescription.npi AS prescriber_id, nppes_provider_city AS prescriber_city, SUM(total_claim_count) AS total_claims
FROM prescription
LEFT JOIN prescriber
USING (npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY prescriber_id, prescriber_city
ORDER BY total_claims DESC
LIMIT 5;

SELECT * 
FROM prescriber;

-- b. Now, report the same for Memphis.
SELECT DISTINCT prescription.npi AS prescriber_id, nppes_provider_city AS prescriber_city, SUM(total_claim_count) AS total_claims
FROM prescription
LEFT JOIN prescriber
USING (npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP BY prescriber_id, prescriber_city
ORDER BY total_claims DESC
LIMIT 5;

-- c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.
SELECT DISTINCT prescription.npi AS prescriber_id, nppes_provider_city AS prescriber_city, SUM(total_claim_count) AS total_claims
FROM prescription
LEFT JOIN prescriber
USING (npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY prescriber_id, prescriber_city
UNION
SELECT DISTINCT prescription.npi AS prescriber_id, nppes_provider_city AS prescriber_city, SUM(total_claim_count) AS total_claims
FROM prescription
LEFT JOIN prescriber
USING (npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP BY prescriber_id, prescriber_city
UNION
SELECT DISTINCT prescription.npi AS prescriber_id, nppes_provider_city AS prescriber_city, SUM(total_claim_count) AS total_claims
FROM prescription
LEFT JOIN prescriber
USING (npi)
WHERE nppes_provider_city = 'KNOXVILLE'
GROUP BY prescriber_id, prescriber_city
UNION
SELECT DISTINCT prescription.npi AS prescriber_id, nppes_provider_city AS prescriber_city, SUM(total_claim_count) AS total_claims
FROM prescription
LEFT JOIN prescriber
USING (npi)
WHERE nppes_provider_city = 'CHATTANOOGA'
GROUP BY prescriber_id, prescriber_city
ORDER BY total_claims DESC;

-- 4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.
SELECT DISTINCT county, SUM(overdose_deaths) AS total_od_deaths
FROM overdose_deaths
LEFT JOIN fips_county
ON overdose_deaths.fipscounty = fips_county.fipscounty::INTEGER
WHERE overdose_deaths > (SELECT ROUND(AVG(overdose_deaths),0) AS avg_deaths FROM overdose_deaths)
GROUP BY county
ORDER BY total_od_deaths DESC;

-- 5.
-- a. Write a query that finds the total population of Tennessee.
SELECT SUM(population) AS total_pop
FROM population;

-- b. Build off of the query that you wrote in part a to write a query that returns for each county that 
-- county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.
SELECT county, population,
	ROUND((population * 100) / (SELECT SUM(population) FROM population),2) AS percentage_of_total_pop
FROM population
INNER JOIN fips_county
USING (fipscounty)
GROUP BY county, population
ORDER  BY percentage_of_total_pop DESC;




SELECT *
FROM cbsa;

SELECT *
FROM drug;

SELECT *
FROM fips_county;

SELECT *
FROM overdose_deaths;

SELECT *
FROM population;

SELECT *
FROM prescriber;

SELECT *
FROM prescription;

SELECT *
FROM zip_fips;
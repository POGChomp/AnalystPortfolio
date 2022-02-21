/*

Project idea: https://www.youtube.com/c/AlexTheAnalyst
Dataset: https://ourworldindata.org/covid-deaths

*/

SELECT *
FROM PortfolioProject..death_data
WHERE continent IS NOT NULL
ORDER BY location, date;

SELECT *
FROM PortfolioProject..vacc_data
ORDER BY location, date;


-- SELECT data that will be used

SELECT location, date, population, total_cases, new_cases, total_deaths
FROM PortfolioProject..death_data
ORDER BY 1, 2;


-- total_cases vs total_deaths
-- Likelyhood of dying if infected with covid in Germany

SELECT location, date, total_cases,  total_deaths, ROUND((total_deaths / total_cases) * 100, 2)  AS death_percentage
FROM PortfolioProject..death_data
WHERE location = 'Germany'
ORDER BY 1, 2;


-- total_cases vs population
-- Percentage of population infected with Covid in Germany per day

SELECT location, date, population, total_cases, ROUND((total_cases / population) * 100, 2) AS percent_population_infected
FROM PortfolioProject..death_data
WHERE location = 'Germany'
ORDER BY 1, 2;


-- Countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS highest_infection_count, ROUND(MAX((total_cases / population) * 100), 2) AS percent_population_infected
FROM PortfolioProject..death_data
GROUP BY location, population
ORDER BY percent_population_infected DESC;


-- Top 10 countries with highest death count per population

SELECT TOP 10 location, population, MAX(CAST(total_deaths AS INT)) AS total_death_count, ROUND((MAX(CAST(total_deaths AS INT)) / population) * 100, 2) AS total_death_count_percentage
FROM PortfolioProject..death_data
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY total_death_count DESC;


-- Continents with the highest death count

-- v1
SELECT continent, MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM PortfolioProject..death_data
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC;

-- v2
SELECT location, MAX(CAST(total_deaths AS INT)) AS total_death_count 
FROM PortfolioProject..death_data
WHERE continent IS NULL AND location NOT LIKE '%income%'
GROUP BY location
ORDER BY total_death_count DESC;


-- Global death rate per day

SELECT  date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, ROUND(SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100, 2) AS death_percentage
FROM PortfolioProject..death_data
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2;


-- Total population vs vaccinations

-- Using CTE
WITH pop_vs_vac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS
(
SELECT death.continent, death.location, death.date, death.population, vacci.new_vaccinations, SUM(CAST(vacci.new_vaccinations AS REAL))
	OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS rolling_people_vaccinated
FROM PortfolioProject..death_data death
JOIN PortfolioProject..vacc_data vacci
	ON death.location = vacci.location
	AND death.date = vacci.date
WHERE death.continent IS NOT NULL
)
SELECT *, ROUND((rolling_people_vaccinated / population) * 100, 2) AS total_percent_vaccinated
FROM Pop_vs_Vac
WHERE location = 'Germany';


-- Using temp table
DROP TABLE IF EXISTS #percent_population_vaccinated
CREATE TABLE #percent_population_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations nvarchar(255),
rolling_people_vaccinated numeric
);

INSERT INTO #percent_population_vaccinated
SELECT death.continent, death.location, death.date, death.population, vacci.new_vaccinations, SUM(CAST(vacci.new_vaccinations AS REAL))
	OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS rolling_people_vaccinated
FROM PortfolioProject..death_data death
JOIN PortfolioProject..vacc_data vacci
	ON death.location = vacci.location
	AND death.date = vacci.date
WHERE death.continent IS NOT NULL;


SELECT *, ROUND((rolling_people_vaccinated / population) * 100, 2) AS total_percent_vaccinated
FROM #percent_population_vaccinated
WHERE location = 'Germany';




-- Creating View to store data for later visualizations

CREATE VIEW percent_population_vaccinated AS
SELECT death.continent, death.location, death.date, death.population, vacci.new_vaccinations, SUM(CAST(vacci.new_vaccinations AS REAL))
	OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS rolling_people_vaccinated
FROM PortfolioProject..death_data death
JOIN PortfolioProject..vacc_data vacci
	ON death.location = vacci.location
	AND death.date = vacci.date
WHERE death.continent IS NOT NULL AND
death.location IN ('Germany', 'United States', 'China', 'India', 'Israel');

CREATE VIEW highest_death_count_continent AS
SELECT location, MAX(CAST(total_deaths AS INT)) AS total_death_count 
FROM PortfolioProject..death_data
WHERE continent IS NULL AND location NOT LIKE '%income%'
GROUP BY location;

CREATE VIEW highest_death_count_country AS
SELECT TOP 100 location, population, MAX(CAST(total_deaths AS INT)) AS highest_death_count
FROM PortfolioProject..death_data
WHERE continent IS NOT NULL
GROUP BY location, population
--ORDER BY highest_death_count DESC;

CREATE VIEW death_rate_per_day_germany AS
SELECT location, date, total_cases,  total_deaths, ROUND((total_deaths / total_cases) * 100, 2)  AS death_percentage
FROM PortfolioProject..death_data
WHERE location = 'Germany';

CREATE VIEW death_rate_per_day_global AS
SELECT  date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, ROUND(SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100, 2) AS death_percentage
FROM PortfolioProject..death_data
WHERE continent IS NOT NULL
GROUP BY date;
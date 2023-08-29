SELECT * FROM CovidDeaths 
WHERE continent <> ''
ORDER BY location, date

SELECT location, date, population, new_cases, total_cases, new_deaths, total_deaths
FROM CovidDeaths 
WHERE continent <> ''
ORDER BY location, date

ALTER TABLE CovidDeaths ALTER COLUMN new_cases float
ALTER TABLE CovidDeaths ALTER COLUMN new_deaths float
ALTER TABLE CovidDeaths ALTER COLUMN total_cases float
ALTER TABLE CovidDeaths ALTER COLUMN total_deaths float
ALTER TABLE CovidDeaths ALTER COLUMN population float

-- Calculating the death percentage (for each day) due to COVID for each country 

SELECT location, date, total_cases, total_deaths, 
CASE
	WHEN total_cases > 0 THEN (total_deaths/total_cases)*100
	ELSE 0
END AS DeathPercentage FROM CovidDeaths 
WHERE continent <> ''
ORDER BY location, date

-- Calculating the % of the population who have been infected by COVID (for each day) for each country

SELECT location, date, population, total_cases, 
CASE
	WHEN population > 0 THEN (total_cases/population)*100
	ELSE 0
END AS InfectedPopulationPercentage FROM CovidDeaths 
WHERE continent <> ''
ORDER BY location, date

-- Calculating the % of the population infected by COVID for each country

SELECT location, population, MAX(total_cases) AS TotalCases,
(MAX(total_cases)/MAX(population))*100 AS InfectedPopulationPercentage
FROM CovidDeaths 
WHERE population > 0 AND continent <> ''
GROUP BY location, population
ORDER BY InfectedPopulationPercentage DESC

-- Calculating the % of the population infected by COVID for each continent

SELECT location, population, MAX(total_cases) AS TotalCases,
(MAX(total_cases)/MAX(population))*100 AS InfectedPopulationPercentage
FROM CovidDeaths 
WHERE population > 0 AND continent = '' AND location NOT IN ('European Union', 'World')
GROUP BY location, population
ORDER BY InfectedPopulationPercentage

-- Calculating the % of the population who died due to COVID for each country

SELECT location, population, MAX(total_deaths) AS TotalDeaths,
(MAX(total_deaths)/MAX(population))*100 AS DeathPopulationPercentage
FROM CovidDeaths 
WHERE population > 0 AND continent <> ''
GROUP BY location, population
ORDER BY DeathPopulationPercentage

-- Calculating the % of the population who died due to COVID for each continent

SELECT location, population, MAX(total_deaths) AS TotalDeaths,
(MAX(total_deaths)/MAX(population))*100 AS DeathPopulationPercentage
FROM CovidDeaths 
WHERE population > 0 AND continent = '' AND location NOT IN ('European Union', 'World')
GROUP BY location, population
ORDER BY DeathPopulationPercentage

-- Global Numbers

-- Calculating the death percentage for the whole world

SELECT SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, 
(SUM(new_deaths)/SUM(new_cases))*100 AS DeathPercentage FROM CovidDeaths
WHERE continent <> ''

SELECT location, SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths,
(SUM(new_deaths)/SUM(new_cases))*100 AS DeathPercentage FROM CovidDeaths
WHERE continent <> ''
GROUP BY location
HAVING SUM(new_cases) > 0
ORDER BY DeathPercentage DESC

SELECT * FROM CovidDeaths cd INNER JOIN CovidVaccinations cv
ON cd.location = cv.location AND cd.date = cv.date

SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations 
FROM CovidDeaths cd INNER JOIN CovidVaccinations cv
ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent <> ''
ORDER BY cd.location, cd.date

SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CONVERT(int, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.date) AS TotalVaccinations
FROM CovidDeaths cd INNER JOIN CovidVaccinations cv
ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent <> ''
ORDER BY cd.location, cd.date

-- Using a COMMON TABLE EXPRESSION

WITH cte (continent, location, date, population, new_vaccinations, total_vaccinations)
AS
(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CAST(cv.new_vaccinations AS int)) OVER (PARTITION BY cd.location ORDER BY cd.date) AS total_vaccinations
FROM CovidDeaths cd INNER JOIN CovidVaccinations cv
ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent <> ''
)
SELECT *,(total_vaccinations/population)*100 AS VaccinatedPopulationPercent FROM cte
WHERE population > 0
ORDER BY location, date

WITH cte (continent, location, date, population, new_vaccinations, total_vaccinations)
AS
(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CAST(cv.new_vaccinations AS int)) OVER (PARTITION BY cd.location ORDER BY cd.date) AS total_vaccinations
FROM CovidDeaths cd INNER JOIN CovidVaccinations cv
ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent <> ''
)
SELECT location, MAX(population) AS population, MAX(total_vaccinations) AS total_vaccinations,
MAX(total_vaccinations)/MAX(population)*100 AS VaccinatedPopulationPercentage FROM cte
WHERE population > 0
GROUP BY location
ORDER BY VaccinatedPopulationPercentage DESC

-- Using a TEMP TABLE

DROP TABLE IF EXISTS #VaccinationStats
CREATE TABLE #VaccinationStats (
continent varchar(255),
location varchar(255),
date datetime,
population float,
new_vaccinations float,
total_vaccinations float
)

INSERT INTO #VaccinationStats
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CAST(cv.new_vaccinations AS int)) OVER (PARTITION BY cd.location ORDER BY cd.date) AS total_vaccinations
FROM CovidDeaths cd INNER JOIN CovidVaccinations cv
ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent <> ''

SELECT *,(total_vaccinations/population)*100 AS VaccinatedPopulationPercentage FROM #VaccinationStats
WHERE population > 0
ORDER BY location, date

-- Using a VIEW

CREATE VIEW VaccinationStats
AS
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CAST(cv.new_vaccinations AS int)) OVER (PARTITION BY cd.location ORDER BY cd.date) AS total_vaccinations
FROM CovidDeaths cd INNER JOIN CovidVaccinations cv
ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent <> ''

SELECT location, date, population, total_vaccinations, 
(total_vaccinations/population)*100 AS VaccinatedPopulationPercentage FROM VaccinationStats
WHERE population > 0
ORDER BY location, date

CREATE VIEW VaccPopulationPercent
AS
SELECT location, date, population, total_vaccinations, 
(total_vaccinations/population)*100 AS VaccinatedPopulationPercentage FROM VaccinationStats
WHERE population > 0

CREATE VIEW MaxVaccPopulationPercent
AS
SELECT location, MAX(population) AS population, MAX(total_vaccinations) AS total_vaccinations,
MAX(VaccinatedPopulationPercentage) AS VaccinatedPopulationPercentage
FROM VaccPopulationPercent
GROUP BY location

SELECT * FROM MaxVaccPopulationPercent	


CREATE VIEW TableauView1 
AS
SELECT SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, 
SUM(new_deaths)*100/SUM(new_cases) AS DeathPercentage FROM CovidDeaths
WHERE continent <> ''

-- This view shows the total cases, total deaths and the death percentage for the whole world
SELECT * FROM TableauView1 


CREATE VIEW TableauView2
AS
SELECT location, SUM(new_deaths) AS TotalDeaths FROM CovidDeaths
WHERE continent = '' AND location NOT IN ('European Union', 'International', 'World')
GROUP BY location

-- This view shows the total deaths for each continent
SELECT * FROM TableauView2


CREATE VIEW TableauView3
AS
SELECT location, population, MAX(total_cases) AS TotalCases,
(MAX(total_cases)/MAX(population))*100 AS InfectedPopulationPercentage
FROM CovidDeaths 
WHERE population > 0 AND continent <> ''
GROUP BY location, population

-- This view shows the total cases and the infected population percentage for each country
SELECT * FROM TableauView3
ORDER BY InfectedPopulationPercentage DESC


SELECT location, population, date, MAX(total_cases) AS TotalCases, 
(MAX(total_cases)/MAX(population))*100 AS InfectedPopulationPercentage
FROM CovidDeaths
WHERE population > 0
GROUP BY location, population, date
ORDER BY location, date

SELECT location, population, date, new_cases, 
SUM(new_cases) OVER (PARTITION BY location ORDER BY date) AS TotalCases
FROM CovidDeaths

-- Using the updated dataset from table 'CovidStats'

SELECT location, date, new_cases, total_cases, new_deaths, total_deaths 
FROM CovidStats
WHERE location = 'World'
ORDER BY location, date

-- Tableau Visualization 1
SELECT location, MAX(total_cases) AS TotalCases, MAX(total_deaths) AS TotalDeaths,
(MAX(total_deaths)/MAX(total_cases))*100 AS DeathPercentage
FROM CovidStats
WHERE location = 'World'
GROUP BY location

-- Tableau Visualization 2
SELECT Location, MAX(total_deaths) AS TotalDeaths FROM CovidStats
WHERE continent IS NULL 
AND location IN ('Asia', 'Africa', 'Europe', 'North America', 'South America', 'Oceania')
GROUP BY location
ORDER BY TotalDeaths DESC

-- Tableau Visualization 3
SELECT Location, MAX(population) AS Population, MAX(total_cases) AS InfectedCount,
(MAX(total_cases)/MAX(population))*100 AS InfectedPopulationPercentage
FROM CovidStats
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY location	

-- Tableau Visualization 4
SELECT Location, Date, MAX(population) AS Population, MAX(total_cases) AS TotalCases, 
(MAX(total_cases)/MAX(population))*100 AS InfectedPopulationPercentage
FROM CovidStats
GROUP BY location, date
ORDER BY location, date

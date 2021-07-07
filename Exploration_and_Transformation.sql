	SELECT *
	FROM portfolioproject.dbo.CovidDeaths
	ORDER BY 3,4

SELECT *
FROM portfolioproject.dbo.CovidVaccinations
ORDER BY 3,4

-- Select the data we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM portfolioproject.dbo.CovidDeaths
ORDER BY 1,2

-- Changing Datatypes for Total_cases, Date and Total_Deaths

ALTER TABLE portfolioproject.dbo.CovidDeaths
ALTER COLUMN total_cases float

ALTER TABLE portfolioproject.dbo.CovidDeaths
ALTER COLUMN total_deaths float

ALTER TABLE portfolioproject.dbo.CovidDeaths
ALTER COLUMN date date

ALTER TABLE portfolioproject.dbo.CovidDeaths
ALTER COLUMN population float

ALTER TABLE portfolioproject.dbo.CovidDeaths
ALTER COLUMN new_cases float

ALTER TABLE portfolioproject.dbo.CovidDeaths
ALTER COLUMN new_deaths float

ALTER TABLE portfolioproject.dbo.CovidDeaths
ALTER COLUMN continent nvarchar(50) NULL

ALTER TABLE portfolioproject.dbo.CovidVaccinations
ALTER COLUMN date date

ALTER TABLE portfolioproject.dbo.CovidVaccinations
ALTER COLUMN new_vaccinations float

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying in Canada if you contract Covid

SELECT location, date, total_cases, total_deaths,
CASE WHEN total_cases=0 THEN 0
ELSE (total_deaths/total_cases)*100.0 END AS Death_Percent
FROM portfolioproject.dbo.CovidDeaths
WHERE location like '%Canada%'
ORDER BY 1,2

-- Looking at Total Cases vs Population
-- Shows likelihood of getting Covid infected in Canada

SELECT location, date, total_cases, population,
CASE WHEN population=0 THEN 0
ELSE round((total_cases/population)*100.0,2) END AS InfectionRate
FROM portfolioproject.dbo.CovidDeaths
WHERE location like '%Canada%'
ORDER BY 1,2


-- Looking at Countries with Highest Infection Rate compared to Population
SELECT date, location, population, max(total_cases) AS HighestInfectionCount, max(round((total_cases/population)*100.0,2)) AS PercentPopAffected
FROM portfolioproject.dbo.CovidDeaths
-- WHERE population<>0
GROUP BY location, population, date
ORDER BY PercentPopAffected desc

-- Looking at Countries with Highest Death Count

SELECT location, max(total_deaths) AS TotalDeathCount
FROM portfolioproject.dbo.CovidDeaths
WHERE continent <> ''
GROUP BY location
ORDER BY TotalDeathCount desc

-- Looking at Continents with Highest Death Count

SELECT continent, max(total_deaths) AS TotalDeathCount
FROM portfolioproject.dbo.CovidDeaths
WHERE continent <> ''
GROUP BY continent
ORDER BY TotalDeathCount desc

-- Global Numbers

UPDATE portfolioproject.dbo.CovidDeaths 
SET new_cases = NULL 
WHERE new_cases = ''

UPDATE portfolioproject.dbo.CovidDeaths 
SET new_deaths = NULL 
WHERE new_deaths = ''

SELECT SUM(new_cases) AS sum_new_cases, SUM(new_deaths) AS sum_new_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS Death_Percent
FROM portfolioproject.dbo.CovidDeaths
WHERE continent <> ''
-- GROUP BY date
ORDER BY 1,2

-- Looking at TotalPopulation vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) as Rolling_People_Vaccinated
FROM portfolioproject.dbo.CovidDeaths AS dea
JOIN portfolioproject.dbo.CovidVaccinations AS vac
ON dea.location=vac.location AND dea.date = vac.date
WHERE dea.continent<>''
ORDER BY 2,3

-- USE OF CTE

UPDATE portfolioproject.dbo.CovidDeaths 
SET population = NULL 
WHERE population = ''

UPDATE portfolioproject.dbo.CovidVaccinations 
SET new_vaccinations = NULL 
WHERE new_vaccinations = ''

WITH POPvsVAC (Continent, Location, Date, Population, New_Vaccinations, Rolling_People_Vaccinated)
AS (SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) as Rolling_People_Vaccinated
FROM portfolioproject.dbo.CovidDeaths AS dea
JOIN portfolioproject.dbo.CovidVaccinations AS vac
ON dea.location=vac.location AND dea.date = vac.date
WHERE dea.continent<>'')

SELECT *, (Rolling_People_Vaccinated/Population)*100 FROM POPvsVAC

-- Temporary Table

DROP TABLE IF EXISTS PercentPopulationVaccinated
CREATE TABLE PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population float,
New_Vaccinations float,
Rolling_People_Vaccinated float
)

INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) as Rolling_People_Vaccinated
FROM portfolioproject.dbo.CovidDeaths AS dea
JOIN portfolioproject.dbo.CovidVaccinations AS vac
ON dea.location=vac.location AND dea.date = vac.date
WHERE dea.continent<>''

SELECT *, (Rolling_People_Vaccinated/Population)*100 FROM PercentPopulationVaccinated

-- Creating View to Store date for visualization using Tableau

USE portfolioproject;
CREATE VIEW PercentPopulationVaccinated_View AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) as Rolling_People_Vaccinated
FROM portfolioproject.dbo.CovidDeaths AS dea
JOIN portfolioproject.dbo.CovidVaccinations AS vac
ON dea.location=vac.location AND dea.date = vac.date
WHERE dea.continent<>''

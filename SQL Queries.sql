
-- Likelyhood of dying from covid in US
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercent
FROM CovidDeaths
WHERE Location like '%states%'
ORDER BY 1,2

-- look at total cases vs population 
-- shows what % of population has had covid
SELECT location, date, total_cases, population, (ISNULL(total_cases,0)/population)*100 as CasePerPop
FROM CovidDeaths
WHERE Location like '%states%'
ORDER BY 1,2

-- look at countries with highest infection rate compared to population

SELECT location, population, max(total_cases) as HighestInfectionCount, max((total_cases/population)*100) as CasePerPop 
FROM CovidDeaths
--WHERE Location like '%states%'
GROUP BY location, population
ORDER BY CasePerPop DESC

-- Show countries with highest death count per population

SELECT location, MAX(cast(total_deaths as int)) as TotalDeaths
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeaths DESC


-- Show continents with highest death count per population

SELECT location, MAX(cast(total_deaths as int)) as TotalDeaths
FROM CovidDeaths
WHERE continent IS NULL
	AND location NOT LIKE '%income%'
GROUP BY location
ORDER BY TotalDeaths DESC


-- Gloabl numbers

SELECT SUM(new_cases) as total_cases, SUM(CAST(new_deaths as INT)) as total_deaths, SUM(CAST(new_deaths as INT)) / SUM(new_cases) * 100 as DeathPercent
FROM CovidDeaths
WHERE continent is not null
--GROUP BY date -- add date for by day
ORDER BY 1,2

--------------------------------------------
-- look at total pop vs vaccinations

SELECT cd.continent, cd.location, cd.date, cd.population, ISNULL(cv.new_vaccinations,0) as new_vaccinations
, SUM(CAST(cv.new_vaccinations as bigint)) OVER (partition by cd.location ORDER BY cd.location, cd.date) as Rolling_Vacc_Count
FROM CovidVaccinations cv 
JOIN CovidDeaths cd 
	ON cd.location = cv.location 
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY 2,3


-----------------------------------
-- use cte

With PopvsVacc (Continent, Location, Date, Population, New_Vacc, RollingVaccCount)
as (

SELECT cd.continent, cd.location, cd.date, cd.population, ISNULL(cv.new_vaccinations,0) as new_vaccinations
, SUM(CAST(cv.new_vaccinations as bigint)) OVER (partition by cd.location ORDER BY cd.location, cd.date) as Rolling_Vacc_Count
FROM CovidVaccinations cv 
JOIN CovidDeaths cd 
	ON cd.location = cv.location 
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL

)
SELECT * , RollingVaccCount/Population*100
FROM PopvsVacc



--------------------------
--  TEMP TABLE

DROP TABLE IF EXISTS #PercentPopVacc
CREATE TABLE #PercentPopVacc
(
Continent	nvarchar(255),
Location	nvarchar(255),
Date		datetime,
Population	numeric,
new_vaccinations	numeric,
rolling_vacc_count	numeric
)

INSERT INTO #PercentPopVacc
SELECT cd.continent, cd.location, cd.date, cd.population, ISNULL(cv.new_vaccinations,0) as new_vaccinations
, SUM(CAST(cv.new_vaccinations as bigint)) OVER (partition by cd.location ORDER BY cd.location, cd.date) as Rolling_Vacc_Count
FROM CovidVaccinations cv 
JOIN CovidDeaths cd 
	ON cd.location = cv.location 
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL

SELECT * , rolling_vacc_count/Population*100
FROM #PercentPopVacc


----
-- Creating View to store data for later visualization

CREATE VIEW PercentPopulationVaccinated as 
SELECT cd.continent, cd.location, cd.date, cd.population, ISNULL(cv.new_vaccinations,0) as new_vaccinations
, SUM(CAST(cv.new_vaccinations as bigint)) OVER (partition by cd.location ORDER BY cd.location, cd.date) as Rolling_Vacc_Count
FROM CovidVaccinations cv 
JOIN CovidDeaths cd 
	ON cd.location = cv.location 
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
--order by 2,3
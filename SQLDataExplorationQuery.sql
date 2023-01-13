--Group by seems to be the most tricky for me

SELECT *
FROM SQLDataExploration.dbo.CovidDeaths
WHERE continent is not null /* For some reason, it counts continents as one entity, so we have to flush those out */
ORDER BY 3,4

-- Find Important Data
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM SQLDataExploration.dbo.CovidDeaths
ORDER BY 1, 2

-- Correlation between Total Cases vs Total Deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Cases_vs_Deaths_Percentage
FROM SQLDataExploration.dbo.CovidDeaths
WHERE location like '%Canada%' /* Looking for a specific country */
ORDER BY 1, 2

--Correlation between Total Cases vs Population
SELECT location, date, population, total_cases, (total_cases/population)*100 AS Cases_vs_Population_Percentage
FROM SQLDataExploration.dbo.CovidDeaths
WHERE location like '%Canada%' /* Looking for a specific country */
ORDER BY 1, 2

--Highest Infection Rate (How many people were infected by Covid)
SELECT location, population, MAX(total_cases) AS Infection_Count, MAX((total_cases/population))*100 AS Covid_Infection_Rate_Percentage
FROM SQLDataExploration.dbo.CovidDeaths
GROUP BY location, population --Why do we need to group by (Need to group by when dealing with max min avg etc)
ORDER BY Covid_Infection_Rate_Percentage DESC

--Country with highest Death count per population
SELECT location, MAX(cast(total_deaths AS BIGINT)) AS Total_Death_Count
FROM SQLDataExploration.dbo.CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY Total_Death_Count DESC


/*Looking at Continents */

--Continents with highest Death count
SELECT location, MAX(cast(total_deaths AS BIGINT)) AS Total_Death_Count
FROM SQLDataExploration.dbo.CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY Total_Death_Count DESC

--Cases/deaths/DeathPercentage per day for the world
SELECT date, SUM(new_cases) AS Total_Cases, SUM(cast(new_deaths AS INT)) AS Total_Deaths, SUM(cast(new_deaths AS INT))/SUM(new_cases) *100 AS DeathsPercentage
FROM SQLDataExploration.dbo.CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1, 2

--Total cases and total deaths
SELECT SUM(new_cases) AS Total_Cases, SUM(cast(new_deaths AS INT)) AS Total_Deaths, SUM(cast(new_deaths AS INT))/SUM(new_cases) *100 AS DeathsPercentage
FROM SQLDataExploration.dbo.CovidDeaths
WHERE continent is not null
ORDER BY 1, 2

--Looking at Covid Vaccinations

--Join(combine) both Covid Deaths and Covid Vaccinations

--USE CTE. Using a CTE allows us to make calculations on a column that we created. If we did not have the CTE, we would not be able to do calc on the newly created column
WITH PopvsVac (Continent, location, date, population, new_vacinations, Concurrent_People_Vaccinated)
AS
(
--Total population vs vaccination (each individual country)
/* At the end, Concurrent_People_Vaccinated will give the total people vaccinated for each individial country. Note: You cannot use a table you create to do calcuations*/
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS BIGINT)) 
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Concurrent_People_Vaccinated
FROM SQLDataExploration.dbo.CovidDeaths dea
JOIN SQLDataExploration.dbo.CovidVaccinations vac
	ON dea.location=vac.location AND dea.date=vac.date
WHERE dea.continent IS NOT NULL 
)
SELECT *, (Concurrent_People_Vaccinated/population) *100
FROM PopvsVac

--Another way to use Concurrent_People_Vaccinated (Temp table)
DROP TABLE  IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(Continent nvarchar(255),
 location nvarchar(255), 
 date datetime,
 population numeric,
 new_vaccinations numeric,
 Concurrent_People_Vaccinated numeric
 )


INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS BIGINT)) 
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Concurrent_People_Vaccinated
FROM SQLDataExploration.dbo.CovidDeaths dea
JOIN SQLDataExploration.dbo.CovidVaccinations vac
	ON dea.location=vac.location AND dea.date=vac.date
WHERE dea.continent IS NOT NULL 

SELECT *, (Concurrent_People_Vaccinated/population) *100
FROM #PercentPopulationVaccinated

--Create view to store later
CREATE VIEW RealPercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS BIGINT)) 
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Concurrent_People_Vaccinated
FROM SQLDataExploration.dbo.CovidDeaths dea
JOIN SQLDataExploration.dbo.CovidVaccinations vac
	ON dea.location=vac.location AND dea.date=vac.date
WHERE dea.continent IS NOT NULL 

/*The difference betweeen group by and partition by is that group by will roll up all the same values and have 1 single output column(look above) whereas partition by wont roll them up and you
will have a column of the same value spanning the entire column. Good to know particular values.*/


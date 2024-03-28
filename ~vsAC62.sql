----QUERY ALL DATA FROM coronaDeaths Table

SELECT *
FROM coronaPortifolioProject..coronaDeaths

----- QUERY ALL from covidVaccinations Table
SELECT *
FROM coronaPortifolioProject..covidVaccinations

---SELECTING DATA WE SHALL BE USING
SELECT continent,location,date,total_cases,new_cases,total_deaths,population
FROM coronaPortifolioProject..coronaDeaths
--WHERE continent IS NOT NULL
ORDER BY 2,3

---TotalDeaths vs Population
--->>>Shows percentage that died of covid
SELECT location,date,total_deaths,population,(CAST(total_deaths AS FLOAT)/CAST(population AS FLOAT))*100 as Death_rate_per_population
FROM coronaPortifolioProject..coronaDeaths
WHERE continent IS NOT NULL
AND location like 'kenya'
ORDER BY 1,2

----Population vs Total Cases
---Shows population that got COVIID
SELECT location,date,total_deaths,population,(CAST(total_cases AS FLOAT)/CAST(population AS FLOAT))*100 as contraction_rate_per_population
FROM coronaPortifolioProject..coronaDeaths
WHERE continent IS NOT NULL
AND location like 'kenya'
ORDER BY 1,2


---Total Deaths Vs Total CASEs in Percent
---->>>> REALISED THAT ON CASTING TO 'INT' RETURNED ZEROS ALLOVER

SELECT continent,location,date,total_cases,total_deaths, (CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT)) * 100 AS death_rate_percentage
FROM coronaPortifolioProject..coronaDeaths
--WHERE continent IS NOT NULL
WHERE location LIKE 'KENYA'
ORDER BY 2,3

---GET MAX TOTAL DEATHS AND CASES

SELECT location,MAX(CAST(total_cases AS INT)) AS HighestCases,MAX(CAST(total_deaths AS INT)) as HighestDeaths
FROM coronaPortifolioProject..coronaDeaths
WHERE continent IS  NOT NULL
GROUP BY location
ORDER BY location

/*
SELECT location,date,MAX(CONVERT(INT,new_cases))
FROM coronaDeaths
WHERE continent IS NOT NULL
AND location like 'kenya'
GROUP BY location,date 
ORDER BY location
*/


---Countries with high infection rate
SELECT location,population,MAX(CAST(total_cases AS INT)) AS highestTotalCase,MAX(CAST(total_cases AS INT)/population) AS infection_rate
FROM coronaPortifolioProject..coronaDeaths
GROUP BY location,population
ORDER BY infection_rate DESC

-----Countries with Highet Death_rates
SELECT location,MAX(CAST(total_deaths AS INT)) as TotalDeathCount
FROM coronaPortifolioProject..coronaDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


---Continents with High Death Rates
SELECT location,MAX(CAST(total_deaths AS INT)) as TotalDeathsCount
FROM coronaPortifolioProject..coronaDeaths
WHERE continent IS  NULL
GROUP BY location
ORDER BY TotalDeathsCount DESC

--GLOBAL Numbers
SELECT 
    SUM(new_cases) AS TotalCases,
    SUM(new_deaths) AS TotalDeaths,
    (CASE 
        WHEN SUM(new_cases) = 0 THEN NULL
        ELSE (CAST(SUM(new_deaths) AS FLOAT) / CAST(SUM(new_cases) AS FLOAT)) * 100
    END) AS deathRates
FROM coronaPortifolioProject..coronaDeaths
--GROUP BY date
--HAVING  (CASE 
--        WHEN SUM(new_cases) = 0 THEN NULL
--        ELSE (CAST(SUM(new_deaths) AS FLOAT) / CAST(SUM(new_cases) AS FLOAT)) * 100
--    END) IS NOT NULL
--ORDER BY  (CASE 
--        WHEN SUM(new_cases) = 0 THEN NULL
--        ELSE (CAST(SUM(new_deaths) AS FLOAT) / CAST(SUM(new_cases) AS FLOAT)) * 100
--    END) DESC;



-----
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingVaccinationCount
FROM coronaPortifolioProject..coronaDeaths dea
JOIN coronaPortifolioProject..covidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

---- USING CTES
WITH PopvsVcccination(continent,location,date,population,new_vaccinations,RollingVaccinationCount)
AS
(
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingVaccinationCount
FROM coronaPortifolioProject..coronaDeaths dea
JOIN coronaPortifolioProject..covidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *,(RollingVaccinationCount/population)*100 vaccination_rate
FROM PopvsVcccination
ORDER BY vaccination_rate DESC


-----Using TEMP TABLES INSTEAD

DROP TABLE IF EXISTS #populationVaccinatedPercentage
CREATE TABLE #populationVaccinatedPercentage(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population int,
new_vaccinations INT,
RollingVaccinationCount int
)

---INSERT INTO THE tempTable

INSERT INTO #populationVaccinatedPercentage(continent,location,date,population,new_vaccinations,RollingVaccinationCount)
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingVaccinationCount
FROM coronaPortifolioProject..coronaDeaths dea
JOIN coronaPortifolioProject..covidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *,(RollingVaccinationCount/population)*100
FROM #populationVaccinatedPercentage

---CREATING VIEWS FOR VISUALIZATION
Create View CovidAffectedPopulation AS
SELECT 
    SUM(new_cases) AS TotalCases,
    SUM(new_deaths) AS TotalDeaths,
    (CASE 
        WHEN SUM(new_cases) = 0 THEN NULL
        ELSE (CAST(SUM(new_deaths) AS FLOAT) / CAST(SUM(new_cases) AS FLOAT)) * 100
    END) AS deathRates
FROM coronaPortifolioProject..coronaDeaths


--ORDER BY 1,2)

SELECT *
FROM CovidAffectedPopulation
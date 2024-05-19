SELECT *
FROM CovidDeaths
where continent is not null 
ORDER BY 3,4

SELECT *
FROM [CovidVaccinations ]
ORDER BY 3,4

-- selecting the data we want to look into

SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY 1,2

-- looking at total cases vs total deaths
-- note that the * 1.0 is necessary as the datatype is int and not float

--Likelihood of death in contracting COVID in countries
SELECT location, date, total_cases, total_deaths, (total_deaths * 1.0 /total_cases)*100 AS DeathsPercentage
FROM CovidDeaths
WHERE location like '%Singapore%' and continent is not null
ORDER BY 1,2

SELECT location, date, total_cases, total_deaths, (total_deaths * 1.0 /total_cases)*100 AS DeathsPercentage
FROM CovidDeaths
WHERE location like '%Asia%' 
ORDER BY 1,2

-- Looking at countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases * 1.0/population))*100 AS PercentPopulationInfected 
FROM CovidDeaths
GROUP BY location, population 
ORDER BY PercentPopulationInfected desc

-- Looking at countries with highest death count per population 
-- required to put "where continent is not null" to remove those data which had a continent as their location 
SELECT location, population, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths 
WHERE continent is not null 
GROUP BY location, population 
ORDER BY TotalDeathCount desc

-- Breaking things down by continent 

-- Continents with the highest death count per population 
SELECT continent, MAX(population) AS ContinentPopulation, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths 
WHERE continent is not null 
GROUP BY continent
ORDER BY TotalDeathCount desc

-- Global Numbers: 
-- I struggled here a lot because the division resulted in 0 (Math wasn't mathing). Found out by asking in Reddit later, that this is because I did not convert total_cases and total_deaths to decimals/numeric. 
-- "You are dividing integers (whole numbers), so by default, your answers will also be in integers. You're looking for fractions (decimals), so you need to divide by a decimal."

SELECT date, total_cases, total_deaths, ((cast(total_deaths as decimal)/(cast(total_cases as decimal)) * 100)) AS 'Death_Percentage'
FROM CovidDeaths
GROUP BY date, total_cases, total_deaths
ORDER BY date
-- In Singapore
SELECT date, location, total_cases, total_deaths, ((cast(total_deaths as decimal)/(cast(total_cases as decimal)) * 100)) AS 'Death_Percentage'
FROM CovidDeaths
WHERE location LIKE '%Singapore%'
GROUP BY date, location, total_cases, total_deaths
ORDER BY date

-- Looking at Total Population VS Vaccinations 

SELECT CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population, CovidVaccinations.new_vaccinations, SUM(CovidVaccinations.new_vaccinations) OVER (Partition by CovidDeaths.location Order by CovidDeaths.location, CovidDeaths.date) as RollingPeopleVaccinated
FROM CovidDeaths
JOIN [CovidVaccinations ]
	ON CovidDeaths.location = [CovidVaccinations ]. location 
	and CovidDeaths.date = CovidVaccinations.date 
WHERE CovidDeaths.continent is not null and CovidDeaths.location LIKE '%Singapore%'
ORDER BY 2, 3

-- Using CTE to include RollingPeopleVaccinated/population * 100

WITH PopsVac (continent, location, date, population, new_vaccination, RollingPeopleVaccinated)
AS
(SELECT CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population, cast(CovidVaccinations.new_vaccinations as decimal), SUM(cast(CovidVaccinations.new_vaccinations as decimal)) OVER (Partition by CovidDeaths.location Order by CovidDeaths.location, CovidDeaths.date) as RollingPeopleVaccinated
FROM CovidDeaths
JOIN [CovidVaccinations ]
	ON CovidDeaths.location = [CovidVaccinations ]. location 
	and CovidDeaths.date = CovidVaccinations.date 
WHERE CovidDeaths.continent is not null and CovidDeaths.location LIKE '%Singapore%')
SELECT *, cast(RollingPeopleVaccinated as decimal)/cast(population as decimal) * 100 as VaccinationPercentage
FROM PopsVac

-- Using TempTables to include RollingPeopleVaccinated/population * 100
DROP TABLE IF EXISTS #temp_VaccinationPercentage
CREATE TABLE #temp_VaccinationPercentage (
continent varchar(50), location varchar(50), date varchar(50), population numeric, new_vaccination numeric, RollingPeopleVaccinated numeric)

SELECT *
FROM #temp_VaccinationPercentage

INSERT INTO #temp_VaccinationPercentage
SELECT CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population, CovidVaccinations.new_vaccinations, SUM(CovidVaccinations.new_vaccinations) OVER (Partition by CovidDeaths.location Order by CovidDeaths.location, CovidDeaths.date) as RollingPeopleVaccinated
FROM CovidDeaths
JOIN [CovidVaccinations ]
	ON CovidDeaths.location = [CovidVaccinations ]. location 
	and CovidDeaths.date = CovidVaccinations.date 
WHERE CovidDeaths.continent is not null and CovidDeaths.location LIKE '%Singapore%'
ORDER BY 2, 3

SELECT *, RollingPeopleVaccinated/population* 100 AS VaccinationPercentage
FROM #temp_VaccinationPercentage

-- Creating View to store data later for visualiation

-- Covid Percentage in Singapore
CREATE VIEW CovidVaccinationPercentage AS
SELECT CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population, CovidVaccinations.new_vaccinations, SUM(CovidVaccinations.new_vaccinations) OVER (Partition by CovidDeaths.location Order by CovidDeaths.location, CovidDeaths.date) as RollingPeopleVaccinated
FROM CovidDeaths
JOIN [CovidVaccinations ]
	ON CovidDeaths.location = [CovidVaccinations ]. location 
	and CovidDeaths.date = CovidVaccinations.date 
WHERE CovidDeaths.continent is not null and CovidDeaths.location LIKE '%Singapore%'
--order by 2, 3

-- Infection Rate
CREATE VIEW GlobalInfectionRate AS
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases * 1.0/population))*100 AS PercentPopulationInfected 
FROM CovidDeaths
GROUP BY location, population 
ORDER BY PercentPopulationInfected desc

--Likelihood of death in contracting COVID in countries
CREATE VIEW DeathLikelihood AS
SELECT location, date, total_cases, total_deaths, (total_deaths * 1.0 /total_cases)*100 AS DeathsPercentage
FROM CovidDeaths
WHERE location like '%Singapore%' and continent is not null
--ORDER BY 1,2

-- Continents with the highest death count per population 
CREATE VIEW ContinentDeaths AS
SELECT continent, MAX(population) AS ContinentPopulation, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths 
WHERE continent is not null 
GROUP BY continent
ORDER BY TotalDeathCount desc

-- Countries death counts
Create View CountriesDeath as 
SELECT location, population, MAX(total_deaths) AS TotalDeathCount, max(cast(total_deaths as decimal))/population * 100 AS DeathPercentage
FROM CovidDeaths 
WHERE continent is not null 
GROUP BY location, population 
ORDER BY TotalDeathCount desc

-- Death Percentage in the world
Create View GlobalDeathPercentage as
SELECT date, total_cases, total_deaths, ((cast(total_deaths as decimal)/(cast(total_cases as decimal)) * 100)) AS 'Death_Percentage'
FROM CovidDeaths
GROUP BY date, total_cases, total_deaths
ORDER BY date

-- Death Percentage In Singapore
Create View SingaporeDeathPercentage as 
SELECT date, location, total_cases, total_deaths, ((cast(total_deaths as decimal)/(cast(total_cases as decimal)) * 100)) AS 'Death_Percentage'
FROM CovidDeaths
WHERE location LIKE '%Singapore%'
GROUP BY date, location, total_cases, total_deaths
ORDER BY date



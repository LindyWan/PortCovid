Select *
From PortfolioProject..CovidVaccinations
Where Continent is not null
order by 3,4

Select *
From PortfolioProject..CovidDeaths
Where Continent is not null
order by 3,4

Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by 1,2

-- Total cases vs Total Deaths
-- Likelihood of dying if you contract covid 

Select location, date, total_cases, total_deaths, 
Cast ((total_deaths/total_cases)*100 as NUMERIC (18,2)) as Death_Percentage
From PortfolioProject..CovidDeaths
where location like '%Brazil%'
order by 1,2


--Total cases vs Population
--What porcentage of the popuplation got Covid

Select location, date, population, total_cases,
Cast ((total_cases/population)*100 AS NUMERIC(18,2)) as Population_Percentage_got_Covid
From PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

-- Percentage total of population infected

Select Location, Population, MAX(total_cases) as TotalcasesBrazil,
Cast (MAX((total_cases/Population))*100 AS NUMERIC(18,2)) as Percent_Brazilians_Infected
From PortfolioProject..CovidDeaths
where location like '%Brazil%'
group by location, population


-- Most infected Country per Population

Select Location, Population, MAX(total_cases) as HighestInfected,
Cast (MAX((total_cases/Population))*100 AS NUMERIC(18,2)) as Highest_Population_Infected
From PortfolioProject..CovidDeaths
Where Continent is not null
group by location, population
order by Highest_Population_Infected desc

-- Contries with the Highest Death Count per Population

Select Location, MAX(cast(total_deaths as int)) as DeathsCount
From PortfolioProject..CovidDeaths
Where Continent is not null
group by Location
order by DeathsCount desc


-- BREAKING THINGS DOWN BY CONTINENT
-- Infections by Continent

Select continent, MAX(cast(total_deaths as int)) as DeathsCount
From PortfolioProject..CovidDeaths
Where Continent is not null
group by continent
order by DeathsCount desc

-- Global Numbers

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
Cast (SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as NUMERIC (18,2)) as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null 
order by 1,2

-- Global Numbers Fully Vaccinated

Select dea.continent, dea.location, dea.date, dea.population, vac.people_fully_vaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

-- Percentage of Population Fully Vaccinated

Select dea.Location, dea.Population, MAX(vac.people_fully_vaccinated) as HighestFully, 
Cast(MAX((vac.people_fully_vaccinated/dea.Population))*100 as NUMERIC(18,2)) as Percent_Population_FullyVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
group by dea.location, dea.population
order by Percent_Population_FullyVaccinated desc

-- Brazilians Fully Vaccinated

Select dea.Location, dea.Population, MAX(vac.people_fully_vaccinated) as HighestFully, 
Cast(MAX((vac.people_fully_vaccinated/dea.Population))*100 as NUMERIC(18,2)) as Perc_Brazilians_FullyVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	where dea.location like '%Brazil%'
group by dea.location, dea.population

------------------------------------------------People fully vaccinated in another way

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.people_fully_vaccinated, 
SUM(CONVERT(bigint, vac.people_fully_vaccinated)) OVER 
(Partition by dea.location Order by dea.location, CONVERT(date, dea.date)) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
On dea.location = vac.location 
and dea.date = vac.date
Where dea.continent is not null
Order by 2, 3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, people_fully_vaccinateds, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.people_fully_vaccinated, 
SUM(CONVERT(bigint, vac.people_fully_vaccinated)) OVER 
(Partition by dea.location Order by dea.location, CONVERT(date, dea.date)) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
people_fully_vaccinated numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.people_fully_vaccinated, 
SUM(CONVERT(bigint, vac.people_fully_vaccinated)) OVER 
(Partition by dea.location Order by dea.location, CONVERT(date, dea.date)) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPeopleVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.people_fully_vaccinated
, SUM(CONVERT(int,vac.people_fully_vaccinated)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 



Select *
from PercentPeopleVaccinated












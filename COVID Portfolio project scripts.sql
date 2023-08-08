/*

Covid Data Observation from 2019 to tilldate

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/


select * 
from PortfolioProject.dbo.CovidDeaths with (nolock)
where continent is not null
order by 3,4


-- Select Data that are going to be starting with

select location, date, new_cases, total_deaths, population
from PortfolioProject.dbo.CovidDeaths with (nolock)
where continent is not null
order by 1,2


-- Total Cases vs Total Deaths
--Shows the percentage of deaths as per total cases 

select location, date, total_cases,total_deaths, (total_deaths/cast(total_cases as float))*100 as DeathPercentage
from PortfolioProject.dbo.CovidDeaths with (nolock)
where continent is not null
order by 1,2 


--Shows likelihood of dying if you contract covid in your country 

select location, date, total_cases,total_deaths, (total_deaths/cast(total_cases as float))*100 as DeathPercentage
from PortfolioProject.dbo.CovidDeaths with (nolock)
where continent is not null
and location like '%India'
order by 1,2 


-- Total Cases vs Population

select location, date, total_cases, population, (cast(total_cases as float)/population)*100 as PercentPopulationInfected
from PortfolioProject.dbo.CovidDeaths with (nolock)
where continent is not null
--and location like '%India'
order by 1,2 


-- Shows what percentage of population infected with Covid in your country

select location, date, total_cases, population, (cast(total_cases as float)/population)*100 as PercentPopulationInfected
from PortfolioProject.dbo.CovidDeaths with (nolock)
where continent is not null
and location like '%India'
order by 1,2 


-- Countries with Highest Infection Rate compared to Population

select location,population, max(total_cases) as HighestInfectionCount, max(cast(total_cases as float)/population)*100 as PercentPopulationInfected
from PortfolioProject.dbo.CovidDeaths with (nolock)
where continent is not null
--and location like '%India'
group by location,population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

select location,population, max(total_deaths) as HighestDeathCount
from PortfolioProject.dbo.CovidDeaths with (nolock)
where continent is not null
--and location like '%India'
group by location,population
order by HighestDeathCount desc


-- Countries with Highest Death Percentage as per Population

select location,population, max(total_deaths) as HighestDeathCount, max(total_deaths/population)*100 as PercentPopulationDeath
from PortfolioProject.dbo.CovidDeaths with (nolock)
where continent is not null
--and location like '%India'
group by location,population
order by PercentPopulationDeath desc


-- BREAKING THINGS DOWN BY CONTINENT

-- Continents with Highest Death Count 

select continent, max(total_deaths) as HighestDeathCount
from PortfolioProject.dbo.CovidDeaths with (nolock)
where continent is not null
--and location like '%India'
group by continent
order by HighestDeathCount desc



-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths with (nolock)
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

with v_coins (continent, location, date, population, notnull_new_vaccinations)
as
(
Select dea.continent, dea.location, dea.date, dea.population, convert(float, isnull(vac.new_vaccinations,0)) as notnull_new_vaccinations
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
select  continent, location, date, population, notnull_new_vaccinations
, sum(notnull_new_vaccinations) over(partition by location order by location,date) as RollingPeopleVaccinated
from v_coins
order by 2,3

------------------------(OR)

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as float)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query to get percentageRollingPeopleVaccinated

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100 
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100  as percentageRollingPeopleVaccinated
From PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
( 
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100 as percentageRollingPeopleVaccinated
From #PercentPopulationVaccinated



-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 


SELECT *
FROM PercentPopulationVaccinated


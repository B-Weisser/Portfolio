/* 
PortFolio Project Covid
Data Source https://ourworldindata.org/covid-deaths
Split into two tables of Covid Deaths (covid_death) and Covid Vaccinations (covid_vax)
*/

select * From covid_vax;
select * From covid_deaths;

-- look at covid_deaths table to see locations that are not countries
SELECT location, continent,max(abs(total_deaths)) as all_deaths      -- abs() because columns were imported as chars due to Nulls
FROM covid_deaths 
group by location 
order by all_deaths desc;

-- same table but non-countries removed
-- AlL ABSOLUTE COVID DEATHS BY COUNTRY
SELECT location, continent,max(abs(total_deaths)) as all_deaths 
FROM covid_deaths 
where continent != "" 
group by location 
order by all_deaths desc;

select location,date, total_cases,new_cases,total_deaths,population 
from covid_deaths
order by 1,2;


-- TOTAL CASES VS. TOTAL DEATHS
-- by country

select location,date, total_cases,total_deaths,round((total_deaths/total_cases)*100,2) as death_ratio
from covid_deaths
where continent != "" 
order by 1,2;


-- OVERALL DEATH RATE PER COUNTRY
 SELECT 
    location,max(abs(total_deaths)),max(abs(total_cases)),
    round((max(abs(total_deaths))/max(abs(total_cases)))*100,2) as max_death_ratio
FROM covid_deaths
where continent != "" 
GROUP BY location;

-- Since I am a German and American citizen, I'll look at these too countrys

SELECT 
    location,max(abs(total_deaths)),max(abs(total_cases)),
    round((max(abs(total_deaths))/max(abs(total_cases)))*100,2) as average_death_ratio
FROM covid_deaths where location="Germany" or location="United States" 
GROUP BY location;

-- PERCENTAGE OF POPULATION WHO CONTRACTED COVID
select location, max(abs(total_cases)) as cases,population,max(total_cases/population*100) as covid_rate
from covid_deaths
GROUP BY location;

-- percentage of population who contracted covid in Germany & US

select location, max(abs(total_cases)) as cases,population,max(total_cases/population*100) as covid_rate
from covid_deaths where location="Germany" or location="United States" 
GROUP BY location;

-- RANKING COUNTRIES WITH HIGHEST INFECTION RATES COMPARED TO POPULATION
select RANK () OVER ( 
		ORDER BY round(max(total_cases/population*100),0) DESC ) rank_no, location,round(max(total_cases/population*100),0) as covid_rate_perc_pop, max(abs(total_cases)) as cases,population
from covid_deaths where continent != ""
GROUP BY location
order by covid_rate_perc_pop desc;

-- finding US & Germany ranks

select rank_tab.rank_no, rank_tab.location, rank_tab.covid_rate_perc_pop, rank_tab.cases, rank_tab.population from
(select RANK () OVER ( 
		ORDER BY round(max(total_cases/population*100),0) DESC ) rank_no, location,round(max(total_cases/population*100),0) as covid_rate_perc_pop, max(abs(total_cases)) as cases,population
from covid_deaths where continent != ""
GROUP BY location
order by covid_rate_perc_pop desc) rank_tab
where location="Germany" or location="United States" 
GROUP BY location;

-- COVID ABSOLUTE DEATH COUNT PER POPULATION IN THE WORLD AND PER CONTINENT
-- Covid death count per population
-- Looking at continents

select location,continent,max(total_deaths/population*100) as covid_death_perc_pop, max(abs(total_deaths)) as deaths,population
from covid_deaths where continent = "" and location not like '%income'
GROUP BY location;

-- RANKING COUNTRIES WITH HIGHEST CASUALTY RATES COMPARED TO POPULATION

select RANK () OVER ( 
		ORDER BY max(total_deaths/population*100) DESC ) rank_no, location,max(total_deaths/population*100) as covid_death_perc_pop, max(abs(total_deaths)) as deaths,population
from covid_deaths where continent != ""
GROUP BY location
order by covid_death_perc_pop desc;

-- finding US & Germany ranks

select rank_tab.rank_no, rank_tab.location, rank_tab.covid_death_perc_pop, rank_tab.deaths, rank_tab.population from
(select RANK () OVER ( 
		ORDER BY max(total_deaths/population*100) DESC ) rank_no, location,max(total_deaths/population*100) as covid_death_perc_pop, max(abs(total_deaths)) as deaths,population
from covid_deaths where continent != ""
GROUP BY location
order by covid_death_perc_pop desc) rank_tab
where location="Germany" or location="United States" 
GROUP BY location;

-- LET'S LOOK AT DEATH RATES AND INCOME LEVELS

select location,continent,max(total_deaths/population*100) as covid_death_perc_pop, max(abs(total_deaths)) as deaths,population
from covid_deaths where location like '%income'
GROUP BY location;

-- TOTAL DEATH COUNT BY COUNTRY
select location,max(abs(total_deaths)) as total_death_count
from covid_deaths where continent = "" and location not like '%income' and location !='World'
GROUP BY location;

-- WORLD WIDE DEATH COUNT SUMMED UP OVER COUNTRIES 
select sum(sub.total_death_count) as world_wide_death_count 
from 
	(
    select max(abs(total_deaths)) as total_death_count
	from covid_deaths 
    where continent = "" and location not like '%income' and location !='World' and location !='European Union'
	GROUP BY location
    ) sub;

-- GLOBAL NUMBERS 
-- for the sake of this project, we'll only look at the locations that are countries and not grab it directly out of the World-location
select date, sum(population) as population, sum(total_cases) as total_cases, sum(new_cases) as new_cases, sum(total_deaths) as total_deaths, sum(new_deaths) as new_deaths, sum(total_deaths)/sum(total_cases)*100 as global_death_rate
from covid_deaths where continent = ""
group by date
order by date asc;

-- COVID VACCINATION TABLE

select * from covid_vax;

-- AT WHAT DATE WERE THE FIRST VACCINES ADMINISTERED IN EACH COUNTRY

select location, min(date), new_vaccinations 
from covid_vax
where new_vaccinations >0 and continent!=''
group by location
order by date,location;

-- looking at Total Vaxination vs. Population
-- DEVELOPMENT OF VACCINATION RATE IN POPULATION PER COUNTRY

select death.location,death.continent, death.date,death.population, vax.new_vaccinations , SUM(vax.new_vaccinations) OVER (Partition by death.Location Order by death.location, death.Date) as RollingPeopleVaccinated
from covid_deaths death
join covid_vax vax
on death.location=vax.location and death.date=vax.date
where death.continent!='' and vax.new_vaccinations>0
order by 1,3;

-- USING CTE TO PERFORM CALCULATION ON PARTITION BY 
-- VACCINATED PER MILLION POPULATION

With PopvsVac (
continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as (
select death.location,death.continent, death.date,death.population, vax.new_vaccinations , SUM(vax.new_vaccinations) OVER (Partition by death.Location Order by death.location, death.Date) as RollingPeopleVaccinated
from covid_deaths death
join covid_vax vax
on death.location=vax.location and death.date=vax.date
where death.continent!='' and vax.new_vaccinations>0
order by 1,3)
select *, round(RollingPeopleVaccinated/Population*1000000) as Vax_per_million from PopvsVac;


-- USE NEW TABLE FOR QUERY

DROP Table if exists PercentPopulationVaccinated;
Create Table PercentPopulationVaccinated
(
Continent char(255),
Location char(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
);

Insert into PercentPopulationVaccinated
select death.continent, death.location, death.date,death.population, abs(vax.new_vaccinations) , SUM(vax.new_vaccinations) OVER (Partition by death.Location Order by death.location, death.Date) as RollingPeopleVaccinated
from covid_deaths death
join covid_vax vax
on death.location=vax.location and death.date=vax.date
where death.continent!='' and vax.new_vaccinations>0;

-- DEVELOPMENT OF PEOPLE VACCINATED PER DATE AND COUNTRY
Select *, (RollingPeopleVaccinated/Population)*100 as percent_vaccinated
From PercentPopulationVaccinated;

-- CREATE VIEW

create view Percent_Population_Vaccinated as 
select death.continent, death.location, death.date,death.population, abs(vax.new_vaccinations) , SUM(vax.new_vaccinations) OVER (Partition by death.Location Order by death.location, death.Date) as RollingPeopleVaccinated
from covid_deaths death
join covid_vax vax
on death.location=vax.location and death.date=vax.date
where death.continent!='' and vax.new_vaccinations>0;


-- TOTAL NUMBER OF PEOPLE VACCINATED PER COUNTRY
Select Location,Population, max((RollingPeopleVaccinated/Population)*100) as total_percent_vaccinated
From PercentPopulationVaccinated
group by location;


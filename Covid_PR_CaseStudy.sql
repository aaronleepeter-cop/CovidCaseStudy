/*
Covid 19 Data Exploration (PostgreSQL version)

Skills used: Joins, CTE's, Temp Tables, Window Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT *
FROM "CovidDeaths"
WHERE continent IS NOT NULL
ORDER BY 3, 4;


-- Select Data that we are going to be starting with

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM "CovidDeaths"
WHERE continent IS NOT NULL
ORDER BY 1, 2;


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths,
       (total_deaths / total_cases) * 100 AS death_percentage
FROM "CovidDeaths"
WHERE location LIKE '%states%'
  AND continent IS NOT NULL
ORDER BY 1, 2;


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

SELECT location, date, population, total_cases,
       (total_cases / population) * 100 AS percent_population_infected
FROM "CovidDeaths"
--WHERE location LIKE '%states%'
ORDER BY 1, 2;


-- Countries with Highest Infection Rate compared to Population

SELECT location, population,
       MAX(total_cases) AS highest_infection_count,
       MAX(total_cases / population) * 100 AS percent_population_infected
FROM "CovidDeaths"
--WHERE location LIKE '%states%'
GROUP BY location, population
ORDER BY percent_population_infected DESC;


-- Countries with Highest Death Count per Population

SELECT location, MAX(total_deaths::INTEGER) AS total_death_count
FROM "CovidDeaths"
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing continents with the highest death count per population

SELECT continent, MAX(total_deaths::INTEGER) AS total_death_count
FROM "CovidDeaths"
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC;


-- GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases,
       SUM(new_deaths::INTEGER) AS total_deaths,
       SUM(new_deaths::INTEGER) / SUM(new_cases) * 100 AS death_percentage
FROM "CovidDeaths"
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1, 2;


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has received at least one Covid Vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(vac.new_vaccinations::INTEGER) OVER (
           PARTITION BY dea.location ORDER BY dea.location, dea.date
       ) AS rolling_people_vaccinated
       --, (rolling_people_vaccinated / population) * 100
FROM "CovidDeaths" dea
JOIN "CovidVaccinations" vac
    ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;


-- Using CTE to perform Calculation on Partition By in previous query

WITH pop_vs_vac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS
(
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
           SUM(vac.new_vaccinations::INTEGER) OVER (
               PARTITION BY dea.location ORDER BY dea.location, dea.date
           ) AS rolling_people_vaccinated
           --, (rolling_people_vaccinated / population) * 100
    FROM "CovidDeaths" dea
    JOIN "CovidVaccinations" vac
        ON dea.location = vac.location
       AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
    --ORDER BY 2, 3
)
SELECT *, (rolling_people_vaccinated / population) * 100
FROM pop_vs_vac;


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS percent_population_vaccinated;

CREATE TEMP TABLE percent_population_vaccinated
(
    continent                 VARCHAR(255),
    location                  VARCHAR(255),
    date                      DATE,
    population                NUMERIC,
    new_vaccinations          NUMERIC,
    rolling_people_vaccinated NUMERIC
);

INSERT INTO percent_population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(vac.new_vaccinations::INTEGER) OVER (
           PARTITION BY dea.location ORDER BY dea.location, dea.date
       ) AS rolling_people_vaccinated
       --, (rolling_people_vaccinated / population) * 100
FROM "CovidDeaths" dea
JOIN "CovidVaccinations" vac
    ON dea.location = vac.location
   AND dea.date = vac.date;
--WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3

SELECT *, (rolling_people_vaccinated / population) * 100
FROM percent_population_vaccinated;


-- Creating View to store data for later visualizations

CREATE OR REPLACE VIEW percent_population_vaccinated_view AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(vac.new_vaccinations::INTEGER) OVER (
           PARTITION BY dea.location ORDER BY dea.location, dea.date
       ) AS rolling_people_vaccinated
       --, (rolling_people_vaccinated / population) * 100
FROM "CovidDeaths" dea
JOIN "CovidVaccinations" vac
    ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

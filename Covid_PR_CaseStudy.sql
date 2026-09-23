/*
Covid-19 Data Exploration (PostgreSQL)

Source tables: "CovidDeaths", "CovidVaccinations"

-- Quick look at the raw data we're working with
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM "CovidDeaths"
WHERE continent IS NOT NULL
ORDER BY location, date;


-- Case fatality rate for India: of confirmed cases, what share resulted in death
SELECT
    location,
    date,
    total_cases,
    total_deaths,
    ROUND((total_deaths::NUMERIC / NULLIF(total_cases, 0)) * 100, 2) AS death_percentage
FROM "CovidDeaths"
WHERE location ILIKE '%india%'
  AND continent IS NOT NULL
ORDER BY date;


-- Percent of each country's population infected, over time
SELECT
    location,
    date,
    population,
    total_cases,
    ROUND((total_cases::NUMERIC / NULLIF(population, 0)) * 100, 4) AS percent_population_infected
FROM "CovidDeaths"
WHERE continent IS NOT NULL
ORDER BY location, date;


-- Countries with the highest infection rate relative to population
SELECT
    location,
    population,
    MAX(total_cases) AS highest_infection_count,
    ROUND(MAX(total_cases::NUMERIC / NULLIF(population, 0)) * 100, 4) AS percent_population_infected
FROM "CovidDeaths"
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY percent_population_infected DESC;


-- Countries with the highest total death count
SELECT
    location,
    MAX(total_deaths::NUMERIC) AS total_death_count
FROM "CovidDeaths"
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;


-- Death count by continent
SELECT
    continent,
    MAX(total_deaths::NUMERIC) AS total_death_count
FROM "CovidDeaths"
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC;


-- Global totals and overall fatality rate (single row, so no ORDER BY needed)
SELECT
    SUM(new_cases) AS total_cases,
    SUM(new_deaths::NUMERIC) AS total_deaths,
    ROUND((SUM(new_deaths::NUMERIC) / NULLIF(SUM(new_cases), 0)) * 100, 2) AS death_percentage
FROM "CovidDeaths"
WHERE continent IS NOT NULL;


-- Rolling count of people vaccinated per country, day by day
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations::NUMERIC) OVER (
        PARTITION BY dea.location ORDER BY dea.date
    ) AS rolling_people_vaccinated
FROM "CovidDeaths" dea
JOIN "CovidVaccinations" vac
    ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;


-- Same rolling figure, turned into a percentage of population via a CTE
-- (window functions can't be referenced directly in the same SELECT's expressions)
WITH pop_vs_vac AS (
    SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(vac.new_vaccinations::NUMERIC) OVER (
            PARTITION BY dea.location ORDER BY dea.date
        ) AS rolling_people_vaccinated
    FROM "CovidDeaths" dea
    JOIN "CovidVaccinations" vac
        ON dea.location = vac.location
       AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT
    *,
    ROUND((rolling_people_vaccinated / NULLIF(population, 0)) * 100, 4) AS percent_population_vaccinated
FROM pop_vs_vac
ORDER BY location, date;


-- View for downstream visualization tools — keeps the rolling calculation
-- reusable without recomputing the window function each time
CREATE OR REPLACE VIEW percent_population_vaccinated_view AS
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations::NUMERIC) OVER (
        PARTITION BY dea.location ORDER BY dea.date
    ) AS rolling_people_vaccinated
FROM "CovidDeaths" dea
JOIN "CovidVaccinations" vac
    ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

COVID-19 Data Exploration (PostgreSQL)

This project loads COVID-19 case, death, and vaccination data into a PostgreSQL database, then uses SQL queries to explore infection rates, death percentages, and vaccination rollout trends across countries and over time.

Overview

Using publicly available COVID-19 data, this project answers questions like:

* What's the likelihood of dying if you contract COVID in a given country?
* What percentage of a country's population has been infected?
* Which countries had the highest infection and death rates relative to population?
* How did vaccination rollout progress over time, country by country?
* What do the global case and death totals look like?

Data Source
CovidDeaths.csv - daily case and death counts by country
CovidVaccinations.csv - daily vaccination and testing data by country

Both datasets are joined on location and date.

Skills Used
Joins — combining the deaths and vaccinations tables
CTEs (Common Table Expressions) - structuring multi-step calculations
Temp Tables - staging intermediate results
Window Functions - calculating rolling vaccination totals per country
Aggregate Functions - SUM, MAX, COUNT for summary statistics
Data Type Conversion - casting text/numeric columns for calculations
Views - saving reusable queries for downstream visualization

Tools Used
PostgreSQL - database engine
pgAdmin - GUI for writing and running queries
Excel - initial review and light cleaning of the raw CSV files (checking headers, spotting blanks/inconsistencies, verifying formats) before importing into PostgreSQL.

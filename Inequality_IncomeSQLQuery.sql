---create database
CREATE DATABASE Reduced_Inequality

--- use Database
--- use Reduced_Inequality
USE Reduced_Inequality

--- import dataset, Inequality_Income.csv

--- retrieve data
SELECT *
FROM Inequality_Income

--- Objectives number one
--- To quantify and compare continental trends in income inequality by calculating key
---descriptive statistics (e.g., mean, median, max, min and range) for each continent from 2010 to 2021,
---thereby identifying the regions with the most pronounced and persistent disparities
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS		--- view column names from the schema
WHERE TABLE_NAME = 'Inequality_Income';

--- unpivote, to convert imported excel wide data tolong data
SELECT Continent,
REPLACE(YearCol, 'Inequality_in_income_', '') AS Year,
Inequality
FROM Inequality_Income
UNPIVOT (
Inequality FOR YearCol IN (
[Inequality_in_income_2010],
[Inequality_in_income_2011],
[Inequality_in_income_2012],
[Inequality_in_income_2013],
[Inequality_in_income_2014],
[Inequality_in_income_2015],
[Inequality_in_income_2016],
[Inequality_in_income_2017],
[Inequality_in_income_2018],
[Inequality_in_income_2019],
[Inequality_in_income_2020],
[Inequality_in_income_2021]
)
) AS Unpvt;

---to calculate descriptive statistics (mean, median, max, min and range)
WITH Unpivoted AS (
SELECT Continent,
CAST(REPLACE(YearCol, 'Inequality_in_income_', '') AS INT) AS Year,
Inequality
FROM Inequality_Income
UNPIVOT (
Inequality FOR YearCol IN (
[Inequality_in_income_2010],
[Inequality_in_income_2011],
[Inequality_in_income_2012],
[Inequality_in_income_2013],
[Inequality_in_income_2014],
[Inequality_in_income_2015],
[Inequality_in_income_2016],
[Inequality_in_income_2017],
[Inequality_in_income_2018],
[Inequality_in_income_2019],
[Inequality_in_income_2020],
[Inequality_in_income_2021]
)
) AS Unpvt
),
WithMedian AS (
SELECT Continent,
Year,
Inequality,
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Inequality)		--- to calculates the 50th percentile, i.e. the median
OVER (PARTITION BY Continent, Year) AS Median_Inequality		--- over (partition by) divides the data into groups based on Continent and Year.
FROM Unpivoted
)
SELECT Continent,
Year,
ROUND(AVG(Inequality), 2) AS Avg_Inequality,
MIN(Inequality) AS Min_Inequality,
MAX(Inequality) AS Max_Inequality,
(MAX(Inequality) - MIN(Inequality)) AS Range_Inequality,
MAX(Median_Inequality) AS Median_Inequality 
FROM WithMedian
GROUP BY Continent, Year
ORDER BY Continent, Year;

--- objectives 2
--- To conduct a time-series analysis of income inequality to uncover significant trends,
--- breakpoints, and patterns of change (upward, downward, or stable) across different
--- continents over the 12-year period.
WITH Unpivoted AS (
SELECT Continent,
CAST(REPLACE(YearCol, 'Inequality_in_income_', '') AS INT) AS Year,
Inequality
FROM Inequality_Income
UNPIVOT (
Inequality FOR YearCol IN (
[Inequality_in_income_2010],
[Inequality_in_income_2011],
[Inequality_in_income_2012],
[Inequality_in_income_2013],
[Inequality_in_income_2014],
[Inequality_in_income_2015],
[Inequality_in_income_2016],
[Inequality_in_income_2017],
[Inequality_in_income_2018],
[Inequality_in_income_2019],
[Inequality_in_income_2020],
[Inequality_in_income_2021]
)
) AS Unpvt
)
SELECT Continent,
Year,
ROUND(AVG(Inequality), 2) AS Avg_Inequality,
ROUND(LAG(AVG(Inequality)) OVER (PARTITION BY Continent ORDER BY Year), 2) AS Prev_Year_Inequality,	---LAG() to compare each year’s average with the previous year.
ROUND(AVG(Inequality) - LAG(AVG(Inequality)) OVER (PARTITION BY Continent ORDER BY Year), 2) AS Yearly_Change,
CASE WHEN (AVG(Inequality) - LAG(AVG(Inequality)) OVER (PARTITION BY Continent ORDER BY Year)) > 0.5 
THEN 'Upward'
WHEN (AVG(Inequality) - LAG(AVG(Inequality)) OVER (PARTITION BY Continent ORDER BY Year)) < -0.5 
THEN 'Downward'
ELSE 'Stable'
END AS Trend
FROM Unpivoted
GROUP BY Continent, Year
ORDER BY Continent, Year;

---Objective 3
--- To investigate intra-continental disparities - by analyzing the variation in inequality levels
--- between countries within the same continent and exploring correlations with key socioeconomic factors such as development status and regional classification.
--- A. Intra-continental disparities by Human Development Groups
WITH Unpivoted AS (
SELECT Continent,
Human_Development_Groups,
CAST(REPLACE(YearCol, 'Inequality_in_income_', '') AS INT) AS Year,
Inequality
FROM Inequality_Income
UNPIVOT (
Inequality FOR YearCol IN (
[Inequality_in_income_2010],
[Inequality_in_income_2011],
[Inequality_in_income_2012],
[Inequality_in_income_2013],
[Inequality_in_income_2014],
[Inequality_in_income_2015],
[Inequality_in_income_2016],
[Inequality_in_income_2017],
[Inequality_in_income_2018],
[Inequality_in_income_2019],
[Inequality_in_income_2020],
[Inequality_in_income_2021]
)
) AS Unpvt
)
SELECT Continent,
Human_Development_Groups,
ROUND(AVG(Inequality), 2) AS Avg_Inequality,
MIN(Inequality) AS Min_Inequality,
MAX(Inequality) AS Max_Inequality,
ROUND(STDEV(Inequality), 2) AS StdDev_Inequality
FROM Unpivoted
GROUP BY Continent, Human_Development_Groups
ORDER BY Continent, Avg_Inequality DESC;

--- B. Disparities by UNDP Developing Regions
WITH Unpivoted AS (
SELECT UNDP_Developing_Regions,
CAST(REPLACE(YearCol, 'Inequality_in_income_', '') AS INT) AS Year,
Inequality
FROM Inequality_Income
UNPIVOT (
Inequality FOR YearCol IN (
[Inequality_in_income_2010],
[Inequality_in_income_2011],
[Inequality_in_income_2012],
[Inequality_in_income_2013],
[Inequality_in_income_2014],
[Inequality_in_income_2015],
[Inequality_in_income_2016],
[Inequality_in_income_2017],
[Inequality_in_income_2018],
[Inequality_in_income_2019],
[Inequality_in_income_2020],
[Inequality_in_income_2021]
)
) AS Unpvt
),
WithMedian AS (
SELECT UNDP_Developing_Regions,
Inequality,
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Inequality)	--- calculates the 50th percentile, i.e. the median.
OVER (PARTITION BY UNDP_Developing_Regions) AS Median_Inequality
FROM Unpivoted
)
SELECT UNDP_Developing_Regions,
ROUND(AVG(Inequality), 2) AS Avg_Inequality,
MIN(Inequality) AS Min_Inequality,
MAX(Inequality) AS Max_Inequality,
(MAX(Inequality) - MIN(Inequality)) AS Range_Inequality,
ROUND(STDEV(Inequality), 2) AS StdDev_Inequality,
MAX(Median_Inequality) AS Median_Inequality
FROM WithMedian
GROUP BY UNDP_Developing_Regions
ORDER BY Avg_Inequality DESC;

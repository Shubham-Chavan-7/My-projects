CREATE TABLE dbo.workforce_salaries (
    work_year          INT           NOT NULL,
    experience_level   CHAR(2)       NOT NULL,
    employment_type    VARCHAR(10)   NOT NULL,
    job_title          VARCHAR(200)  NOT NULL,
    salary             DECIMAL(18,2) NOT NULL,
    salary_currency    CHAR(3)       NOT NULL,
    salary_in_usd      DECIMAL(18,2) NOT NULL,
    employee_residence CHAR(2)       NOT NULL,
    remote_ratio       INT           NOT NULL,
    company_location   CHAR(2)       NOT NULL,
    company_size       CHAR(1)       NOT NULL
);
GO


/*===========================================================
 TASK 1
 Investigating the job market based on company size in 2021
===========================================================*/
SELECT
    company_size,
    COUNT(*) AS employee_count_2021
FROM dbo.workforce_salaries
WHERE work_year = 2021
GROUP BY company_size
ORDER BY company_size;
GO


/*===========================================================
 TASK 2
 Top 3 job titles by highest average salary for PT in 2023,
 considering only countries with > 50 employees
===========================================================*/
WITH eligible_countries AS (
    SELECT employee_residence
    FROM dbo.workforce_salaries
    WHERE work_year = 2023
    GROUP BY employee_residence
    HAVING COUNT(*) > 50
),
avg_salaries AS (
    SELECT
        job_title,
        AVG(salary_in_usd) AS avg_salary_usd
    FROM dbo.workforce_salaries w
    WHERE w.work_year = 2023
      AND w.employment_type = 'PT'
      AND w.employee_residence IN (SELECT employee_residence FROM eligible_countries)
    GROUP BY job_title
)
SELECT TOP (3)
    job_title,
    avg_salary_usd
FROM avg_salaries
ORDER BY avg_salary_usd DESC;
GO


/*===========================================================
 TASK 3
 Countries where mid-level (MI) avg salary is greater than the
 overall mid-level avg salary in 2023
===========================================================*/
WITH overall_mid AS (
    SELECT AVG(salary_in_usd) AS overall_mid_avg
    FROM dbo.workforce_salaries
    WHERE work_year = 2023
      AND experience_level = 'MI'
),
country_mid AS (
    SELECT
        employee_residence,
        AVG(salary_in_usd) AS country_mid_avg
    FROM dbo.workforce_salaries
    WHERE work_year = 2023
      AND experience_level = 'MI'
    GROUP BY employee_residence
)
SELECT
    c.employee_residence,
    c.country_mid_avg
FROM country_mid c
CROSS JOIN overall_mid o
WHERE c.country_mid_avg > o.overall_mid_avg
ORDER BY c.country_mid_avg DESC;
GO


/*===========================================================
 TASK 4
 Highest and lowest average salary locations for SE in 2023
===========================================================*/
WITH se_country_avg AS (
    SELECT
        company_location,
        AVG(salary_in_usd) AS avg_se_salary
    FROM dbo.workforce_salaries
    WHERE work_year = 2023
      AND experience_level = 'SE'
    GROUP BY company_location
)
SELECT TOP (1)
    'HIGHEST' AS category,
    company_location,
    avg_se_salary
FROM se_country_avg
ORDER BY avg_se_salary DESC;

SELECT TOP (1)
    'LOWEST' AS category,
    company_location,
    avg_se_salary
FROM se_country_avg
ORDER BY avg_se_salary ASC;
GO


/*===========================================================
 TASK 5
 Salary growth rates by job title between 2023 and 2024
===========================================================*/
WITH job_year_avg AS (
    SELECT
        job_title,
        work_year,
        AVG(salary_in_usd) AS avg_salary
    FROM dbo.workforce_salaries
    WHERE work_year IN (2023, 2024)
    GROUP BY job_title, work_year
),
growth AS (
    SELECT
        j23.job_title,
        j23.avg_salary AS avg_2023,
        j24.avg_salary AS avg_2024,
        ((j24.avg_salary - j23.avg_salary) * 100.0 /
         NULLIF(j23.avg_salary, 0)) AS pct_increase_23_24
    FROM job_year_avg j23
    JOIN job_year_avg j24
      ON j23.job_title = j24.job_title
     AND j23.work_year = 2023
     AND j24.work_year = 2024
)
SELECT *
FROM growth
ORDER BY pct_increase_23_24 DESC;
GO


/*===========================================================
 TASK 6
 Top 3 countries with highest salary growth for EN roles
 from 2020 to 2023, only where total employees > 50
===========================================================*/
WITH en_country_year AS (
    SELECT
        employee_residence,
        work_year,
        AVG(salary_in_usd) AS avg_salary,
        COUNT(*) AS cnt
    FROM dbo.workforce_salaries
    WHERE experience_level = 'EN'
      AND work_year IN (2020, 2023)
    GROUP BY employee_residence, work_year
),
joined AS (
    SELECT
        c20.employee_residence,
        c20.avg_salary AS avg_2020,
        c23.avg_salary AS avg_2023,
        ((c23.avg_salary - c20.avg_salary) * 100.0 /
         NULLIF(c20.avg_salary, 0)) AS pct_growth,
        (c20.cnt + c23.cnt) AS total_employees
    FROM en_country_year c20
    JOIN en_country_year c23
      ON c20.employee_residence = c23.employee_residence
     AND c20.work_year = 2020
     AND c23.work_year = 2023
)
SELECT TOP (3)
    employee_residence,
    avg_2020,
    avg_2023,
    pct_growth
FROM joined
WHERE total_employees > 50
ORDER BY pct_growth DESC;
GO


/*===========================================================
 TASK 7
 Update remote_ratio to 100 for employees earning > 90,000
 in US and AU
===========================================================*/
UPDATE dbo.workforce_salaries
SET remote_ratio = 100
WHERE salary_in_usd > 90000
  AND employee_residence IN ('US', 'AU');
GO


/*===========================================================
 TASK 8
 Salary updates for 2024 based on % increases by experience
 level (example percentages – adjust as required)
===========================================================*/
UPDATE dbo.workforce_salaries
SET salary_in_usd = salary_in_usd *
    CASE experience_level
        WHEN 'SE' THEN 1.22  -- +22%
        WHEN 'MI' THEN 1.30  -- +30%
        WHEN 'EN' THEN 1.18  -- +18%
        WHEN 'EX' THEN 1.25  -- +25%
        ELSE 1.00
    END
WHERE work_year = 2024;
GO


/*===========================================================
 TASK 9
 Year with the highest average salary for each job title
===========================================================*/
WITH job_year_avg AS (
    SELECT
        job_title,
        work_year,
        AVG(salary_in_usd) AS avg_salary
    FROM dbo.workforce_salaries
    GROUP BY job_title, work_year
),
ranked AS (
    SELECT
        job_title,
        work_year,
        avg_salary,
        ROW_NUMBER() OVER (
            PARTITION BY job_title
            ORDER BY avg_salary DESC
        ) AS rn
    FROM job_year_avg
)
SELECT
    job_title,
    work_year AS best_year,
    avg_salary AS best_avg_salary
FROM ranked
WHERE rn = 1
ORDER BY job_title;
GO


/*===========================================================
 TASK 10
 Percentage of employment types (FT / PT / others) by job title
===========================================================*/
WITH counts AS (
    SELECT
        job_title,
        employment_type,
        COUNT(*) AS cnt
    FROM dbo.workforce_salaries
    GROUP BY job_title, employment_type
),
totals AS (
    SELECT
        job_title,
        SUM(cnt) AS total_cnt
    FROM counts
    GROUP BY job_title
)
SELECT
    t.job_title,
    SUM(CASE WHEN c.employment_type = 'FT' THEN c.cnt ELSE 0 END)
        * 100.0 / NULLIF(t.total_cnt, 0) AS pct_FT,
    SUM(CASE WHEN c.employment_type = 'PT' THEN c.cnt ELSE 0 END)
        * 100.0 / NULLIF(t.total_cnt, 0) AS pct_PT,
    SUM(CASE WHEN c.employment_type NOT IN ('FT','PT') THEN c.cnt ELSE 0 END)
        * 100.0 / NULLIF(t.total_cnt, 0) AS pct_other
FROM totals t
JOIN counts c ON c.job_title = t.job_title
GROUP BY t.job_title, t.total_cnt
ORDER BY t.job_title;
GO


/*===========================================================
 TASK 11
 Countries offering full remote work for managers with
 salary_in_usd > 90,000
===========================================================*/
SELECT DISTINCT
    employee_residence
FROM dbo.workforce_salaries
WHERE job_title LIKE '%Manager%'
  AND salary_in_usd > 90000
  AND remote_ratio = 100
ORDER BY employee_residence;
GO


/*===========================================================
 TASK 12
 Top 5 countries with the most large companies (company_size = 'L')
===========================================================*/
SELECT TOP (5)
    company_location,
    COUNT(*) AS large_company_employee_count
FROM dbo.workforce_salaries
WHERE company_size = 'L'
GROUP BY company_location
ORDER BY large_company_employee_count DESC;
GO


/*===========================================================
 TASK 13
 Percentage of employees who are fully remote and earn > 100,000
===========================================================*/
WITH total AS (
    SELECT COUNT(*) AS total_employees
    FROM dbo.workforce_salaries
),
qualified AS (
    SELECT COUNT(*) AS qualified_employees
    FROM dbo.workforce_salaries
    WHERE remote_ratio = 100
      AND salary_in_usd > 100000
)
SELECT
    qualified_employees * 100.0 / NULLIF(total_employees, 0) AS pct_fully_remote_over_100k
FROM total
CROSS JOIN qualified;
GO


/*===========================================================
 TASK 14
 Locations where entry-level (EN) avg salaries exceed the market
 average for entry-level
===========================================================*/
WITH global_en AS (
    SELECT AVG(salary_in_usd) AS global_en_avg
    FROM dbo.workforce_salaries
    WHERE experience_level = 'EN'
),
loc_en AS (
    SELECT
        company_location,
        AVG(salary_in_usd) AS loc_en_avg
    FROM dbo.workforce_salaries
    WHERE experience_level = 'EN'
    GROUP BY company_location
)
SELECT
    l.company_location,
    l.loc_en_avg
FROM loc_en l
CROSS JOIN global_en g
WHERE l.loc_en_avg > g.global_en_avg
ORDER BY l.loc_en_avg DESC;
GO


/*===========================================================
 TASK 15
 Countries paying the maximum average salary for each job title
===========================================================*/
WITH jt_country AS (
    SELECT
        job_title,
        employee_residence,
        AVG(salary_in_usd) AS avg_salary
    FROM dbo.workforce_salaries
    GROUP BY job_title, employee_residence
),
ranked AS (
    SELECT
        job_title,
        employee_residence,
        avg_salary,
        ROW_NUMBER() OVER (
            PARTITION BY job_title
            ORDER BY avg_salary DESC
        ) AS rn
    FROM jt_country
)
SELECT
    job_title,
    employee_residence AS best_paying_country,
    avg_salary
FROM ranked
WHERE rn = 1
ORDER BY job_title;
GO


/*===========================================================
 TASK 16
 Countries with sustained salary growth over three years
 (example: 2021, 2022, 2023)
===========================================================*/
WITH country_year AS (
    SELECT
        employee_residence,
        work_year,
        AVG(salary_in_usd) AS avg_salary
    FROM dbo.workforce_salaries
    WHERE work_year BETWEEN 2021 AND 2023
    GROUP BY employee_residence, work_year
),
pivoted AS (
    SELECT
        c21.employee_residence,
        c21.avg_salary AS avg_2021,
        c22.avg_salary AS avg_2022,
        c23.avg_salary AS avg_2023
    FROM country_year c21
    JOIN country_year c22
      ON c21.employee_residence = c22.employee_residence
     AND c22.work_year = 2022
    JOIN country_year c23
      ON c21.employee_residence = c23.employee_residence
     AND c23.work_year = 2023
    WHERE c21.work_year = 2021
)
SELECT
    employee_residence,
    avg_2021,
    avg_2022,
    avg_2023
FROM pivoted
WHERE avg_2021 < avg_2022
  AND avg_2022 < avg_2023
ORDER BY employee_residence;
GO


/*===========================================================
 TASK 17
 Percentage of fully remote work by experience level
 (compare 2021 vs 2024)
===========================================================*/
WITH base AS (
    SELECT
        work_year,
        experience_level,
        COUNT(*) AS total_cnt,
        SUM(CASE WHEN remote_ratio = 100 THEN 1 ELSE 0 END) AS fully_remote_cnt
    FROM dbo.workforce_salaries
    WHERE work_year IN (2021, 2024)
    GROUP BY work_year, experience_level
)
SELECT
    work_year,
    experience_level,
    fully_remote_cnt * 100.0 / NULLIF(total_cnt, 0) AS pct_fully_remote
FROM base
ORDER BY experience_level, work_year;
GO


/*===========================================================
 TASK 18
 Average salary increase percentage by experience level and
 job title (2023 to 2024)
===========================================================*/
WITH combo_year AS (
    SELECT
        job_title,
        experience_level,
        work_year,
        AVG(salary_in_usd) AS avg_salary
    FROM dbo.workforce_salaries
    WHERE work_year IN (2023, 2024)
    GROUP BY job_title, experience_level, work_year
),
joined AS (
    SELECT
        c23.job_title,
        c23.experience_level,
        c23.avg_salary AS avg_2023,
        c24.avg_salary AS avg_2024,
        (c24.avg_salary - c23.avg_salary) * 100.0 /
            NULLIF(c23.avg_salary, 0) AS pct_increase_23_24
    FROM combo_year c23
    JOIN combo_year c24
      ON c23.job_title = c24.job_title
     AND c23.experience_level = c24.experience_level
     AND c23.work_year = 2023
     AND c24.work_year = 2024
)
SELECT
    job_title,
    experience_level,
    avg_2023,
    avg_2024,
    pct_increase_23_24
FROM joined
ORDER BY pct_increase_23_24 DESC;
GO


/*===========================================================
 TASK 19
 Role-based access control by experience level
 (row-level security style example)
===========================================================*/
-- Example helper table that maps SQL users to experience levels
CREATE TABLE dbo.UserExperienceAccess (
    user_name        SYSNAME    NOT NULL,
    experience_level CHAR(2)    NOT NULL
);

-- Example: grant a user access to MI level data
-- INSERT INTO dbo.UserExperienceAccess (user_name, experience_level)
-- VALUES ('DOMAIN\\SomeUser', 'MI');

-- View that automatically filters rows based on logged-in user
CREATE VIEW dbo.vw_Workforce_By_Experience
AS
SELECT w.*
FROM dbo.workforce_salaries AS w
JOIN dbo.UserExperienceAccess AS u
    ON u.experience_level = w.experience_level
   AND u.user_name = SUSER_SNAME();
GO


/*===========================================================
 TASK 20
 Guiding clients in switching domains based on salary insights
 (recommend roles with higher avg salary in same location and level)
===========================================================*/
DECLARE @current_job_title       VARCHAR(200) = 'Data Analyst';
DECLARE @current_experience_level CHAR(2)     = 'MI';
DECLARE @current_location        CHAR(2)     = 'US';

WITH current_role AS (
    SELECT
        AVG(salary_in_usd) AS current_avg_salary
    FROM dbo.workforce_salaries
    WHERE job_title = @current_job_title
      AND experience_level = @current_experience_level
      AND employee_residence = @current_location
),
other_roles AS (
    SELECT
        job_title,
        AVG(salary_in_usd) AS avg_salary
    FROM dbo.workforce_salaries
    WHERE experience_level = @current_experience_level
      AND employee_residence = @current_location
    GROUP BY job_title
)
SELECT
    o.job_title AS recommended_job_title,
    o.avg_salary AS recommended_avg_salary
FROM other_roles o
CROSS JOIN current_role c
WHERE o.avg_salary > c.current_avg_salary
  AND o.job_title <> @current_job_title
ORDER BY o.avg_salary DESC;
GO

-- CREATE DATABASE recruitment_analytics;
-- USE recruitment_analytics;
/*
CREATE TABLE candidates (
    candidate_id INT PRIMARY KEY,
    candidate_name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(15),
    experience_years DECIMAL(3,1),
    current_location VARCHAR(60)
);

CREATE TABLE jobs(
     job_id INT PRIMARY KEY,
     job_title VARCHAR(100),
     department VARCHAR (80),
     job_location VARCHAR(100),
     open_date DATE NOT NULL,
     close_date DATE
);

CREATE TABLE applications (
    application_id INT PRIMARY KEY,
    candidate_id INT NOT NULL,
    job_id INT NOT NULL,
    source VARCHAR(50),
    recruiter_id INT,
    application_date DATE NOT NULL,
    current_status VARCHAR(50),

    FOREIGN KEY (candidate_id) REFERENCES candidates(candidate_id),
    FOREIGN KEY (job_id) REFERENCES jobs(job_id)
);

CREATE TABLE recruitment_stage_events (
    stage_event_id INT PRIMARY KEY,
    application_id INT NOT NULL,
    stage_name VARCHAR(50) NOT NULL,
    stage_date DATE,
    stage_status VARCHAR(20),
    drop_reason TEXT,

    FOREIGN KEY (application_id) REFERENCES applications(application_id)
);
*/ 

SELECT * FROM candidates;
SELECT * FROM jobs;
SELECT * FROM applications;
SELECT * FROM recruitment_stage_events;

-- Q1. How many total applications were received
SELECT count(*) AS Total_Applications 
FROM applications ;

-- -- Q2. how does the application volume vary month by month?
-- Applications recieved by Month
SELECT 
YEAR(application_date) AS Year,
MONTH(application_date) AS Month,
COUNT(*) AS Applications_Recieved
FROM applications
GROUP BY  YEAR(application_date),
    MONTH(application_date)
ORDER BY 
    year, month;
    
-- Q2. How many candidates are at each stage of the recruitment funnel?
SELECT stage_name, COUNT(DISTINCT application_id) AS application_count
FROM recruitment_stage_events
GROUP BY stage_name
ORDER BY application_count DESC;

-- Q3. What is the conversion rate between recruitment stages? 
-- What percentage of applications move from one stage to the next?

-- Stage-wise Conversion Rate
WITH stage_counts AS (
    SELECT 
        stage_name, COUNT(DISTINCT application_id) AS stage_count
	FROM recruitment_stage_events
    GROUP BY stage_name
)
SELECT 
    stage_name,
    stage_count,
    ROUND(
        stage_count * 100.0 /
        LAG(stage_count) OVER (ORDER BY stage_count DESC),
        2
    ) AS conversion_rate_percentage
FROM stage_counts;

-- Q4. How many candidates were finally hired?
-- Total Hires 
SELECT COUNT(*) AS Total_Hires
FROM applications
WHERE current_status = 'Hired';

-- Q5. What is the average time-to-hire?
-- What is the average time taken to hire a candidate from application date to joining date?
SELECT 
    AVG(DATEDIFF(j.joining_date, a.application_date)) AS avg_time_to_hire_days
FROM applications a
JOIN (
    SELECT 
        application_id,
        MIN(stage_date) AS joining_date
    FROM recruitment_stage_events
    WHERE stage_name = 'Joined'
    GROUP BY application_id
) j
ON a.application_id = j.application_id;

-- Q5 Which sourcing channels are performing the best?
-- Applications Received by Source
SELECT 
    source,
    COUNT(*) AS applications_received
FROM applications
GROUP BY source
ORDER BY applications_received DESC;

-- Hire by Source 
SELECT 
    source,
    COUNT(*) AS total_hires
FROM applications
WHERE current_status = 'Hired'
GROUP BY source
ORDER BY total_hires DESC;

-- Source-wise Hire Conversion Rate
SELECT 
    source,
    COUNT(CASE WHEN current_status = 'Hired' THEN 1 END) * 100.0 / COUNT(*) 
        AS hire_conversion_rate
FROM applications
GROUP BY source
ORDER BY hire_conversion_rate DESC;

-- Business Question: Why are candidates dropping out at different recruitment stages?
-- What are the primary reasons for candidate drop-offs at each stage of the recruitment funnel?

-- Drop-offs by Stage
SELECT 
    stage_name,
    COUNT(*) AS drop_count
FROM recruitment_stage_events
WHERE stage_status IN ('Rejected', 'Declined', 'No Show', 'Withdrawn')
GROUP BY stage_name
ORDER BY drop_count DESC;

-- Drop-off Reasons by Stage
SELECT 
    stage_name,
    drop_reason,
    COUNT(*) AS drop_count
FROM recruitment_stage_events
WHERE drop_reason IS NOT NULL
  AND drop_reason <> ''
GROUP BY stage_name, drop_reason
ORDER BY stage_name, drop_count DESC;


-- Top Drop-off Reason Overall
SELECT 
    drop_reason,
    COUNT(*) AS total_drops
FROM recruitment_stage_events
WHERE drop_reason IS NOT NULL
  AND drop_reason <> ''
GROUP BY drop_reason
ORDER BY total_drops DESC
LIMIT 5;



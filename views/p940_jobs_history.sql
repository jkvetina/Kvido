CREATE OR REPLACE FORCE VIEW p940_jobs_history AS
WITH x AS (
    SELECT
        c.app_id,
        c.today__
    FROM calendar c
    WHERE c.app_id      = sess.get_app_id()
        AND c.today     = app.get_date_str()
)
SELECT
    MAX(d.log_id)       AS log_id,
    d.job_name,
    COUNT(d.log_id)     AS counter,
    SUM(d.errors)       AS errors,
    --
    MIN(CAST(d.actual_start_date AS DATE))          AS first_run,
    NULLIF(MAX(CAST(d.actual_start_date AS DATE)),
        MIN(CAST(d.actual_start_date AS DATE)))     AS last_run,
    --
    NULL                AS avg_run_duration,
    NULL                AS avg_cpu_used,
    --
    d.status
--
FROM user_scheduler_job_run_details d
JOIN x
    ON CAST(d.actual_start_date AS DATE)    >= x.today__
    AND CAST(d.actual_start_date AS DATE)   < x.today__ + 1
GROUP BY d.job_name, d.status;


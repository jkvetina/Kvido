CREATE OR REPLACE FORCE VIEW p940_jobs_history AS
WITH x AS (
    SELECT
        c.app_id,
        c.today
    FROM calendar c
    WHERE c.app_id      = sess.get_app_id()
        AND c.today     = app.get_date_str()
)
SELECT
    MAX(d.log_id)       AS log_id,
    d.job_name,
    --
    NULLIF(SUM(CASE WHEN d.status = 'SUCCEEDED'  THEN 1 ELSE 0 END), 0)     AS succeeded,
    NULLIF(SUM(CASE WHEN d.status != 'SUCCEEDED' THEN 1 ELSE 0 END), 0)     AS failed,
    --
    MAX(d.errors)       AS error_desc,
    --
    MIN(CAST(d.actual_start_date AS DATE))          AS first_run,
    NULLIF(MAX(CAST(d.actual_start_date AS DATE)),
        MIN(CAST(d.actual_start_date AS DATE)))     AS last_run,
    --
    --app.get_duration(d.run_duration)    AS run_duration,  AVG ???
    --app.get_duration(d.cpu_used)        AS cpu_used,
    --
    NULL                AS avg_run_duration,
    NULL                AS avg_cpu_used
FROM user_scheduler_job_run_details d
JOIN x
    ON x.today          = TO_CHAR(d.actual_start_date, 'YYYY-MM-DD')
GROUP BY d.job_name;


CREATE OR REPLACE FORCE VIEW p940_jobs_details AS
WITH x AS (
    SELECT
        c.today,
        c.app_id
    FROM calendar c
    WHERE c.app_id      = sess.get_app_id()
        AND c.today     = app.get_date_str()
)
SELECT
    d.log_id,
    d.job_name,
    d.actual_start_date                 AS start_date,
    app.get_duration(d.run_duration)    AS run_duration,
    app.get_duration(d.cpu_used)        AS cpu_used,
    d.status,
    --d.session_id,
    d.error#,
    d.errors,
    d.output,
    d.additional_info
FROM user_scheduler_job_run_details d
JOIN x
    ON x.today          = TO_CHAR(d.actual_start_date, 'YYYY-MM-DD');


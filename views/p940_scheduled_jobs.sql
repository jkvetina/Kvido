CREATE OR REPLACE FORCE VIEW p940_scheduled_jobs AS
SELECT
    j.job_name,
    j.job_type,
    j.job_priority,
    j.job_action,
    j.number_of_arguments AS job_args,
    j.repeat_interval,
    --
    NULLIF(j.run_count, 0)      AS run_count,
    NULLIF(j.failure_count, 0)  AS failure_count,
    NULLIF(j.retry_count, 0)    AS retry_count,
    --
    j.next_run_date,
    j.last_start_date,
    --
    app.get_duration(j.last_run_duration) AS last_run_duration,
    --
    CASE
        WHEN j.auto_drop = 'TRUE'
            THEN apex.get_icon('fa-check-square', 'Autodrop enabled')
            END AS autodrop_,
    --
    CASE
        WHEN j.state = 'SCHEDULED' AND j.enabled = 'TRUE'
            THEN apex.get_icon('fa-check-square', 'Job is enabled')
            END AS enabled_,
    --
    j.comments
FROM user_scheduler_jobs j;


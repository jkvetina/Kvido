--DROP TABLE p902_activity_chart;
--CREATE GLOBAL TEMPORARY TABLE p902_activity_chart (
CREATE TABLE p902_activity_chart (
    user_id             VARCHAR2(30)    NOT NULL,
    bucket_id           NUMBER(4)       NOT NULL,
    --
    chart_label         VARCHAR2(400),
    count_pages         NUMBER,
    count_forms         NUMBER,
    count_users         NUMBER,
    --
    count_business#1    NUMBER,
    count_business#2    NUMBER,
    --
    CONSTRAINT pk_p902_activity_chart
        PRIMARY KEY (user_id, bucket_id)
);
--ON COMMIT PRESERVE ROWS;


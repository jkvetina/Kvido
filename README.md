# ERR - PL/SQL logger

Purpose of this project is to track all errors (and debug messages) in ORACLE database as a tree
so you can quickly analyze what happened. It has automatic scope recognition,
simple arguments passing and many interesting features.

[![Paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=EX68GXSFFWV2S&item_name=ERR+-+PL/SQL+logger&currency_code=EUR&source=url) &nbsp;
If you like my work, please consider donation.

<br />

## Quick overview

All you need to do is add [ERR.LOG_MODULE](./packages/err.spec.sql#log_module) calls to beginning of your every procedure.
There is a view [LOGS_CHECK_MISSING_CALLS](./views/logs_check_missing_calls.sql) which will help you to track missing occurrences.

```sql
PROCEDURE your_procedure AS
BEGIN
    err.log_module();

    -- your code
    NULL;
END;
```

<br />

## Check tree by using LOGS_TREE view

1) set any log_id you are interested in

```sql
BEGIN
    err.set_tree_id(err.get_log_id());
END;
/
```

2) check view content

```sql
SELECT
    e.log_id,
    e.flag,
    e.action_name,
    e.module_name,
    e.line,
    RTRIM(e.context_a || '|' || e.context_b || '|' || e.context_c, '|') AS contexts,
    e.arguments,
    e.timer,
    e.session_db
FROM logs_tree e;
```

<br />

## More examples

### Track module with arguments and timer

```sql
PROCEDURE your_procedure (
    in_argument1    VARCHAR2,
    in_argument2    NUMBER,
    in_argument3    DATE
) AS
BEGIN
    err.log_module(in_argument1, in_argument2, in_argument3);

    -- your code
    NULL;

    err.update_timer();
END;
```

### Track debugging info and possible warning

```sql
PROCEDURE your_procedure AS
BEGIN
    err.log_module();
    err.log_debug('I AM GOING TO DO SOMETHING');

    -- your code
    NULL;

    -- log result
    err.log_result('RESULT');

    -- log warning if needed
    IF TRUE THEN
        err.log_warning('THIS IS NOT GOOD');
    END IF;
END;
```

### Track app errors

```sql
PROCEDURE your_procedure AS
BEGIN
    err.log_module();

    -- your code
    NULL;

    -- log error if needed
    IF TRUE THEN
        err.log_error('THIS IS REALLY BAD');
    END IF;
END;
```

### Track app errors and raise exception

```sql
PROCEDURE your_procedure AS
BEGIN
    err.log_module();

    -- your code
    NULL;
EXCEPTION
WHEN OTHERS THEN
    err.raise_error();
END;
```

<br />


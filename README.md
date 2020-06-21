# ERR

Purpose of this package is to track all errors (and debug messages) in application as a tree
so you can quickly analyze what happend. It has automatic scope recognition, simple arguments passing
and many interesting features.

## Quick overview

All you need to do is add [err.log_module](./packages/err.spec.sql#log_module) calls to beginning of your every procedure.
There is a view [logs_check_missing_calls](./views/logs_check_missing_calls.sql) which will help you to track missing occurrences.

### Track module in tree

```sql
PROCEDURE your_procedure AS
BEGIN
    err.log_module();

    -- your code
    NULL;
END;
```

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

### `err.log_module` explained

To access log tree you have to add [`err.log_module`](../packages/err.spec.sql#log_module) calls to beginning of your every procedure.
You are supposed to call this procedure (or function) exactly once in each module.
You can skip functions called in SQL queries to avoid too many rows in [`logs`](../tables/logs.md).

There is an aid view [`logs_check_modules`](../views/logs_check_modules.sql) which will help you to track missing occurrences.

<br />



#### Source code (18 lines)

```sql
FUNCTION log_module (
    in_arg1         logs.arguments%TYPE     := NULL,
    in_arg2         logs.arguments%TYPE     := NULL,
    in_arg3         logs.arguments%TYPE     := NULL,
    in_arg4         logs.arguments%TYPE     := NULL,
    in_arg5         logs.arguments%TYPE     := NULL,
    in_arg6         logs.arguments%TYPE     := NULL,
    in_arg7         logs.arguments%TYPE     := NULL,
    in_arg8         logs.arguments%TYPE     := NULL
)
RETURN logs.log_id%TYPE AS
BEGIN
    RETURN err.log__ (
        in_action_name  => err.empty_action,
        in_flag         => err.flag_module,
        in_arguments    => err.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
    );
END;
```

> This function also exists as a procedure which calles this function but without returning `log_id` value.

<br />



#### Minimal example

```sql
PROCEDURE your_procedure AS
BEGIN
    err.log_module();

    -- your code
    NULL;
END;
```

<br />



#### Track module with arguments and optional timer

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

<br />



#### Using assigned `log_id`

```sql
PROCEDURE your_procedure
AS
    log_id logs.log_id%TYPE;
BEGIN
    log_id := err.log_module();

    -- your code
    NULL;
END;
```

<br />


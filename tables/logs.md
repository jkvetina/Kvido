## Table `logs`

Description of main table [`logs`](../tables/logs.sql) with daily partitions based on `create_at` column.

| ID | Column name                    | Data type        | NN | PK | Comment |
| -: | :----------------------------- | :--------------- | -- | -- | :------ |
|  1 | `log_id`                       | NUMBER           | Y | Y | Error ID generated from sequence `log_id` |
|  2 | `log_parent`                   | NUMBER           | N | N | Parent error to easily create tree; dont use FK to avoid deadlocks |
|  3 | `app_id`                       | NUMBER(4)        | N | N | APEX Application ID |
|  4 | `page_id`                      | NUMBER(6)        | N | N | APEX Application PAGE ID |
|  5 | `user_id`                      | VARCHAR2(30)     | Y | N | User ID |
|  6 | `flag`                         | CHAR(1)          | Y | N | Type of error listed in `err` package specification; FK missing for performance reasons |
|  7 | `action_name`                  | VARCHAR2(32)     | Y | N | Action name to distinguish position in module or warning and error names |
|  8 | `module_name`                  | VARCHAR2(64)     | Y | N | Module name (procedure or function name) |
|  9 | `module_line`                  | NUMBER(8)        | Y | N | Line in the module |
| 10 | `module_depth`                 | NUMBER(4)        | Y | N | Depth of module in callstack |
| 11 | `arguments`                    | VARCHAR2(2000)   | N | N | Arguments passed to module |
| 12 | `message`                      | VARCHAR2(4000)   | N | N | Formatted call stack, error stack or query with DML error |
| 13 | `context_a`                    | VARCHAR2(30)     | N | N | Your APP context; use more descriptive name |
| 14 | `context_b`                    | VARCHAR2(30)     | N | N | Your APP context |
| 15 | `context_c`                    | VARCHAR2(30)     | N | N | Your APP context |
| 16 | `scheduler_name`               | VARCHAR2(30)     | N | N | Scheduler name when log was initiated from `DBMS_SCHEDULER` |
| 17 | `scheduler_id`                 | NUMBER           | N | N | Scheduler ID to track down details |
| 18 | `session_db`                   | NUMBER           | N | N | Database session ID |
| 19 | `session_apex`                 | NUMBER           | N | N | APEX session ID |
| 20 | `scn`                          | NUMBER           | N | N | System change number |
| 21 | `timer`                        | VARCHAR2(15)     | N | N | Timer for current row in seconds |
| 22 | `created_at`                   | TIMESTAMP        | Y | N | Timestamp of creation |

<br />



#### `logs.log_id`, `logs.log_parent` - to build the tree structure

`logs.log_id` is generated via [`log_id`](../sequences/log_id.sql) sequence.

`logs.log_parent` is referencing current caller to visualize log records as a tree.

You dont need to worry about `logs.log_parent` value, it is retrieved automatically based on current callstack
using private `err.map_modules` and `err.map_actions` arrays.

> Set is done by [`err.set_caller_module`](../packages/err.spec.sql#set_caller_module) and [`err.set_caller_action`](../packages/err.spec.sql#set_caller_action) procedures.\
> Get is done by [`err.get_caller_info`](../packages/err.spec.sql#get_caller_info) function (resp. procedure with OUT parameters).

<br />



#### `logs.app_id`, `logs.page_id` - APEX app and page info

`logs.app_id` is your APEX application id, if available, retrieved by [`ctx.get_app_id`](../packages/ctx.spec.sql#get_app_id).

`logs.page_id` is your APEX page id retrieved by [`ctx.get_page_id`](../packages/ctx.spec.sql#get_page_id).

<br />



#### `logs.user_id` - APEX or `SYS_CONTEXT` or DB user id

`logs.user_id` is your APEX user id or `SYS_CONTEXT` or database user retrieved by [`ctx.get_user_id`](../packages/ctx.spec.sql#get_user_id).

<br />



#### `logs.flag` - available flags

Different flags are used to distinguish different types of logs.\
You can change or add new flags in [`err`](../packages/err.spec.sql) package specification.\
Every flag has its own `err.log_*` modules.

> Logging can be adjusted per flag, see [`logs_tracking`](../tables/logs_tracking.sql) table.

|  Flag | Used by     | Description |
| ----: | :---------- | :---------- |
|     M | [`err.log_module`](./packages/err.spec.sql#log_module) | Called at start of you every procedure |
|     A | [`err.log_action`](./packages/err.spec.sql#log_action) | To distinguish different parts of longer modules |
|     D | [`err.log_debug`](./packages/err.spec.sql#log_debug) | To store any debug info |
|     I | [`err.log_context`](./packages/err.spec.sql#log_context)<br />[`err.log_userenv`](./packages/err.spec.sql#log_userenv)<br />[`err.log_cgi`](./packages/err.spec.sql#log_cgi) | To store various enviroment variables |
|     R | [`err.log_result`](./packages/err.spec.sql#log_result) | To store your calculation results |
|     W | [`err.log_warning`](./packages/err.spec.sql#log_warning) | To store warning with optional action_name |
|     E | [`err.log_error`](./packages/err.spec.sql#log_error) | To store error with optional action_name |

<br />


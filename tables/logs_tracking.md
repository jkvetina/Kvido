## Table `logs_tracking`

Description of table [`logs_tracking`](./tables/logs_tracking.sql) which is used to adjust what is logged and what not.

You can adjust tracking for specific users, flags and/or modules by using blacklisted or whitelisted records.\
Whitelisted row (`track` = "Y") precedes blacklisted (`track` = "N") row and you can use "%" as LIKE in SQL.

| ID | Column name                    | Data type        | NN | PK | Comment |
| -: | :----------------------------- | :--------------- | -- | -- | :------ |
|  1 | `user_id`                      | VARCHAR2(30)     | Y | Y | User ID; % for any user |
|  2 | `module_name`                  | VARCHAR2(30)     | Y | Y | Module name in LOGS table; % for any module |
|  3 | `flag`                         | CHAR(1)          | Y | Y | Flag used in LOGS table; % for any flag |
|  4 | `track`                        | CHAR(1)          | Y | N | Y = track; N = dont track; Y > N |

<br />


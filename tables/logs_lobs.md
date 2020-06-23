## Table `logs_lobs`

Description of table [`logs_lobs`](../tables/logs_lobs.sql) which holds large objects.

| ID | Column name                    | Data type        | NN | PK | Comment |
| -: | :----------------------------- | :--------------- | -- | -- | :------ |
|  1 | `log_id`                       | NUMBER           | Y | Y | ID to have multiple LOBs attached to single row in LOGS |
|  2 | `parent_log`                   | NUMBER           | Y | N | Referenced log_id in LOBS table |
|  3 | `lob_name`                     | VARCHAR2(255)    | N | N | Optional name of the object/file |
|  4 | `lob_length`                   | NUMBER           | N | N | Length in bytes |
|  5 | `blob_content`                 | BLOB             | N | N | BLOB |
|  6 | `clob_content`                 | CLOB             | N | N | CLOB |

<br />



#### `logs_lobs.log_id`, `logs_lobs.log_parent` - to build the tree structure

`logs_lobs.log_id` is generated via [`log_id`](../sequences/log_id.sql) sequence.

`logs_lobs.parent_log` is reference to related record in [`logs`](../tables/logs.sql) table.

<br />



#### `logs_lobs.lob_name`

`logs_lobs.lob_name` is optional name of your LOB/file.

<br />



#### `logs_lobs.lob_length`

`logs_lobs.lob_length` is calculated automaticaly.

<br />



#### `logs_lobs.clob_content`, `logs_lobs.blob_content`

`logs_lobs.clob_content` can be populated via calls to overloaded
[`err.attach_clob`](../packages/err.spec.sql#attach_clob) procedure with `CLOB` or `XMLTYPE` arguments and optional `logs_lobs.lob_name`.

For binary LOBs use `logs_lobs.blob_content` resp. [`err.attach_blob`](../packages/err.spec.sql#attach_blob) procedure.

<br />


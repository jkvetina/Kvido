# (de)BUG - PL/SQL logger & debugger

## Simple to use yet powerful

Purpose of this project is to track all errors (and debug messages) in ORACLE database __as a tree__
so you can quickly analyze what happened. It has automatic scope recognition,
simple arguments passing and many interesting features.

### Some features

- automatic scope recognition and tree building
- simple arguments passing
- tracking setup in a table (what, where, who)
- DML errors linked to proper log record with passed args
- LOBs linked to proper log record
- support scheduler and context passing
- include profiling
- automatic error backtrace on errors
- environmental and application contexts logging
- APEX support (apps, pages, items...)
- automatic purging of old records

<br />



### Simple example

```sql
PROCEDURE your_procedure (
    in_argument1    VARCHAR2,
    in_argument2    NUMBER,
    in_argument3    DATE
) AS
BEGIN
    bug.log_module(in_argument1, in_argument2, in_argument3);

    -- your code
    NULL;

    bug.update_timer();
END;
```

<br />



### Documentation, tips and examples are available on [Wiki](../../wiki).

If you like my work, please consider small donation.

[![Paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=EX68GXSFFWV2S&item_name=(de)BUG+-+PL/SQL+debugger&currency_code=EUR&source=url)

<br />


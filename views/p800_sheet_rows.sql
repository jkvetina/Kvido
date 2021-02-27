CREATE OR REPLACE FORCE VIEW p800_sheet_rows AS
SELECT
    c001, c002,       c004,       c006, c007, c008, c009, c010,
    c011, c012, c013, c014, c015, c016, c017, c018, c019, c020,
    c021, c022, c023, c024, c025, c026, c027, c028, c029, c030,
    c031, c032, c033, c034, c035, c036, c037, c038, c039, c040,
    c041, c042, c043, c044, c045, c046, c047, c048, c049, c050
FROM apex_collections
WHERE collection_name = 'SQL_' || apex.get_item('$TARGET')
    AND c005 = sess.get_session_id();



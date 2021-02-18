--DROP TABLE languages PURGE;
CREATE TABLE languages (
    lang_id             VARCHAR2(5)    CONSTRAINT nn_languages_lang_id NOT NULL,
    --
    updated_by          VARCHAR2(30),
    updated_at          DATE,
    --
    CONSTRAINT pk_languages
        PRIMARY KEY (lang_id)
)
STORAGE (BUFFER_POOL KEEP);
--
COMMENT ON TABLE  languages                     IS 'List of languages';
--
COMMENT ON COLUMN languages.lang_id             IS 'Language ID';


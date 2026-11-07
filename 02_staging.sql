-- 02_staging.sql · Tablas espejo de las fuentes, todo en texto (recepción cruda)
DROP TABLE IF EXISTS stg.stg_f1_hurto_personas, stg.stg_f2_divipola, stg.stg_f3_poblacion, stg.stg_f4_sedes CASCADE;

CREATE TABLE stg.stg_f1_hurto_personas (   -- F1 · CSV datos.gov.co (MinDefensa / SIEDCO)
    fecha_hecho   TEXT,
    cod_depto     TEXT,
    departamento  TEXT,
    cod_muni      TEXT,
    municipio     TEXT,
    cantidad      TEXT
);

CREATE TABLE stg.stg_f2_divipola (         -- F2 · JSON API SODA DANE
    cod_dpto        TEXT,
    dpto            TEXT,
    cod_mpio        TEXT,
    nom_mpio        TEXT,
    tipo_municipio  TEXT,
    longitud        TEXT,
    latitud         TEXT
);

CREATE TABLE stg.stg_f3_poblacion (        -- F3 · XLSX DANE, hoja PobMunicipalxÁrea
    dp               TEXT,
    dpnom            TEXT,
    mpio             TEXT,
    dpmp             TEXT,
    anio             INTEGER,
    area_geografica  TEXT,
    total            BIGINT
);

CREATE TABLE stg.stg_f4_sedes (            -- F4 · XLSX interno (datos sintéticos)
    id_sede          TEXT,
    nombre_sede      TEXT,
    cod_dane_mpio    TEXT,
    ciudad           TEXT,
    regional         TEXT,
    fecha_apertura   TEXT,
    radio_cobertura  TEXT
);

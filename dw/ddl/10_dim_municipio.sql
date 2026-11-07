-- 10_dim_municipio.sql · Limpieza e integración stg -> dw (ejecutado por el trabajo de PDI después de t01_dim_municipio.ktr)
TRUNCATE dw.dim_municipio RESTART IDENTITY CASCADE;

-- ---------------------------------------------------------------- dim_municipio (F2)
-- Reglas: código DANE como única llave (LPAD 5), coma decimal -> punto, región por departamento.
INSERT INTO dw.dim_municipio (cod_dane_mpio, nombre_municipio, cod_departamento, nombre_departamento,
                              region, tipo_municipio, latitud, longitud)
SELECT LPAD(TRIM(cod_mpio), 5, '0'),
       TRIM(nom_mpio),
       LPAD(TRIM(cod_dpto), 2, '0'),
       TRIM(dpto),
       CASE LPAD(TRIM(cod_dpto), 2, '0')
            WHEN '08' THEN 'Caribe'   WHEN '13' THEN 'Caribe'   WHEN '20' THEN 'Caribe'
            WHEN '23' THEN 'Caribe'   WHEN '44' THEN 'Caribe'   WHEN '47' THEN 'Caribe'
            WHEN '70' THEN 'Caribe'   WHEN '88' THEN 'Insular'
            WHEN '19' THEN 'Pacífica' WHEN '27' THEN 'Pacífica' WHEN '52' THEN 'Pacífica'
            WHEN '76' THEN 'Pacífica'
            WHEN '50' THEN 'Orinoquía' WHEN '81' THEN 'Orinoquía' WHEN '85' THEN 'Orinoquía'
            WHEN '99' THEN 'Orinoquía'
            WHEN '18' THEN 'Amazonía' WHEN '86' THEN 'Amazonía' WHEN '91' THEN 'Amazonía'
            WHEN '94' THEN 'Amazonía' WHEN '95' THEN 'Amazonía' WHEN '97' THEN 'Amazonía'
            ELSE 'Andina' END,
       TRIM(tipo_municipio),
       CAST(REPLACE(TRIM(latitud),  ',', '.') AS NUMERIC(9,6)),
       CAST(REPLACE(TRIM(longitud), ',', '.') AS NUMERIC(9,6))
FROM stg.stg_f2_divipola
WHERE cod_mpio IS NOT NULL;


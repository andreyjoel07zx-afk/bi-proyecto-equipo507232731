-- 12_dim_cobertura.sql · Limpieza e integración stg -> dw (ejecutado por el trabajo de PDI después de t03_dim_cobertura.ktr)
TRUNCATE dw.dim_cobertura RESTART IDENTITY CASCADE;

-- ---------------------------------------------------------------- dim_cobertura (F4 + F2), SCD 2
-- Reglas: LPAD al código ('5001' -> '05001'), fechas dd/mm/aaaa o aaaa-mm-dd, radio en km
-- (si el número es mayor que 500 está en metros y se divide entre 1000).
DROP TABLE IF EXISTS stg.tmp_sedes;
CREATE TABLE stg.tmp_sedes AS
SELECT TRIM(id_sede)                                AS id_sede,
       TRIM(nombre_sede)                            AS nombre_sede,
       CAST(LPAD(TRIM(cod_dane_mpio), 5, '0') AS CHAR(5)) AS cod_dane_mpio,
       TRIM(regional)                               AS regional,
       CASE WHEN TRIM(fecha_apertura) ~ '^\d{1,2}/\d{1,2}/\d{4}$'
            THEN TO_DATE(TRIM(fecha_apertura), 'DD/MM/YYYY')
            ELSE CAST(SUBSTRING(TRIM(fecha_apertura) FROM 1 FOR 10) AS DATE) END AS fecha_apertura,
       CASE WHEN CAST(REGEXP_REPLACE(radio_cobertura, '[^0-9.]', '', 'g') AS NUMERIC) > 500
            THEN CAST(REGEXP_REPLACE(radio_cobertura, '[^0-9.]', '', 'g') AS NUMERIC) / 1000
            ELSE CAST(REGEXP_REPLACE(radio_cobertura, '[^0-9.]', '', 'g') AS NUMERIC) END AS radio_km
FROM stg.stg_f4_sedes
WHERE id_sede IS NOT NULL;

INSERT INTO dw.dim_cobertura (estado_cobertura, id_sede_referencia, sede_referencia, regional_vigia,
                              radio_km, rango_distancia, fecha_inicio_vigencia)
SELECT e.estado, s.id_sede, s.nombre_sede, s.regional, s.radio_km,
       CASE e.estado WHEN 'Con sede'           THEN 'Mismo municipio'
                     WHEN 'Área de influencia' THEN '0 a ' || ROUND(s.radio_km) || ' km'
                     ELSE 'Más de ' || ROUND(s.radio_km) || ' km' END,
       s.fecha_apertura
FROM stg.tmp_sedes s
CROSS JOIN (VALUES ('Con sede', 1), ('Área de influencia', 2), ('Sin cobertura', 3)) AS e(estado, o)
ORDER BY s.id_sede, e.o;

-- Distancia (Haversine, km) de cada municipio a cada sede usando los centroides de F2.
DROP TABLE IF EXISTS stg.tmp_distancias;
CREATE TABLE stg.tmp_distancias AS
SELECT m.cod_dane_mpio, s.id_sede, s.cod_dane_mpio AS cod_sede, s.fecha_apertura, s.radio_km,
       2 * 6371 * ASIN(SQRT(
           POWER(SIN(RADIANS(m.latitud - c.latitud) / 2), 2) +
           COS(RADIANS(c.latitud)) * COS(RADIANS(m.latitud)) *
           POWER(SIN(RADIANS(m.longitud - c.longitud) / 2), 2))) AS distancia_km
FROM dw.dim_municipio m
CROSS JOIN stg.tmp_sedes s
JOIN dw.dim_municipio c ON c.cod_dane_mpio = s.cod_dane_mpio;
CREATE INDEX ix_tmp_dist ON stg.tmp_distancias (cod_dane_mpio, distancia_km);
CREATE INDEX ix_tmp_pob ON stg.tmp_poblacion (cod_dane_mpio, anio);
ANALYZE stg.tmp_distancias; ANALYZE stg.tmp_poblacion;


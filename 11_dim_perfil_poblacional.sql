-- 11_dim_perfil_poblacional.sql · Limpieza e integración stg -> dw (ejecutado por el trabajo de PDI después de t02_dim_perfil_poblacional.ktr)
TRUNCATE dw.dim_perfil_poblacional RESTART IDENTITY CASCADE;

-- ---------------------------------------------------------------- dim_perfil_poblacional
-- 4 categorías de tamaño x 3 tipos de ruralidad = 12 perfiles.
INSERT INTO dw.dim_perfil_poblacional (rango_poblacion, categoria_tamano, orden_tamano,
                                       rango_pct_cabecera, tipo_ruralidad)
SELECT t.rango, t.categoria, t.orden, r.rango, r.tipo
FROM (VALUES ('Menos de 20.000',     'Pequeño',    1),
             ('20.000 a 100.000',    'Mediano',    2),
             ('100.000 a 500.000',   'Intermedio', 3),
             ('Más de 500.000',      'Grande',     4)) AS t(rango, categoria, orden)
CROSS JOIN (VALUES ('Menos de 40%',  'Predominantemente rural'),
                   ('40% a 70%',     'Mixto'),
                   ('70% o más',     'Predominantemente urbano')) AS r(rango, tipo)
ORDER BY t.orden, r.rango;

-- Población por municipio y año (F3): se usa 'Total' y 'Cabecera Municipal' por separado
-- para no mezclar el total con sus componentes (evita doble conteo).
DROP TABLE IF EXISTS stg.tmp_poblacion CASCADE;
CREATE TABLE stg.tmp_poblacion AS
SELECT CAST(LPAD(TRIM(mpio), 5, '0') AS CHAR(5)) AS cod_dane_mpio,
       anio,
       SUM(CASE WHEN UPPER(TRIM(area_geografica)) = 'TOTAL' THEN total END)              AS poblacion_total,
       SUM(CASE WHEN UPPER(TRIM(area_geografica)) = 'CABECERA MUNICIPAL' THEN total END) AS poblacion_cabecera
FROM stg.stg_f3_poblacion
WHERE mpio IS NOT NULL AND anio BETWEEN 2022 AND 2025
GROUP BY 1, 2;

ALTER TABLE stg.tmp_poblacion ADD COLUMN sk_perfil INTEGER;
UPDATE stg.tmp_poblacion p
SET sk_perfil = d.sk_perfil
FROM dw.dim_perfil_poblacional d
WHERE d.categoria_tamano = CASE WHEN p.poblacion_total <  20000  THEN 'Pequeño'
                                WHEN p.poblacion_total < 100000  THEN 'Mediano'
                                WHEN p.poblacion_total < 500000  THEN 'Intermedio'
                                ELSE 'Grande' END
  AND d.tipo_ruralidad = CASE WHEN COALESCE(p.poblacion_cabecera::NUMERIC / NULLIF(p.poblacion_total, 0), 0) <  0.40 THEN 'Predominantemente rural'
                              WHEN COALESCE(p.poblacion_cabecera::NUMERIC / NULLIF(p.poblacion_total, 0), 0) <  0.70 THEN 'Mixto'
                              ELSE 'Predominantemente urbano' END;


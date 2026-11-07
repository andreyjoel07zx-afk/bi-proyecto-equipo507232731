-- 05_carga_dw.sql · Transforma stg -> dw aplicando las reglas de limpieza (Tabla 2.3)
-- Orden: dim_municipio, dim_perfil_poblacional, dim_cobertura y al final fact_hurto_personas.
-- Requiere: 01 a 04 ejecutados y las 4 tablas stg cargadas.

TRUNCATE dw.fact_hurto_personas, dw.dim_municipio, dw.dim_perfil_poblacional, dw.dim_cobertura
    RESTART IDENTITY CASCADE;

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
DROP TABLE IF EXISTS stg.tmp_poblacion;
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

-- ---------------------------------------------------------------- fact_hurto_personas (F1 + F3)
-- Reglas: descartar COD_MUNI 'SIN ESTABLECER', fechas en dos formatos, periodo 2022-2025,
-- integrar solo por código DANE (se ignora el nombre de F1), agregar municipio x día.
DROP TABLE IF EXISTS stg.tmp_hechos;
CREATE TABLE stg.tmp_hechos AS
SELECT CAST(cod_dane_mpio AS CHAR(5)) AS cod_dane_mpio, fecha, SUM(cantidad) AS cantidad_victimas
FROM (
    SELECT LPAD(TRIM(cod_muni), 5, '0') AS cod_dane_mpio,
           CASE WHEN TRIM(fecha_hecho) ~ '^\d{1,2}/\d{1,2}/\d{4}$'
                THEN TO_DATE(TRIM(fecha_hecho), 'DD/MM/YYYY')
                ELSE CAST(SUBSTRING(TRIM(fecha_hecho) FROM 1 FOR 10) AS DATE) END AS fecha,
           CAST(cantidad AS INTEGER) AS cantidad
    FROM stg.stg_f1_hurto_personas
    WHERE UPPER(TRIM(cod_muni)) <> 'SIN ESTABLECER'
) f
WHERE fecha BETWEEN DATE '2022-01-01' AND DATE '2025-12-31'
GROUP BY 1, 2;
ANALYZE stg.tmp_hechos;

INSERT INTO dw.fact_hurto_personas (sk_tiempo, sk_municipio, sk_perfil, sk_cobertura,
                                    cantidad_victimas, poblacion_total, tasa_hurto_100k)
SELECT t.sk_tiempo,
       m.sk_municipio,
       p.sk_perfil,
       c.sk_cobertura,
       h.cantidad_victimas,
       p.poblacion_total,
       ROUND(h.cantidad_victimas * 100000.0 / NULLIF(p.poblacion_total, 0), 4)  -- NULL si el DANE reporta población 0
FROM stg.tmp_hechos h
JOIN dw.dim_tiempo    t ON t.fecha = h.fecha
JOIN dw.dim_municipio m ON m.cod_dane_mpio = h.cod_dane_mpio
JOIN stg.tmp_poblacion p ON p.cod_dane_mpio = h.cod_dane_mpio AND p.anio = t.anio
-- sede más cercana que ya estaba abierta en la fecha del hecho (SCD 2 por vigencia)
CROSS JOIN LATERAL (
    SELECT d.id_sede, d.cod_sede, d.radio_km, d.distancia_km
    FROM stg.tmp_distancias d
    WHERE d.cod_dane_mpio = h.cod_dane_mpio AND d.fecha_apertura <= h.fecha
    ORDER BY d.distancia_km
    LIMIT 1
) s
JOIN dw.dim_cobertura c
  ON c.id_sede_referencia = s.id_sede
 AND c.estado_cobertura = CASE WHEN s.cod_sede = h.cod_dane_mpio    THEN 'Con sede'
                               WHEN s.distancia_km <= s.radio_km    THEN 'Área de influencia'
                               ELSE 'Sin cobertura' END;

-- ---------------------------------------------------------------- vista para el tablero
-- Población municipio-año sin repetir por día (denominador correcto de la tasa en Power BI).
CREATE OR REPLACE VIEW dw.v_poblacion_municipio_anio AS
SELECT m.sk_municipio, p.anio, p.poblacion_total, p.poblacion_cabecera, p.sk_perfil
FROM stg.tmp_poblacion p
JOIN dw.dim_municipio m ON m.cod_dane_mpio = p.cod_dane_mpio;

SELECT 'dim_tiempo' AS tabla, COUNT(*) AS filas FROM dw.dim_tiempo
UNION ALL SELECT 'dim_municipio', COUNT(*) FROM dw.dim_municipio
UNION ALL SELECT 'dim_perfil_poblacional', COUNT(*) FROM dw.dim_perfil_poblacional
UNION ALL SELECT 'dim_cobertura', COUNT(*) FROM dw.dim_cobertura
UNION ALL SELECT 'fact_hurto_personas', COUNT(*) FROM dw.fact_hurto_personas;

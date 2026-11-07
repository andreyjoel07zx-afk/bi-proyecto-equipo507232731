-- 13_fact_hurto_personas.sql · Limpieza e integración stg -> dw (ejecutado por el trabajo de PDI después de t04_fact_hurto_personas.ktr)
TRUNCATE dw.fact_hurto_personas RESTART IDENTITY;

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


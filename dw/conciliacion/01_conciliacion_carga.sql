-- 01_conciliacion_carga.sql · Conteos y totales fuente (staging) vs. data warehouse

-- 1. F1 · leídos = cargados + descartados
SELECT COUNT(*)                                                             AS leidos_fuente,
       COUNT(*) FILTER (WHERE UPPER(TRIM(cod_muni)) = 'SIN ESTABLECER')      AS descartados_sin_codigo,
       COUNT(*) FILTER (WHERE UPPER(TRIM(cod_muni)) <> 'SIN ESTABLECER'
                          AND RIGHT(TRIM(fecha_hecho), 4) NOT IN ('2022','2023','2024','2025')) AS descartados_fuera_periodo,
       (SELECT COUNT(*) FROM dw.fact_hurto_personas)                         AS cargados_dw,
       COUNT(*) FILTER (WHERE UPPER(TRIM(cod_muni)) <> 'SIN ESTABLECER'
                          AND RIGHT(TRIM(fecha_hecho), 4) IN ('2022','2023','2024','2025')) AS validos_periodo,
       SUM(CAST(cantidad AS INTEGER)) FILTER (WHERE UPPER(TRIM(cod_muni)) <> 'SIN ESTABLECER'
                          AND RIGHT(TRIM(fecha_hecho), 4) IN ('2022','2023','2024','2025')) AS victimas_fuente,
       (SELECT SUM(cantidad_victimas) FROM dw.fact_hurto_personas)           AS victimas_dw
FROM stg.stg_f1_hurto_personas;

-- 2. Víctimas por año: fuente vs. DW (la diferencia debe ser 0)
SELECT s.anio, s.victimas_fuente, d.victimas_dw, s.victimas_fuente - d.victimas_dw AS diferencia
FROM (SELECT CAST(RIGHT(TRIM(fecha_hecho), 4) AS INTEGER) AS anio, SUM(CAST(cantidad AS INTEGER)) AS victimas_fuente
      FROM stg.stg_f1_hurto_personas
      WHERE UPPER(TRIM(cod_muni)) <> 'SIN ESTABLECER'
        AND RIGHT(TRIM(fecha_hecho), 4) IN ('2022','2023','2024','2025')
      GROUP BY 1) s
JOIN (SELECT t.anio, SUM(f.cantidad_victimas) AS victimas_dw
      FROM dw.fact_hurto_personas f JOIN dw.dim_tiempo t USING (sk_tiempo)
      GROUP BY 1) d ON d.anio = s.anio
ORDER BY 1;

-- 3. F2 · municipios DIVIPOLA vs. dim_municipio
SELECT 'F2 staging (leídos)' AS origen, COUNT(DISTINCT LPAD(TRIM(cod_mpio), 5, '0')) AS municipios FROM stg.stg_f2_divipola
UNION ALL
SELECT 'DW dim_municipio', COUNT(*) FROM dw.dim_municipio;

-- 4a. F3 · filas leídas y filas del periodo
SELECT COUNT(*) AS filas_leidas,
       COUNT(*) FILTER (WHERE mpio IS NOT NULL AND anio BETWEEN 2022 AND 2025) AS filas_2022_2025,
       COUNT(*) FILTER (WHERE mpio IS NOT NULL AND anio BETWEEN 2022 AND 2025
                          AND UPPER(TRIM(area_geografica)) = 'TOTAL')        AS filas_area_total
FROM stg.stg_f3_poblacion;

-- 4. F3 · población 'Total' por año: fuente vs. tabla de población usada por el DW
SELECT s.anio, s.poblacion_fuente, d.poblacion_dw, s.poblacion_fuente - d.poblacion_dw AS diferencia
FROM (SELECT anio, SUM(total) AS poblacion_fuente
      FROM stg.stg_f3_poblacion
      WHERE UPPER(TRIM(area_geografica)) = 'TOTAL' AND anio BETWEEN 2022 AND 2025
      GROUP BY 1) s
JOIN (SELECT anio, SUM(poblacion_total) AS poblacion_dw
      FROM dw.v_poblacion_municipio_anio GROUP BY 1) d USING (anio)
ORDER BY 1;

-- 5. F4 · sedes vs. dim_cobertura (5 sedes x 3 estados = 15)
SELECT 'F4 staging (leídos)' AS origen, COUNT(*) AS registros FROM stg.stg_f4_sedes
UNION ALL
SELECT 'DW dim_cobertura', COUNT(*) FROM dw.dim_cobertura;

-- 6. dim_tiempo · 1.461 días continuos
SELECT MIN(fecha) AS inicio, MAX(fecha) AS fin, COUNT(*) AS dias_cargados,
       1461 AS dias_esperados, COUNT(*) - 1461 AS diferencia
FROM dw.dim_tiempo;

-- 7. Integridad: hechos sin dimensión (debe dar 0 en todas)
SELECT COUNT(*) FILTER (WHERE t.sk_tiempo    IS NULL) AS sin_tiempo,
       COUNT(*) FILTER (WHERE m.sk_municipio IS NULL) AS sin_municipio,
       COUNT(*) FILTER (WHERE p.sk_perfil    IS NULL) AS sin_perfil,
       COUNT(*) FILTER (WHERE c.sk_cobertura IS NULL) AS sin_cobertura
FROM dw.fact_hurto_personas f
LEFT JOIN dw.dim_tiempo t USING (sk_tiempo)
LEFT JOIN dw.dim_municipio m USING (sk_municipio)
LEFT JOIN dw.dim_perfil_poblacional p USING (sk_perfil)
LEFT JOIN dw.dim_cobertura c USING (sk_cobertura);

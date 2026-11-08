-- modelo/extraccion.sql · Conjunto de datos para la pregunta P4 (Entrega 3)
-- Una fila por municipio y mes (enero 2022 - diciembre 2025), con las víctimas del mes
-- (0 cuando no hubo hechos) y los atributos de las dimensiones conocidos de antemano.
WITH meses AS (                       -- calendario mensual desde dim_tiempo
    SELECT anio, mes,
           MIN(sk_tiempo)                          AS sk_tiempo_mes,   -- primer día del mes
           SUM(CASE WHEN es_festivo    THEN 1 ELSE 0 END) AS dias_festivos,
           SUM(CASE WHEN es_fin_semana THEN 1 ELSE 0 END) AS dias_fin_semana
    FROM dw.dim_tiempo
    GROUP BY anio, mes
),
municipios AS (                       -- municipios con al menos un hecho en el periodo
    SELECT DISTINCT f.sk_municipio FROM dw.fact_hurto_personas f
),
victimas_mes AS (                     -- hechos agregados a municipio-mes
    SELECT f.sk_municipio, t.anio, t.mes, SUM(f.cantidad_victimas) AS victimas
    FROM dw.fact_hurto_personas f
    JOIN dw.dim_tiempo t ON t.sk_tiempo = f.sk_tiempo
    GROUP BY f.sk_municipio, t.anio, t.mes
),
atributos AS (                        -- perfil y cobertura más recientes de cada municipio
    SELECT DISTINCT ON (f.sk_municipio)
           f.sk_municipio, p.categoria_tamano, p.tipo_ruralidad, c.estado_cobertura
    FROM dw.fact_hurto_personas f
    JOIN dw.dim_tiempo t             ON t.sk_tiempo  = f.sk_tiempo
    JOIN dw.dim_perfil_poblacional p ON p.sk_perfil  = f.sk_perfil
    JOIN dw.dim_cobertura c          ON c.sk_cobertura = f.sk_cobertura
    ORDER BY f.sk_municipio, t.fecha DESC
)
SELECT m.sk_municipio, d.cod_dane_mpio, d.nombre_municipio, d.nombre_departamento, d.region,
       me.anio, me.mes, me.sk_tiempo_mes, me.dias_festivos, me.dias_fin_semana,
       a.categoria_tamano, a.tipo_ruralidad, a.estado_cobertura,
       po.poblacion_total,
       COALESCE(v.victimas, 0) AS victimas
FROM municipios m
CROSS JOIN meses me
JOIN dw.dim_municipio d ON d.sk_municipio = m.sk_municipio
JOIN atributos a        ON a.sk_municipio = m.sk_municipio
LEFT JOIN dw.v_poblacion_municipio_anio po
       ON po.sk_municipio = m.sk_municipio AND po.anio = me.anio
LEFT JOIN victimas_mes v
       ON v.sk_municipio = m.sk_municipio AND v.anio = me.anio AND v.mes = me.mes
ORDER BY m.sk_municipio, me.anio, me.mes;

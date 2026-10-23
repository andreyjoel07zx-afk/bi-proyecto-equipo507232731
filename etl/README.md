# ETL · Orden de ejecución y parámetros

La implementación se hace en la Entrega 2 con Pentaho Data Integration. Este es el orden planeado.

| Orden | Archivo | Tipo | Qué hace |
|---|---|---|---|
| 1 | `trabajos/job_carga_completa.kjb` | Trabajo | Ejecuta todas las transformaciones en orden y registra el log |
| 2 | `transformaciones/t01_stg_f1_hurtos.ktr` | Transformación | Lee el CSV de F1, filtra 2022-2025, descarta «SIN ESTABLECER» y carga stg |
| 3 | `transformaciones/t02_stg_f2_divipola.ktr` | Transformación | Lee el JSON de F2, cambia coma decimal por punto y carga stg |
| 4 | `transformaciones/t03_stg_f3_poblacion.ktr` | Transformación | Lee el XLSX de F3 desde la fila 8, normaliza códigos y separa el área «Total» |
| 5 | `transformaciones/t04_stg_f4_sedes.ktr` | Transformación | Lee el XLSX de F4, unifica fechas, códigos y unidades del radio |
| 6 | `transformaciones/t05_dim_tiempo.ktr` | Transformación | Genera la dimensión de tiempo 2022-2025 con festivos de Colombia |
| 7 | `transformaciones/t06_dimensiones.ktr` | Transformación | Carga dim_municipio, dim_perfil_poblacional y dim_cobertura |
| 8 | `transformaciones/t07_fact_hurto.ktr` | Transformación | Busca llaves sustitutas y carga fact_hurto_personas |

## Parámetros

| Parámetro | Valor | Uso |
|---|---|---|
| `RUTA_RAW` | `../datos/raw` | Carpeta de las fuentes originales |
| `DB_HOST` | `localhost` | Servidor PostgreSQL |
| `DB_NAME` | `dw_hurtos` | Base de datos del almacén |
| `ANIO_INICIO` | `2022` | Primer año a cargar |
| `ANIO_FIN` | `2025` | Último año a cargar |
| `RADIO_KM` | `50` | Distancia máxima para «Área de influencia» de una sede |

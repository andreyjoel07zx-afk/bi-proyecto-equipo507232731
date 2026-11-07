# ETL · Vigía Segura S.A.S. (Entrega 2)

## Motor y versiones

- Pentaho Data Integration (Spoon) 9.4.0.0-343, con el driver JDBC `postgresql-42.2.23.jar` incluido.
- Data warehouse en PostgreSQL (Neon, servicio en la nube). Base `neondb`, esquemas `stg` (staging) y `dw` (estrella).
- Administración y conciliación con DBeaver CE.

## Parámetros de conexión (sin contraseña)

La conexión `dw_neon` de todos los `.ktr` y del `.kjb` se arma con variables. Se definen en `%USERPROFILE%\.kettle\kettle.properties`:

```
DW_HOST=ep-tiny-mud-b61t0hrh.c-2.sa-east-1.aws.neon.tech
DW_PORT=5432
DW_DB=neondb
DW_USER=neondb_owner
DW_PASSWORD=<cada integrante escribe la suya; nunca se sube al repositorio>
```

La conexión usa `sslmode=require` y `reWriteBatchedInserts=true`.

## Ubicación esperada de las fuentes

Las rutas son relativas al repositorio (`${Internal.Entry.Current.Directory}/../../datos/raw/`):

| Archivo | Fuente |
|---|---|
| `datos/raw/F1_hurto_personas.csv` | F1, CSV de datos.gov.co, descomprimido desde `F1_hurto_personas.zip` |
| `datos/raw/F2_divipola.json` | F2, JSON de la API SODA del DANE |
| `datos/raw/F3_poblacion_municipal.xlsx` | F3, XLSX del DANE, hoja `PobMunicipalxÁrea` |
| `datos/raw/F4_sedes_vigia.xlsx` | F4, XLSX interno, hoja `Sedes` |

## Orden de ejecución (`etl/trabajos/job_carga_completa.kjb`)

| # | Entrada del trabajo | Qué hace |
|---|---|---|
| 1 | `01_esquemas.sql` | Crea los esquemas `stg` y `dw` |
| 2 | `02_staging.sql` | Crea las 4 tablas espejo de staging |
| 3 | `03_tablas_dw.sql` | Crea las 4 dimensiones y la tabla de hechos (PK y FK) |
| 4 | `04_dim_tiempo.sql` | Pobla `dim_tiempo` 2022-2025 (1.461 días, con festivos de Colombia) |
| 5 | `t01_dim_municipio.ktr` + `10_dim_municipio.sql` | F2 JSON → staging; código DANE con LPAD, coma decimal → punto, región |
| 6 | `t02_dim_perfil_poblacional.ktr` + `11_…sql` | F3 XLSX desde la fila 8 → staging; separa 'Total' y 'Cabecera'; 12 perfiles |
| 7 | `t03_dim_cobertura.ktr` + `12_…sql` | F4 XLSX → staging; LPAD al código, fechas en dos formatos, metros a km, Haversine, SCD 2 |
| 8 | `t04_fact_hurto_personas.ktr` + `13_…sql` | F1 CSV → staging; descarta 'SIN ESTABLECER' y años fuera de 2022-2025, agrega municipio × día y busca las llaves |

Cada transformación lee la fuente original y la carga sin modificar a su tabla `stg`. La entrada SQL que sigue aplica las reglas de limpieza e inserta en `dw`. Las dimensiones se cargan antes que los hechos.

Conciliación: `dw/conciliacion/01_conciliacion_carga.sql`.

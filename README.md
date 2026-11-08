# bi-proyecto-equipo507232731 · Vigía Segura S.A.S.

Proyecto final de Business Intelligence · Fundación Universitaria Konrad Lorenz
Docente: Leandro Pájaro Fuentes

## Caso

Vigía Segura S.A.S. es una empresa de seguridad privada (organización ficticia y verosímil) con cinco sedes en Bogotá, Medellín, Cali, Barranquilla y Bucaramanga. Su gerente comercial no puede decidir **en qué municipios abrir nuevas sedes ni en qué meses reforzar el servicio**, porque las cifras de hurto, la población y los códigos de municipios están en archivos separados que nadie ha integrado.

**Pregunta principal (P0):** ¿qué municipios sin sede de Vigía Segura tienen la mayor tasa de hurto a personas por cada 100.000 habitantes entre 2022 y 2025, y cómo evolucionó esa tasa año a año?

**Pregunta BA (P4, Entrega 3):** ¿cuántas víctimas se esperan por municipio en los próximos seis meses? Se responde con un modelo de regresión (bosque aleatorio, MAE 5,79 víctimas por municipio y mes) que pronostica 136.057 víctimas para enero-junio de 2026.

## Integrantes

| Nombre | Código |
|---|---|
| Laura Juliana López Loaiza | 507252008 |
| Andrey Joel Ordoñez Romero | 507232731 |
| Laura Jimena Cardenas Umaña | 507231704 |

## Fuentes de datos

| Id | Fuente | Formato | Origen |
|---|---|---|---|
| F1 | Hurto a personas, MinDefensa / Policía Nacional | CSV | [datos.gov.co 4rxi-8m8d](https://www.datos.gov.co/d/4rxi-8m8d) |
| F2 | DIVIPOLA, códigos de municipios, DANE | JSON (API SODA) | [datos.gov.co gdxc-w37w](https://www.datos.gov.co/d/gdxc-w37w) |
| F3 | Proyecciones de población municipal por área 2018-2042, DANE | XLSX | [dane.gov.co](https://www.dane.gov.co/index.php/estadisticas-por-tema/demografia-y-poblacion/proyecciones-de-poblacion) |
| F4 | Maestro de sedes de Vigía Segura | XLSX | **Datos sintéticos** creados por el equipo |

URL exacta, fecha de descarga, licencia y pasos: ver [`datos/descarga.md`](datos/descarga.md).

## Herramientas

- Integración (ETL): Pentaho Data Integration (Spoon)
- Almacén de datos: PostgreSQL en Neon (base `neondb`, esquemas `stg` y `dw`), administrado con DBeaver
- Usuario final: Power BI Desktop
- Modelo predictivo: Python (Jupyter Notebook, pandas, scikit-learn)
- Diagramas: draw.io

## Estructura del repositorio

```
bi-proyecto-equipo507232731/
├── README.md            caso, integrantes, herramientas y cómo reproducir
├── .gitignore
├── docs/
│   ├── entregas/        PDF de cada entrega (E1, E2, E3, final)
│   └── diagramas/       arquitectura y esquema dimensional: PNG + draw.io
├── datos/
│   ├── raw/             fuentes originales
│   ├── muestras/        20 filas por fuente, en CSV
│   ├── diccionarios/    un diccionario por fuente
│   └── descarga.md      URL, fecha y pasos para obtener cada fuente
├── dw/
│   ├── ddl/             scripts CREATE TABLE de dimensiones, hechos y predicciones (14_pred_*)
│   └── conciliacion/    consultas de conteo y totales por fuente
├── etl/
│   ├── transformaciones/ archivos .ktr de Pentaho
│   ├── trabajos/        archivos .kjb de Pentaho
│   └── README.md        orden de ejecución y parámetros
├── dashboard/           tablero_vigia_segura.pbix (3 páginas) y una captura por página
└── modelo/              notebook del modelo, extraccion.sql, requirements.txt y figuras
```

## Cómo reproducir

1. Descargar F1, F2 y F3 siguiendo `datos/descarga.md` y guardarlas en `datos/raw/` (F4 ya está incluida).
2. Crear la base en PostgreSQL (Neon) y ejecutar los scripts `01` a `04` de `dw/ddl/`.
3. Ejecutar el trabajo de Pentaho `etl/trabajos/job_carga_completa.kjb` siguiendo `etl/README.md`.
4. Validar la carga con `dw/conciliacion/01_conciliacion_carga.sql`.
5. Abrir `dashboard/tablero_vigia_segura.pbix` en Power BI Desktop y, si pide credenciales, conectarse a Neon (usuario `neondb_owner`).
6. Ejecutar el modelo predictivo (ver abajo).

## Modelo predictivo (Entrega 3)

**Ejecutar en Google Colab (recomendado)**

1. Abrir `https://colab.research.google.com/github/andreyjoel07zx-afk/bi-proyecto-equipo507232731/blob/main/modelo/modelo_prediccion_hurto.ipynb`.
2. *Entorno de ejecución → Ejecutar todo*. Cuando lo pida, escribir la contraseña del data warehouse (se lee con `getpass`, no se guarda). Los SQL se descargan del repositorio.

**Ejecutar en local (Jupyter)**

```bash
cd modelo
pip install -r requirements.txt
export DW_PASSWORD=...        # opcional; si no, el notebook la pide
jupyter nbconvert --to notebook --execute modelo_prediccion_hurto.ipynb   # o abrirlo y "Reiniciar y ejecutar todo"
```

Variables opcionales: `DW_HOST`, `DW_PORT`, `DW_DB`, `DW_USER`, `DW_SSLMODE` (por defecto apuntan a Neon). Ninguna contraseña se guarda en el repositorio.

**Qué hace el notebook:** extrae el conjunto municipio-mes con `modelo/extraccion.sql`, explora los datos, crea las variables derivadas (rezagos de 6 a 12 meses), entrena regresión lineal y bosque aleatorio con división temporal (entrenamiento hasta junio de 2025, prueba julio-diciembre de 2025), compara MAE y RMSE, pronostica enero-junio de 2026 y guarda las predicciones en `dw.pred_hurto_municipio_mes` (script `dw/ddl/14_pred_hurto_municipio_mes.sql`).

**Visualizar el modelo:** en Power BI, página **«Predicciones vs reales»** del tablero (`dashboard/captura_pagina3_predicciones.png`): víctimas reales frente a predichas por mes, MAE del modelo, pronóstico por municipio y filtros por periodo y región. Las figuras del notebook están en `modelo/figuras/`.

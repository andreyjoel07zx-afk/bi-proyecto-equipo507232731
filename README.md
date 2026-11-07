# bi-proyecto-equipo507232731 · Vigía Segura S.A.S.

Proyecto final de Business Intelligence · Fundación Universitaria Konrad Lorenz
Docente: Leandro Pájaro Fuentes

## Caso

Vigía Segura S.A.S. es una empresa de seguridad privada (organización ficticia y verosímil) con cinco sedes en Bogotá, Medellín, Cali, Barranquilla y Bucaramanga. Su gerente comercial no puede decidir **en qué municipios abrir nuevas sedes ni en qué meses reforzar el servicio**, porque las cifras de hurto, la población y los códigos de municipios están en archivos separados que nadie ha integrado.

**Pregunta principal (P0):** ¿qué municipios sin sede de Vigía Segura tienen la mayor tasa de hurto a personas por cada 100.000 habitantes entre 2022 y 2025, y cómo evolucionó esa tasa año a año?

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
- Almacén de datos: PostgreSQL 16, administrado con DBeaver
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
│   ├── ddl/             scripts CREATE TABLE de dimensiones y hechos
│   └── conciliacion/    consultas de conteo y totales por fuente
├── etl/
│   ├── transformaciones/ archivos .ktr de Pentaho
│   ├── trabajos/        archivos .kjb de Pentaho
│   └── README.md        orden de ejecución y parámetros
├── dashboard/           archivo .pbix o enlace publicado, y capturas
└── modelo/              notebooks de Python del modelo predictivo
```

## Cómo reproducir

1. Descargar F1, F2 y F3 siguiendo `datos/descarga.md` y guardarlas en `datos/raw/` (F4 ya está incluida).
2. Crear la base `dw_hurtos` en PostgreSQL y ejecutar los scripts de `dw/ddl/` (Entrega 2).
3. Ejecutar los trabajos de Pentaho en el orden de `etl/README.md` (Entrega 2).
4. Validar las cargas con las consultas de `dw/conciliacion/` (Entrega 2).
5. Abrir el tablero de `dashboard/` en Power BI (Entrega 3).
6. Ejecutar los notebooks de `modelo/` (entrega final).

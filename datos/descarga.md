# Descarga de fuentes

Registro de procedencia de cada fuente. Fecha de consulta y descarga: 21/10/2026.

## F1 · Hurto a personas (MinDefensa / Policía Nacional)

| Dato | Valor |
|---|---|
| Nombre del conjunto | HURTO PERSONAS |
| Publicador | Ministerio de Defensa Nacional, con datos del SIEDCO de la Policía Nacional |
| Ficha | https://www.datos.gov.co/d/4rxi-8m8d |
| URL de descarga | https://www.datos.gov.co/api/views/4rxi-8m8d/rows.csv?accessType=DOWNLOAD |
| Formato | CSV (separador coma, fecha dd/mm/aaaa) |
| Archivo | `datos/raw/F1_hurto_personas.csv` |
| Periodo del archivo | 01/01/2003 a 30/09/2026 (se usa 01/01/2022 a 31/12/2025) |
| Registros | 654.716 en el archivo completo; 174.407 en 2022-2025 |
| Licencia | Creative Commons Atribución-CompartirIgual 4.0 Internacional (CC BY-SA 4.0) |

Pasos:
1. Abrir la URL de descarga; el navegador baja el CSV completo.
2. Renombrarlo `F1_hurto_personas.csv` y guardarlo en `datos/raw/` sin modificarlo. El filtro de años lo hace el ETL.

## F2 · DIVIPOLA, códigos de municipios (DANE)

| Dato | Valor |
|---|---|
| Nombre del conjunto | DIVIPOLA- Códigos municipios |
| Publicador | DANE |
| Ficha | https://www.datos.gov.co/d/gdxc-w37w |
| URL de la API | https://www.datos.gov.co/resource/gdxc-w37w.json?$limit=2000 |
| Formato | JSON |
| Archivo | `datos/raw/F2_divipola.json` |
| Periodo | Corte al 30/12/2024 |
| Registros | 1.122 |
| Licencia | CC BY-SA 4.0 |

Pasos:
1. Abrir la URL de la API en el navegador (el parámetro `$limit=2000` trae todos los registros).
2. Guardar la página como `F2_divipola.json` en `datos/raw/`.

## F3 · Proyecciones de población municipal por área (DANE)

| Dato | Valor |
|---|---|
| Nombre | Serie municipal de población por área, 2018-2042 (base CNPV 2018) |
| Publicador | DANE |
| Página | https://www.dane.gov.co/index.php/estadisticas-por-tema/demografia-y-poblacion/proyecciones-de-poblacion |
| URL de descarga | https://www.dane.gov.co/files/censo2018/proyecciones-de-poblacion/Municipal/PPED-AreaMun-2018-2042_VP.xlsx |
| Formato | XLSX, hoja `PobMunicipalxÁrea`, encabezado en la fila 8 |
| Archivo | `datos/raw/F3_poblacion_municipal.xlsx` |
| Periodo | 2018 a 2042 (se usa 2022 a 2025) |
| Registros | Aprox. 84.200 filas municipio-año-área |
| Licencia | Uso libre citando la fuente (términos de uso de dane.gov.co) |

Pasos:
1. Abrir la URL de descarga; se baja el XLSX.
2. Renombrarlo `F3_poblacion_municipal.xlsx` y guardarlo en `datos/raw/` sin modificarlo.

## F4 · Maestro de sedes Vigía Segura (sintético)

| Dato | Valor |
|---|---|
| Procedencia | Creado por el equipo; la organización es ficticia |
| Formato | XLSX |
| Archivo | `datos/raw/F4_sedes_vigia.xlsx` (ya incluido) |
| Registros | 5 sedes |
| Licencia | Datos sintéticos del equipo, uso académico |
| Nota | Se introdujeron inconsistencias a propósito: códigos DANE sin cero inicial, fechas en dos formatos y radio de cobertura en km y en metros |

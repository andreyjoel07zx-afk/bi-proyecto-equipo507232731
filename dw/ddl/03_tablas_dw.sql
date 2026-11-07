-- 03_tablas_dw.sql · Esquema estrella: 4 dimensiones + tabla de hechos
-- Grano: víctimas de hurto a personas registradas en un municipio en un día.
DROP TABLE IF EXISTS dw.fact_hurto_personas, dw.dim_tiempo, dw.dim_municipio,
                     dw.dim_perfil_poblacional, dw.dim_cobertura CASCADE;

CREATE TABLE dw.dim_tiempo (
    sk_tiempo      INTEGER      PRIMARY KEY,          -- YYYYMMDD
    fecha          DATE         NOT NULL UNIQUE,
    dia            SMALLINT     NOT NULL,
    nombre_dia     VARCHAR(10)  NOT NULL,
    dia_semana     SMALLINT     NOT NULL,             -- 1 = lunes … 7 = domingo
    es_fin_semana  BOOLEAN      NOT NULL,
    es_festivo     BOOLEAN      NOT NULL,
    mes            SMALLINT     NOT NULL,
    nombre_mes     VARCHAR(10)  NOT NULL,
    trimestre      SMALLINT     NOT NULL,
    semestre       SMALLINT     NOT NULL,
    anio           SMALLINT     NOT NULL
);

CREATE TABLE dw.dim_municipio (
    sk_municipio         SERIAL        PRIMARY KEY,
    cod_dane_mpio        CHAR(5)       NOT NULL UNIQUE,   -- llave natural
    nombre_municipio     VARCHAR(80)   NOT NULL,
    cod_departamento     CHAR(2)       NOT NULL,
    nombre_departamento  VARCHAR(80)   NOT NULL,
    region               VARCHAR(20)   NOT NULL,
    tipo_municipio       VARCHAR(30)   NOT NULL,
    latitud              NUMERIC(9,6),
    longitud             NUMERIC(9,6)
);

CREATE TABLE dw.dim_perfil_poblacional (
    sk_perfil           SERIAL       PRIMARY KEY,
    rango_poblacion     VARCHAR(30)  NOT NULL,
    categoria_tamano    VARCHAR(30)  NOT NULL,
    orden_tamano        SMALLINT     NOT NULL,
    rango_pct_cabecera  VARCHAR(20)  NOT NULL,
    tipo_ruralidad      VARCHAR(30)  NOT NULL,
    UNIQUE (categoria_tamano, tipo_ruralidad)
);

CREATE TABLE dw.dim_cobertura (                      -- SCD tipo 2
    sk_cobertura           SERIAL       PRIMARY KEY,
    estado_cobertura       VARCHAR(25)  NOT NULL,    -- Con sede / Área de influencia / Sin cobertura
    id_sede_referencia     VARCHAR(5)   NOT NULL,
    sede_referencia        VARCHAR(60)  NOT NULL,
    regional_vigia         VARCHAR(30)  NOT NULL,
    radio_km               NUMERIC(6,1) NOT NULL,
    rango_distancia        VARCHAR(30)  NOT NULL,
    fecha_inicio_vigencia  DATE         NOT NULL,
    fecha_fin_vigencia     DATE         NOT NULL DEFAULT DATE '9999-12-31',
    version                SMALLINT     NOT NULL DEFAULT 1,
    es_actual              BOOLEAN      NOT NULL DEFAULT TRUE,
    UNIQUE (id_sede_referencia, estado_cobertura, version)
);

CREATE TABLE dw.fact_hurto_personas (
    sk_hecho           BIGSERIAL     PRIMARY KEY,
    sk_tiempo          INTEGER       NOT NULL REFERENCES dw.dim_tiempo(sk_tiempo),
    sk_municipio       INTEGER       NOT NULL REFERENCES dw.dim_municipio(sk_municipio),
    sk_perfil          INTEGER       NOT NULL REFERENCES dw.dim_perfil_poblacional(sk_perfil),
    sk_cobertura       INTEGER       NOT NULL REFERENCES dw.dim_cobertura(sk_cobertura),
    cantidad_victimas  INTEGER       NOT NULL,       -- aditiva
    poblacion_total    INTEGER       NOT NULL,       -- semiaditiva (municipio-año)
    tasa_hurto_100k    NUMERIC(12,4),                -- no aditiva (NULL si población = 0); se recalcula al agregar
    UNIQUE (sk_tiempo, sk_municipio)
);
CREATE INDEX ix_fact_municipio ON dw.fact_hurto_personas (sk_municipio);
CREATE INDEX ix_fact_cobertura ON dw.fact_hurto_personas (sk_cobertura);
CREATE INDEX ix_fact_perfil    ON dw.fact_hurto_personas (sk_perfil);

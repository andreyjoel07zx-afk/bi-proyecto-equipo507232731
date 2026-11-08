-- 14_pred_hurto_municipio_mes.sql · Tabla de predicciones del modelo (Entrega 3, pregunta P4)
-- Una fila por municipio y mes: prueba jul-dic 2025 (con valor real) y pronóstico ene-jun 2026.
DROP TABLE IF EXISTS dw.pred_hurto_municipio_mes;
CREATE TABLE dw.pred_hurto_municipio_mes (
    sk_municipio        INTEGER      NOT NULL REFERENCES dw.dim_municipio (sk_municipio),
    sk_tiempo           INTEGER      NULL     REFERENCES dw.dim_tiempo (sk_tiempo),  -- primer día del mes; NULL en 2026 (fuera de dim_tiempo)
    anio                SMALLINT     NOT NULL,
    mes                 SMALLINT     NOT NULL CHECK (mes BETWEEN 1 AND 12),
    tipo_periodo        VARCHAR(20)  NOT NULL,          -- 'Prueba 2025' | 'Pronóstico 2026'
    victimas_reales     INTEGER      NULL,              -- NULL en el pronóstico
    victimas_predichas  NUMERIC(10,2) NOT NULL,
    error_absoluto      NUMERIC(10,2) NULL,
    modelo              VARCHAR(40)  NOT NULL,
    fecha_carga         DATE         NOT NULL,
    PRIMARY KEY (sk_municipio, anio, mes)
);
CREATE INDEX ix_pred_tiempo ON dw.pred_hurto_municipio_mes (sk_tiempo);

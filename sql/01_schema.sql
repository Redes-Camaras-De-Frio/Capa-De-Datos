-- ============================================================
-- Sistema de Monitoreo de Cadena de Frío
-- 01_schema.sql — Creación de tablas
-- PostgreSQL 15+
-- ============================================================

-- Eliminar tablas en orden inverso (respeta FK)
DROP TABLE IF EXISTS alertas;
DROP TABLE IF EXISTS lecturas;
DROP TABLE IF EXISTS sensores;
DROP TABLE IF EXISTS camaras;
DROP TABLE IF EXISTS sedes;
DROP TABLE IF EXISTS usuarios;

-- ============================================================
-- AUTH
-- ============================================================

CREATE TABLE usuarios (
    id            SERIAL       PRIMARY KEY,
    nombre        VARCHAR(80)  NOT NULL,
    email         VARCHAR(120) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    rol           VARCHAR(20)  NOT NULL CHECK (rol IN ('admin', 'operador')),
    activo        BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- ============================================================
-- INFRAESTRUCTURA
-- ============================================================

CREATE TABLE sedes (
    id          SERIAL       PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL,
    tipo        VARCHAR(30)  NOT NULL CHECK (tipo IN ('farmacia', 'distribuidora', 'botica')),
    direccion   VARCHAR(200),
    created_at  TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE camaras (
    id          SERIAL       PRIMARY KEY,
    sede_id     INT          NOT NULL REFERENCES sedes(id),
    nombre      VARCHAR(80)  NOT NULL,
    temp_min    DECIMAL(5,2) NOT NULL,
    temp_max    DECIMAL(5,2) NOT NULL,
    activa      BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP    NOT NULL DEFAULT NOW(),
    CHECK (temp_min < temp_max)
);

-- ============================================================
-- MONITOREO
-- ============================================================

CREATE TABLE sensores (
    id          SERIAL      PRIMARY KEY,
    camara_id   INT         NOT NULL REFERENCES camaras(id),
    tipo        VARCHAR(30) NOT NULL CHECK (tipo IN ('temperatura', 'humedad', 'apertura', 'movimiento', 'agua', 'humo')),
    unidad      VARCHAR(10) NOT NULL,
    activo      BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE TABLE lecturas (
    id            BIGSERIAL      PRIMARY KEY,
    sensor_id     INT            NOT NULL REFERENCES sensores(id),
    valor         DECIMAL(10,4)  NOT NULL,
    registrado_en TIMESTAMP      NOT NULL DEFAULT NOW()
);

CREATE TABLE alertas (
    id           SERIAL       PRIMARY KEY,
    camara_id    INT          NOT NULL REFERENCES camaras(id),
    sensor_id    INT          REFERENCES sensores(id),
    lectura_id   BIGINT       REFERENCES lecturas(id),
    tipo         VARCHAR(30)  NOT NULL CHECK (tipo IN ('temp_alta', 'temp_baja', 'humedad_alta', 'apertura', 'movimiento', 'agua', 'humo', 'sin_senal')),
    mensaje      VARCHAR(255) NOT NULL,
    resuelta     BOOLEAN      NOT NULL DEFAULT FALSE,
    creado_en    TIMESTAMP    NOT NULL DEFAULT NOW(),
    resuelto_en  TIMESTAMP,
    resuelto_por INT          REFERENCES usuarios(id)
);

-- ============================================================
-- ÍNDICES
-- ============================================================

-- Lecturas: consultas frecuentes por sensor y por rango de tiempo
CREATE INDEX idx_lecturas_sensor_id     ON lecturas (sensor_id);
CREATE INDEX idx_lecturas_registrado_en ON lecturas (registrado_en DESC);

-- Alertas: filtrar por cámara y por estado de resolución
CREATE INDEX idx_alertas_camara_id ON alertas (camara_id);
CREATE INDEX idx_alertas_resuelta  ON alertas (resuelta);

-- ============================================================
-- ASIGNACIÓN USUARIO ↔ SEDE (tenencia múltiple)
-- ============================================================

CREATE TABLE usuario_sede (
    usuario_id INT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    sede_id    INT NOT NULL REFERENCES sedes(id) ON DELETE CASCADE,
    PRIMARY KEY (usuario_id, sede_id)
);

CREATE INDEX idx_usuario_sede_usuario_id ON usuario_sede (usuario_id);
CREATE INDEX idx_usuario_sede_sede_id    ON usuario_sede (sede_id);

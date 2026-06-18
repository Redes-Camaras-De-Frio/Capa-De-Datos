-- ============================================================
-- Sistema de Monitoreo de Cadena de Frío
-- 02_seed.sql — Datos iniciales
-- Ejecutar después de 01_schema.sql
-- ============================================================

-- ============================================================
-- USUARIOS
-- Contraseña de todos los usuarios de prueba: admin123
-- Hash generado con bcrypt (cost 10) — reemplazar en producción
-- ============================================================

INSERT INTO usuarios (nombre, email, password_hash, rol) VALUES
    ('Administrador',   'admin@farmacia.com',    '$2b$10$EAacrno6PkZhwRMaLt7NDeo3AKHHdELO845f2lwhFcIt7vMRdcnva', 'admin'),
    ('Operador Central','operador@farmacia.com', '$2b$10$EAacrno6PkZhwRMaLt7NDeo3AKHHdELO845f2lwhFcIt7vMRdcnva', 'operador'),
    ('Técnico',         'tecnico@farmacia.com',  '$2b$10$EAacrno6PkZhwRMaLt7NDeo3AKHHdELO845f2lwhFcIt7vMRdcnva', 'tecnico');

-- ============================================================
-- SEDES
-- ============================================================

INSERT INTO sedes (nombre, tipo, direccion) VALUES
    ('Farmacia Central',  'farmacia',     'Av. Principal 123, Lima'),
    ('Distribuidora Norte', 'distribuidora', 'Carretera Norte km 45, Lima');

-- ============================================================
-- CÁMARAS
-- Farmacia central: 1 cámara pequeña (2°C a 8°C — medicamentos refrigerados)
-- Distribuidora: 3 cámaras grandes (rangos distintos según producto)
-- ============================================================

INSERT INTO camaras (sede_id, nombre, temp_min, temp_max) VALUES
    (1, 'Cámara Farmacia Central',    2.00,  8.00),   -- id: 1
    (2, 'Cámara Grande 1 - Vacunas',  2.00,  8.00),   -- id: 2
    (2, 'Cámara Grande 2 - Biológicos', -20.00, -15.00), -- id: 3
    (2, 'Cámara Grande 3 - General',  2.00, 15.00);   -- id: 4

-- ============================================================
-- SENSORES
-- Farmacia (cámara 1): sensores básicos
-- Distribuidora (cámaras 2-4): sensores completos
-- ============================================================

-- ============================================================
-- ASIGNACIÓN USUARIO ↔ SEDE
-- Admin no se inserta (acceso total)
-- ============================================================

INSERT INTO usuario_sede (usuario_id, sede_id) VALUES
    (2, 1),   -- Operador Central → Farmacia Central
    (3, 2);   -- Técnico → Distribuidora Norte

-- ============================================================
-- SENSORES
-- ============================================================

INSERT INTO sensores (camara_id, tipo, unidad) VALUES
    -- Cámara 1: Farmacia Central
    (1, 'temperatura', '°C'),
    (1, 'humedad',     '%'),
    (1, 'apertura',    'bool'),

    -- Cámara 2: Distribuidora - Vacunas
    (2, 'temperatura', '°C'),
    (2, 'humedad',     '%'),
    (2, 'apertura',    'bool'),
    (2, 'movimiento',  'bool'),
    (2, 'agua',        'bool'),

    -- Cámara 3: Distribuidora - Biológicos
    (3, 'temperatura', '°C'),
    (3, 'humedad',     '%'),
    (3, 'apertura',    'bool'),
    (3, 'movimiento',  'bool'),
    (3, 'agua',        'bool'),
    (3, 'humo',        'bool'),

    -- Cámara 4: Distribuidora - General
    (4, 'temperatura', '°C'),
    (4, 'humedad',     '%'),
    (4, 'apertura',    'bool'),
    (4, 'movimiento',  'bool'),
    (4, 'agua',        'bool');

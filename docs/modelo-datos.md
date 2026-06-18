# Modelo de Datos — Sistema de Monitoreo de Cadena de Frío

## 1. Resumen del sistema

Sistema IoT para el monitoreo de temperatura en cámaras de frío de una farmacia central y tres sedes remotas (distribuidores). Registra lecturas periódicas, genera alertas ante valores fuera de rango y permite supervisión desde un dashboard.

---

## 2. Entidades principales

| Tabla      | Descripción                                                                       |
|------------|-----------------------------------------------------------------------------------|
| `usuarios` | Personas con acceso al sistema (admin, operador, técnico).                        |
| `sedes`    | Ubicaciones físicas: farmacias, boticas, distribuidores. Escalable sin límite.    |
| `camaras`  | Cámaras de frío registradas en cada sede, con su rango de temperatura permitido.  |
| `sensores` | Sensores instalados en cada cámara (temperatura, humedad, movimiento, luz, etc.). |
| `lecturas` | Registro histórico de valores por sensor. Un valor genérico por lectura.          |
| `alertas`  | Alertas generadas por cámara cuando un sensor reporta un valor fuera de rango.    |
| `usuario_sede` | Asignación muchos-a-muchos entre usuarios y sedes (control de acceso).              |

---

## 3. Modelo relacional

### 3.1 `usuarios`

| Columna         | Tipo          | Restricciones     | Descripción                                      |
|-----------------|---------------|-------------------|--------------------------------------------------|
| `id`            | SERIAL        | PK                | Identificador único.                             |
| `nombre`        | VARCHAR(80)   | NOT NULL          | Nombre completo del usuario.                     |
| `email`         | VARCHAR(120)  | NOT NULL, UNIQUE  | Correo electrónico para login.                   |
| `password_hash` | VARCHAR(255)  | NOT NULL          | Contraseña cifrada (bcrypt).                     |
| `rol`           | VARCHAR(20)   | NOT NULL          | Valores: `admin`, `operador`, `tecnico`.            |
| `activo`        | BOOLEAN       | NOT NULL, DEFAULT TRUE | Estado de la cuenta.                       |
| `created_at`    | TIMESTAMP     | DEFAULT NOW()     | Fecha de registro.                               |

---

### 3.2 `sedes`

| Columna      | Tipo          | Restricciones  | Descripción                                          |
|--------------|---------------|----------------|------------------------------------------------------|
| `id`         | SERIAL        | PK             | Identificador único.                                 |
| `nombre`     | VARCHAR(100)  | NOT NULL       | Ej.: "Farmacia Central", "Distribuidor Norte".       |
| `tipo`       | VARCHAR(30)   | NOT NULL       | Valores: `farmacia`, `distribuidora`, `botica`.      |
| `direccion`  | VARCHAR(200)  | NULL           | Dirección física (opcional).                         |
| `created_at` | TIMESTAMP     | DEFAULT NOW()  | Fecha de registro.                                   |

---

### 3.3 `camaras`

| Columna      | Tipo          | Restricciones     | Descripción                                        |
|--------------|---------------|-------------------|----------------------------------------------------|
| `id`         | SERIAL        | PK                | Identificador único.                               |
| `sede_id`    | INT           | NOT NULL, FK      | Sede a la que pertenece la cámara.                 |
| `nombre`     | VARCHAR(80)   | NOT NULL          | Nombre descriptivo. Ej.: "Cámara A - Vacunas".     |
| `temp_min`   | DECIMAL(5,2)  | NOT NULL          | Temperatura mínima permitida en °C.                |
| `temp_max`   | DECIMAL(5,2)  | NOT NULL          | Temperatura máxima permitida en °C.                |
| `activa`     | BOOLEAN       | NOT NULL, DEFAULT TRUE | Indica si la cámara está operativa.          |
| `created_at` | TIMESTAMP     | DEFAULT NOW()     | Fecha de registro.                                 |

---

### 3.4 `sensores`

| Columna      | Tipo         | Restricciones      | Descripción                                                        |
|--------------|--------------|--------------------|--------------------------------------------------------------------|
| `id`         | SERIAL       | PK                 | Identificador único.                                               |
| `camara_id`  | INT          | NOT NULL, FK       | Cámara donde está instalado el sensor.                             |
| `tipo`       | VARCHAR(30)  | NOT NULL           | Valores: `temperatura`, `humedad`, `apertura`, `movimiento`, `agua`, `humo`. |
| `unidad`     | VARCHAR(10)  | NOT NULL           | Unidad de medida según tipo: `°C`, `%`, `bool`.                   |
| `activo`     | BOOLEAN      | NOT NULL, DEFAULT TRUE | Indica si el sensor está operativo.                            |
| `created_at` | TIMESTAMP    | DEFAULT NOW()      | Fecha de registro.                                                 |

> **Catálogo de tipos:**
> | Tipo | Unidad | Descripción |
> |---|---|---|
> | `temperatura` | `°C` | Temperatura interior de la cámara. |
> | `humedad` | `%` | Humedad relativa interior. |
> | `apertura` | `bool` | Detecta si la puerta de la cámara está abierta (1) o cerrada (0). |
> | `movimiento` | `bool` | Detecta presencia o movimiento dentro de la cámara (1 = detectado). |
> | `agua` | `bool` | Detecta presencia de agua o fuga (1 = detectado). |
> | `humo` | `bool` | Detecta humo. Aplicable principalmente en sala de control, no en cámara de frío. |
>
> **Nota:** Un sensor humiture (DHT22) se registra como dos sensores lógicos: uno de `temperatura` y uno de `humedad`. El MCU envía dos lecturas por cada ciclo de medición.
>
> **Nota:** Los monitores/displays conectados al MCU son dispositivos de salida, no generan lecturas. No se registran en esta tabla.

---

### 3.5 `lecturas`

| Columna         | Tipo           | Restricciones | Descripción                                                      |
|-----------------|----------------|---------------|------------------------------------------------------------------|
| `id`            | BIGSERIAL      | PK            | Identificador único (BIGINT por volumen esperado).               |
| `sensor_id`     | INT            | NOT NULL, FK  | Sensor que generó la lectura.                                    |
| `valor`         | DECIMAL(10,4)  | NOT NULL      | Valor registrado. Su significado depende del `tipo` del sensor.  |
| `registrado_en` | TIMESTAMP      | NOT NULL      | Fecha y hora exacta de la lectura.                               |

> **Sobre el valor genérico:** temperatura = grados °C, humedad = porcentaje, movimiento/luz = 0 (inactivo) o 1 (activo).

> **Nota sobre volumen:** Con 4 cámaras, ~3 sensores cada una, y lecturas cada 5 minutos: ~3,500 filas/día (~1.2M/año). PostgreSQL lo maneja sin problema. Para producción se recomienda política de retención (ej.: conservar últimos 90 días).

---

### 3.6 `alertas`

| Columna        | Tipo          | Restricciones          | Descripción                                             |
|----------------|---------------|------------------------|---------------------------------------------------------|
| `id`           | SERIAL        | PK                     | Identificador único.                                    |
| `camara_id`    | INT           | NOT NULL, FK           | Cámara que originó la alerta.                           |
| `sensor_id`    | INT           | NULL, FK               | Sensor específico que disparó la alerta (opcional).     |
| `lectura_id`   | BIGINT        | NULL, FK               | Lectura puntual que disparó la alerta (opcional).       |
| `tipo`         | VARCHAR(30)   | NOT NULL               | Valores: `temp_alta`, `temp_baja`, `humedad_alta`, `apertura`, `movimiento`, `agua`, `humo`, `sin_senal`. |
| `mensaje`      | VARCHAR(255)  | NOT NULL               | Descripción legible de la alerta.                       |
| `resuelta`     | BOOLEAN       | NOT NULL, DEFAULT FALSE| Estado de la alerta.                                    |
| `creado_en`    | TIMESTAMP     | NOT NULL               | Momento en que se generó la alerta.                     |
| `resuelto_en`  | TIMESTAMP     | NULL                   | Momento en que fue marcada como resuelta.               |
| `resuelto_por` | INT           | NULL, FK               | Usuario que resolvió la alerta.                         |

---

### 3.7 `usuario_sede`

Tabla de asignación muchos-a-muchos entre usuarios y sedes. Controla qué sedes puede ver cada usuario.

| Columna      | Tipo    | Restricciones               | Descripción                                      |
|--------------|---------|-----------------------------|--------------------------------------------------|
| `usuario_id` | INT     | PK, FK → usuarios(id)       | Usuario asignado a la sede.                      |
| `sede_id`    | INT     | PK, FK → sedes(id)          | Sede a la que el usuario tiene acceso.           |

**Regla de negocio:**
- `admin` no tiene entradas en esta tabla → acceso total.
- `operador` / `tecnico` tiene una o más entradas → solo ve esas sedes.

---

## 4. Diagrama de relaciones (resumen)

```
usuarios (N) ◄──► (N) sedes   (a través de usuario_sede)
                         
sedes (1) ──── (N) camaras (1) ──── (N) sensores (1) ──── (N) lecturas
                       │                    │
                       └──── (N) alertas ◄──┘
                                   │
                                   ├──── (1) lecturas  [opcional]
                                   └──── (1) usuarios  [resuelto_por]
```

---

## 5. Decisiones de diseño

| Decisión | Justificación |
|---|---|
| `sedes` separado de `camaras` | Permite que una sede tenga más de una cámara. Escala sin cambios de esquema: se agrega una fila en `sedes`. |
| `sensores` como tabla propia | Permite agregar cualquier tipo de sensor (temperatura, humedad, movimiento, luz...) sin alterar el esquema. |
| `valor` genérico en `lecturas` | Un solo campo numérico sirve para todos los tipos de sensor. Booleanos se expresan como 0/1. |
| `BIGSERIAL` en `lecturas` | La tabla de lecturas es la de mayor crecimiento; BIGINT evita el límite de ~2 mil millones de INT. |
| `sensor_id` nullable en alertas | La alerta se origina en una cámara; el sensor es contexto adicional, no siempre disponible (ej.: sin señal). |
| `rol` como VARCHAR en `usuarios` | Tres roles fijos (`admin`, `operador`, `tecnico`). Suficiente para académico; en producción se normalizaría a tabla `roles`. |

---

## 6. Intervalos de lectura

| Entorno     | Intervalo sugerido | Variable de entorno    |
|-------------|-------------------|------------------------|
| Producción  | 300 seg (5 min)   | `INTERVALO_SEG=300`    |
| Demo/prueba | 10–20 seg         | `INTERVALO_SEG=10`     |

El script de simulación debe leer el intervalo desde la variable de entorno, **no hardcodearlo**.

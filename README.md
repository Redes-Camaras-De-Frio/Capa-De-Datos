# Capa de Datos — Sistema de Monitoreo de Cadena de Frío

Base de datos PostgreSQL del sistema IoT para monitoreo de temperatura en cámaras de frío.

## Tecnologías

- **PostgreSQL 15** — Base de datos relacional
- **pgAdmin 4** — Panel de administración visual

## Estructura

```
Capa_de_Datos/
├── sql/
│   ├── 01_schema.sql     # Creación de tablas con FKs, constraints e índices
│   └── 02_seed.sql       # Datos iniciales (usuarios, sedes, cámaras, sensores)
├── docs/
│   ├── modelo-datos.md   # Documentación detallada del modelo
│   └── diagrama-er.puml  # Diagrama entidad-relación
└── docker-compose.yml
```

## Inicio rápido

```bash
# Desde la raíz del proyecto
docker-compose up -d
```

O standalone:

```bash
docker-compose -f Capa_de_Datos/docker-compose.yml up -d
```

## Esquema

| Tabla | Descripción |
|---|---|
| `usuarios` | Personas con acceso al sistema (admin, operador) |
| `sedes` | Ubicaciones físicas (farmacias, distribuidoras, boticas) |
| `camaras` | Cámaras de frío con rango de temperatura permitido |
| `sensores` | Sensores por cámara (temperatura, humedad, apertura, etc.) |
| `lecturas` | Histórico de valores por sensor (~3500 filas/día) |
| `alertas` | Alertas generadas por valores fuera de rango |

## Usuarios de prueba

| Email | Password | Rol |
|---|---|---|
| admin@farmacia.com | admin123 | admin |
| operador@farmacia.com | admin123 | operador |

## Conexión

| Propiedad | Valor |
|---|---|
| Host | `localhost` |
| Puerto | `5433` |
| Base de datos | `cadena_frio` |
| Usuario | `postgres` |
| Password | `postgres` |
| pgAdmin | http://localhost:5050 |

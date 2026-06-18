require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  host:     process.env.DB_HOST     || 'localhost',
  port:     parseInt(process.env.DB_PORT) || 5432,
  database: process.env.DB_NAME     || 'cadena_frio',
  user:     process.env.DB_USER     || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
});

const INTERVALO_MS = parseInt(process.env.INTERVALO_SEG || '10') * 1000;

// ─── Generación de valores por tipo de sensor ────────────────────────────────

function generarValor(tipo, tempMin, tempMax) {
  switch (tipo) {
    case 'temperatura': {
      // 15% de probabilidad de salir del rango (para generar alertas en demo)
      if (Math.random() < 0.15) {
        return Math.random() < 0.5
          ? +(tempMin - (Math.random() * 3 + 0.5)).toFixed(2)
          : +(tempMax + (Math.random() * 3 + 0.5)).toFixed(2);
      }
      return +(tempMin + Math.random() * (tempMax - tempMin)).toFixed(2);
    }
    case 'humedad':
      // 85% del tiempo en rango normal, 15% alta
      return Math.random() < 0.15
        ? +(80 + Math.random() * 15).toFixed(2)
        : +(40 + Math.random() * 39).toFixed(2);
    case 'apertura':
      return Math.random() < 0.05 ? 1 : 0;   // 5%: puerta abierta
    case 'movimiento':
      return Math.random() < 0.08 ? 1 : 0;   // 8%: movimiento detectado
    case 'agua':
      return Math.random() < 0.03 ? 1 : 0;   // 3%: fuga detectada
    case 'humo':
      return Math.random() < 0.01 ? 1 : 0;   // 1%: humo detectado
    default:
      return 0;
  }
}

// ─── Evaluación de alertas ───────────────────────────────────────────────────

function evaluarAlerta(tipo, valor, tempMin, tempMax) {
  switch (tipo) {
    case 'temperatura':
      if (valor < tempMin)
        return { tipo: 'temp_baja',     mensaje: `Temperatura baja: ${valor}°C (mín. permitido: ${tempMin}°C)` };
      if (valor > tempMax)
        return { tipo: 'temp_alta',     mensaje: `Temperatura alta: ${valor}°C (máx. permitido: ${tempMax}°C)` };
      return null;
    case 'humedad':
      if (valor > 80)
        return { tipo: 'humedad_alta',  mensaje: `Humedad alta: ${valor}% (máx. permitido: 80%)` };
      return null;
    case 'apertura':
      if (valor === 1)
        return { tipo: 'apertura',      mensaje: 'Puerta de cámara abierta detectada.' };
      return null;
    case 'movimiento':
      if (valor === 1)
        return { tipo: 'movimiento',    mensaje: 'Movimiento detectado en cámara.' };
      return null;
    case 'agua':
      if (valor === 1)
        return { tipo: 'agua',          mensaje: 'Presencia de agua o fuga detectada.' };
      return null;
    case 'humo':
      if (valor === 1)
        return { tipo: 'humo',          mensaje: 'Humo detectado en cámara.' };
      return null;
    default:
      return null;
  }
}

// ─── Consulta de sensores activos ────────────────────────────────────────────

async function obtenerSensores() {
  const { rows } = await pool.query(`
    SELECT
      s.id,
      s.tipo,
      s.unidad,
      c.id       AS camara_id,
      c.nombre   AS camara_nombre,
      c.temp_min,
      c.temp_max,
      se.nombre  AS sede_nombre
    FROM sensores s
    JOIN camaras c  ON s.camara_id = c.id
    JOIN sedes   se ON c.sede_id   = se.id
    WHERE s.activo = true AND c.activa = true
    ORDER BY se.id, c.id, s.id
  `);
  return rows;
}

// ─── Ciclo de simulación ─────────────────────────────────────────────────────

async function simularCiclo() {
  const sensores = await obtenerSensores();
  const ahora = new Date();

  console.log(`\n[${ ahora.toISOString() }] — ${sensores.length} sensores activos`);
  console.log('─'.repeat(60));

  for (const sensor of sensores) {
    const tempMin = parseFloat(sensor.temp_min);
    const tempMax = parseFloat(sensor.temp_max);
    const valor   = generarValor(sensor.tipo, tempMin, tempMax);

    const { rows } = await pool.query(
      `INSERT INTO lecturas (sensor_id, valor, registrado_en)
       VALUES ($1, $2, $3) RETURNING id`,
      [sensor.id, valor, ahora]
    );
    const lecturaId = rows[0].id;

    const alerta = evaluarAlerta(sensor.tipo, valor, tempMin, tempMax);

    if (alerta) {
      await pool.query(
        `INSERT INTO alertas (camara_id, sensor_id, lectura_id, tipo, mensaje, creado_en)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [sensor.camara_id, sensor.id, lecturaId, alerta.tipo, alerta.mensaje, ahora]
      );
      console.log(`  ⚠  [${sensor.sede_nombre} / ${sensor.camara_nombre}] ${alerta.mensaje}`);
    } else {
      console.log(`  ✓  [${sensor.sede_nombre} / ${sensor.camara_nombre}] ${sensor.tipo}: ${valor} ${sensor.unidad}`);
    }
  }
}

// ─── Inicio ──────────────────────────────────────────────────────────────────

async function main() {
  try {
    await pool.query('SELECT 1');
    console.log('Conexión a PostgreSQL establecida.');
  } catch (err) {
    console.error('No se pudo conectar a PostgreSQL:', err.message);
    process.exit(1);
  }

  console.log(`Simulación iniciada — intervalo: ${INTERVALO_MS / 1000}s`);
  console.log('Presiona Ctrl+C para detener.');

  await simularCiclo();
  setInterval(simularCiclo, INTERVALO_MS);
}

main();

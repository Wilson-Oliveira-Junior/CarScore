import { Pool } from 'pg';
import { AnalysisInput, ScoreWeights, defaultWeights, normalizeWeights } from './score';

const connectionString = process.env.DATABASE_URL;

export const pool = new Pool(
  connectionString
    ? { connectionString }
    : {
        host: process.env.DB_HOST ?? 'localhost',
        port: Number(process.env.DB_PORT ?? 5432),
        user: process.env.DB_USER ?? 'carscore',
        password: process.env.DB_PASSWORD ?? 'carscore',
        database: process.env.DB_NAME ?? 'carscore',
      }
);

export async function initDb() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS analysis_weights (
      id INTEGER PRIMARY KEY,
      price DOUBLE PRECISION NOT NULL,
      fuel DOUBLE PRECISION NOT NULL,
      maintenance DOUBLE PRECISION NOT NULL,
      adequacy DOUBLE PRECISION NOT NULL,
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  `);

  await pool.query(`
    INSERT INTO analysis_weights (id, price, fuel, maintenance, adequacy)
    VALUES (1, $1, $2, $3, $4)
    ON CONFLICT (id) DO NOTHING;
  `, [defaultWeights.price, defaultWeights.fuel, defaultWeights.maintenance, defaultWeights.adequacy]);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS analysis_history (
      id BIGSERIAL PRIMARY KEY,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      vehicle_label TEXT NOT NULL,
      year INTEGER NOT NULL,
      asking_price DOUBLE PRECISION NOT NULL,
      km_per_month DOUBLE PRECISION NOT NULL,
      km_per_liter DOUBLE PRECISION NOT NULL,
      fuel_price_per_liter DOUBLE PRECISION NOT NULL,
      maintenance_monthly DOUBLE PRECISION NOT NULL,
      fuel_monthly DOUBLE PRECISION NOT NULL,
      monthly_total DOUBLE PRECISION NOT NULL,
      price_score INTEGER NOT NULL,
      fuel_score INTEGER NOT NULL,
      maintenance_score INTEGER NOT NULL,
      adequacy_score INTEGER NOT NULL,
      final_score INTEGER NOT NULL,
      label TEXT NOT NULL
    );
  `);
}

export async function getWeights(): Promise<ScoreWeights> {
  const { rows } = await pool.query(
    'SELECT price, fuel, maintenance, adequacy FROM analysis_weights WHERE id = 1'
  );

  if (rows.length === 0) {
    return defaultWeights;
  }

  return normalizeWeights({
    price: Number(rows[0].price),
    fuel: Number(rows[0].fuel),
    maintenance: Number(rows[0].maintenance),
    adequacy: Number(rows[0].adequacy),
  });
}

export async function updateWeights(weights: ScoreWeights): Promise<ScoreWeights> {
  const normalized = normalizeWeights(weights);
  await pool.query(
    `
      UPDATE analysis_weights
      SET price = $1, fuel = $2, maintenance = $3, adequacy = $4, updated_at = NOW()
      WHERE id = 1
    `,
    [normalized.price, normalized.fuel, normalized.maintenance, normalized.adequacy]
  );
  return normalized;
}

type PersistInput = {
  input: AnalysisInput;
  result: {
    fuelMonthly: number;
    monthlyTotal: number;
    pillars: {
      priceScore: number;
      fuelScore: number;
      maintenanceScore: number;
      adequacyScore: number;
    };
    finalScore: number;
    label: string;
  };
};

export async function insertAnalysis({ input, result }: PersistInput): Promise<number> {
  const { rows } = await pool.query(
    `
      INSERT INTO analysis_history (
        vehicle_label, year, asking_price, km_per_month, km_per_liter,
        fuel_price_per_liter, maintenance_monthly,
        fuel_monthly, monthly_total,
        price_score, fuel_score, maintenance_score, adequacy_score,
        final_score, label
      )
      VALUES (
        $1, $2, $3, $4, $5,
        $6, $7,
        $8, $9,
        $10, $11, $12, $13,
        $14, $15
      )
      RETURNING id
    `,
    [
      input.vehicleLabel,
      input.year,
      input.askingPrice,
      input.kmPerMonth,
      input.kmPerLiter,
      input.fuelPricePerLiter,
      input.maintenanceMonthly,
      result.fuelMonthly,
      result.monthlyTotal,
      result.pillars.priceScore,
      result.pillars.fuelScore,
      result.pillars.maintenanceScore,
      result.pillars.adequacyScore,
      result.finalScore,
      result.label,
    ]
  );

  return Number(rows[0].id);
}

export async function getAnalysisHistory(limit = 20) {
  const safeLimit = Math.max(1, Math.min(100, Number(limit) || 20));
  const { rows } = await pool.query(
    `
      SELECT
        id,
        created_at,
        vehicle_label,
        year,
        asking_price,
        monthly_total,
        final_score,
        label
      FROM analysis_history
      ORDER BY created_at DESC
      LIMIT $1
    `,
    [safeLimit]
  );

  return rows.map((row) => ({
    id: Number(row.id),
    createdAt: row.created_at,
    vehicleLabel: row.vehicle_label,
    year: Number(row.year),
    askingPrice: Number(row.asking_price),
    monthlyTotal: Number(row.monthly_total),
    finalScore: Number(row.final_score),
    label: row.label,
  }));
}

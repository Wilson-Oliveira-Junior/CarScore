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
      client_id TEXT,
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
      label TEXT NOT NULL,
      parts_score INTEGER,
      parts_label TEXT,
      parts_annual_cost DOUBLE PRECISION,
      parts_monthly_cost DOUBLE PRECISION,
      combined_score INTEGER,
      combined_label TEXT,
      combined_car_weight DOUBLE PRECISION,
      combined_parts_weight DOUBLE PRECISION
    );
  `);

  await pool.query(`ALTER TABLE analysis_history ADD COLUMN IF NOT EXISTS parts_score INTEGER;`);
  await pool.query(`ALTER TABLE analysis_history ADD COLUMN IF NOT EXISTS parts_label TEXT;`);
  await pool.query(`ALTER TABLE analysis_history ADD COLUMN IF NOT EXISTS parts_annual_cost DOUBLE PRECISION;`);
  await pool.query(`ALTER TABLE analysis_history ADD COLUMN IF NOT EXISTS parts_monthly_cost DOUBLE PRECISION;`);
  await pool.query(`ALTER TABLE analysis_history ADD COLUMN IF NOT EXISTS combined_score INTEGER;`);
  await pool.query(`ALTER TABLE analysis_history ADD COLUMN IF NOT EXISTS combined_label TEXT;`);
  await pool.query(`ALTER TABLE analysis_history ADD COLUMN IF NOT EXISTS combined_car_weight DOUBLE PRECISION;`);
  await pool.query(`ALTER TABLE analysis_history ADD COLUMN IF NOT EXISTS combined_parts_weight DOUBLE PRECISION;`);
  await pool.query(`ALTER TABLE analysis_history ADD COLUMN IF NOT EXISTS client_id TEXT;`);
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
  clientId?: string;
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
  parts?: {
    partsScore: number;
    label: string;
    annualPartsCost: number;
    monthlyPartsCost: number;
  };
  combined?: {
    score: number;
    label: string;
    weights: {
      car: number;
      parts: number;
    };
  };
};

export async function insertAnalysis({ clientId, input, result, parts, combined }: PersistInput): Promise<number> {
  const { rows } = await pool.query(
    `
      INSERT INTO analysis_history (
        client_id,
        vehicle_label, year, asking_price, km_per_month, km_per_liter,
        fuel_price_per_liter, maintenance_monthly,
        fuel_monthly, monthly_total,
        price_score, fuel_score, maintenance_score, adequacy_score,
        final_score, label,
        parts_score, parts_label, parts_annual_cost, parts_monthly_cost,
        combined_score, combined_label, combined_car_weight, combined_parts_weight
      )
      VALUES (
        $1, $2, $3, $4, $5, $6,
        $7, $8,
        $9, $10,
        $11, $12, $13, $14,
        $15, $16,
        $17, $18, $19, $20,
        $21, $22, $23, $24
      )
      RETURNING id
    `,
    [
      clientId ?? null,
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
      parts?.partsScore ?? null,
      parts?.label ?? null,
      parts?.annualPartsCost ?? null,
      parts?.monthlyPartsCost ?? null,
      combined?.score ?? null,
      combined?.label ?? null,
      combined?.weights.car ?? null,
      combined?.weights.parts ?? null,
    ]
  );

  return Number(rows[0].id);
}

export async function getAnalysisHistory(limit = 20, clientId?: string) {
  const safeLimit = Math.max(1, Math.min(100, Number(limit) || 20));
  const baseSelect = `
      SELECT
        id,
        created_at,
        client_id,
        vehicle_label,
        year,
        asking_price,
        monthly_total,
        final_score,
        label,
        parts_score,
        parts_label,
        parts_annual_cost,
        parts_monthly_cost,
        combined_score,
        combined_label,
        combined_car_weight,
        combined_parts_weight
      FROM analysis_history
  `;

  const hasClientFilter = typeof clientId === 'string' && clientId.trim().length > 0;
  const query = hasClientFilter
    ? `${baseSelect} WHERE client_id = $1 ORDER BY created_at DESC LIMIT $2`
    : `${baseSelect} ORDER BY created_at DESC LIMIT $1`;
  const params = hasClientFilter ? [clientId!.trim(), safeLimit] : [safeLimit];
  const { rows } = await pool.query(query, params);

  return rows.map((row) => ({
    id: Number(row.id),
    createdAt: row.created_at,
    clientId: row.client_id ?? null,
    vehicleLabel: row.vehicle_label,
    year: Number(row.year),
    askingPrice: Number(row.asking_price),
    monthlyTotal: Number(row.monthly_total),
    finalScore: Number(row.final_score),
    label: row.label,
    partsScore: row.parts_score != null ? Number(row.parts_score) : null,
    partsLabel: row.parts_label ?? null,
    partsAnnualCost: row.parts_annual_cost != null ? Number(row.parts_annual_cost) : null,
    partsMonthlyCost: row.parts_monthly_cost != null ? Number(row.parts_monthly_cost) : null,
    combinedScore: row.combined_score != null ? Number(row.combined_score) : null,
    combinedLabel: row.combined_label ?? null,
    combinedWeights:
      row.combined_car_weight != null && row.combined_parts_weight != null
        ? {
            car: Number(row.combined_car_weight),
            parts: Number(row.combined_parts_weight),
          }
        : null,
  }));
}

export async function clearAnalysisHistory(clientId?: string): Promise<number> {
  const hasClientFilter = typeof clientId === 'string' && clientId.trim().length > 0;
  const { rowCount } = hasClientFilter
    ? await pool.query(`DELETE FROM analysis_history WHERE client_id = $1`, [clientId!.trim()])
    : await pool.query(`DELETE FROM analysis_history`);

  return rowCount ?? 0;
}

/**
 * contracts.ts
 * Fonte única de verdade para todos os tipos e schemas da API CarScore v1.
 * Tanto o servidor quanto os testes importam daqui — nunca duplique tipos.
 */
import { z } from 'zod';

// ─── Entrada: análise de veículo ───────────────────────────────────────────
export const AnalysisInputSchema = z.object({
  /** Ex.: "Honda Civic" */
  vehicleLabel: z.string().min(3, 'vehicleLabel deve ter ao menos 3 caracteres'),

  /** Ano de fabricação */
  year: z
    .number()
    .int()
    .min(1950)
    .max(new Date().getFullYear() + 1),

  /** Preço pedido pelo vendedor (R$) */
  askingPrice: z.number().positive(),

  /** Quilometragem rodada por mês */
  kmPerMonth: z.number().positive(),

  /** Consumo médio do veículo (km/l) */
  kmPerLiter: z.number().positive(),

  /** Preço atual do combustível (R$/l) */
  fuelPricePerLiter: z.number().positive(),

  /** Estimativa mensal de manutenção (R$); padrão 0 */
  maintenanceMonthly: z.number().nonnegative().default(0),

  /**
   * Preço de referência FIPE obtido via /v1/vehicles/fipe-price (R$).
   * Quando informado, o score de preço usa esse valor em vez da heurística interna.
   */
  fipeReferencePrice: z.number().positive().optional(),
});

export type AnalysisInputContract = z.infer<typeof AnalysisInputSchema>;

// ─── Saída: pilares do score ───────────────────────────────────────────────
export type PillarsContract = {
  /** Score de preço (0–100): quão dentro da faixa de referência está o preço */
  priceScore: number;
  /** Score de combustível (0–100): impacto mensal no orçamento */
  fuelScore: number;
  /** Score de manutenção (0–100): custo mensal estimado */
  maintenanceScore: number;
  /** Score de adequação (0–100): compatibilidade entre perfil de uso e veículo */
  adequacyScore: number;
};

// ─── Saída: pesos normalizados usados no cálculo ──────────────────────────
export type WeightsContract = {
  price: number;
  fuel: number;
  maintenance: number;
  adequacy: number;
};

// ─── Saída: resultado completo da análise ─────────────────────────────────
export type AnalysisResultContract = {
  /** Gasto mensal estimado com combustível (R$) */
  fuelMonthly: number;
  /** Custo mensal total estimado: combustível + manutenção (R$) */
  monthlyTotal: number;
  pillars: PillarsContract;
  weights: WeightsContract;
  /** Score final de viabilidade (0–100) */
  finalScore: number;
  /**
   * Classificação textual:
   * - compra_saudavel    (80–100)
   * - viavel_com_atencao (60–79)
   * - alto_custo_para_perfil (40–59)
   * - nao_recomendado    (0–39)
   */
  label: 'compra_saudavel' | 'viavel_com_atencao' | 'alto_custo_para_perfil' | 'nao_recomendado';
};

// ─── Saída: envelope da resposta POST /v1/analysis/estimate ───────────────
export type AnalysisResponseContract = {
  input: AnalysisInputContract;
  result: AnalysisResultContract;
  meta: {
    analysisId: number;
  };
};

// ─── Entrada: atualização de pesos ────────────────────────────────────────
export const WeightsUpdateSchema = z.object({
  price: z.number().nonnegative(),
  fuel: z.number().nonnegative(),
  maintenance: z.number().nonnegative(),
  adequacy: z.number().nonnegative(),
});

export type WeightsUpdateContract = z.infer<typeof WeightsUpdateSchema>;

// ─── Saída: item de histórico ──────────────────────────────────────────────
export type HistoryItemContract = {
  id: number;
  createdAt: string; // ISO 8601
  vehicleLabel: string;
  year: number;
  askingPrice: number;
  finalScore: number;
  label: string;
  monthlyTotal: number;
};

// ─── Saída: envelope do histórico ─────────────────────────────────────────
export type HistoryResponseContract = {
  items: HistoryItemContract[];
  count: number;
};

// ─── Saída: envelope de pesos ─────────────────────────────────────────────
export type WeightsResponseContract = {
  weights: WeightsContract;
};

// ─── Erros padrão ──────────────────────────────────────────────────────────
export type ErrorResponseContract = {
  error: 'invalid_payload' | 'invalid_weights' | 'not_found' | 'internal_error';
  message?: string;
  details?: Record<string, unknown>;
};

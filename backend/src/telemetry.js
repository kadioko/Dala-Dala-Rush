import { isUuid, validRoute } from './validation.js';

const number = value => typeof value === 'number' && Number.isFinite(value) && value >= 0 && value <= 1e9;
const integer = value => number(value) && Number.isSafeInteger(value);
const boolean = value => typeof value === 'boolean';
const choice = values => value => values.includes(value);
const endReason = choice(['unknown', 'fuel', 'car', 'bodaboda', 'bajaji', 'truck', 'police', 'cone', 'barrier', 'pothole', 'tire', 'pedestrian', 'mbuzi']);
const run = { run_ref: isUuid, route: validRoute, score: integer, coins: integer, distance: number,
  elapsed: number, passengers: integer, dropoffs: integer, near_misses: integer,
  condition: choice(['day', 'dusk', 'night', 'rain']), continued: boolean, end_reason: endReason,
  goal_met: boolean, tutorial_stage: value => integer(value) && value <= 3, daily_route: boolean };
const tutorial = { stage: value => integer(value) && value >= 1 && value <= 3,
  step: value => integer(value) && value <= 2, step_reached: value => integer(value) && value <= 2 };
const moment = { route: validRoute, moment: choice(['fare_rush', 'boda_watch', 'truck_line', 'checkpoint_clear', 'fuel_scout', 'jam_breaker', 'highland_pass']), target_spawned: boolean };
const placement = choice(['continue_after_crash', 'double_coins']);
const schemas = {
  run_end: run, run_segment_end: run, run_settled: run,
  tutorial_stage_started: tutorial, tutorial_stage_finished: tutorial,
  tutorial_step_completed: tutorial, tutorial_attempt_finished: tutorial,
  online_leaderboard_submit: { success: boolean }, online_leaderboard_global: { success: boolean },
  online_leaderboard_friends: { success: boolean }, retention_return: { day: choice([1, 7]) },
  fuel_failure: { route: validRoute, elapsed: number, distance: number, tutorial_stage: run.tutorial_stage },
  route_moment_start: moment, route_moment_complete: moment, route_moment_timeout: moment,
  vehicle_unlocked: { vehicle: choice(['classic_blue', 'kariakoo_yellow', 'mwendokasi_red', 'night_bus', 'vip', 'old_school', 'simba_express', 'bongo_flava']), price: integer, runs: integer },
  ad_rewarded_requested: { placement, sdk_ready: boolean }, ad_rewarded_loaded: {},
  ad_rewarded_load_failed: {}, ad_rewarded_earned: { placement },
};

export function telemetryProperties(eventName, value, version = 1) {
  if (![1, 2].includes(version) || !value || typeof value !== 'object' || Array.isArray(value)) return null;
  const schema = schemas[eventName]; if (!schema) return null;
  const clean = {};
  for (const [key, item] of Object.entries(value)) {
    if (!Object.hasOwn(schema, key)) { if (version === 2) return null; continue; }
    if (!schema[key](item)) return null;
    clean[key] = item;
  }
  if (['run_settled', 'run_segment_end'].includes(eventName)
    && (!clean.run_ref || !clean.route || clean.score === undefined)) return null;
  return clean;
}

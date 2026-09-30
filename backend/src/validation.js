export const ROUTE_IDS = new Set([
  "kariakoo", "mwenge", "mbezi", "posta", "kigamboni", "ubungo",
]);
const BLOCKED_DISPLAY_NAME_ROLES = new Set([
	"admin", "administrator", "developer", "moderator", "official", "owner", "staff", "support", "system",
]);

export function isUuid(value) {
  return typeof value === "string"
    && /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

export function boundedInteger(value, minimum, maximum) {
  return typeof value === "number"
    && Number.isSafeInteger(value)
    && value >= minimum
    && value <= maximum;
}

export function validRoute(value) {
  return typeof value === "string" && ROUTE_IDS.has(value);
}

export function validDisplayName(value) {
	if (typeof value !== "string" || !/^[\p{L}\p{N}][\p{L}\p{N} ._-]{1,15}$/u.test(value)) return false;
	const words = value.normalize("NFKC").toLocaleLowerCase("en").split(/[ ._-]+/u);
	return !words.some((word) => BLOCKED_DISPLAY_NAME_ROLES.has(word));
}

export function jsonByteLength(value) {
  return Buffer.byteLength(JSON.stringify(value), "utf8");
}

export const TELEMETRY_EVENT_NAMES = new Set([
  "tutorial_stage_finished",
  "run_end",
  "online_leaderboard_submit",
  "online_leaderboard_global",
  "online_leaderboard_friends",
  "retention_return",
]);

export function validTelemetryEvent(value) {
  return typeof value === "string" && TELEMETRY_EVENT_NAMES.has(value);
}

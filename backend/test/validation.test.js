import test from "node:test";
import assert from "node:assert/strict";
import { boundedInteger, isUuid, jsonByteLength, validDisplayName, validRoute, validTelemetryEvent } from "../src/validation.js";

test("validates routes and bounded integers", () => {
  assert.equal(validRoute("kariakoo"), true);
  assert.equal(validRoute("unknown"), false);
  assert.equal(boundedInteger(25, 0, 30), true);
  assert.equal(boundedInteger(25.5, 0, 30), false);
});

test("validates installation IDs and snapshot sizes", () => {
  assert.equal(isUuid("f47ac10b-58cc-4372-a567-0e02b2c3d479"), true);
  assert.equal(isUuid("not-a-uuid"), false);
  assert.equal(jsonByteLength({ coins: 10 }) > 0, true);
});

test("validates concise public leaderboard names", () => {
	assert.equal(validDisplayName("Konda Juma"), true);
	assert.equal(validDisplayName("Official_Dereva"), false);
	assert.equal(validDisplayName("Admin"), false);
	assert.equal(validDisplayName("Officially Fast"), true);
  assert.equal(validDisplayName("A"), false);
  assert.equal(validDisplayName("name\nwith-break"), false);
  assert.equal(validDisplayName("this name is longer than sixteen"), false);
});

test("accepts only the documented minimal telemetry event names", () => {
  assert.equal(validTelemetryEvent("run_end"), true);
  assert.equal(validTelemetryEvent("tutorial_stage_finished"), true);
  assert.equal(validTelemetryEvent("player_name"), false);
});

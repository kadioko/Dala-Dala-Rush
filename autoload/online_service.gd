extends Node
## Optional Railway service seam for future cloud backups, server-side referral
## gates, and an unverified global leaderboard. Every online feature remains
## behind its own explicit in-game consent; the game is fully playable offline.

signal request_finished(operation: String, success: bool, payload: Dictionary)

## A server URL is public; never put a database URL, Railway token, or service
## secret in the client. This release switch enables phone testing of the
## consent-gated features against the reviewed HTTPS endpoint.
const API_BASE_URL := "https://dala-dala-api-production.up.railway.app"
const RELEASE_CLOUD_SYNC_ENABLED := true
const MAX_SNAPSHOT_BYTES := 65536
const REQUEST_TIMEOUT_SECONDS := 12.0
const MAX_RESPONSE_BYTES := 131072
const Ids := preload("res://data/operation_ids.gd")
const PRIVATE_LOCAL_KEYS: Array[String] = [
	"leaderboard", "referral_invite_code", "referral_welcome_claimed",
	"referral_inviter_code", "referral_confirmation_code",
	"referral_claimed_invitees", "referral_success_count",
	"analytics_first_open_unix", "analytics_last_open_unix",
	"analytics_session_count", "online_installation_id", "online_sync_token",
	"online_cloud_revision", "cloud_sync_opt_in", "leaderboard_display_name",
	"online_leaderboard_opt_in", "pending_leaderboard_submissions",
	"leaderboard_cache", "online_telemetry_opt_in", "leaderboard_upload_status",
	"leaderboard_upload_route", "leaderboard_upload_score", "leaderboard_upload_updated_at",
	"online_pending_cloud_upload",
	"online_pending_transfer", "active_run_id", "last_reward_receipt",
	"ghost_best", "ghost_rival", "latest_replay", "daily_replay_best", "hub_presence_opt_in",
]

var _submission_in_flight: bool = false
var _registration_in_flight: bool = false
var _submission_retry_after_unix: int = 0
var _cloud_upload_in_flight: bool = false
var _telemetry_in_flight: bool = false
var _leaderboard_epoch: int = 0
var _transfer_in_flight: bool = false

func _ready() -> void:
	call_deferred("retry_pending_leaderboard_submissions")
	call_deferred("retry_pending_transfer")

func is_enabled() -> bool:
	return API_BASE_URL.begins_with("https://") \
		and (OS.is_debug_build() or RELEASE_CLOUD_SYNC_ENABLED)

func is_release_rollout_enabled() -> bool:
	return API_BASE_URL.begins_with("https://") and RELEASE_CLOUD_SYNC_ENABLED

func has_identity() -> bool:
	return not String(SaveSystem.get_value("online_installation_id", "")).is_empty() \
		and not String(SaveSystem.get_value("online_sync_token", "")).is_empty()

## The app must call this from an explicit future cloud-sync setting. It never
## runs automatically at startup or after a game-over screen.
func register_installation() -> void:
	if not is_enabled():
		_finish("registration", false, {"reason": "disabled"})
		return
	if _registration_in_flight:
		return
	_registration_in_flight = true
	_request_json("/v1/installations", HTTPClient.METHOD_POST, {}, "registration", false)

## Starts an intentional cloud backup. The snapshot excludes offline referral
## codes, local analytics, local leaderboard names, and the sync credential.
func upload_cloud_save() -> void:
	if _cloud_upload_in_flight:
		return
	if not is_enabled() or not has_identity():
		_finish("cloud_upload", false, {"reason": "not_ready"})
		return
	var snapshot: Dictionary = cloud_snapshot(SaveSystem.data)
	var encoded: PackedByteArray = JSON.stringify(snapshot).to_utf8_buffer()
	if encoded.size() > MAX_SNAPSHOT_BYTES:
		_finish("cloud_upload", false, {"reason": "snapshot_too_large"})
		return
	var pending: Dictionary = prepare_cloud_upload(snapshot,
		SaveSystem.get_value("online_pending_cloud_upload", {}),
		int(SaveSystem.get_value("online_cloud_revision", 0)))
	if pending.has("conflict_revision"):
		_finish("cloud_upload", false, {"error": "stale_revision", "currentRevision": pending.conflict_revision})
		return
	SaveSystem.set_value("online_pending_cloud_upload", pending)
	if SaveSystem.last_save_error != OK:
		_finish("cloud_upload", false, {"error": "save_failed"})
		return
	_cloud_upload_in_flight = true
	_request_json("/v1/cloud-save", HTTPClient.METHOD_POST, pending, "cloud_upload", true,
		{"sent_snapshot": pending.save.duplicate(true), "operation_id": pending.operationId,
		"sent_revision": pending.revision})

static func prepare_cloud_upload(snapshot: Dictionary, pending: Variant, revision: int) -> Dictionary:
	if pending is Dictionary and Ids.is_valid(pending.get("operationId")) \
	and pending.get("save") is Dictionary and valid_revision(pending.get("baseRevision")) \
	and valid_revision(pending.get("revision")) \
	and int(pending.revision) == int(pending.baseRevision) + 1:
		return (pending as Dictionary).duplicate(true)
	return {"operationId": Ids.create(), "baseRevision": maxi(0, revision),
		"revision": maxi(0, revision) + 1, "save": snapshot.duplicate(true)}

func resolve_cloud_conflict() -> void:
	var pending: Dictionary = SaveSystem.get_value("online_pending_cloud_upload", {})
	if not valid_revision(pending.get("conflict_revision")):
		return
	SaveSystem.set_value("online_pending_cloud_upload", prepare_cloud_upload(
		cloud_snapshot(SaveSystem.data), {}, int(pending.conflict_revision)))
	upload_cloud_save()

func download_cloud_save() -> void:
	if not is_enabled() or not has_identity():
		_finish("cloud_download", false, {"reason": "not_ready"})
		return
	_request_json("/v1/cloud-save", HTTPClient.METHOD_GET, {}, "cloud_download", true)

## Permanently removes this device's online record. Local game progress stays
## on the phone; players can keep playing offline immediately afterward.
func delete_online_account() -> void:
	if not is_enabled() or not has_identity():
		_finish("account_delete", false, {"reason": "not_ready"})
		return
	# Invalidate callbacks from a separate handover before deleting this identity.
	SaveSystem.set_value("online_pending_transfer", {})
	_transfer_in_flight = false
	if SaveSystem._batch_depth != 0 or SaveSystem.last_save_error != OK:
		_finish("account_delete", false, {"error": "save_failed"})
		return
	_request_json("/v1/account", HTTPClient.METHOD_DELETE, {}, "account_delete", true)

func create_transfer_code() -> void:
	if not is_enabled() or not has_identity():
		_finish("transfer_code", false, {"reason": "not_ready"})
		return
	_request_json("/v1/account/transfer-code", HTTPClient.METHOD_POST, {}, "transfer_code", true)

func claim_transfer_code(raw_code: String) -> void:
	if _transfer_in_flight:
		return
	if not is_enabled():
		_finish("transfer_claim", false, {"reason": "disabled"})
		return
	var transfer_code: String = raw_code.strip_edges().to_upper()
	if transfer_code.is_empty():
		_finish("transfer_claim", false, {"reason": "invalid_code"})
		return
	var pending: Dictionary = SaveSystem.get_value("online_pending_transfer", {})
	if pending.get("transferCode") != transfer_code or not Ids.is_valid(pending.get("operationId")):
		if not pending.is_empty():
			_finish("transfer_claim", false, {"error": "transfer_claim_in_progress"})
			return
		pending = {"transferCode": transfer_code, "operationId": Ids.create(),
			"syncToken": Marshalls.raw_to_base64(Crypto.new().generate_random_bytes(32)).replace("+", "-").replace("/", "_").trim_suffix("=")}
	SaveSystem.set_value("online_pending_transfer", pending)
	if SaveSystem._batch_depth != 0 or SaveSystem.last_save_error != OK:
		_finish("transfer_claim", false, {"error": "save_failed"})
		return
	_transfer_in_flight = true
	_request_json("/v2/account/claim-transfer", HTTPClient.METHOD_POST,
		pending, "transfer_claim", false, {"transfer_operation": pending.operationId})

func retry_pending_transfer() -> void:
	if _transfer_in_flight or not is_enabled():
		return
	var pending: Dictionary = SaveSystem.get_value("online_pending_transfer", {})
	if not Ids.is_valid(pending.get("operationId")) or pending.get("syncToken") is not String:
		return
	if not Ids.is_valid(pending.get("installationId")):
		claim_transfer_code(String(pending.get("transferCode", "")))
		return
	SaveSystem.set_value("online_pending_transfer", pending)
	if SaveSystem._batch_depth != 0 or SaveSystem.last_save_error != OK:
		_finish("transfer_ack", false, {"error": "save_failed"})
		return
	_transfer_in_flight = true
	_request_json("/v2/account/acknowledge-transfer", HTTPClient.METHOD_POST,
		{"installationId": pending.installationId, "operationId": pending.operationId, "syncToken": pending.syncToken},
		"transfer_ack", false, {"transfer_operation": pending.operationId})

## Online competition is opt-in and has no rewards. Scores remain labelled
## unverified until the game has server-side run verification.
func update_leaderboard_profile(raw_name: String) -> void:
	if not is_enabled() or not has_identity():
		_finish("leaderboard_profile", false, {"reason": "not_ready"})
		return
	var display_name: String = SaveSystem.normalize_leaderboard_name(raw_name)
	_request_json("/v1/leaderboard-profile", HTTPClient.METHOD_PUT,
		{"displayName": display_name}, "leaderboard_profile", true)

func submit_leaderboard_score(route_id: String, score: int) -> void:
	if not is_enabled() or not has_identity() or not SaveSystem.is_online_leaderboard_opted_in():
		_finish("leaderboard_submit", false, {"reason": "not_ready"})
		return
	_request_json("/v1/leaderboards/unverified", HTTPClient.METHOD_POST,
		{"routeId": route_id, "score": maxi(0, score),
		"displayName": SaveSystem.get_leaderboard_display_name()}, "leaderboard_submit", true,
		{"route_id": route_id, "submitted_score": maxi(0, score)})

## Every route personal best may be submitted online. This is intentionally
## independent of the offline Top-5 table, which is only a local display.
func queue_leaderboard_submission(route_id: String, score: int) -> void:
	if not SaveSystem.queue_leaderboard_submission(route_id, score):
		return
	retry_pending_leaderboard_submissions()

func retry_pending_leaderboard_submissions() -> void:
	if _submission_in_flight or not is_enabled() or not has_identity() \
			or not SaveSystem.is_online_leaderboard_opted_in():
		return
	if leaderboard_submission_wait_seconds() > 0:
		return
	var pending: Array = SaveSystem.get_pending_leaderboard_submissions()
	if pending.is_empty():
		return
	var entry: Dictionary = pending[0] as Dictionary
	_submission_in_flight = true
	submit_leaderboard_score(String(entry.get("route", "kariakoo")), int(entry.get("score", 0)))

func leaderboard_submission_wait_seconds() -> int:
	return maxi(0, _submission_retry_after_unix - int(Time.get_unix_time_from_system()))

func queue_existing_route_personal_bests() -> void:
	for route_id in ["kariakoo", "mwenge", "mbezi", "posta", "kigamboni", "ubungo", "arusha"]:
		var score: int = SaveSystem.get_route_best(route_id)
		if score > 0:
			SaveSystem.queue_leaderboard_submission(route_id, score)
	retry_pending_leaderboard_submissions()

func pending_leaderboard_submission_count() -> int:
	return SaveSystem.get_pending_leaderboard_submissions().size()

func fetch_global_leaderboard(route_id: String, request_id: int = 0) -> void:
	if not is_enabled():
		_finish("leaderboard_global", false, {"reason": "disabled"})
		return
	_request_json("/v1/leaderboards/unverified/" + route_id.uri_encode(),
		HTTPClient.METHOD_GET, {}, "leaderboard_global", false,
		{"route_id": route_id, "request_id": request_id, "tab_id": "world"})
	if has_identity() and SaveSystem.is_online_leaderboard_opted_in():
		_request_json("/v1/leaderboards/nearby/" + route_id.uri_encode(),
			HTTPClient.METHOD_GET, {}, "leaderboard_nearby", true,
			{"route_id": route_id, "request_id": request_id, "tab_id": "world"})

func create_leaderboard_friend_code() -> void:
	if not is_enabled() or not has_identity() or not SaveSystem.is_online_leaderboard_opted_in():
		_finish("leaderboard_friend_code", false, {"reason": "not_ready"})
		return
	_request_json("/v1/leaderboards/friends/invite", HTTPClient.METHOD_POST, {},
		"leaderboard_friend_code", true)

func claim_leaderboard_friend_code(raw_code: String) -> void:
	if not is_enabled() or not has_identity() or not SaveSystem.is_online_leaderboard_opted_in():
		_finish("leaderboard_friend_claim", false, {"reason": "not_ready"})
		return
	var invite_code: String = raw_code.strip_edges().to_upper().replace(" ", "")
	if invite_code.is_empty():
		_finish("leaderboard_friend_claim", false, {"reason": "invalid_code"})
		return
	_request_json("/v1/leaderboards/friends/claim", HTTPClient.METHOD_POST,
		{"inviteCode": invite_code}, "leaderboard_friend_claim", true)

func fetch_friends_leaderboard(route_id: String, request_id: int = 0) -> void:
	if not is_enabled() or not has_identity() or not SaveSystem.is_online_leaderboard_opted_in():
		_finish("leaderboard_friends", false, {"reason": "not_ready"})
		return
	_request_json("/v1/leaderboards/friends/" + route_id.uri_encode(),
		HTTPClient.METHOD_GET, {}, "leaderboard_friends", true,
		{"route_id": route_id, "request_id": request_id, "tab_id": "friends"})

func fetch_leaderboard_friends(request_id: int = 0) -> void:
	if not is_enabled() or not has_identity() or not SaveSystem.is_online_leaderboard_opted_in():
		_finish("leaderboard_friend_list", false, {"reason": "not_ready", "request_id": request_id})
		return
	_request_json("/v1/leaderboards/friends", HTTPClient.METHOD_GET, {},
		"leaderboard_friend_list", true, {"request_id": request_id})

func fetch_leaderboard_blocks() -> void:
	if not is_enabled() or not has_identity() or not SaveSystem.is_online_leaderboard_opted_in():
		_finish("leaderboard_block_list", false, {"reason": "not_ready"})
		return
	_request_json("/v1/leaderboards/blocks", HTTPClient.METHOD_GET, {},
		"leaderboard_block_list", true)

func unblock_leaderboard_friend(friend_id: String) -> void:
	if not is_enabled() or not has_identity() or not SaveSystem.is_online_leaderboard_opted_in():
		_finish("leaderboard_friend_unblock", false, {"reason": "not_ready"})
		return
	_request_json("/v1/leaderboards/blocks/" + friend_id.uri_encode(),
		HTTPClient.METHOD_DELETE, {}, "leaderboard_friend_unblock", true,
		{"friend_id": friend_id})

func remove_leaderboard_friend(friend_id: String) -> void:
	if not is_enabled() or not has_identity() or not SaveSystem.is_online_leaderboard_opted_in():
		_finish("leaderboard_friend_remove", false, {"reason": "not_ready"})
		return
	_request_json("/v1/leaderboards/friends/" + friend_id.uri_encode(),
		HTTPClient.METHOD_DELETE, {}, "leaderboard_friend_remove", true,
		{"friend_id": friend_id})

func block_leaderboard_friend(friend_id: String) -> void:
	if not is_enabled() or not has_identity() or not SaveSystem.is_online_leaderboard_opted_in():
		_finish("leaderboard_friend_block", false, {"reason": "not_ready"})
		return
	_request_json("/v1/leaderboards/blocks/" + friend_id.uri_encode(),
		HTTPClient.METHOD_POST, {}, "leaderboard_friend_block", true,
		{"friend_id": friend_id})

func report_leaderboard_entry(report_ref: String, route_id: String, reason: String) -> void:
	if not is_enabled() or not has_identity() or not SaveSystem.is_online_leaderboard_opted_in():
		_finish("leaderboard_report", false, {"reason": "not_ready"})
		return
	_request_json("/v1/leaderboards/reports", HTTPClient.METHOD_POST,
		{"reportRef": report_ref, "routeId": route_id, "reason": reason},
		"leaderboard_report", true)

func update_hub_presence(x: int, y: int, vehicle_id: String, emote: String = "") -> void:
	if not SaveSystem.get_value("hub_presence_opt_in", false) or not SaveSystem.is_online_leaderboard_opted_in():
		_finish("hub_presence", false, {"reason": "not_opted_in"})
		return
	if not is_enabled() or not has_identity():
		_finish("hub_presence", false, {"reason": "not_ready"})
		return
	_request_json("/v1/hub/presence", HTTPClient.METHOD_PUT,
		{"districtId": "kariakoo", "x": clampi(x, 0, 1000), "y": clampi(y, 0, 1000),
		"vehicleId": vehicle_id, "emote": emote}, "hub_presence", true)

func fetch_hub_crowd() -> void:
	if not SaveSystem.get_value("hub_presence_opt_in", false) or not SaveSystem.is_online_leaderboard_opted_in():
		_finish("hub_crowd", false, {"reason": "not_opted_in"})
		return
	if not is_enabled() or not has_identity():
		_finish("hub_crowd", false, {"reason": "not_ready"})
		return
	_request_json("/v1/hub/crowd/kariakoo", HTTPClient.METHOD_GET, {}, "hub_crowd", true)

func leave_hub_presence() -> void:
	if not is_enabled() or not has_identity():
		return
	_request_json("/v1/hub/presence", HTTPClient.METHOD_DELETE, {}, "hub_presence_leave", true)

func leave_online_leaderboard() -> void:
	if not is_enabled() or not has_identity():
		_finish("leaderboard_leave", false, {"reason": "not_ready"})
		return
	_leaderboard_epoch += 1
	_request_json("/v1/leaderboard-profile", HTTPClient.METHOD_DELETE, {}, "leaderboard_leave", true)

func flush_telemetry() -> void:
	if _telemetry_in_flight or not is_enabled() or not has_identity() or not SaveSystem.is_online_telemetry_opted_in():
		return
	var events: Array = AnalyticsService.get_railway_batch(25)
	if events.is_empty():
		return
	_telemetry_in_flight = true
	_request_json("/v1/telemetry", HTTPClient.METHOD_POST, {"events": events},
		"telemetry", true, {"events": events})

func cloud_snapshot(source: Dictionary) -> Dictionary:
	var snapshot: Dictionary = {}
	for raw_key in source.keys():
		var key: String = String(raw_key)
		if not cloud_key_allowed(key):
			continue
		snapshot[key] = source[raw_key]
	return snapshot

## Restore is only called after the player confirms replacement in Settings.
## It accepts only known save keys and then runs the normal save repair pass.
func apply_cloud_snapshot(payload: Dictionary) -> bool:
	var raw_save: Variant = payload.get("save", {})
	if typeof(raw_save) != TYPE_DICTIONARY:
		return false
	var snapshot: Dictionary = raw_save as Dictionary
	if not SaveSystem.valid_envelope(snapshot) \
	or int(snapshot.get("schema_version", 1)) > int(SaveSystem.DEFAULTS.schema_version):
		return false
	SaveSystem.begin_batch()
	for raw_key in snapshot.keys():
		var key: String = String(raw_key)
		if not cloud_key_allowed(key):
			continue
		var value: Variant = snapshot[raw_key]
		if not SaveSystem._is_compatible_value(SaveSystem.DEFAULTS.get(key, {}), value):
			continue
		SaveSystem.set_value(key, value)
	SaveSystem.set_value("online_cloud_revision", maxi(0, int(payload.get("revision", 0))))
	SaveSystem.set_value("online_pending_cloud_upload", {})
	SaveSystem._normalize_core_data()
	GameState.reload_profile()
	LocaleManager.set_locale(String(SaveSystem.get_value("locale", "sw")))
	AudioManager.set_music_on(bool(SaveSystem.get_value("music_on", true)))
	AudioManager.set_sfx_on(bool(SaveSystem.get_value("sfx_on", true)))
	SaveSystem.end_batch()
	return SaveSystem.last_save_error == OK

static func cloud_key_allowed(key: String) -> bool:
	if key in PRIVATE_LOCAL_KEYS:
		return false
	if SaveSystem.DEFAULTS.has(key):
		return true
	for vehicle in preload("res://data/vehicles.gd").LIST:
		if key == "livery_" + String(vehicle.id):
			return true
	return false

func _request_json(path: String, method: HTTPClient.Method, body: Dictionary,
		operation: String, requires_identity: bool, context: Dictionary = {}) -> void:
	var request := HTTPRequest.new()
	request.timeout = REQUEST_TIMEOUT_SECONDS
	request.body_size_limit = MAX_RESPONSE_BYTES
	add_child(request)
	var identity_at_start: String = String(SaveSystem.get_value("online_installation_id", ""))
	var token_at_start: String = String(SaveSystem.get_value("online_sync_token", ""))
	var board_epoch_at_start: int = _leaderboard_epoch
	var headers: PackedStringArray = PackedStringArray(["Content-Type: application/json"])
	if requires_identity:
		headers.append("X-Installation-Id: " + String(SaveSystem.get_value("online_installation_id", "")))
		headers.append("X-Sync-Token: " + String(SaveSystem.get_value("online_sync_token", "")))
	request.request_completed.connect(func(result: int, response_code: int,
			_headers: PackedStringArray, response_body: PackedByteArray) -> void:
		request.queue_free()
		if operation in ["transfer_claim", "transfer_ack"] \
		and context.get("transfer_operation") != (SaveSystem.get_value("online_pending_transfer", {}) as Dictionary).get("operationId"):
			return
		if requires_identity and (identity_at_start != String(SaveSystem.get_value("online_installation_id", "")) \
		or token_at_start != String(SaveSystem.get_value("online_sync_token", ""))):
			return
		if operation == "leaderboard_submit" and board_epoch_at_start != _leaderboard_epoch:
			_submission_in_flight = false
			return
		var parsed: Variant = JSON.parse_string(response_body.get_string_from_utf8())
		var payload: Dictionary = parsed as Dictionary if parsed is Dictionary else {}
		var succeeded: bool = result == HTTPRequest.RESULT_SUCCESS \
			and response_code >= 200 and response_code < 300 and valid_response(operation, payload)
		if succeeded and operation == "cloud_upload":
			succeeded = int(payload.revision) == int(context.get("sent_revision", -1)) \
				and payload.get("operationId") == context.get("operation_id")
		if succeeded and operation == "telemetry":
			succeeded = int(payload.accepted) == (context.get("events", []) as Array).size()
		if succeeded and operation in ["transfer_claim", "transfer_ack"]:
			succeeded = payload.get("operationId") == context.get("transfer_operation")
		if result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300 and not succeeded:
			payload = {"error": "invalid_response"}
		payload.merge(context, true)
		if succeeded:
			_apply_success(operation, payload)
			if operation == "cloud_upload" and cloud_snapshot(SaveSystem.data) != context.get("sent_snapshot", {}):
				_cloud_upload_in_flight = false
				upload_cloud_save()
				return
		_finish(operation, succeeded, payload)
	)
	var payload_text: String = JSON.stringify(body) \
		if method not in [HTTPClient.METHOD_GET, HTTPClient.METHOD_DELETE] else ""
	var error: Error = request.request(API_BASE_URL + path, headers, method, payload_text)
	if error != OK:
		request.queue_free()
		var failed_payload: Dictionary = {"reason": "request_failed"}
		failed_payload.merge(context, true)
		_finish(operation, false, failed_payload)

static func valid_revision(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and float(value) == floorf(float(value)) \
		and float(value) >= 0.0 and float(value) <= 2147483647.0

static func valid_response(operation: String, payload: Dictionary) -> bool:
	match operation:
		"registration":
			return Ids.is_valid(payload.get("installationId")) and payload.get("syncToken") is String \
				and String(payload.syncToken).length() >= 32 and String(payload.syncToken).length() <= 128
		"transfer_claim": return Ids.is_valid(payload.get("installationId")) and Ids.is_valid(payload.get("operationId")) and payload.get("requiresAcknowledgement") == true
		"transfer_ack": return Ids.is_valid(payload.get("installationId")) and Ids.is_valid(payload.get("operationId")) and payload.get("acknowledged") == true
		"cloud_upload": return valid_revision(payload.get("revision"))
		"cloud_download": return valid_revision(payload.get("revision")) and payload.get("save") is Dictionary
		"account_delete", "leaderboard_leave": return payload.get("deleted") == true
		"leaderboard_submit": return payload.get("accepted") is bool and payload.get("verification") == "unverified"
		"leaderboard_global", "leaderboard_friends": return payload.get("scores") is Array and payload.scores.size() <= 25
		"leaderboard_nearby":
			if payload.get("verification") != "unverified" or payload.get("nearby") is not Array or payload.nearby.size() > 7:
				return false
			if payload.get("own") != null and not _valid_rank_row(payload.own): return false
			for row in payload.nearby:
				if not _valid_rank_row(row): return false
			return true
		"hub_presence": return payload.get("present") == true and valid_revision(payload.get("expiresInSeconds"))
		"hub_presence_leave": return payload.get("left") == true
		"hub_crowd":
			if payload.get("districtId") != "kariakoo" or payload.get("players") is not Array or payload.players.size() > 20:
				return false
			for player in payload.players:
				if player is not Dictionary or not Ids.is_valid(player.get("playerId")) \
				or player.get("displayName") is not String or String(player.displayName).length() > 64 \
				or not valid_revision(player.get("x")) or int(player.x) > 1000 \
				or not valid_revision(player.get("y")) or int(player.y) > 1000 \
				or player.get("vehicleId") not in ["classic_blue", "kariakoo_yellow", "mwendokasi_red", "night_bus", "vip", "old_school", "simba_express", "bongo_flava"] \
				or player.get("emote") not in ["", "wave", "horn", "dance"]:
					return false
			return true
		"telemetry": return valid_revision(payload.get("accepted"))
	return not payload.is_empty()

static func _valid_rank_row(row: Variant) -> bool:
	return row is Dictionary and valid_revision(row.get("rank")) and int(row.rank) > 0 \
		and valid_revision(row.get("score")) and row.get("displayName") is String \
		and String(row.displayName).length() <= 64 and row.get("isYou") is bool \
		and row.get("reportRef") is String and String(row.reportRef).length() <= 128

func _apply_success(operation: String, payload: Dictionary) -> void:
	if operation == "transfer_claim":
		var pending: Dictionary = SaveSystem.get_value("online_pending_transfer", {})
		pending["installationId"] = payload.installationId
		SaveSystem.set_value("online_pending_transfer", pending)
		_transfer_in_flight = false
		if SaveSystem._batch_depth == 0 and SaveSystem.last_save_error == OK:
			call_deferred("retry_pending_transfer")
		return
	if operation == "registration" or operation == "transfer_ack":
		if operation == "transfer_ack":
			payload["syncToken"] = (SaveSystem.get_value("online_pending_transfer", {}) as Dictionary).get("syncToken", "")
		var installation_id: String = String(payload.get("installationId", "")).strip_edges()
		var sync_token: String = String(payload.get("syncToken", "")).strip_edges()
		if installation_id.is_empty() or sync_token.is_empty():
			return
		SaveSystem.begin_batch()
		SaveSystem.set_value("online_installation_id", installation_id)
		SaveSystem.set_value("online_sync_token", sync_token)
		if operation == "transfer_ack":
			_cloud_upload_in_flight = false
			_telemetry_in_flight = false
			_submission_in_flight = false
			_leaderboard_epoch += 1
			SaveSystem.set_value("online_pending_cloud_upload", {})
			SaveSystem.set_value("online_cloud_revision", 0)
			SaveSystem.set_value("online_pending_transfer", {})
		SaveSystem.end_batch()
	elif operation == "cloud_upload":
		SaveSystem.begin_batch()
		SaveSystem.set_value("online_cloud_revision", int(payload.get("revision", 0)))
		SaveSystem.set_value("online_pending_cloud_upload", {})
		SaveSystem.end_batch()
	elif operation == "account_delete":
		SaveSystem.clear_online_account()
		_transfer_in_flight = false
		_leaderboard_epoch += 1
		AnalyticsService.discard_railway_events()
		_submission_in_flight = false
		_cloud_upload_in_flight = false
		_telemetry_in_flight = false
		SaveSystem.set_value("online_pending_cloud_upload", {})
	elif operation == "leaderboard_submit":
		_submission_in_flight = false
		SaveSystem.clear_submitted_leaderboard_score(
			String(payload.get("route_id", "")), int(payload.get("submitted_score", 0)),
			bool(payload.get("accepted", true))
		)
		call_deferred("retry_pending_leaderboard_submissions")
	elif operation == "leaderboard_global" or operation == "leaderboard_friends":
		var raw_scores: Variant = payload.get("scores", [])
		if raw_scores is Array:
			SaveSystem.cache_online_leaderboard(String(payload.get("tab_id", "")),
				String(payload.get("route_id", "")), raw_scores as Array)
	elif operation == "leaderboard_leave":
		SaveSystem.begin_batch()
		SaveSystem.set_online_leaderboard_opt_in(false)
		SaveSystem.set_value("pending_leaderboard_submissions", [])
		SaveSystem.set_leaderboard_upload_status("")
		SaveSystem.end_batch()
	elif operation == "telemetry":
		var sent_events: Variant = payload.get("events", [])
		if sent_events is Array:
			AnalyticsService.acknowledge_railway_batch(sent_events as Array)
		call_deferred("flush_telemetry")

func _finish(operation: String, success: bool, payload: Dictionary) -> void:
	if operation in ["transfer_claim", "transfer_ack"]:
		_transfer_in_flight = false
		if not success and payload.get("error") in ["transfer_not_found", "invalid_transfer", "transfer_superseded", "transfer_upgrade_required"]:
			SaveSystem.set_value("online_pending_transfer", {})
	if operation == "cloud_upload":
		_cloud_upload_in_flight = false
		if not success and payload.get("error") == "stale_revision" and valid_revision(payload.get("currentRevision")):
			var pending: Dictionary = SaveSystem.get_value("online_pending_cloud_upload", {})
			pending["conflict_revision"] = int(payload.currentRevision)
			SaveSystem.set_value("online_pending_cloud_upload", pending)
	if operation == "telemetry":
		_telemetry_in_flight = false
	if operation == "registration":
		_registration_in_flight = false
	if operation == "leaderboard_submit" and not success:
		_submission_in_flight = false
		var reason: String = String(payload.get("error", ""))
		var status: String = "retry"
		if reason == "rate_limited":
			status = "rate_limited"
			_submission_retry_after_unix = int(Time.get_unix_time_from_system()) \
				+ maxi(1, int(payload.get("retryAfterSeconds", 60)))
		elif reason == "invalid_display_name":
			status = "invalid_name"
		elif reason == "profile_hidden":
			status = "profile_hidden"
		SaveSystem.set_leaderboard_upload_status(status,
			String(payload.get("route_id", "")), int(payload.get("submitted_score", 0)))
	elif operation == "leaderboard_submit" and success:
		_submission_retry_after_unix = 0
	AnalyticsService.log_event("online_" + operation, {"success": success})
	request_finished.emit(operation, success, payload)

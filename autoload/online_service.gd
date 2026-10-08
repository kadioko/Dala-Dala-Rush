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
]

var _submission_in_flight: bool = false
var _registration_in_flight: bool = false
var _submission_retry_after_unix: int = 0

func _ready() -> void:
	call_deferred("retry_pending_leaderboard_submissions")

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
	if not is_enabled() or not has_identity():
		_finish("cloud_upload", false, {"reason": "not_ready"})
		return
	var snapshot: Dictionary = cloud_snapshot(SaveSystem.data)
	var encoded: PackedByteArray = JSON.stringify(snapshot).to_utf8_buffer()
	if encoded.size() > MAX_SNAPSHOT_BYTES:
		_finish("cloud_upload", false, {"reason": "snapshot_too_large"})
		return
	var revision: int = int(SaveSystem.get_value("online_cloud_revision", 0)) + 1
	_request_json("/v1/cloud-save", HTTPClient.METHOD_POST, {
		"revision": revision,
		"save": snapshot,
	}, "cloud_upload", true)

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
	_request_json("/v1/account", HTTPClient.METHOD_DELETE, {}, "account_delete", true)

func create_transfer_code() -> void:
	if not is_enabled() or not has_identity():
		_finish("transfer_code", false, {"reason": "not_ready"})
		return
	_request_json("/v1/account/transfer-code", HTTPClient.METHOD_POST, {}, "transfer_code", true)

func claim_transfer_code(raw_code: String) -> void:
	if not is_enabled():
		_finish("transfer_claim", false, {"reason": "disabled"})
		return
	var transfer_code: String = raw_code.strip_edges().to_upper()
	if transfer_code.is_empty():
		_finish("transfer_claim", false, {"reason": "invalid_code"})
		return
	_request_json("/v1/account/claim-transfer", HTTPClient.METHOD_POST,
		{"transferCode": transfer_code}, "transfer_claim", false)

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

func leave_online_leaderboard() -> void:
	if not is_enabled() or not has_identity():
		_finish("leaderboard_leave", false, {"reason": "not_ready"})
		return
	_request_json("/v1/leaderboard-profile", HTTPClient.METHOD_DELETE, {}, "leaderboard_leave", true)

func flush_telemetry() -> void:
	if not is_enabled() or not has_identity() or not SaveSystem.is_online_telemetry_opted_in():
		return
	var events: Array = AnalyticsService.get_railway_batch(25)
	if events.is_empty():
		return
	_request_json("/v1/telemetry", HTTPClient.METHOD_POST, {"events": events},
		"telemetry", true, {"events": events})

func cloud_snapshot(source: Dictionary) -> Dictionary:
	var snapshot: Dictionary = {}
	for raw_key in source.keys():
		var key: String = String(raw_key)
		if key in PRIVATE_LOCAL_KEYS:
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
	SaveSystem.begin_batch()
	for raw_key in snapshot.keys():
		var key: String = String(raw_key)
		if key in PRIVATE_LOCAL_KEYS or not SaveSystem.DEFAULTS.has(key):
			continue
		var value: Variant = snapshot[raw_key]
		if not SaveSystem._is_compatible_value(SaveSystem.DEFAULTS[key], value):
			continue
		SaveSystem.set_value(key, value)
	SaveSystem.set_value("online_cloud_revision", maxi(0, int(payload.get("revision", 0))))
	SaveSystem._normalize_core_data()
	SaveSystem.end_batch()
	return true

func _request_json(path: String, method: HTTPClient.Method, body: Dictionary,
		operation: String, requires_identity: bool, context: Dictionary = {}) -> void:
	var request := HTTPRequest.new()
	request.timeout = REQUEST_TIMEOUT_SECONDS
	add_child(request)
	var headers: PackedStringArray = PackedStringArray(["Content-Type: application/json"])
	if requires_identity:
		headers.append("X-Installation-Id: " + String(SaveSystem.get_value("online_installation_id", "")))
		headers.append("X-Sync-Token: " + String(SaveSystem.get_value("online_sync_token", "")))
	request.request_completed.connect(func(result: int, response_code: int,
			_headers: PackedStringArray, response_body: PackedByteArray) -> void:
		request.queue_free()
		var parsed: Variant = JSON.parse_string(response_body.get_string_from_utf8())
		var payload: Dictionary = parsed as Dictionary if parsed is Dictionary else {}
		payload.merge(context, true)
		var succeeded: bool = result == HTTPRequest.RESULT_SUCCESS \
			and response_code >= 200 and response_code < 300
		if succeeded:
			_apply_success(operation, payload)
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

func _apply_success(operation: String, payload: Dictionary) -> void:
	if operation == "registration" or operation == "transfer_claim":
		var installation_id: String = String(payload.get("installationId", "")).strip_edges()
		var sync_token: String = String(payload.get("syncToken", "")).strip_edges()
		if installation_id.is_empty() or sync_token.is_empty():
			return
		SaveSystem.begin_batch()
		SaveSystem.set_value("online_installation_id", installation_id)
		SaveSystem.set_value("online_sync_token", sync_token)
		SaveSystem.end_batch()
	elif operation == "cloud_upload":
		SaveSystem.set_value("online_cloud_revision", int(payload.get("revision", 0)))
	elif operation == "account_delete":
		SaveSystem.clear_online_account()
		AnalyticsService.discard_railway_events()
		_submission_in_flight = false
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

func _finish(operation: String, success: bool, payload: Dictionary) -> void:
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
		SaveSystem.set_leaderboard_upload_status(status,
			String(payload.get("route_id", "")), int(payload.get("submitted_score", 0)))
	elif operation == "leaderboard_submit" and success:
		_submission_retry_after_unix = 0
	AnalyticsService.log_event("online_" + operation, {"success": success})
	request_finished.emit(operation, success, payload)

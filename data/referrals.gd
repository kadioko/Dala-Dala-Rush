class_name Referrals
## Offline-first referral codes and one-time reward confirmations.
##
## This handshake is intentionally simple: an invited player claims one invite
## code, then sends the generated confirmation back to the inviter. A backend
## can replace the confirmation step later without changing the saved economy.

const INVITE_PREFIX := "DDR-"
const RECEIPT_PREFIX := "DDR-R-"
const CODE_ALPHABET := "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
const CODE_LENGTH := 6
const WELCOME_REWARD := 75
const REFERRER_REWARD := 125
const MAX_REFERRAL_REWARDS := 10
const MILESTONE_REWARDS := {
	3: 100,
	5: 200,
	10: 500,
}
const RECEIPT_SALT := "dala-dala-rush-tz-referral-v1"
const PLAY_STORE_URL := "https://play.google.com/store/apps/details?id=com.kadioko.daladalarush"

static func ensure_invite_code() -> String:
	var saved_code := normalize_invite_code(String(SaveSystem.get_value("referral_invite_code", "")))
	if is_valid_invite_code(saved_code):
		return saved_code
	var new_code := _generate_invite_code()
	SaveSystem.set_value("referral_invite_code", new_code)
	return new_code

static func normalize_invite_code(raw_code: String) -> String:
	var compact := raw_code.strip_edges().to_upper()
	compact = compact.replace(" ", "").replace("-", "")
	if compact.begins_with("DDR"):
		compact = compact.substr(3)
	if compact.length() != CODE_LENGTH:
		return ""
	for index in range(compact.length()):
		if CODE_ALPHABET.find(compact.substr(index, 1)) < 0:
			return ""
	return INVITE_PREFIX + compact

static func is_valid_invite_code(code: String) -> bool:
	return not normalize_invite_code(code).is_empty()

static func validate_invite_claim(raw_code: String, own_code: String, already_claimed: bool) -> Dictionary:
	if already_claimed:
		return {"ok": false, "reason": "already"}
	var normalized := normalize_invite_code(raw_code)
	if normalized.is_empty():
		return {"ok": false, "reason": "invalid"}
	if normalized == normalize_invite_code(own_code):
		return {"ok": false, "reason": "self"}
	return {"ok": true, "code": normalized}

static func claim_invite_code(raw_code: String) -> Dictionary:
	var own_code := ensure_invite_code()
	var validation := validate_invite_claim(
		raw_code,
		own_code,
		bool(SaveSystem.get_value("referral_welcome_claimed", false))
	)
	if not bool(validation.get("ok", false)):
		return validation

	var inviter_code := String(validation.get("code", ""))
	var confirmation := build_confirmation_code(inviter_code, own_code)
	SaveSystem.begin_batch()
	SaveSystem.set_value("referral_welcome_claimed", true)
	SaveSystem.set_value("referral_inviter_code", inviter_code)
	SaveSystem.set_value("referral_confirmation_code", confirmation)
	SaveSystem.add_coins(WELCOME_REWARD)
	SaveSystem.end_batch()
	return {
		"ok": true,
		"reward": WELCOME_REWARD,
		"confirmation": confirmation,
	}

static func build_confirmation_code(inviter_code: String, invitee_code: String) -> String:
	var inviter := normalize_invite_code(inviter_code)
	var invitee := normalize_invite_code(invitee_code)
	if inviter.is_empty() or invitee.is_empty() or inviter == invitee:
		return ""
	var inviter_token := inviter.trim_prefix(INVITE_PREFIX)
	var invitee_token := invitee.trim_prefix(INVITE_PREFIX)
	return "%s%s-%s-%s" % [
		RECEIPT_PREFIX,
		inviter_token,
		invitee_token,
		_confirmation_checksum(inviter, invitee),
	]

static func inspect_confirmation_code(raw_code: String) -> Dictionary:
	var compact := raw_code.strip_edges().to_upper().replace(" ", "")
	var parts := compact.split("-", false)
	if parts.size() != 5 or parts[0] != "DDR" or parts[1] != "R":
		return {"ok": false, "reason": "invalid"}
	var inviter := normalize_invite_code(String(parts[2]))
	var invitee := normalize_invite_code(String(parts[3]))
	var checksum := String(parts[4])
	if inviter.is_empty() or invitee.is_empty() or inviter == invitee:
		return {"ok": false, "reason": "invalid"}
	if checksum != _confirmation_checksum(inviter, invitee):
		return {"ok": false, "reason": "invalid"}
	return {
		"ok": true,
		"inviter": inviter,
		"invitee": invitee,
		"canonical": build_confirmation_code(inviter, invitee),
	}

static func claim_confirmation_code(raw_code: String) -> Dictionary:
	var parsed := inspect_confirmation_code(raw_code)
	if not bool(parsed.get("ok", false)):
		return parsed
	var own_code := ensure_invite_code()
	if String(parsed.get("inviter", "")) != own_code:
		return {"ok": false, "reason": "wrong_owner"}

	var claimed_invitees: Array[String] = _claimed_invitee_codes()
	var invitee_code := String(parsed.get("invitee", ""))
	if invitee_code in claimed_invitees:
		return {"ok": false, "reason": "duplicate"}
	if claimed_invitees.size() >= MAX_REFERRAL_REWARDS:
		return {"ok": false, "reason": "limit"}

	claimed_invitees.append(invitee_code)
	var success_count := claimed_invitees.size()
	var milestone_bonus := milestone_reward_for(success_count)
	var total_reward := REFERRER_REWARD + milestone_bonus
	SaveSystem.begin_batch()
	SaveSystem.set_value("referral_claimed_invitees", claimed_invitees)
	SaveSystem.set_value("referral_success_count", success_count)
	SaveSystem.add_coins(total_reward)
	SaveSystem.end_batch()
	return {
		"ok": true,
		"reward": total_reward,
		"base_reward": REFERRER_REWARD,
		"milestone_bonus": milestone_bonus,
		"count": success_count,
	}

static func milestone_reward_for(success_count: int) -> int:
	return int(MILESTONE_REWARDS.get(success_count, 0))

static func next_milestone_after(success_count: int) -> Dictionary:
	var thresholds: Array[int] = []
	for raw_threshold in MILESTONE_REWARDS.keys():
		thresholds.append(int(raw_threshold))
	thresholds.sort()
	for threshold in thresholds:
		if threshold > success_count:
			return {
				"count": threshold,
				"reward": milestone_reward_for(threshold),
			}
	return {}

static func invite_share_url(invite_code: String) -> String:
	var normalized := normalize_invite_code(invite_code)
	var referrer_value := "utm_source=player_referral&utm_content=%s" % normalized
	return "%s&referrer=%s" % [PLAY_STORE_URL, referrer_value.uri_encode()]

static func _claimed_invitee_codes() -> Array[String]:
	var result: Array[String] = []
	var saved_value: Variant = SaveSystem.get_value("referral_claimed_invitees", [])
	if saved_value is Array:
		for raw_value in saved_value:
			if typeof(raw_value) != TYPE_STRING:
				continue
			var code := normalize_invite_code(String(raw_value))
			if not code.is_empty() and code not in result:
				result.append(code)
	return result

static func _generate_invite_code() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var token := ""
	for _index in range(CODE_LENGTH):
		var alphabet_index := rng.randi_range(0, CODE_ALPHABET.length() - 1)
		token += CODE_ALPHABET.substr(alphabet_index, 1)
	return INVITE_PREFIX + token

static func _confirmation_checksum(inviter_code: String, invitee_code: String) -> String:
	var payload := "%s|%s|%s" % [inviter_code, invitee_code, RECEIPT_SALT]
	return payload.sha256_text().substr(0, 8).to_upper()

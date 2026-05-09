extends Node
## Rewarded-ad placeholder service.
## No real SDK is included in the MVP. Replace these methods when adding AdMob,
## Unity LevelPlay, or another Android ad provider.

signal reward_failed(placement: String)
signal reward_granted(placement: String)

const PLACEMENT_CONTINUE := "continue_after_crash"
const PLACEMENT_DOUBLE_COINS := "double_coins"

var rewarded_ads_enabled: bool = false

func is_rewarded_available(_placement: String = "") -> bool:
	return rewarded_ads_enabled

func show_rewarded_continue() -> bool:
	return _show_rewarded(PLACEMENT_CONTINUE)

func show_rewarded_double_coins() -> bool:
	return _show_rewarded(PLACEMENT_DOUBLE_COINS)

func _show_rewarded(placement: String) -> bool:
	if not rewarded_ads_enabled:
		emit_signal("reward_failed", placement)
		return false
	emit_signal("reward_granted", placement)
	return true

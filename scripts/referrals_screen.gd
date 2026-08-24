extends Control
## Offline referral hub: share an invite, claim one welcome code, and redeem
## confirmations returned by invited players.

const UIFactory := preload("res://ui/ui_factory.gd")
const ReferralsData := preload("res://data/referrals.gd")
const ShareHelperLib := preload("res://scripts/share_helper.gd")

var _title: Label
var _intro: Label
var _balance: Label
var _invite_title: Label
var _invite_body: Label
var _invite_code: LineEdit
var _invite_progress: Label
var _invite_milestone: Label
var _share_invite_btn: Button
var _welcome_title: Label
var _welcome_body: Label
var _inviter_input: LineEdit
var _claim_invite_btn: Button
var _welcome_status: Label
var _confirmation_code: LineEdit
var _share_confirmation_btn: Button
var _reward_title: Label
var _reward_body: Label
var _confirmation_input: LineEdit
var _claim_confirmation_btn: Button
var _message: Label
var _back_btn: Button

func _ready() -> void:
	UIFactory.paint_background(self, Color("#10151d"))

	var scroll := ScrollContainer.new()
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_left = 20
	scroll.offset_right = -20
	scroll.offset_top = 28 + UIFactory.safe_top_inset(get_viewport_rect().size.y)
	scroll.offset_bottom = -24 - UIFactory.safe_bottom_inset(get_viewport_rect().size.y)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 12)
	scroll.add_child(root)

	_title = UIFactory.make_title("", 32)
	root.add_child(_title)
	_intro = _make_wrapped_label(16, UIFactory.COL_MUTED)
	root.add_child(_intro)
	_balance = UIFactory.make_label("", 18, UIFactory.COL_ACCENT)
	root.add_child(_balance)

	var invite_box := _add_section(root, Color("#17283a"))
	_invite_title = _make_section_title()
	invite_box.add_child(_invite_title)
	_invite_body = _make_wrapped_label(15, UIFactory.COL_MUTED)
	invite_box.add_child(_invite_body)
	_invite_code = _make_code_field(false)
	invite_box.add_child(_invite_code)
	_invite_progress = _make_wrapped_label(14, Color("#63d6a0"))
	invite_box.add_child(_invite_progress)
	_invite_milestone = _make_wrapped_label(14, UIFactory.COL_ACCENT)
	invite_box.add_child(_invite_milestone)
	_share_invite_btn = UIFactory.make_button("")
	_share_invite_btn.custom_minimum_size = Vector2(0, 54)
	_share_invite_btn.pressed.connect(_on_share_invite)
	invite_box.add_child(_share_invite_btn)

	var welcome_box := _add_section(root)
	_welcome_title = _make_section_title()
	welcome_box.add_child(_welcome_title)
	_welcome_body = _make_wrapped_label(15, UIFactory.COL_MUTED)
	welcome_box.add_child(_welcome_body)
	_inviter_input = _make_code_field(true)
	_inviter_input.max_length = 12
	_inviter_input.text_submitted.connect(func(_text: String): _on_claim_invite())
	welcome_box.add_child(_inviter_input)
	_claim_invite_btn = UIFactory.make_button("", false)
	_claim_invite_btn.custom_minimum_size = Vector2(0, 52)
	_claim_invite_btn.pressed.connect(_on_claim_invite)
	welcome_box.add_child(_claim_invite_btn)
	_welcome_status = _make_wrapped_label(14, Color("#63d6a0"))
	welcome_box.add_child(_welcome_status)
	_confirmation_code = _make_code_field(false)
	welcome_box.add_child(_confirmation_code)
	_share_confirmation_btn = UIFactory.make_button("", false)
	_share_confirmation_btn.custom_minimum_size = Vector2(0, 52)
	_share_confirmation_btn.pressed.connect(_on_share_confirmation)
	welcome_box.add_child(_share_confirmation_btn)

	var reward_box := _add_section(root)
	_reward_title = _make_section_title()
	reward_box.add_child(_reward_title)
	_reward_body = _make_wrapped_label(15, UIFactory.COL_MUTED)
	reward_box.add_child(_reward_body)
	_confirmation_input = _make_code_field(true)
	_confirmation_input.max_length = 40
	_confirmation_input.text_submitted.connect(func(_text: String): _on_claim_confirmation())
	reward_box.add_child(_confirmation_input)
	_claim_confirmation_btn = UIFactory.make_button("", false)
	_claim_confirmation_btn.custom_minimum_size = Vector2(0, 52)
	_claim_confirmation_btn.pressed.connect(_on_claim_confirmation)
	reward_box.add_child(_claim_confirmation_btn)

	_message = _make_wrapped_label(15, UIFactory.COL_ACCENT)
	_message.custom_minimum_size = Vector2(0, 42)
	root.add_child(_message)

	_back_btn = UIFactory.make_button("", false)
	_back_btn.custom_minimum_size = Vector2(0, 54)
	_back_btn.pressed.connect(_on_back)
	root.add_child(_back_btn)
	root.add_child(_spacer(8))

	LocaleManager.locale_changed.connect(_refresh)
	_refresh()

func _add_section(parent: VBoxContainer, color: Color = UIFactory.COL_PANEL) -> VBoxContainer:
	var panel := UIFactory.make_panel(color)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	return box

func _make_section_title() -> Label:
	var label := UIFactory.make_label("", 20, UIFactory.COL_TEXT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _make_wrapped_label(font_size: int, color: Color) -> Label:
	var label := UIFactory.make_label("", font_size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _make_code_field(editable: bool) -> LineEdit:
	var field := LineEdit.new()
	field.custom_minimum_size = Vector2(0, 50)
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.editable = editable
	field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	field.add_theme_font_size_override("font_size", 18)
	field.add_theme_color_override("font_color", UIFactory.COL_TEXT)
	field.add_theme_color_override("font_uneditable_color", UIFactory.COL_ACCENT)
	return field

func _spacer(height: int) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	return spacer

func _refresh(_locale: String = "") -> void:
	var own_code := ReferralsData.ensure_invite_code()
	var success_count := int(SaveSystem.get_value("referral_success_count", 0))
	var welcome_claimed := bool(SaveSystem.get_value("referral_welcome_claimed", false))
	var confirmation := String(SaveSystem.get_value("referral_confirmation_code", ""))

	_title.text = LocaleManager.t("REFERRAL_TITLE")
	_intro.text = LocaleManager.t("REFERRAL_INTRO")
	_balance.text = LocaleManager.t("REFERRAL_BALANCE").replace(
		"{n}", str(int(SaveSystem.get_value("total_coins", 0))))
	_invite_title.text = LocaleManager.t("REFERRAL_YOUR_CODE")
	_invite_body.text = LocaleManager.t("REFERRAL_INVITE_BODY") \
		.replace("{n}", str(ReferralsData.REFERRER_REWARD))
	_invite_code.text = own_code
	_invite_progress.text = LocaleManager.t("REFERRAL_PROGRESS") \
		.replace("{current}", str(success_count)) \
		.replace("{max}", str(ReferralsData.MAX_REFERRAL_REWARDS))
	var next_milestone := ReferralsData.next_milestone_after(success_count)
	if next_milestone.is_empty():
		_invite_milestone.text = LocaleManager.t("REFERRAL_ALL_MILESTONES")
	else:
		_invite_milestone.text = LocaleManager.t("REFERRAL_NEXT_MILESTONE") \
			.replace("{count}", str(int(next_milestone.get("count", 0)))) \
			.replace("{n}", str(int(next_milestone.get("reward", 0))))
	_share_invite_btn.text = LocaleManager.t("REFERRAL_SHARE_INVITE")

	_welcome_title.text = LocaleManager.t("REFERRAL_GOT_INVITE")
	_welcome_body.text = LocaleManager.t("REFERRAL_WELCOME_BODY") \
		.replace("{n}", str(ReferralsData.WELCOME_REWARD))
	_inviter_input.placeholder_text = LocaleManager.t("REFERRAL_INVITE_HINT")
	_claim_invite_btn.text = LocaleManager.t("REFERRAL_CLAIM_WELCOME")
	_inviter_input.visible = not welcome_claimed
	_claim_invite_btn.visible = not welcome_claimed
	_welcome_status.visible = welcome_claimed
	_confirmation_code.visible = welcome_claimed and not confirmation.is_empty()
	_share_confirmation_btn.visible = welcome_claimed and not confirmation.is_empty()
	if welcome_claimed:
		_welcome_status.text = LocaleManager.t("REFERRAL_WELCOME_DONE") \
			.replace("{n}", str(ReferralsData.WELCOME_REWARD))
		_confirmation_code.text = confirmation
		_share_confirmation_btn.text = LocaleManager.t("REFERRAL_SEND_CONFIRMATION")

	_reward_title.text = LocaleManager.t("REFERRAL_CLAIM_TITLE")
	_reward_body.text = LocaleManager.t("REFERRAL_CLAIM_BODY") \
		.replace("{n}", str(ReferralsData.REFERRER_REWARD))
	_confirmation_input.placeholder_text = LocaleManager.t("REFERRAL_CONFIRM_HINT")
	_claim_confirmation_btn.text = LocaleManager.t("REFERRAL_CLAIM_REWARD")
	_claim_confirmation_btn.disabled = success_count >= ReferralsData.MAX_REFERRAL_REWARDS
	_confirmation_input.editable = not _claim_confirmation_btn.disabled
	_back_btn.text = LocaleManager.t("BACK")

func _on_share_invite() -> void:
	AudioManager.play_sfx("click")
	var own_code := ReferralsData.ensure_invite_code()
	var share_text := LocaleManager.t("REFERRAL_SHARE_TEXT") \
		.replace("{code}", own_code) \
		.replace("{n}", str(ReferralsData.WELCOME_REWARD)) \
		.replace("{url}", ReferralsData.invite_share_url(own_code))
	var shared := ShareHelperLib.share_text(share_text)
	AnalyticsService.log_event("referral_invite_shared", {
		"platform": "android" if OS.get_name() == "Android" else "desktop",
	})
	_message.text = LocaleManager.t("REFERRAL_SHARE_OPENED") \
		if OS.get_name() == "Android" and shared else LocaleManager.t("SHARE_COPIED")

func _on_claim_invite() -> void:
	AudioManager.play_sfx("click")
	var result := ReferralsData.claim_invite_code(_inviter_input.text)
	if not bool(result.get("ok", false)):
		_message.text = _claim_error(String(result.get("reason", "invalid")))
		FeedbackManager.tap()
		return
	AudioManager.play_sfx("powerup")
	AnalyticsService.log_event("referral_welcome_claimed", {
		"reward": int(result.get("reward", 0)),
	})
	_message.text = LocaleManager.t("REFERRAL_WELCOME_SUCCESS") \
		.replace("{n}", str(int(result.get("reward", 0))))
	_inviter_input.clear()
	_refresh()

func _on_share_confirmation() -> void:
	AudioManager.play_sfx("click")
	var confirmation := String(SaveSystem.get_value("referral_confirmation_code", ""))
	var share_text := LocaleManager.t("REFERRAL_CONFIRM_TEXT") \
		.replace("{code}", confirmation)
	var shared := ShareHelperLib.share_text(share_text)
	AnalyticsService.log_event("referral_confirmation_shared")
	_message.text = LocaleManager.t("REFERRAL_SHARE_OPENED") \
		if OS.get_name() == "Android" and shared else LocaleManager.t("SHARE_COPIED")

func _on_claim_confirmation() -> void:
	AudioManager.play_sfx("click")
	var result := ReferralsData.claim_confirmation_code(_confirmation_input.text)
	if not bool(result.get("ok", false)):
		_message.text = _claim_error(String(result.get("reason", "invalid")))
		FeedbackManager.tap()
		return
	AudioManager.play_sfx("powerup")
	var milestone_bonus := int(result.get("milestone_bonus", 0))
	AnalyticsService.log_event("referral_reward_claimed", {
		"reward": int(result.get("reward", 0)),
		"count": int(result.get("count", 0)),
		"milestone_bonus": milestone_bonus,
	})
	if milestone_bonus > 0:
		_message.text = LocaleManager.t("REFERRAL_REWARD_MILESTONE") \
			.replace("{base}", str(int(result.get("base_reward", 0)))) \
			.replace("{bonus}", str(milestone_bonus)) \
			.replace("{total}", str(int(result.get("reward", 0))))
	else:
		_message.text = LocaleManager.t("REFERRAL_REWARD_SUCCESS") \
			.replace("{n}", str(int(result.get("reward", 0))))
	_confirmation_input.clear()
	_refresh()

func _claim_error(reason: String) -> String:
	match reason:
		"already": return LocaleManager.t("REFERRAL_ERR_ALREADY")
		"self": return LocaleManager.t("REFERRAL_ERR_SELF")
		"wrong_owner": return LocaleManager.t("REFERRAL_ERR_OWNER")
		"duplicate": return LocaleManager.t("REFERRAL_ERR_DUPLICATE")
		"limit": return LocaleManager.t("REFERRAL_ERR_LIMIT")
		_: return LocaleManager.t("REFERRAL_ERR_INVALID")

func _on_back() -> void:
	AudioManager.play_sfx("click")
	TransitionManager.go_to("res://scenes/main_menu.tscn")

func handle_back() -> void:
	_on_back()

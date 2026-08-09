extends Node
## In-app purchase seam for Google Play Billing.
## See docs/MONETIZATION.md — includes the TZ carrier-billing notes
## (Vodacom/Airtel/Tigo users can pay without a card via Play).
##
## Until the Play Billing plugin is installed this only exposes the
## catalog and emits purchase_failed, so store UI can be built/tested.

signal purchase_completed(product_id: String)
signal purchase_failed(product_id: String, reason: String)

const CATALOG: Array = [
	{"id": "coins_small",  "key": "IAP_COINS_SMALL",  "coins": 500,  "usd": 0.99},
	{"id": "coins_big",    "key": "IAP_COINS_BIG",    "coins": 3000, "usd": 3.99},
	{"id": "vip_bundle",   "key": "IAP_VIP",          "coins": 0,    "usd": 4.99},
]

var billing_available: bool = false

func _ready() -> void:
	# TODO: detect the Godot Play Billing plugin
	# (e.g. Engine.has_singleton("GodotGooglePlayBilling")), connect its
	# signals, query product details, then set billing_available = true.
	pass

func purchase(product_id: String) -> void:
	if not billing_available:
		purchase_failed.emit(product_id, "billing_unavailable")
		return
	# TODO: launch the purchase flow via the plugin.
	# On success: _grant(product_id); acknowledge/consume; emit purchase_completed.

func _grant(product_id: String) -> void:
	SaveSystem.begin_batch()
	for p in CATALOG:
		if p.id == product_id and int(p.coins) > 0:
			SaveSystem.add_coins(int(p.coins))
	# vip_bundle: unlock the VIP vehicle outright
	if product_id == "vip_bundle":
		SaveSystem.unlock_vehicle("vip")
	SaveSystem.end_batch()

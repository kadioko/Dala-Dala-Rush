# Audio Assets

The game runs with procedural placeholder audio. To use real sounds, drop files
into `res://audio/` with these exact names — they are picked up automatically
(`.ogg` preferred, `.wav` and `.mp3` also work). Anything missing keeps its
procedural fallback.

| File | Used for | Suggested feel |
|---|---|---|
| `audio/coin.ogg` | Coin pickup | Short bright ding, < 0.2 s |
| `audio/passenger.ogg` | Passenger pickup | Friendly chirp or "karibu!" voice |
| `audio/crash.ogg` | Crash / game over | Metal crunch + thud |
| `audio/click.ogg` | UI button | Soft tick |
| `audio/horn.ogg` | Horn (pembe) | Real daladala two-tone air horn |
| `audio/powerup.ogg` | Shield/magnet/boost/fuel | Rising sparkle |
| `audio/music.ogg` | Background loop | Upbeat bongo flava / singeli instrumental, seamless loop |

## Specs

- Mono, 22,050 Hz (or 44,100 if quality matters more than size).
- OGG Vorbis quality ~4 is plenty.
- Music loop: 30–60 s, must loop seamlessly (set loop in Godot's import dock or it's set automatically for music.ogg).
- Keep total audio under ~3 MB for low-end phones.

## Swahili voice lines (already wired — just add files)

Short shouted conductor (mpiga debe) lines add huge character. The trigger
points are already in the code; these keys are **file-only** (completely
silent until the recording exists — no placeholder beep):

| File | Trigger | Line |
|---|---|---|
| `audio/voice_twende.ogg` | Countdown "GO" | "Twende!" |
| `audio/voice_mwisho.ogg` | Crash / game over | "Mwisho! Mwisho!" |
| `audio/voice_mafuta.ogg` | Fuel drops below low threshold | "Mafuta!" |
| `audio/voice_kituo.ogg` | Bus stop approaching | "Kituo! Shusha!" |
| `audio/voice_karibu.ogg` | (spare hook — wire where you like) | "Karibu!" |

To add more: append the key to `VOICE_KEYS` in `autoload/audio_manager.gd`
and call `AudioManager.play_sfx("voice_x")` at the trigger.

## Where to get audio

- freesound.org (CC0/CC-BY — check licences)
- Record real daladala horns/ambience in Dar — nothing beats authentic
- Commission a short bongo flava loop from a local producer

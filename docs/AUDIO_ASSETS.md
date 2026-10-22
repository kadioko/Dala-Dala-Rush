# Audio Assets

Last verified: October 22, 2026. Rights ledger: `audio/SOURCES.md`.

Five synthetic Swahili placeholder WAV clips are now in `res://audio/`, approved
by the owner. They are not human recordings; provenance and exact lines are in
`audio/SOURCES.md`. SFX/music still use procedural fallbacks. Put cleared
recordings in `res://audio/` with these exact names; they are picked up automatically
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

## Swahili Voice Lines

Short shouted conductor (mpiga debe) lines add huge character. The trigger
points are already in the code; the **file-only** keys below now load short
synthetic WAV placeholders instead of remaining silent:

| File | Trigger | Line |
|---|---|---|
| `audio/voice_twende.wav` | Countdown "GO" | "Twende, twende!" |
| `audio/voice_mwisho.wav` | Crash / game over | "Mwisho, mwisho!" |
| `audio/voice_mafuta.wav` | Fuel drops below low threshold | "Mafuta!" |
| `audio/voice_kituo.wav` | Bus stop approaching | "Kituo! Shusha!" |
| `audio/voice_karibu.wav` | Spare hook | "Karibu, abiria!" |

The on-screen Swahili launch cue is also `TWENDE!`; keep the recording and
localized text synchronized.

To add more: append the key to `VOICE_KEYS` in `autoload/audio_manager.gd`
and call `AudioManager.play_sfx("voice_x")` at the trigger.

## Current Input Feedback

The horn is available from the center driving-dock button and only while it
has charges. On desktop/editor builds, `H` is the horn shortcut. Keep the horn
sample short enough that repeated charges remain distinct rather than becoming
a continuous wall of sound.

## Release Priority

1. Replace `horn.ogg`, `crash.ogg`, and `coin.ogg` first; these are heard most.
2. Add a licensed original music loop and verify seamless looping after app
   background/resume.
3. Record Swahili voice lines with clear permission from each performer.
4. Verify every asset's licence and keep attribution records when required.
5. Test volume balance through a phone speaker, cheap earphones, and with
   music/SFX toggles in both languages.

## Where to get audio

- freesound.org (CC0/CC-BY — check licences)
- Record real daladala horns/ambience in Dar — nothing beats authentic
- Commission a short bongo flava loop from a local producer

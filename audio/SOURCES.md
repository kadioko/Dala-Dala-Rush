# Audio Rights Ledger

Updated October 22, 2026.

The owner approved **synthetic Swahili placeholders**, not human recordings,
on October 22. The five mono PCM WAV files below were rendered locally with
eSpeak NG 1.51, Debian package `1.51+dfsg-10+deb12u2`, built-in `sw` formant
voice. There is no sampled performer, voice clone, cloud speech request, or
third-party music recording in these clips. SFX/music still use the project's
procedural synthesis. These robotic placeholders are not advertised as real
conductor recordings; native-speaker and phone-speaker review remains open.

Before adding any recording, record its filename, creator/performer, date,
source, licence or written permission, permitted redistribution/commercial
use, and required attribution here. Keep permission documents outside the
public repository if they contain personal information. Do not record nearby
people without permission or use recognizable background music.

| Filename | Text | Generator | Status |
|---|---|---|---|
| `voice_twende.wav` | Twende, twende! | eSpeak NG `sw` | Synthetic placeholder, countdown |
| `voice_mwisho.wav` | Mwisho, mwisho! | eSpeak NG `sw` | Synthetic placeholder, crash |
| `voice_mafuta.wav` | Mafuta! | eSpeak NG `sw` | Synthetic placeholder, low fuel |
| `voice_kituo.wav` | Kituo! Shusha! | eSpeak NG `sw` | Synthetic placeholder, approaching stop |
| `voice_karibu.wav` | Karibu, abiria! | eSpeak NG `sw` | Synthetic placeholder, spare hook |

All are mono, 22,050 Hz, 16-bit, 0.91-1.71 seconds, about 330 KB combined.
Measured peaks are below 0 dBFS. The build helper is
`tools/generate_swahili_placeholders.sh`; it installs the engine only in an
ephemeral build container. Used base image:
`debian:bookworm-slim@sha256:7ff6ba31527b9e336162fa061746c366c4b2032f4d2cff2078bea43f78efe3f8`.
It does not redistribute the engine executable or its voice-data bundle in
the Android app. The engine is GPLv3-or-later; generated output is distinct
from distributing that engine. See the [project licence](https://github.com/espeak-ng/espeak-ng/blob/master/COPYING),
[Swahili language listing](https://github.com/espeak-ng/espeak-ng/blob/master/docs/languages.md),
and [FSF output guidance](https://www.gnu.org/licenses/gpl-faq.en.html#GPLOutput).

Do not infer a human performer's consent or endorsement from synthetic output.
Original/commissioned conductor recordings can replace these exact filenames
after their rights and quality have been reviewed.

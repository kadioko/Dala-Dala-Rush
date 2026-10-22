#!/bin/sh
# Run inside debian:bookworm-slim with the project mounted at /workspace.
# Build-time synthesis only: no speech engine or voice data ships in the game.
set -eu
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y --no-install-recommends espeak-ng
espeak-ng --version
espeak-ng --voices=sw
espeak-ng -v sw -s 182 -p 42 -a 120 -g 3 -w audio/voice_twende.wav 'Twende, twende!'
espeak-ng -v sw -s 182 -p 42 -a 120 -g 3 -w audio/voice_mwisho.wav 'Mwisho, mwisho!'
espeak-ng -v sw -s 175 -p 44 -a 120 -g 3 -w audio/voice_mafuta.wav 'Mafuta!'
espeak-ng -v sw -s 180 -p 42 -a 120 -g 3 -w audio/voice_kituo.wav 'Kituo! Shusha!'
espeak-ng -v sw -s 180 -p 46 -a 120 -g 3 -w audio/voice_karibu.wav 'Karibu, abiria!'

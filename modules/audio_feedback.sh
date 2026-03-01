#!/bin/bash
# 🔊 AUDIO FEEDBACK MODULE v1.1
# Generates sci-fi UI sounds using SOX.
# Gracefully degrades when no audio device is available.

# Check for audio device once at load time
AUDIO_AVAILABLE=false
if command -v play &>/dev/null && aplay -l &>/dev/null 2>&1; then
    AUDIO_AVAILABLE=true
fi

play_tone() {
    $AUDIO_AVAILABLE || return 0
    local type=$1
    case $type in
        "startup")
            play -n -c1 synth 0.1 sine 400 fade 0 0.1 0.05 vol 0.3 &>/dev/null &
            sleep 0.05
            play -n -c1 synth 0.1 sine 800 fade 0 0.1 0.05 vol 0.3 &>/dev/null &
            ;;
        "click")
            play -n -c1 synth 0.05 sine 1200 fade 0 0.05 0.03 vol 0.1 &>/dev/null &
            ;;
        "confirm")
            play -n -c1 synth 0.08 sine 600 fade 0 0.08 0.05 vol 0.2 &>/dev/null &
            sleep 0.05
            play -n -c1 synth 0.1 sine 1000 fade 0 0.1 0.05 vol 0.2 &>/dev/null &
            ;;
        "error")
            play -n -c1 synth 0.2 saw 150 fade 0 0.2 0.1 vol 0.2 &>/dev/null &
            ;;
        "warning")
            play -n -c1 synth 0.15 sine 300 fade 0 0.15 0.08 vol 0.15 &>/dev/null &
            ;;
    esac
}

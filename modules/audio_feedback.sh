#!/bin/bash
# 🔊 AUDIO FEEDBACK MODULE
# Generates sci-fi UI sounds using SOX.

play_tone() {
    local type=$1
    case $type in
        "startup")
            play -n -c1 synth 0.1 sine 400 fade 0 0.1 0.1 vol 0.3 &>/dev/null &
            play -n -c1 synth 0.1 sine 800 fade 0 0.1 0.1 vol 0.3 &>/dev/null &
            ;;
        "click")
            play -n -c1 synth 0.05 sine 1200 fade 0 0.05 0.05 vol 0.1 &>/dev/null &
            ;;
        "confirm")
            play -n -c1 synth 0.1 sine 600 fade 0 0.1 0.1 vol 0.2 &>/dev/null &
            play -n -c1 synth 0.1 sine 1000 fade 0 0.1 0.1 vol 0.2 &>/dev/null &
            ;;
        "error")
            play -n -c1 synth 0.2 saw 150 fade 0 0.2 0.2 vol 0.2 &>/dev/null &
            ;;
    esac
}

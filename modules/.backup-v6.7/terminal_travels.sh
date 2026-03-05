#!/bin/bash
# 🕹️ TERMINAL TRAVELS MODULE
# Launches the curated text adventure collection.

play_games() {
    clear
    play_tone "confirm"
    cd ~/Projects/active/experiments/terminal-travels && ./terminal-travels
}

#!/usr/bin/env python3
"""Tiny on-demand SDR remote tuner + MP3 stream."""

from __future__ import annotations

import atexit
import json
import math
import os
import queue
import signal
import subprocess
import threading
import time
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse


def env_int(name: str, default: int, minimum: int, maximum: int) -> int:
    raw = os.environ.get(name)
    if raw is None:
        return default
    try:
        value = int(raw)
    except ValueError:
        return default
    return max(minimum, min(maximum, value))


LISTEN_HOST = os.environ.get("SDR_LISTEN_HOST", "172.17.0.1")
LISTEN_PORT = env_int("SDR_LISTEN_PORT", 8097, 1024, 65535)
STREAM_IDLE_TIMEOUT = env_int("SDR_IDLE_TIMEOUT", 180, 30, 1800)
MAX_LISTENERS = env_int("SDR_MAX_LISTENERS", 3, 1, 8)
MAX_POST_BYTES = env_int("SDR_MAX_POST_BYTES", 2048, 128, 16384)
START_COOLDOWN_SECONDS = 1.5
CHUNK_SIZE = 8192
httpd: ThreadingHTTPServer | None = None
ALLOWED_MODES = {"fm", "airband", "nfm"}
SECURITY_HEADERS = {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "SAMEORIGIN",
    "Referrer-Policy": "strict-origin-when-cross-origin",
    "Permissions-Policy": "camera=(), microphone=(), geolocation=()",
    "Content-Security-Policy": (
        "default-src 'self'; "
        "base-uri 'none'; "
        "frame-ancestors 'self'; "
        "connect-src 'self'; "
        "media-src 'self'; "
        "img-src 'self' data:; "
        "script-src 'unsafe-inline'; "
        "style-src 'unsafe-inline'"
    ),
}

RTL_MODULES = [
    "rtl2832_sdr",
    "rtl2832",
    "r820t",
    "dvb_usb_rtl28xxu",
    "dvb_usb_v2",
]

UI_HTML = """<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>SDR Remote</title>
  <style>
    :root {
      color-scheme: dark;
      --bg: #101113;
      --panel: #171b18;
      --panel-2: #0d120f;
      --line: rgba(121, 205, 159, 0.24);
      --ink: #f1f4e8;
      --muted: #a8baa8;
      --hot: #d8b85e;
      --warn: #ef7b63;
      --good: #74d99f;
      --cyan: #77d7d9;
      --berry: #dd7a9d;
    }
    * { box-sizing: border-box; }
    html { overflow-x: hidden; }
    body {
      margin: 0;
      min-height: 100vh;
      font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background:
        linear-gradient(180deg, rgba(14, 25, 18, 0.92), rgba(16, 17, 19, 1) 42rem),
        var(--bg);
      color: var(--ink);
      overflow-x: hidden;
    }
    .wrap {
      width: 100%;
      max-width: 960px;
      margin: 0 auto;
      padding: 18px 16px 42px;
    }
    .hero, .panel {
      border: 1px solid var(--line);
      background: rgba(23, 27, 24, 0.96);
      box-shadow: 0 16px 38px rgba(0,0,0,0.24);
      border-radius: 8px;
      overflow: hidden;
    }
    .hero { padding: 18px; }
    .hero-head {
      display: flex;
      justify-content: space-between;
      gap: 14px;
      align-items: start;
    }
    .hero-head > div {
      min-width: 0;
    }
    .transport-actions {
      display: flex;
      flex: 0 0 auto;
      gap: 8px;
      align-items: center;
    }
    h1 {
      margin: 0;
      font-size: 2.1rem;
      line-height: 1.05;
      letter-spacing: 0;
    }
    p { color: var(--muted); line-height: 1.48; }
    .lede {
      max-width: 42rem;
      margin: 8px 0 0;
      font-size: 1rem;
    }
    .statusbar {
      display: grid;
      grid-template-columns: repeat(4, minmax(0, 1fr));
      gap: 10px;
      margin-top: 16px;
    }
    .stat {
      padding: 11px 12px;
      min-width: 0;
      border-radius: 8px;
      background: rgba(7, 11, 9, 0.76);
      border: 1px solid rgba(121, 205, 159, 0.16);
    }
    .label {
      display: block;
      font-size: 0.72rem;
      letter-spacing: 0;
      overflow-wrap: anywhere;
      color: var(--muted);
      text-transform: uppercase;
      margin-bottom: 6px;
      font-weight: 700;
    }
    .value {
      font-family: "IBM Plex Mono", "SFMono-Regular", Consolas, monospace;
      font-size: 1rem;
      color: var(--ink);
      overflow-wrap: anywhere;
    }
    .panel {
      padding: 16px;
      margin-top: 14px;
    }
    .panel.compact {
      padding: 14px 16px;
    }
    .grid {
      display: grid;
      gap: 10px;
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
    }
    button, input, select {
      font: inherit;
      color: var(--ink);
      min-height: 44px;
      border-radius: 8px;
      border: 1px solid var(--line);
      background: #0d120f;
    }
    button {
      width: 100%;
      padding: 12px 14px;
      cursor: pointer;
      letter-spacing: 0;
      font-weight: 750;
    }
    button:hover,
    button:focus-visible {
      border-color: var(--good);
      outline: none;
      box-shadow: 0 0 0 3px rgba(116, 217, 159, 0.14);
    }
    button[disabled] {
      opacity: 0.55;
      cursor: wait;
    }
    button.hot {
      border-color: rgba(216,184,94,0.42);
      color: var(--hot);
      background: rgba(216,184,94,0.08);
    }
    button.primary {
      border-color: rgba(119, 215, 217, 0.45);
      color: #0b1012;
      background: var(--cyan);
    }
    button.stop {
      border-color: rgba(239,123,99,0.38);
      color: var(--warn);
      background: rgba(239,123,99,0.08);
    }
    button.mini,
    button.compact {
      width: auto;
      min-width: 5rem;
      padding: 10px 12px;
      font-size: 0.9rem;
    }
    .controls {
      display: grid;
      gap: 10px;
      grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
    }
    .custom {
      display: grid;
      gap: 10px;
      grid-template-columns: minmax(0, 1.15fr) minmax(11rem, 0.8fr) minmax(7rem, auto);
      margin-top: 12px;
    }
    input, select {
      padding: 12px 14px;
      width: 100%;
    }
    input:focus,
    select:focus {
      border-color: var(--cyan);
      outline: none;
      box-shadow: 0 0 0 3px rgba(119, 215, 217, 0.12);
    }
    audio {
      width: 100%;
      margin-top: 12px;
      min-width: 0;
      filter: hue-rotate(12deg) saturate(1.1);
    }
    body:not([data-stream="live"]) audio {
      display: none;
    }
    .hint { font-size: 0.92rem; }
    .status-message {
      min-height: 1.35rem;
      margin-top: 10px;
      color: var(--cyan);
      font-size: 0.95rem;
      font-weight: 700;
    }
    .links {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      margin-top: 10px;
      min-width: 0;
    }
    .links code,
    .utility-row code {
      display: inline-block;
      max-width: 100%;
      padding: 8px 10px;
      border-radius: 8px;
      border: 1px solid rgba(119, 215, 217, 0.18);
      background: rgba(7, 11, 9, 0.68);
      color: var(--ink);
      overflow-wrap: anywhere;
      white-space: normal;
      font-family: "IBM Plex Mono", "SFMono-Regular", Consolas, monospace;
    }
    .visual-wrap {
      margin-top: 12px;
      border-radius: 8px;
      overflow: hidden;
      border: 1px solid rgba(121, 205, 159, 0.18);
      background:
        linear-gradient(180deg, rgba(7,11,9,0.95), rgba(15,22,17,0.95)),
        repeating-linear-gradient(90deg, rgba(116,217,159,0.05) 0, rgba(116,217,159,0.05) 1px, transparent 1px, transparent 24px);
    }
    #viz {
      width: 100%;
      height: 160px;
      display: block;
    }
    .favorite-tools {
      display: grid;
      gap: 10px;
      grid-template-columns: minmax(0, 1.2fr) auto auto;
      margin-top: 12px;
    }
    .favorites-list {
      display: grid;
      gap: 10px;
      margin-top: 12px;
    }
    .favorite-item {
      display: grid;
      gap: 8px;
      grid-template-columns: minmax(0, 1fr) auto;
      align-items: center;
    }
    .favorite-item button:first-child {
      text-align: left;
      text-transform: none;
      letter-spacing: 0;
    }
    .favorite-meta {
      display: block;
      margin-top: 4px;
      font-size: 0.84rem;
      color: var(--muted);
    }
    .msgline {
      min-height: 1.3em;
      margin-top: 10px;
      color: var(--muted);
      font-size: 0.92rem;
    }
    .note {
      margin-top: 12px;
      padding: 12px 14px;
      border-radius: 8px;
      border: 1px solid rgba(216,184,94,0.22);
      background: rgba(216,184,94,0.07);
      color: #f2ddb0;
      line-height: 1.42;
    }
    .note strong { color: var(--hot); }
    .utility-row {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      align-items: center;
    }
    .utility-row a {
      color: var(--cyan);
      font-weight: 700;
    }
    @media (max-width: 720px) {
      .wrap {
        padding: 10px 8px 28px;
      }
      .hero,
      .panel {
        padding: 14px;
      }
      .hero-head {
        align-items: start;
      }
      .transport-actions {
        flex-direction: column;
      }
      h1 {
        font-size: 1.55rem;
        line-height: 1.1;
      }
      .lede {
        font-size: 0.95rem;
      }
      .statusbar {
        grid-template-columns: repeat(2, minmax(0, 1fr));
      }
      .controls {
        grid-template-columns: 1fr;
      }
      .custom { grid-template-columns: 1fr; }
      .favorite-tools { grid-template-columns: 1fr; }
      .favorite-item { grid-template-columns: 1fr; }
      button.mini,
      button.compact { width: 5rem; }
      #viz { height: 140px; }
    }
  </style>
</head>
<body>
  <div class="wrap">
    <section class="hero">
      <div class="hero-head">
        <div>
          <h1>SDR Remote</h1>
          <p class="lede">Tune the Pi dongle and listen from this browser.</p>
        </div>
        <div class="transport-actions">
          <button class="compact primary" id="playBtn" type="button">Play</button>
          <button class="compact stop" data-stop type="button">Stop</button>
        </div>
      </div>
      <div class="statusbar">
        <div class="stat"><span class="label">State</span><span class="value" id="state">idle</span></div>
        <div class="stat"><span class="label">Mode</span><span class="value" id="mode">--</span></div>
        <div class="stat"><span class="label">Frequency</span><span class="value" id="freq">--</span></div>
        <div class="stat"><span class="label">Listeners</span><span class="value" id="listeners">0</span></div>
      </div>
      <audio id="player" controls preload="none"></audio>
      <div class="status-message" id="statusMsg" role="status" aria-live="polite">Ready.</div>
      <div class="note">
        <strong>Analog only.</strong> FM, airband, marine, ham, and old-school utility chatter are fair game here.
        Modern emergency traffic is often digital, trunked, or encrypted.
      </div>
    </section>

    <section class="panel compact">
      <span class="label">FM Presets</span>
      <div class="controls">
        <button class="hot" data-mode="fm" data-freq="106.7" data-label="PBS 106.7" type="button">PBS 106.7</button>
        <button class="hot" data-mode="fm" data-freq="102.7" data-label="Triple R 102.7" type="button">Triple R 102.7</button>
        <button class="hot" data-mode="fm" data-freq="94.9" data-label="JOY 94.9" type="button">JOY 94.9</button>
        <button class="hot" data-mode="fm" data-freq="90.7" data-label="SYN 90.7" type="button">SYN 90.7</button>
        <button class="hot" data-mode="fm" data-freq="105.9" data-label="ABC Classic 105.9" type="button">ABC Classic 105.9</button>
      </div>
    </section>

    <section class="panel compact">
      <span class="label">Custom Tune</span>
      <div class="custom">
        <input id="freqInput" type="text" inputmode="decimal" placeholder="Frequency MHz e.g. 118.0 or 460.550">
        <select id="modeInput">
          <option value="fm">FM</option>
          <option value="airband">Airband AM</option>
          <option value="nfm">Analog NFM</option>
        </select>
        <button id="startCustom" type="button">Start</button>
      </div>
    </section>

    <section class="panel compact">
      <span class="label">Airband Starters</span>
      <div class="controls">
        <button data-mode="airband" data-freq="118.0" data-label="Band Edge 118.0" type="button">Band Edge 118.0</button>
        <button data-mode="airband" data-freq="121.5" data-label="Guard 121.5" type="button">Guard 121.5</button>
        <button data-mode="airband" data-freq="123.45" data-label="Air-to-Air 123.45" type="button">Air-to-Air 123.45</button>
      </div>
    </section>

    <section class="panel compact">
      <span class="label">Analog Utility Starters</span>
      <div class="controls">
        <button data-mode="nfm" data-freq="146.5" data-label="2m Ham 146.5" type="button">2m Ham 146.5</button>
        <button data-mode="nfm" data-freq="156.8" data-label="Marine 16 156.8" type="button">Marine 16 156.8</button>
        <button data-mode="nfm" data-freq="460.550" data-label="Utility 460.550" type="button">Utility 460.550</button>
      </div>
    </section>

    <section class="panel">
      <span class="label">Signal View</span>
      <p class="hint">Browser-side audio spectrum. No extra Pi tax beyond the stream itself.</p>
      <div class="visual-wrap">
        <canvas id="viz" width="900" height="180"></canvas>
      </div>
    </section>

    <section class="panel">
      <span class="label">Favorites</span>
      <div class="favorite-tools">
        <input id="favoriteName" type="text" placeholder="Optional label for current tune">
        <button id="saveFavorite" type="button">Save Current</button>
        <button class="mini stop" id="clearFavorites" type="button">Clear All</button>
      </div>
      <div class="msgline" id="favoriteMsg"></div>
      <div class="favorites-list" id="favoritesList"></div>
    </section>

    <section class="panel compact">
      <span class="label">Diagnostics</span>
      <div class="utility-row">
        <code>~/pibulus-os/scripts/sdr_lab.sh remote-status</code>
        <a href="/deck/help.html">Deck Help</a>
      </div>
      <div class="links">
        <code id="pageUrl"></code>
        <code id="streamUrl"></code>
      </div>
    </section>
  </div>

  <script>
    const FAVORITES_KEY = 'pibulus.sdr.favorites.v1';
    const player = document.getElementById('player');
    const pageUrl = document.getElementById('pageUrl');
    const streamUrl = document.getElementById('streamUrl');
    const viz = document.getElementById('viz');
    const vizCtx = viz.getContext('2d');
    const favoriteName = document.getElementById('favoriteName');
    const favoriteMsg = document.getElementById('favoriteMsg');
    const favoritesList = document.getElementById('favoritesList');
    const freqInput = document.getElementById('freqInput');
    const modeInput = document.getElementById('modeInput');
    const statusMsg = document.getElementById('statusMsg');
    const playBtn = document.getElementById('playBtn');
    const RETUNE_COOLDOWN_MS = 1700;
    pageUrl.textContent = window.location.href;
    streamUrl.textContent = new URL('./stream.mp3', window.location.href).href;
    let currentStatus = { active: false, mode: null, frequency_mhz: null, listeners: 0 };
    let messageTimer = null;
    let statusMessageTimer = null;
    let streamToken = 0;
    let lastTune = { mode: 'fm', freq: '106.7' };
    let lastStartAt = 0;
    let busyTimer = null;
    let audioCtx = null;
    let analyser = null;
    let sourceNode = null;
    let freqData = null;
    let waveData = null;
    const presetLabels = {};

    function modeLabel(mode) {
      return ({ fm: 'FM', airband: 'Airband', nfm: 'Analog NFM' })[mode] || mode || '--';
    }

    function favoriteKey(mode, freq) {
      return mode + ':' + String(freq);
    }

    function flashMessage(text) {
      favoriteMsg.textContent = text;
      if (messageTimer) window.clearTimeout(messageTimer);
      messageTimer = window.setTimeout(function() {
        favoriteMsg.textContent = '';
      }, 2600);
    }

    function setStatusMessage(text, timeout) {
      statusMsg.textContent = text || '';
      if (statusMessageTimer) window.clearTimeout(statusMessageTimer);
      if (timeout) {
        statusMessageTimer = window.setTimeout(function() {
          statusMsg.textContent = currentStatus.active ? 'Stream live.' : 'Ready.';
        }, timeout);
      }
    }

    function setControlsBusy(busy) {
      if (busyTimer) {
        window.clearTimeout(busyTimer);
        busyTimer = null;
      }
      document.querySelectorAll('button[data-mode], #startCustom').forEach(function(button) {
        button.disabled = busy;
      });
      document.body.dataset.busy = busy ? 'true' : 'false';
    }

    function releaseControlsAfterCooldown() {
      const remaining = Math.max(0, RETUNE_COOLDOWN_MS - (Date.now() - lastStartAt));
      busyTimer = window.setTimeout(function() {
        setControlsBusy(false);
      }, remaining);
    }

    function loadFavorites() {
      try {
        const raw = localStorage.getItem(FAVORITES_KEY);
        const parsed = raw ? JSON.parse(raw) : [];
        if (!Array.isArray(parsed)) return [];
        return parsed.filter(function(item) {
          return item && typeof item.name === 'string' && typeof item.mode === 'string' && typeof item.freq === 'string';
        }).slice(0, 16);
      } catch (err) {
        return [];
      }
    }

    function saveFavorites(items) {
      localStorage.setItem(FAVORITES_KEY, JSON.stringify(items.slice(0, 16)));
    }

    function renderFavorites() {
      const items = loadFavorites();
      favoritesList.innerHTML = '';
      if (!items.length) {
        const empty = document.createElement('div');
        empty.className = 'hint';
        empty.textContent = 'No favorites saved yet.';
        favoritesList.appendChild(empty);
        return;
      }

      items.forEach(function(item, index) {
        const row = document.createElement('div');
        row.className = 'favorite-item';

        const tuneBtn = document.createElement('button');
        const meta = modeLabel(item.mode) + ' · ' + item.freq + ' MHz';
        tuneBtn.textContent = item.name + ' — ' + meta;
        tuneBtn.addEventListener('click', function() {
          favoriteName.value = item.name;
          start(item.mode, item.freq);
        });

        const deleteBtn = document.createElement('button');
        deleteBtn.className = 'mini stop';
        deleteBtn.textContent = 'Delete';
        deleteBtn.addEventListener('click', function() {
          const next = loadFavorites();
          next.splice(index, 1);
          saveFavorites(next);
          renderFavorites();
          flashMessage('Favorite removed.');
        });

        row.appendChild(tuneBtn);
        row.appendChild(deleteBtn);
        favoritesList.appendChild(row);
      });
    }

    function currentFavoriteCandidate() {
      const mode = (currentStatus && currentStatus.mode) || modeInput.value;
      const freq = (currentStatus && currentStatus.frequency_mhz) || freqInput.value.trim();
      if (!mode || !freq) return null;
      const label = favoriteName.value.trim() || presetLabels[favoriteKey(mode, freq)] || (modeLabel(mode) + ' ' + freq);
      return { name: label, mode: mode, freq: String(freq) };
    }

    function saveCurrentFavorite() {
      const candidate = currentFavoriteCandidate();
      if (!candidate) {
        flashMessage('Pick or start a station first.');
        return;
      }
      const items = loadFavorites();
      const key = favoriteKey(candidate.mode, candidate.freq);
      const deduped = items.filter(function(item) {
        return favoriteKey(item.mode, item.freq) !== key;
      });
      deduped.unshift(candidate);
      saveFavorites(deduped);
      favoriteName.value = '';
      renderFavorites();
      flashMessage('Saved ' + candidate.name + '.');
    }

    function drawIdleSpectrum() {
      const width = viz.width;
      const height = viz.height;
      vizCtx.clearRect(0, 0, width, height);
      const gradient = vizCtx.createLinearGradient(0, 0, 0, height);
      gradient.addColorStop(0, 'rgba(57,217,138,0.15)');
      gradient.addColorStop(1, 'rgba(3,10,6,0.12)');
      vizCtx.fillStyle = gradient;
      vizCtx.fillRect(0, 0, width, height);
      vizCtx.strokeStyle = 'rgba(57,217,138,0.12)';
      vizCtx.lineWidth = 1;
      for (let y = 20; y < height; y += 20) {
        vizCtx.beginPath();
        vizCtx.moveTo(0, y + 0.5);
        vizCtx.lineTo(width, y + 0.5);
        vizCtx.stroke();
      }
      vizCtx.fillStyle = 'rgba(218,246,221,0.55)';
      vizCtx.font = '16px IBM Plex Mono, monospace';
      vizCtx.fillText('Signal view wakes up when audio is playing.', 18, height / 2);
    }

    function ensureAudioGraph() {
      if (audioCtx) return;
      const AudioContext = window.AudioContext || window.webkitAudioContext;
      if (!AudioContext) return;
      audioCtx = new AudioContext();
      sourceNode = audioCtx.createMediaElementSource(player);
      analyser = audioCtx.createAnalyser();
      analyser.fftSize = 256;
      analyser.smoothingTimeConstant = 0.84;
      freqData = new Uint8Array(analyser.frequencyBinCount);
      waveData = new Uint8Array(analyser.fftSize);
      sourceNode.connect(analyser);
      analyser.connect(audioCtx.destination);
    }

    function drawSpectrum() {
      window.requestAnimationFrame(drawSpectrum);
      const width = viz.width;
      const height = viz.height;
      vizCtx.clearRect(0, 0, width, height);
      drawIdleSpectrum();
      if (!analyser || player.paused || !player.src) return;

      analyser.getByteFrequencyData(freqData);
      analyser.getByteTimeDomainData(waveData);

      const barWidth = width / freqData.length;
      for (let i = 0; i < freqData.length; i += 1) {
        const magnitude = freqData[i] / 255;
        const barHeight = Math.max(3, magnitude * (height - 26));
        const x = i * barWidth;
        const hue = 120 - Math.min(65, i * 0.4);
        vizCtx.fillStyle = 'hsla(' + hue + ', 85%, 58%, 0.82)';
        vizCtx.fillRect(x, height - barHeight, Math.max(2, barWidth - 2), barHeight);
      }

      vizCtx.beginPath();
      vizCtx.lineWidth = 2;
      vizCtx.strokeStyle = 'rgba(255,176,0,0.9)';
      for (let i = 0; i < waveData.length; i += 1) {
        const x = (i / (waveData.length - 1)) * width;
        const y = (waveData[i] / 255) * height;
        if (i === 0) vizCtx.moveTo(x, y);
        else vizCtx.lineTo(x, y);
      }
      vizCtx.stroke();
    }

    function setStatus(data) {
      currentStatus = data || currentStatus;
      document.getElementById('state').textContent = data.active ? 'live' : 'idle';
      document.getElementById('mode').textContent = data.mode || '--';
      document.getElementById('freq').textContent = data.frequency_mhz ? data.frequency_mhz + ' MHz' : '--';
      document.getElementById('listeners').textContent = String(data.listeners || 0);
      document.body.dataset.stream = data.active ? 'live' : 'idle';
      playBtn.textContent = data.active ? 'Play' : 'Play';
    }

    function refreshStatus() {
      fetch('./status', { cache: 'no-store' })
        .then(r => r.json())
        .then(setStatus)
        .catch(() => {});
    }

    function attachAudio(token) {
      ensureAudioGraph();
      if (audioCtx && audioCtx.state === 'suspended') {
        audioCtx.resume().catch(function(){});
      }
      player.src = './stream.mp3?ts=' + Date.now();
      player.load();
      const playAttempt = player.play();
      if (playAttempt && typeof playAttempt.catch === 'function') {
        playAttempt
          .then(function() {
            if (token === streamToken && currentStatus.active) {
              setStatusMessage('Playing on this device.');
            }
          })
          .catch(function() {
            if (token === streamToken && currentStatus.active) {
              setStatusMessage('Stream is live. Press Play again or use the audio bar.');
            }
          });
      }
    }

    function start(mode, freq) {
      const now = Date.now();
      const remaining = RETUNE_COOLDOWN_MS - (now - lastStartAt);
      if (remaining > 0) {
        setStatusMessage('Give the dongle a second before retuning.', remaining);
        return;
      }
      lastStartAt = now;
      lastTune = { mode: mode, freq: String(freq) };
      const token = ++streamToken;
      setControlsBusy(true);
      setStatusMessage('Tuning ' + modeLabel(mode) + ' ' + freq + ' MHz...');
      fetch('./start', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ mode, freq })
      })
      .then(function(r) {
        return r.json().then(function(data) {
          if (!r.ok) {
            throw new Error(data.error || 'start failed');
          }
          return data;
        });
      })
      .then(data => {
        setStatus(data);
        freqInput.value = String(freq);
        modeInput.value = mode;
        attachAudio(token);
      })
      .catch(function(err) {
        if (token === streamToken) {
          setStatusMessage(err.message || 'Start failed.');
        }
      })
      .finally(function() {
        releaseControlsAfterCooldown();
      });
    }

    function playCurrent() {
      if (currentStatus.active) {
        setStatusMessage('Connecting audio...');
        attachAudio(streamToken);
        return;
      }
      const mode = lastTune.mode || modeInput.value || 'fm';
      const freq = lastTune.freq || freqInput.value.trim() || '106.7';
      start(mode, freq);
    }

    document.querySelectorAll('button[data-mode]').forEach(btn => {
      presetLabels[favoriteKey(btn.dataset.mode, btn.dataset.freq)] = btn.dataset.label || btn.textContent.trim();
      btn.addEventListener('click', () => start(btn.dataset.mode, btn.dataset.freq));
    });

    document.getElementById('startCustom').addEventListener('click', () => {
      const mode = modeInput.value;
      const freq = freqInput.value.trim();
      if (!freq) return;
      start(mode, freq);
    });
    playBtn.addEventListener('click', playCurrent);

    document.getElementById('saveFavorite').addEventListener('click', saveCurrentFavorite);
    document.getElementById('clearFavorites').addEventListener('click', function() {
      if (!loadFavorites().length) {
        flashMessage('No favorites to clear.');
        return;
      }
      localStorage.removeItem(FAVORITES_KEY);
      renderFavorites();
      flashMessage('Favorites cleared.');
    });
    favoriteName.addEventListener('keydown', function(ev) {
      if (ev.key === 'Enter') saveCurrentFavorite();
    });

    function stopStream() {
      streamToken += 1;
      setStatusMessage('Stopping stream...');
      fetch('./stop', { method: 'POST' })
        .then(function(r) {
          return r.json().then(function(data) {
            if (!r.ok) {
              throw new Error(data.error || 'stop failed');
            }
            return data;
          });
        })
        .then(data => {
          setStatus(data);
          player.pause();
          player.removeAttribute('src');
          player.load();
          setStatusMessage('Stopped.', 1800);
        })
        .catch(function(err) {
          setStatusMessage(err.message || 'Stop failed.');
        });
    }

    document.querySelectorAll('[data-stop]').forEach(function(button) {
      button.addEventListener('click', stopStream);
    });

    player.addEventListener('play', function() {
      ensureAudioGraph();
      if (audioCtx && audioCtx.state === 'suspended') {
        audioCtx.resume().catch(function(){});
      }
    });
    player.addEventListener('playing', function() {
      if (currentStatus.active && player.src) {
        setStatusMessage('Playing on this device.');
      }
    });
    player.addEventListener('waiting', function() {
      if (currentStatus.active && player.src) {
        setStatusMessage('Buffering stream...');
      }
    });
    player.addEventListener('error', function() {
      if (currentStatus.active && player.src) {
        setStatusMessage('Stream is live, but the browser audio element hit an error. Try Start again.');
      }
    });

    drawIdleSpectrum();
    drawSpectrum();
    renderFavorites();
    refreshStatus();
    setInterval(refreshStatus, 5000);
  </script>
</body>
</html>
"""


def json_bytes(payload: dict) -> bytes:
    return json.dumps(payload, indent=2, sort_keys=True).encode("utf-8")


class StreamManager:
    def __init__(self) -> None:
        self.lock = threading.RLock()
        self.listeners: dict[int, queue.Queue[bytes]] = {}
        self.next_listener_id = 1
        self.mode: str | None = None
        self.frequency_mhz: str | None = None
        self.rtl_proc: subprocess.Popen[bytes] | None = None
        self.ffmpeg_proc: subprocess.Popen[bytes] | None = None
        self.pump_thread: threading.Thread | None = None
        self.watchdog_thread = threading.Thread(target=self._watchdog_loop, daemon=True)
        self.started_at = 0.0
        self.last_activity = 0.0
        self.last_error = ""
        self.last_start_request = 0.0
        self.stopping = False
        self.watchdog_thread.start()

    def status(self) -> dict:
        with self.lock:
            active = self.ffmpeg_proc is not None and self.ffmpeg_proc.poll() is None
            return {
                "active": active,
                "mode": self.mode,
                "frequency_mhz": self.frequency_mhz,
                "listeners": len(self.listeners),
                "max_listeners": MAX_LISTENERS,
                "uptime_seconds": round(time.time() - self.started_at, 1) if active else 0,
                "idle_timeout_seconds": STREAM_IDLE_TIMEOUT,
                "last_error": self.last_error,
            }

    def _release_kernel_modules(self) -> None:
        for mod in RTL_MODULES:
            subprocess.run(["/usr/sbin/modprobe", "-r", mod], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)

    def _restore_kernel_modules(self) -> None:
        for mod in ["dvb_usb_rtl28xxu", "rtl2832", "rtl2832_sdr", "r820t"]:
            subprocess.run(["/usr/sbin/modprobe", mod], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)

    def _build_commands(self, mode: str, freq: str) -> tuple[list[str], list[str]]:
        if mode == "fm":
            rtl_cmd = ["rtl_fm", "-f", f"{freq}M", "-M", "wbfm", "-s", "200000", "-r", "48000", "-"]
            ffmpeg_cmd = [
                "ffmpeg", "-nostdin", "-loglevel", "error",
                "-f", "s16le", "-ar", "48000", "-ac", "1", "-i", "pipe:0",
                "-vn", "-ac", "1", "-ar", "44100",
                "-c:a", "libmp3lame", "-b:a", "96k",
                "-f", "mp3", "pipe:1",
            ]
        elif mode == "airband":
            rtl_cmd = ["rtl_fm", "-f", f"{freq}M", "-M", "am", "-s", "12000", "-r", "24000", "-A", "fast", "-"]
            ffmpeg_cmd = [
                "ffmpeg", "-nostdin", "-loglevel", "error",
                "-f", "s16le", "-ar", "24000", "-ac", "1", "-i", "pipe:0",
                "-vn", "-ac", "1", "-ar", "32000",
                "-c:a", "libmp3lame", "-b:a", "48k",
                "-f", "mp3", "pipe:1",
            ]
        elif mode == "nfm":
            rtl_cmd = ["rtl_fm", "-f", f"{freq}M", "-M", "fm", "-s", "24000", "-r", "24000", "-A", "fast", "-E", "dc", "-"]
            ffmpeg_cmd = [
                "ffmpeg", "-nostdin", "-loglevel", "error",
                "-f", "s16le", "-ar", "24000", "-ac", "1", "-i", "pipe:0",
                "-vn", "-ac", "1", "-ar", "32000",
                "-c:a", "libmp3lame", "-b:a", "48k",
                "-f", "mp3", "pipe:1",
            ]
        else:
            raise ValueError(f"unsupported mode: {mode}")
        return rtl_cmd, ffmpeg_cmd

    def _valid_frequency(self, mode: str, raw: str) -> float:
        if mode not in ALLOWED_MODES:
            raise ValueError("mode must be one of: fm, airband, nfm")
        try:
            freq = float(raw)
        except ValueError as exc:
            raise ValueError("frequency must be numeric") from exc
        if not math.isfinite(freq):
            raise ValueError("frequency must be finite")

        if mode == "fm" and not (64.0 <= freq <= 108.5):
            raise ValueError("FM frequency should be between 64.0 and 108.5 MHz")
        if mode == "airband" and not (108.0 <= freq <= 137.0):
            raise ValueError("airband frequency should be between 108.0 and 137.0 MHz")
        if mode == "nfm" and not (30.0 <= freq <= 960.0):
            raise ValueError("analog NFM frequency should be between 30.0 and 960.0 MHz")
        return freq

    def start(self, mode: str, raw_freq: str) -> dict:
        mode = mode.strip().lower()
        freq = self._valid_frequency(mode, raw_freq)
        freq_text = f"{freq:.3f}".rstrip("0").rstrip(".")
        rtl_cmd, ffmpeg_cmd = self._build_commands(mode, freq_text)

        with self.lock:
            now = time.time()
            if now - self.last_start_request < START_COOLDOWN_SECONDS:
                raise ValueError("tuning too quickly; wait a second")
            self.last_start_request = now
            self._stop_locked(restore_modules=True)
            self.last_error = ""
            self.listeners.clear()
            self._release_kernel_modules()
            try:
                self.rtl_proc = subprocess.Popen(
                    rtl_cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.DEVNULL,
                    preexec_fn=os.setsid,
                    bufsize=0,
                )
                assert self.rtl_proc.stdout is not None
                self.ffmpeg_proc = subprocess.Popen(
                    ffmpeg_cmd,
                    stdin=self.rtl_proc.stdout,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.DEVNULL,
                    preexec_fn=os.setsid,
                    bufsize=0,
                )
                self.rtl_proc.stdout.close()
            except Exception:
                self._stop_locked(restore_modules=True)
                raise
            self.mode = mode
            self.frequency_mhz = freq_text
            self.started_at = time.time()
            self.last_activity = self.started_at
            self.stopping = False
            self.pump_thread = threading.Thread(target=self._pump_stream, daemon=True)
            self.pump_thread.start()
            time.sleep(0.35)
            if self.rtl_proc and self.rtl_proc.poll() is not None:
                self.last_error = "rtl_fm exited immediately. Device busy or invalid tune."
                self._stop_locked(restore_modules=True)
                raise RuntimeError(self.last_error)
            if self.ffmpeg_proc and self.ffmpeg_proc.poll() is not None:
                self.last_error = "ffmpeg exited immediately. Stream pipeline failed."
                self._stop_locked(restore_modules=True)
                raise RuntimeError(self.last_error)
            return self.status()

    def stop(self) -> dict:
        with self.lock:
            self._stop_locked(restore_modules=True)
            return self.status()

    def _stop_locked(self, restore_modules: bool) -> None:
        self.stopping = True
        for proc in [self.ffmpeg_proc, self.rtl_proc]:
            if proc is None:
                continue
            try:
                os.killpg(os.getpgid(proc.pid), signal.SIGTERM)
            except ProcessLookupError:
                pass
            except Exception:
                proc.terminate()
        for proc in [self.ffmpeg_proc, self.rtl_proc]:
            if proc is None:
                continue
            try:
                proc.wait(timeout=1.5)
            except subprocess.TimeoutExpired:
                try:
                    os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
                except Exception:
                    proc.kill()
        self.ffmpeg_proc = None
        self.rtl_proc = None
        self.listeners.clear()
        self.mode = None
        self.frequency_mhz = None
        self.started_at = 0.0
        self.last_activity = time.time()
        self.stopping = False
        if restore_modules:
            self._restore_kernel_modules()

    def _pump_stream(self) -> None:
        proc = self.ffmpeg_proc
        if proc is None or proc.stdout is None:
            return

        try:
            while True:
                chunk = proc.stdout.read(CHUNK_SIZE)
                if not chunk:
                    break
                with self.lock:
                    listener_items = list(self.listeners.items())
                for listener_id, listener_queue in listener_items:
                    try:
                        listener_queue.put_nowait(chunk)
                    except queue.Full:
                        try:
                            listener_queue.get_nowait()
                        except queue.Empty:
                            pass
                        try:
                            listener_queue.put_nowait(chunk)
                        except queue.Full:
                            self.unregister(listener_id)
        finally:
            with self.lock:
                if not self.stopping:
                    self._stop_locked(restore_modules=True)

    def _watchdog_loop(self) -> None:
        while True:
            time.sleep(5)
            should_stop = False
            with self.lock:
                active = self.ffmpeg_proc is not None and self.ffmpeg_proc.poll() is None
                if active and not self.listeners and (time.time() - self.last_activity) > STREAM_IDLE_TIMEOUT:
                    should_stop = True
            if should_stop:
                self.stop()

    def register(self) -> tuple[int, queue.Queue[bytes]] | tuple[None, None]:
        with self.lock:
            active = self.ffmpeg_proc is not None and self.ffmpeg_proc.poll() is None
            if not active:
                return None, None
            if len(self.listeners) >= MAX_LISTENERS:
                return None, None
            listener_id = self.next_listener_id
            self.next_listener_id += 1
            listener_queue: queue.Queue[bytes] = queue.Queue(maxsize=48)
            self.listeners[listener_id] = listener_queue
            self.last_activity = time.time()
            return listener_id, listener_queue

    def unregister(self, listener_id: int | None) -> None:
        if listener_id is None:
            return
        with self.lock:
            self.listeners.pop(listener_id, None)
            self.last_activity = time.time()


manager = StreamManager()


class SDRHTTPServer(ThreadingHTTPServer):
    allow_reuse_address = True


class Handler(BaseHTTPRequestHandler):
    server_version = "sdr-remote/1.0"

    def log_message(self, fmt: str, *args) -> None:
        syslog = f"{self.address_string()} - {fmt % args}"
        print(syslog, flush=True)

    def _send_common_headers(self, content_type: str | None = None) -> None:
        if content_type:
            self.send_header("Content-Type", content_type)
        self.send_header("Cache-Control", "no-store")
        for header, value in SECURITY_HEADERS.items():
            self.send_header(header, value)

    def _send_bytes(self, status: int, payload: bytes, content_type: str) -> None:
        self.send_response(status)
        self._send_common_headers(content_type)
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def _send_json(self, status: int, payload: dict) -> None:
        self._send_bytes(status, json_bytes(payload), "application/json")

    def _send_head(self, status: int, content_type: str) -> None:
        self.send_response(status)
        self._send_common_headers(content_type)
        self.end_headers()

    def _read_json(self) -> dict:
        try:
            length = int(self.headers.get("Content-Length", "0") or 0)
        except ValueError as exc:
            raise ValueError("invalid Content-Length") from exc
        if length > MAX_POST_BYTES:
            raise ValueError("request body too large")
        if length <= 0:
            return {}
        raw = self.rfile.read(length)
        try:
            payload = json.loads(raw.decode("utf-8"))
        except json.JSONDecodeError as exc:
            raise ValueError("invalid JSON body") from exc
        if not isinstance(payload, dict):
            raise ValueError("JSON body must be an object")
        return payload

    def do_HEAD(self) -> None:
        path = urlparse(self.path).path
        if path in ["/", ""]:
            self._send_head(HTTPStatus.OK, "text/html; charset=utf-8")
            return
        if path == "/status":
            self._send_head(HTTPStatus.OK, "application/json")
            return
        if path == "/stream.mp3":
            status = manager.status()
            self._send_head(HTTPStatus.OK if status["active"] else HTTPStatus.CONFLICT, "audio/mpeg")
            return
        self._send_head(HTTPStatus.NOT_FOUND, "application/json")

    def do_GET(self) -> None:
        path = urlparse(self.path).path
        if path in ["/", ""]:
            self._send_bytes(HTTPStatus.OK, UI_HTML.encode("utf-8"), "text/html; charset=utf-8")
            return
        if path == "/status":
            self._send_json(HTTPStatus.OK, manager.status())
            return
        if path == "/stream.mp3":
            listener_id, listener_queue = manager.register()
            if listener_id is None or listener_queue is None:
                status = manager.status()
                error = "listener limit reached" if status["active"] else "stream is idle"
                self._send_json(HTTPStatus.CONFLICT, {"error": error})
                return
            self.send_response(HTTPStatus.OK)
            self._send_common_headers("audio/mpeg")
            self.send_header("X-Accel-Buffering", "no")
            self.end_headers()
            try:
                while True:
                    try:
                        chunk = listener_queue.get(timeout=1.0)
                    except queue.Empty:
                        status = manager.status()
                        if not status["active"]:
                            break
                        continue
                    self.wfile.write(chunk)
                    self.wfile.flush()
            except (BrokenPipeError, ConnectionResetError):
                pass
            finally:
                manager.unregister(listener_id)
            return
        self._send_json(HTTPStatus.NOT_FOUND, {"error": "not found"})

    def do_POST(self) -> None:
        path = urlparse(self.path).path
        try:
            if path == "/start":
                body = self._read_json()
                status = manager.start(str(body.get("mode", "")).strip(), str(body.get("freq", "")).strip())
                self._send_json(HTTPStatus.OK, status)
                return
            if path == "/stop":
                self._send_json(HTTPStatus.OK, manager.stop())
                return
        except ValueError as exc:
            self._send_json(HTTPStatus.BAD_REQUEST, {"error": str(exc)})
            return
        except Exception as exc:
            manager.last_error = str(exc)
            self._send_json(HTTPStatus.INTERNAL_SERVER_ERROR, {"error": str(exc)})
            return
        self._send_json(HTTPStatus.NOT_FOUND, {"error": "not found"})


def shutdown(*_: object) -> None:
    manager.stop()
    global httpd
    if httpd is not None:
        threading.Thread(target=httpd.shutdown, daemon=True).start()


def main() -> None:
    global httpd
    atexit.register(shutdown)
    signal.signal(signal.SIGTERM, shutdown)
    signal.signal(signal.SIGINT, shutdown)
    httpd = SDRHTTPServer((LISTEN_HOST, LISTEN_PORT), Handler)
    httpd.daemon_threads = True
    print(f"sdr_remote listening on {LISTEN_HOST}:{LISTEN_PORT}", flush=True)
    try:
        httpd.serve_forever()
    finally:
        httpd.server_close()


if __name__ == "__main__":
    main()

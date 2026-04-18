#!/usr/bin/env python3
"""Tiny on-demand SDR remote tuner + MP3 stream."""

from __future__ import annotations

import atexit
import json
import os
import queue
import signal
import subprocess
import threading
import time
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


LISTEN_HOST = "0.0.0.0"
LISTEN_PORT = 8097
STREAM_IDLE_TIMEOUT = 180
CHUNK_SIZE = 8192
httpd: ThreadingHTTPServer | None = None

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
      --bg: #07110a;
      --panel: #0f1f15;
      --line: #214c31;
      --ink: #daf6dd;
      --muted: #7ec69a;
      --hot: #ffb000;
      --warn: #ff6d4d;
      --good: #39d98a;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      font-family: "IBM Plex Mono", "SFMono-Regular", Consolas, monospace;
      background:
        radial-gradient(circle at top right, rgba(57,217,138,0.12), transparent 30%),
        linear-gradient(180deg, #040904 0%, var(--bg) 100%);
      color: var(--ink);
    }
    .wrap {
      max-width: 920px;
      margin: 0 auto;
      padding: 28px 18px 48px;
    }
    .hero, .panel {
      border: 1px solid var(--line);
      background: rgba(15,31,21,0.92);
      box-shadow: 0 0 0 1px rgba(57,217,138,0.08) inset, 0 18px 48px rgba(0,0,0,0.28);
      border-radius: 18px;
    }
    .hero { padding: 20px; }
    h1 {
      margin: 0 0 10px;
      font-size: clamp(1.6rem, 3vw, 2.4rem);
      letter-spacing: 0.08em;
      text-transform: uppercase;
    }
    p { color: var(--muted); line-height: 1.5; }
    .statusbar {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
      gap: 12px;
      margin-top: 18px;
    }
    .stat {
      padding: 12px;
      border-radius: 14px;
      background: rgba(3,10,6,0.55);
      border: 1px solid rgba(57,217,138,0.14);
    }
    .label {
      display: block;
      font-size: 0.72rem;
      letter-spacing: 0.1em;
      color: var(--muted);
      text-transform: uppercase;
      margin-bottom: 6px;
    }
    .value {
      font-size: 1.05rem;
      color: var(--ink);
    }
    .panel {
      padding: 18px;
      margin-top: 18px;
    }
    .grid {
      display: grid;
      gap: 12px;
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
    }
    button, input, select {
      font: inherit;
      color: var(--ink);
      border-radius: 12px;
      border: 1px solid var(--line);
      background: #0b180f;
    }
    button {
      width: 100%;
      padding: 12px 14px;
      cursor: pointer;
      text-transform: uppercase;
      letter-spacing: 0.06em;
    }
    button:hover { border-color: var(--good); }
    button.hot { border-color: rgba(255,176,0,0.35); color: var(--hot); }
    button.stop { border-color: rgba(255,109,77,0.35); color: var(--warn); }
    button.mini {
      width: auto;
      padding: 10px 12px;
      font-size: 0.82rem;
    }
    .controls {
      display: grid;
      gap: 10px;
      grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
    }
    .custom {
      display: grid;
      gap: 10px;
      grid-template-columns: 1.2fr 1fr auto;
      margin-top: 12px;
    }
    input, select { padding: 12px 14px; width: 100%; }
    audio {
      width: 100%;
      margin-top: 14px;
      filter: hue-rotate(12deg) saturate(1.15);
    }
    .hint { font-size: 0.92rem; }
    .links {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      margin-top: 14px;
    }
    .links code {
      display: inline-block;
      padding: 8px 10px;
      border-radius: 999px;
      border: 1px solid rgba(57,217,138,0.18);
      background: rgba(3,10,6,0.45);
      color: var(--ink);
    }
    .visual-wrap {
      margin-top: 12px;
      border-radius: 14px;
      overflow: hidden;
      border: 1px solid rgba(57,217,138,0.18);
      background:
        linear-gradient(180deg, rgba(1,6,3,0.95), rgba(9,22,14,0.95)),
        repeating-linear-gradient(90deg, rgba(57,217,138,0.05) 0, rgba(57,217,138,0.05) 1px, transparent 1px, transparent 24px);
    }
    #viz {
      width: 100%;
      height: 180px;
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
      letter-spacing: 0.02em;
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
      border-radius: 14px;
      border: 1px solid rgba(255,176,0,0.18);
      background: rgba(255,176,0,0.06);
      color: #f6ddb0;
      line-height: 1.45;
    }
    .note strong { color: var(--hot); }
    @media (max-width: 640px) {
      .custom { grid-template-columns: 1fr; }
      .favorite-tools { grid-template-columns: 1fr; }
      .favorite-item { grid-template-columns: 1fr; }
      button.mini { width: 100%; }
    }
  </style>
</head>
<body>
  <div class="wrap">
    <section class="hero">
      <h1>SDR Remote</h1>
      <p>On-demand tuner for the dongle. Nothing chews CPU until you start a stream, and it auto-sleeps after a few quiet minutes with no listeners.</p>
      <div class="statusbar">
        <div class="stat"><span class="label">State</span><span class="value" id="state">idle</span></div>
        <div class="stat"><span class="label">Mode</span><span class="value" id="mode">--</span></div>
        <div class="stat"><span class="label">Frequency</span><span class="value" id="freq">--</span></div>
        <div class="stat"><span class="label">Listeners</span><span class="value" id="listeners">0</span></div>
      </div>
      <audio id="player" controls preload="none"></audio>
      <div class="links">
        <code id="pageUrl"></code>
        <code id="streamUrl"></code>
      </div>
      <div class="note">
        <strong>Analog only.</strong> FM, airband, marine, ham, and old-school utility chatter are fair game here.
        Modern police / emergency traffic is often digital, trunked, or encrypted, so this page is a starter deck, not a magic surveillance portal.
      </div>
    </section>

    <section class="panel">
      <span class="label">Quickstart</span>
      <p class="hint">1. Hit a preset or enter a frequency and press Start. 2. Audio plays on this device, not the Pi. 3. Save anything good to Favorites. 4. Hit Stop when done, or let it auto-sleep after 3 minutes with no listeners.</p>
      <p class="hint">If it feels weird: check <code>~/pibulus-os/scripts/sdr_lab.sh remote-status</code> in the deck terminal, or open <a href="/deck/help.html" style="color:#daf6dd;">Deck Help</a>.</p>
    </section>

    <section class="panel">
      <span class="label">Quick FM Presets</span>
      <div class="controls">
        <button class="hot" data-mode="fm" data-freq="106.7" data-label="PBS 106.7">PBS 106.7</button>
        <button class="hot" data-mode="fm" data-freq="102.7" data-label="Triple R 102.7">Triple R 102.7</button>
        <button class="hot" data-mode="fm" data-freq="94.9" data-label="JOY 94.9">JOY 94.9</button>
        <button class="hot" data-mode="fm" data-freq="90.7" data-label="SYN 90.7">SYN 90.7</button>
        <button class="hot" data-mode="fm" data-freq="105.9" data-label="ABC Classic 105.9">ABC Classic 105.9</button>
      </div>
    </section>

    <section class="panel">
      <span class="label">Airband Starters</span>
      <p class="hint">AM voice. Good for airport chatter, guard, and general aviation mischief.</p>
      <div class="controls">
        <button data-mode="airband" data-freq="118.0" data-label="Band Edge 118.0">Band Edge 118.0</button>
        <button data-mode="airband" data-freq="121.5" data-label="Guard 121.5">Guard 121.5</button>
        <button data-mode="airband" data-freq="123.45" data-label="Air-to-Air 123.45">Air-to-Air 123.45</button>
      </div>
    </section>

    <section class="panel">
      <span class="label">Analog Utility Starters</span>
      <p class="hint">Narrowband FM. These are starter bookmarks for analog listening, not guaranteed active channels.</p>
      <div class="controls">
        <button data-mode="nfm" data-freq="146.5" data-label="2m Ham 146.5">2m Ham 146.5</button>
        <button data-mode="nfm" data-freq="156.8" data-label="Marine 16 156.8">Marine 16 156.8</button>
        <button data-mode="nfm" data-freq="460.550" data-label="Utility 460.550">Utility 460.550</button>
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
      <p class="hint">Saved in this browser. Good for your own weird little channel map.</p>
      <div class="favorite-tools">
        <input id="favoriteName" type="text" placeholder="Optional label for current tune">
        <button id="saveFavorite">Save Current</button>
        <button class="mini stop" id="clearFavorites">Clear All</button>
      </div>
      <div class="msgline" id="favoriteMsg"></div>
      <div class="favorites-list" id="favoritesList"></div>
    </section>

    <section class="panel">
      <span class="label">Custom Tune</span>
      <p class="hint">FM is best for music. Airband is AM voice. Analog utility/public-safety-style listening is narrowband FM only.</p>
      <div class="custom">
        <input id="freqInput" type="text" inputmode="decimal" placeholder="Frequency MHz e.g. 118.0 or 460.550">
        <select id="modeInput">
          <option value="fm">FM</option>
          <option value="airband">Airband AM</option>
          <option value="nfm">Analog Utility / NFM</option>
        </select>
        <button id="startCustom">Start</button>
      </div>
      <div class="controls" style="margin-top:12px;">
        <button data-mode="airband" data-freq="118.0">Airband 118.0</button>
        <button data-mode="nfm" data-freq="460.550">Analog 460.550</button>
        <button class="stop" id="stopBtn">Stop Stream</button>
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
    pageUrl.textContent = window.location.href;
    streamUrl.textContent = new URL('./stream.mp3', window.location.href).href;
    let currentStatus = { active: false, mode: null, frequency_mhz: null, listeners: 0 };
    let messageTimer = null;
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
    }

    function refreshStatus() {
      fetch('./status', { cache: 'no-store' })
        .then(r => r.json())
        .then(setStatus)
        .catch(() => {});
    }

    function attachAudio() {
      ensureAudioGraph();
      if (audioCtx && audioCtx.state === 'suspended') {
        audioCtx.resume().catch(function(){});
      }
      player.src = './stream.mp3?ts=' + Date.now();
      player.play().catch(() => {});
    }

    function start(mode, freq) {
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
        attachAudio();
      })
      .catch(function(err) {
        flashMessage(err.message || 'Start failed.');
      });
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

    document.getElementById('stopBtn').addEventListener('click', () => {
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
        })
        .catch(function(err) {
          flashMessage(err.message || 'Stop failed.');
        });
    });

    player.addEventListener('play', function() {
      ensureAudioGraph();
      if (audioCtx && audioCtx.state === 'suspended') {
        audioCtx.resume().catch(function(){});
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
        try:
            freq = float(raw)
        except ValueError as exc:
            raise ValueError("frequency must be numeric") from exc

        if mode == "fm" and not (64.0 <= freq <= 108.5):
            raise ValueError("FM frequency should be between 64.0 and 108.5 MHz")
        if mode == "airband" and not (108.0 <= freq <= 137.0):
            raise ValueError("airband frequency should be between 108.0 and 137.0 MHz")
        if mode == "nfm" and not (30.0 <= freq <= 960.0):
            raise ValueError("analog NFM frequency should be between 30.0 and 960.0 MHz")
        return freq

    def start(self, mode: str, raw_freq: str) -> dict:
        freq = self._valid_frequency(mode, raw_freq)
        freq_text = f"{freq:.3f}".rstrip("0").rstrip(".")

        with self.lock:
            self._stop_locked(restore_modules=True)
            self.last_error = ""
            self.listeners.clear()
            self._release_kernel_modules()
            rtl_cmd, ffmpeg_cmd = self._build_commands(mode, freq_text)
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


class Handler(BaseHTTPRequestHandler):
    server_version = "sdr-remote/1.0"

    def log_message(self, fmt: str, *args) -> None:
        syslog = f"{self.address_string()} - {fmt % args}"
        print(syslog, flush=True)

    def _send_bytes(self, status: int, payload: bytes, content_type: str) -> None:
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Cache-Control", "no-store")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def _send_json(self, status: int, payload: dict) -> None:
        self._send_bytes(status, json_bytes(payload), "application/json")

    def _read_json(self) -> dict:
        length = int(self.headers.get("Content-Length", "0") or 0)
        if length <= 0:
            return {}
        raw = self.rfile.read(length)
        return json.loads(raw.decode("utf-8"))

    def do_GET(self) -> None:
        if self.path in ["/", ""]:
            self._send_bytes(HTTPStatus.OK, UI_HTML.encode("utf-8"), "text/html; charset=utf-8")
            return
        if self.path == "/status":
            self._send_json(HTTPStatus.OK, manager.status())
            return
        if self.path.startswith("/stream.mp3"):
            listener_id, listener_queue = manager.register()
            if listener_id is None or listener_queue is None:
                self._send_json(HTTPStatus.CONFLICT, {"error": "stream is idle"})
                return
            self.send_response(HTTPStatus.OK)
            self.send_header("Content-Type", "audio/mpeg")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Access-Control-Allow-Origin", "*")
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
        try:
            if self.path == "/start":
                body = self._read_json()
                status = manager.start(str(body.get("mode", "")).strip(), str(body.get("freq", "")).strip())
                self._send_json(HTTPStatus.OK, status)
                return
            if self.path == "/stop":
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
    httpd = ThreadingHTTPServer((LISTEN_HOST, LISTEN_PORT), Handler)
    httpd.daemon_threads = True
    print(f"sdr_remote listening on {LISTEN_HOST}:{LISTEN_PORT}", flush=True)
    try:
        httpd.serve_forever()
    finally:
        httpd.server_close()


if __name__ == "__main__":
    main()

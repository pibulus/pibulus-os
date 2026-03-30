/**
 * UI Sounds — Tiny audio feedback engine for cyberdeck interfaces
 * CC0 sounds from Kenney.nl — zero dependencies, zero frameworks
 *
 * Usage:
 *   <script src="ui-sounds.js"></script>
 *   UISounds.init({ basePath: '/sounds/' });
 *   // Auto-wires: [data-sound-hover], [data-sound-click], [data-sound-toggle]
 *   // Or manual: UISounds.play('hover');
 */
;(function () {
  'use strict';

  const SOUNDS = {
    hover:    { file: 'select_003.mp3',       vol: 0.08 },
    click:    { file: 'click_003.mp3',        vol: 0.15 },
    open:     { file: 'open_002.mp3',         vol: 0.12 },
    close:    { file: 'close_002.mp3',        vol: 0.12 },
    toggle:   { file: 'switch_002.mp3',       vol: 0.14 },
    confirm:  { file: 'confirmation_002.mp3', vol: 0.18 },
    pluck:    { file: 'pluck_001.mp3',        vol: 0.15 },
    bong:     { file: 'bong_001.mp3',         vol: 0.12 },
    glitch:   { file: 'glitch_003.mp3',       vol: 0.10 },
    drop:     { file: 'drop_002.mp3',         vol: 0.12 },
    glass:    { file: 'glass_002.mp3',        vol: 0.10 },
    error:    { file: 'error_004.mp3',        vol: 0.15 },
    tick:     { file: 'tick_001.mp3',         vol: 0.08 },
    scroll:   { file: 'scroll_002.mp3',       vol: 0.06 },
  };

  // Pool size per sound — avoids cutting off rapid-fire plays
  const POOL_SIZE = 3;
  const DEBOUNCE_MS = 60;

  let basePath = '/sounds/';
  let masterVol = 1.0;
  let enabled = true;
  let pools = {};
  let lastPlayTime = {};
  let initialized = false;

  function buildPool(key) {
    const s = SOUNDS[key];
    if (!s) return null;
    const pool = [];
    for (let i = 0; i < POOL_SIZE; i++) {
      const audio = new Audio(basePath + s.file);
      audio.preload = 'auto';
      audio.volume = Math.min(1, s.vol * masterVol);
      pool.push(audio);
    }
    return pool;
  }

  function play(key) {
    if (!enabled || !SOUNDS[key]) return;

    // Debounce rapid calls to same sound
    const now = Date.now();
    if (now - (lastPlayTime[key] || 0) < DEBOUNCE_MS) return;
    lastPlayTime[key] = now;

    // Lazy-create pool on first play
    if (!pools[key]) pools[key] = buildPool(key);
    const pool = pools[key];

    // Find a free audio element (one that's ended or hasn't started)
    const audio = pool.find(a => a.paused || a.ended) || pool[0];
    audio.volume = Math.min(1, SOUNDS[key].vol * masterVol);
    audio.currentTime = 0;
    audio.play().catch(function (e) {
      if (e.name !== 'NotAllowedError') console.warn('[UISounds]', key, e.message);
    });
  }

  function preload(keys) {
    (keys || Object.keys(SOUNDS)).forEach(function (key) {
      if (!pools[key]) pools[key] = buildPool(key);
    });
  }

  function wireDataAttributes() {
    // [data-sound-hover="hover"] — plays on mouseenter
    document.querySelectorAll('[data-sound-hover]').forEach(function (el) {
      const key = el.dataset.soundHover || 'hover';
      el.addEventListener('mouseenter', function () { play(key); });
    });

    // [data-sound-click="click"] — plays on click
    document.querySelectorAll('[data-sound-click]').forEach(function (el) {
      const key = el.dataset.soundClick || 'click';
      el.addEventListener('click', function () { play(key); });
    });

    // [data-sound-toggle] — alternates open/close on click
    document.querySelectorAll('[data-sound-toggle]').forEach(function (el) {
      let isOpen = false;
      el.addEventListener('click', function () {
        isOpen = !isOpen;
        play(isOpen ? 'open' : 'close');
      });
    });
  }

  function init(opts) {
    if (initialized) return;
    opts = opts || {};
    if (opts.basePath) basePath = opts.basePath;
    if (opts.volume != null) masterVol = opts.volume;
    if (opts.enabled === false) enabled = false;

    wireDataAttributes();

    // Preload the most common sounds
    preload(['hover', 'click', 'open', 'close', 'glass', 'confirm', 'pluck', 'bong']);

    initialized = true;
  }

  // Public API
  window.UISounds = {
    init: init,
    play: play,
    preload: preload,
    wire: wireDataAttributes,
    setVolume: function (v) {
      masterVol = Math.max(0, Math.min(1, v));
      // Update all existing pool elements
      Object.keys(pools).forEach(function (key) {
        var s = SOUNDS[key];
        pools[key].forEach(function (a) {
          a.volume = Math.min(1, s.vol * masterVol);
        });
      });
    },
    toggle: function (on) {
      enabled = on !== undefined ? !!on : !enabled;
      return enabled;
    },
    isEnabled: function () { return enabled; },
    sounds: Object.keys(SOUNDS),
  };
})();

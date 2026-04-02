/**
 * UI Sounds — Web Audio synthesis, no samples needed
 * Soft tactile feedback with micro-variation each play
 */
;(function () {
  "use strict";

  var ctx = null;
  var enabled = true;
  var lastPlay = {};

  function getCtx() {
    if (!ctx) {
      try { ctx = new (window.AudioContext || window.webkitAudioContext)(); }
      catch (e) { return null; }
    }
    if (ctx.state === "suspended") ctx.resume();
    return ctx;
  }

  function hover() {
    if (!enabled) return;
    var now = Date.now();
    if (now - (lastPlay.hover || 0) < 80) return;
    lastPlay.hover = now;

    var c = getCtx();
    if (!c) return;
    var t = c.currentTime;

    // Slight random pitch each time — organic feel
    var freq = 310 + (Math.random() - 0.5) * 40; // 290–330 Hz

    var osc = c.createOscillator();
    var gain = c.createGain();
    var filter = c.createBiquadFilter();

    osc.type = "sine";
    osc.frequency.value = freq;
    // Tiny detune drift for analog warmth
    osc.detune.value = (Math.random() - 0.5) * 6;

    filter.type = "lowpass";
    filter.frequency.value = 700;
    filter.Q.value = 0.5;

    osc.connect(filter);
    filter.connect(gain);
    gain.connect(c.destination);

    // Ultra-short envelope — soft thup
    gain.gain.setValueAtTime(0, t);
    gain.gain.linearRampToValueAtTime(0.06, t + 0.008);
    gain.gain.linearRampToValueAtTime(0, t + 0.07);

    osc.start(t);
    osc.stop(t + 0.08);
  }

  function click() {
    if (!enabled) return;
    var now = Date.now();
    if (now - (lastPlay.click || 0) < 80) return;
    lastPlay.click = now;

    var c = getCtx();
    if (!c) return;
    var t = c.currentTime;

    var freq = 360 + (Math.random() - 0.5) * 30;

    var osc = c.createOscillator();
    var gain = c.createGain();
    var filter = c.createBiquadFilter();

    osc.type = "sine";
    osc.frequency.value = freq;
    osc.detune.value = (Math.random() - 0.5) * 6;

    filter.type = "lowpass";
    filter.frequency.value = 900;
    filter.Q.value = 0.4;

    osc.connect(filter);
    filter.connect(gain);
    gain.connect(c.destination);

    // Slightly brighter/punchier for clicks
    gain.gain.setValueAtTime(0, t);
    gain.gain.linearRampToValueAtTime(0.10, t + 0.005);
    gain.gain.linearRampToValueAtTime(0, t + 0.06);

    osc.start(t);
    osc.stop(t + 0.07);
  }

  function init() {
    document.querySelectorAll("[data-sound-hover]").forEach(function (el) {
      el.addEventListener("mouseenter", hover);
    });
    document.querySelectorAll("[data-sound-click]").forEach(function (el) {
      el.addEventListener("click", click);
    });
  }

  window.UISounds = {
    init: init,
    play: function (key) { if (key === "hover") hover(); else if (key === "click") click(); },
    toggle: function (on) { enabled = on !== undefined ? !!on : !enabled; return enabled; }
  };
})();

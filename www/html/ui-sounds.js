/**
 * UI Sounds — Minimal hover/click feedback
 * CC0 sounds from Kenney.nl
 */
;(function () {
  "use strict";

  var SOUNDS = {
    hover: { file: "select_003.mp3", vol: 0.06 },
    click: { file: "click_003.mp3",  vol: 0.12 }
  };

  var basePath = "/sounds/";
  var enabled = true;
  var cache = {};
  var lastPlay = {};

  function play(key) {
    if (!enabled || !SOUNDS[key]) return;
    var now = Date.now();
    if (now - (lastPlay[key] || 0) < 80) return;
    lastPlay[key] = now;
    if (!cache[key]) {
      cache[key] = new Audio(basePath + SOUNDS[key].file);
      cache[key].preload = "auto";
    }
    var a = cache[key];
    a.volume = SOUNDS[key].vol;
    a.currentTime = 0;
    a.play().catch(function () {});
  }

  function init(opts) {
    if (opts && opts.basePath) basePath = opts.basePath;
    document.querySelectorAll("[data-sound-hover]").forEach(function (el) {
      el.addEventListener("mouseenter", function () { play("hover"); });
    });
    document.querySelectorAll("[data-sound-click]").forEach(function (el) {
      el.addEventListener("click", function () { play("click"); });
    });
  }

  window.UISounds = {
    init: init,
    play: play,
    toggle: function (on) { enabled = on !== undefined ? !!on : !enabled; return enabled; }
  };
})();

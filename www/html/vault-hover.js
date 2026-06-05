/* Quick Cat Vault hover feedback. Tiny, local, and deliberately soft. */
;(function () {
  "use strict";

  var ctx = null;
  var unlocked = false;
  var lastPlay = 0;

  var tones = [
    { root: 420, pop: 630, type: "triangle", volume: 0.034 },
    { root: 470, pop: 705, type: "sine", volume: 0.03 },
    { root: 520, pop: 780, type: "triangle", volume: 0.028 },
    { root: 390, pop: 585, type: "sine", volume: 0.032 }
  ];

  function audioContext() {
    if (!ctx) {
      var Ctor = window.AudioContext || window.webkitAudioContext;
      if (!Ctor) return null;
      try { ctx = new Ctor(); } catch (err) { return null; }
    }
    if (ctx.state === "suspended") ctx.resume().catch(function () {});
    return ctx;
  }

  function unlock() {
    unlocked = true;
    audioContext();
  }

  function isFolder(el) {
    if (!el || !el.matches) return false;
    if (el.matches('[data-dir="true"]')) return true;
    if (el.querySelector && el.querySelector('[data-dir="true"]')) return true;
    var text = (el.textContent || "").toLowerCase();
    var icon = el.querySelector && el.querySelector("i, svg, .material-icons");
    return !!icon && /folder/.test(text);
  }

  function folderFromEvent(target) {
    if (!target || !target.closest) return null;
    var candidates = [
      target.closest('#listing .item[data-dir="true"]'),
      target.closest('[data-dir="true"]'),
      target.closest('#listing .item'),
      target.closest('tr')
    ];
    for (var i = 0; i < candidates.length; i += 1) {
      if (isFolder(candidates[i])) return candidates[i];
    }
    return null;
  }

  function ping() {
    if (!unlocked) return;
    var now = performance.now();
    if (now - lastPlay < 115) return;
    lastPlay = now;

    var c = audioContext();
    if (!c) return;

    var tone = tones[Math.floor(Math.random() * tones.length)];
    var t = c.currentTime;
    var root = tone.root + (Math.random() - 0.5) * 28;
    var pop = tone.pop + (Math.random() - 0.5) * 46;

    var osc = c.createOscillator();
    var gain = c.createGain();
    var filter = c.createBiquadFilter();

    osc.type = tone.type;
    osc.frequency.setValueAtTime(root, t);
    osc.frequency.exponentialRampToValueAtTime(pop, t + 0.038);
    osc.detune.setValueAtTime((Math.random() - 0.5) * 8, t);

    filter.type = "lowpass";
    filter.frequency.setValueAtTime(1150, t);
    filter.frequency.exponentialRampToValueAtTime(620, t + 0.08);
    filter.Q.setValueAtTime(0.7, t);

    gain.gain.setValueAtTime(0.0001, t);
    gain.gain.exponentialRampToValueAtTime(tone.volume, t + 0.01);
    gain.gain.exponentialRampToValueAtTime(0.0001, t + 0.092);

    osc.connect(filter);
    filter.connect(gain);
    gain.connect(c.destination);
    osc.start(t);
    osc.stop(t + 0.105);
  }

  document.addEventListener("pointerdown", unlock, { once: true, passive: true });
  document.addEventListener("keydown", unlock, { once: true, passive: true });

  document.addEventListener("pointerover", function (event) {
    var folder = folderFromEvent(event.target);
    if (!folder || (event.relatedTarget && folder.contains(event.relatedTarget))) return;
    folder.classList.add("vault-folder-hover");
    window.setTimeout(function () { folder.classList.remove("vault-folder-hover"); }, 260);
    ping();
  }, true);
})();

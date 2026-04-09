(function() {
  let isPlaying    = false;
  let lastSongId   = null;
  let pollTimer    = null;
  let trackElapsed = 0;
  let trackDuration = 0;
  let progressTimer = null;
  let lastHistoryKey = '';
  let pollFailCount = 0;
  let lastTickWall = 0;
  const pollChannel = ('BroadcastChannel' in window) ? new BroadcastChannel('kpab-poll') : null;

  const audioEl        = document.getElementById('audioEl');
  const playBtn        = document.getElementById('playBtn');
  const volSlider      = document.getElementById('volSlider');
  const volIcon        = document.getElementById('volIcon');
  const albumArt       = document.getElementById('albumArt');
  const artPlaceholder = document.getElementById('artPlaceholder');
  const trackArtist    = document.getElementById('trackArtist');
  const trackTitle     = document.getElementById('trackTitle');
  const trackAlbum     = document.getElementById('trackAlbum');
  const genreTag       = document.getElementById('genreTag');
  const signalLost     = document.getElementById('signalLost');
  const listenerCount  = document.getElementById('listenerCount');
  const historyList    = document.getElementById('historyList');
  const visualizer     = document.getElementById('visualizer');
  const progressFill   = document.getElementById('progressFill');
  const timeElapsed    = document.getElementById('timeElapsed');
  const timeDuration   = document.getElementById('timeDuration');
  const playerChassis  = document.getElementById('playerChassis');

  // Visualizer bars
  for (let i = 0; i < 18; i++) {
    const bar = document.createElement('div');
    bar.className = 'viz-bar';
    bar.style.setProperty('--dur', (0.35 + Math.random() * 0.55).toFixed(2) + 's');
    bar.style.animationDelay = (Math.random() * 0.4).toFixed(2) + 's';
    bar.style.height = '100%';
    visualizer.appendChild(bar);
  }

  function startProgressTick() {
    clearInterval(progressTimer);
    lastTickWall = Date.now();
    progressTimer = setInterval(() => {
      if (trackDuration > 0) {
        const now = Date.now();
        const delta = Math.round((now - lastTickWall) / 1000);
        lastTickWall = now;
        trackElapsed = Math.min(trackElapsed + delta, trackDuration);
        const pct = trackElapsed / trackDuration;
        progressFill.style.transform = 'scaleX(' + pct + ')';
        timeElapsed.textContent = fmtTime(trackElapsed);
      }
    }, 1000);
  }

  function updateNowPlaying(data) {
    const np = data.now_playing;
    const song = np?.song;
    const history = data.song_history || [];
    const listeners = data.listeners?.current ?? '\u2014';

    listenerCount.textContent = listeners;
    signalLost.style.display = 'none';
    trackArtist.style.display = '';
    trackTitle.style.display = '';

    if (!song) return;

    trackElapsed = np.elapsed || 0;
    trackDuration = np.duration || 0;
    timeElapsed.textContent = fmtTime(trackElapsed);
    timeDuration.textContent = fmtTime(trackDuration);
    if (trackDuration > 0) {
      progressFill.style.transform = 'scaleX(' + (trackElapsed / trackDuration) + ')';
    }

    const songId = song.id || song.title;

    if (songId !== lastSongId) {
      lastSongId = songId;

      progressFill.style.transition = 'none';
      progressFill.style.transform = 'scaleX(0)';
      requestAnimationFrame(() => {
        progressFill.style.transition = 'transform 1s linear';
        if (trackDuration > 0) {
          progressFill.style.transform = 'scaleX(' + (trackElapsed / trackDuration) + ')';
        }
      });

      startProgressTick();

      trackArtist.style.opacity = '0';
      trackTitle.style.opacity = '0';
      trackAlbum.style.opacity = '0';

      setTimeout(() => {
        trackArtist.textContent = song.artist || 'Unknown Artist';
        trackTitle.textContent = song.title || 'Unknown Track';
        trackAlbum.textContent = song.album || '';

        if (song.genre) {
          genreTag.textContent = song.genre;
          genreTag.style.display = 'inline-block';
        } else {
          genreTag.style.display = 'none';
        }

        trackArtist.style.transition = 'opacity 0.4s ease';
        trackTitle.style.transition = 'opacity 0.4s ease';
        trackAlbum.style.transition = 'opacity 0.4s ease';
        trackArtist.style.opacity = '1';
        trackTitle.style.opacity = '1';
        trackAlbum.style.opacity = '1';
      }, 200);

      const artUrl = fixArtUrl(song.art);
      if (artUrl) {
        const tmp = new Image();
        tmp.onload = () => {
          albumArt.src = artUrl;
          albumArt.style.display = 'block';
          artPlaceholder.style.display = 'none';
          if (isPlaying) albumArt.classList.add('playing');
        };
        tmp.onerror = () => {
          albumArt.style.display = 'none';
          artPlaceholder.style.display = 'flex';
        };
        tmp.src = artUrl;
      } else {
        albumArt.style.display = 'none';
        artPlaceholder.style.display = 'flex';
      }

      if ('mediaSession' in navigator) {
        navigator.mediaSession.metadata = new MediaMetadata({
          title: song.title || STATION.name,
          artist: song.artist || STATION.tagline,
          album: song.album || STATION.name,
          artwork: artUrl ? [{ src: artUrl, sizes: '512x512', type: 'image/jpeg' }] : []
        });
      }
    }

    if (history.length > 0) {
      const historyKey = history.slice(0, 5).map(h => h.song?.id || h.song?.title || '').join('|');
      if (historyKey === lastHistoryKey) return;
      lastHistoryKey = historyKey;

      historyList.innerHTML = '';
      history.slice(0, 5).forEach((item, idx) => {
        const s = item.song;
        if (!s) return;

        const div = document.createElement('div');
        div.className = 'history-item';
        div.style.opacity = '0';
        div.style.transition = 'opacity 0.3s ease ' + (idx * 0.06) + 's';

        const artUrl = fixArtUrl(s.art);
        let artEl;
        if (artUrl) {
          artEl = document.createElement('img');
          artEl.className = 'history-art';
          artEl.src = artUrl;
          artEl.alt = '';
          artEl.loading = 'lazy';
          artEl.onerror = function() {
            const ph = document.createElement('div');
            ph.className = 'history-art-placeholder';
            ph.textContent = '\u266A';
            this.parentNode.replaceChild(ph, this);
          };
        } else {
          artEl = document.createElement('div');
          artEl.className = 'history-art-placeholder';
          artEl.textContent = '\u266A';
        }

        const textEl = document.createElement('div');
        textEl.className = 'history-text';
        textEl.innerHTML = '<span>' + escHtml(s.artist || '?') + '</span> \u2014 ' + escHtml(s.title || '?');

        const actions = document.createElement('div');
        actions.className = 'history-actions';

        const ytBtn = document.createElement('a');
        ytBtn.className = 'history-action-btn';
        ytBtn.textContent = '\u25B6 YT';
        ytBtn.title = 'Search on YouTube';
        ytBtn.href = 'https://www.youtube.com/results?search_query=' + encodeURIComponent((s.artist || '') + ' ' + (s.title || ''));
        ytBtn.target = '_blank';
        ytBtn.rel = 'noopener noreferrer';
        ytBtn.addEventListener('click', (e) => e.stopPropagation());

        const wikiBtn = document.createElement('a');
        wikiBtn.className = 'history-action-btn';
        wikiBtn.textContent = '\u24D8 Wiki';
        wikiBtn.title = 'Search artist on Wikipedia';
        wikiBtn.href = 'https://en.wikipedia.org/wiki/Special:Search?search=' + encodeURIComponent(s.artist || '');
        wikiBtn.target = '_blank';
        wikiBtn.rel = 'noopener noreferrer';
        wikiBtn.addEventListener('click', (e) => e.stopPropagation());

        actions.appendChild(ytBtn);
        actions.appendChild(wikiBtn);

        div.appendChild(artEl);
        div.appendChild(textEl);
        div.appendChild(actions);
        historyList.appendChild(div);

        div.addEventListener('touchstart', function(e) {
          const wasActive = this.classList.contains('touch-active');
          document.querySelectorAll('.history-item.touch-active').forEach(function(el) { el.classList.remove('touch-active'); });
          if (!wasActive) {
            this.classList.add('touch-active');
            e.preventDefault();
          }
        }, { passive: false });

        requestAnimationFrame(() => { requestAnimationFrame(() => { div.style.opacity = '1'; }); });
      });
    }
  }

  function showSignalLost() {
    signalLost.style.display = 'block';
    trackArtist.style.display = 'none';
    trackTitle.style.display = 'none';
    trackAlbum.textContent = '';
    genreTag.style.display = 'none';
    listenerCount.textContent = '\u2014';
    timeElapsed.textContent = '--:--';
    timeDuration.textContent = '--:--';
    progressFill.style.transform = 'scaleX(0)';
  }

  async function poll() {
    try {
      const res = await fetch(STATION.apiUrl, { mode: 'cors', cache: 'no-store', headers: { 'Accept': 'application/json' } });
      if (!res.ok) throw new Error('HTTP ' + res.status);
      const data = await res.json();
      pollFailCount = 0;
      updateNowPlaying(data);
      if (pollChannel) pollChannel.postMessage(data);
    } catch (err) {
      console.warn('[' + STATION.name + '] Poll failed:', err.message);
      pollFailCount++;
      showSignalLost();
    }
  }

  if (pollChannel) {
    pollChannel.onmessage = (e) => {
      pollFailCount = 0;
      updateNowPlaying(e.data);
    };
  }

  function startPolling() {
    clearInterval(pollTimer);
    poll();
    pollTimer = setInterval(poll, STATION.pollInterval);
  }

  audioEl.volume = parseFloat(volSlider.value);

  function setPlaying(state) {
    isPlaying = state;
    if (state) {
      playBtn.textContent = '\u23F8';
      playBtn.classList.add('playing');
      playBtn.setAttribute('aria-label', 'Pause stream');
      visualizer.classList.add('active');
      albumArt.classList.add('playing');
      playerChassis.classList.add('playing');
    } else {
      playBtn.textContent = '\u25B6';
      playBtn.classList.remove('playing');
      playBtn.setAttribute('aria-label', 'Play stream');
      visualizer.classList.remove('active');
      albumArt.classList.remove('playing');
      playerChassis.classList.remove('playing');
    }
  }

  // ── Volume fades & stream reconnect ───────────────────────
  // All mutable reconnect/fade state lives here so every code path
  // that touches playback can cleanly cancel in-flight work.

  let reconnectTimer = null;
  let fadeTick       = null;

  function cancelFade() {
    if (fadeTick) { clearInterval(fadeTick); fadeTick = null; }
  }

  // Fade audioEl.volume → 0 in ~300ms, then call onDone.
  function fadeOut(onDone) {
    cancelFade();
    const start = audioEl.volume;
    if (start === 0) { onDone(); return; }
    let step = 0;
    const steps = 6;
    fadeTick = setInterval(() => {
      step++;
      audioEl.volume = Math.max(0, start * (1 - step / steps));
      if (step >= steps) { cancelFade(); onDone(); }
    }, 50);
  }

  // Fade audioEl.volume 0 → slider value in ~500ms.
  function fadeIn() {
    cancelFade();
    const target = parseFloat(volSlider.value);
    if (target === 0) return;
    audioEl.volume = 0;
    let step = 0;
    const steps = 10;
    fadeTick = setInterval(() => {
      step++;
      audioEl.volume = Math.min(target, target * (step / steps));
      if (step >= steps) { cancelFade(); audioEl.volume = target; }
    }, 50);
  }

  // Queue a stream reconnect after delayMs.
  // withFadeIn=true: mute before connecting, then fade in on 'playing'.
  // Guards against double-queuing via reconnectTimer check.
  function scheduleReconnect(delayMs, withFadeIn) {
    if (reconnectTimer) return;
    setPlaying(false);
    reconnectTimer = setTimeout(() => {
      reconnectTimer = null;
      if (withFadeIn) audioEl.volume = 0;
      audioEl.src = STATION.streamUrl;
      const p = audioEl.play();
      if (p !== undefined) {
        p.then(() => {
          setPlaying(true);
          if (withFadeIn) fadeIn();
        }).catch(() => {
          audioEl.volume = parseFloat(volSlider.value);
          setPlaying(false);
        });
      }
    }, delayMs);
  }

  // ── Play / pause button ────────────────────────────────────
  // Cancels any in-flight fade or pending reconnect first so an
  // explicit user action is never overridden by an auto-reconnect.
  playBtn.addEventListener('click', () => {
    cancelFade();
    if (reconnectTimer) { clearTimeout(reconnectTimer); reconnectTimer = null; }
    if (isPlaying) {
      audioEl.pause();
      audioEl.src = '';
      audioEl.volume = parseFloat(volSlider.value); // restore if mid-fade
      setPlaying(false);
    } else {
      audioEl.src = STATION.streamUrl;
      const p = audioEl.play();
      if (p !== undefined) p.then(() => setPlaying(true)).catch(() => setPlaying(false));
    }
  });

  audioEl.addEventListener('playing', () => setPlaying(true));
  audioEl.addEventListener('pause',   () => setPlaying(false));
  audioEl.addEventListener('ended',   () => {
    // For a live stream 'ended' means the connection dropped.
    // Reconnect silently — no fade, just restore ASAP.
    if (isPlaying) scheduleReconnect(2000, false);
  });
  audioEl.addEventListener('error',   () => {
    if (isPlaying) scheduleReconnect(2000, false);
    else setPlaying(false);
  });

  // ── Mutiny skip coordination ───────────────────────────────
  // mutiny.js dispatches 'kpab-skip' the instant AzuraCast confirms
  // the skip. Sequence:
  //   1. fadeOut (~400ms) — intentional, feels like a DJ transition
  //   2. clear src — pre-empts the stream blip from Liquidsoap's cut
  //   3. wait 1.5s — Liquidsoap settles onto the next track
  //   4. reconnect + fadeIn (~600ms) — smooth entry to new song
  // Total: ~2.5s. Deliberate pause > jarring error stop.
  document.addEventListener('kpab-skip', () => {
    if (!isPlaying) return;
    cancelFade();
    if (reconnectTimer) { clearTimeout(reconnectTimer); reconnectTimer = null; }
    fadeOut(() => {
      audioEl.pause();
      audioEl.src = '';
      scheduleReconnect(900, true);
    });
  });

  volSlider.addEventListener('input', () => {
    const v = parseFloat(volSlider.value);
    audioEl.volume = v;
    volIcon.textContent = v === 0 ? '\uD83D\uDD07' : v < 0.4 ? '\uD83D\uDD09' : '\uD83D\uDD0A';
  });

  if ('mediaSession' in navigator) {
    navigator.mediaSession.setActionHandler('play', () => {
      if (!isPlaying) playBtn.click();
    });
    navigator.mediaSession.setActionHandler('pause', () => {
      if (isPlaying) playBtn.click();
    });
  }

  startPolling();

  document.addEventListener('touchstart', (e) => {
    if (!e.target.closest('.history-item')) {
      document.querySelectorAll('.history-item.touch-active').forEach(el => el.classList.remove('touch-active'));
    }
  });

  document.addEventListener('visibilitychange', () => {
    if (document.hidden) {
      clearInterval(pollTimer);
      clearInterval(progressTimer);
    } else {
      startPolling();
      startProgressTick();
    }
  });
})();

(function() {
  const DB_NAME = 'kpab-catalog';
  const DB_VERSION = 1;
  const STORE_NAME = 'tracks';
  const META_STORE = 'meta';
  const STALE_MS = 6 * 60 * 60 * 1000; // 6 hours

  let db = null;
  let reqLoaded = false;
  let reqDebounce = null;
  let trackCount = 0;

  const requestSection = document.getElementById('requestSection');
  const requestToggle = document.getElementById('requestToggle');
  const requestPanel = document.getElementById('requestPanel');
  const requestClose = document.getElementById('requestClose');
  const requestSearch = document.getElementById('requestSearch');
  const requestResults = document.getElementById('requestResults');
  const requestEmpty = document.getElementById('requestEmpty');
  const searchCount = document.getElementById('searchCount');
  const requestToast = document.getElementById('requestToast');

  // ── IndexedDB helpers ──────────────────────────────────────

  function openDB() {
    return new Promise((resolve, reject) => {
      const req = indexedDB.open(DB_NAME, DB_VERSION);
      req.onupgradeneeded = (e) => {
        const d = e.target.result;
        if (!d.objectStoreNames.contains(STORE_NAME)) {
          d.createObjectStore(STORE_NAME, { keyPath: 'id', autoIncrement: true });
        }
        if (!d.objectStoreNames.contains(META_STORE)) {
          d.createObjectStore(META_STORE);
        }
      };
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  }

  function idbPut(store, data, key) {
    return new Promise((resolve, reject) => {
      const tx = db.transaction(store, 'readwrite');
      const s = tx.objectStore(store);
      const r = key !== undefined ? s.put(data, key) : s.put(data);
      r.onsuccess = () => resolve(r.result);
      r.onerror = () => reject(r.error);
    });
  }

  function idbGet(store, key) {
    return new Promise((resolve, reject) => {
      const tx = db.transaction(store, 'readonly');
      const r = tx.objectStore(store).get(key);
      r.onsuccess = () => resolve(r.result);
      r.onerror = () => reject(r.error);
    });
  }

  function idbCount(store) {
    return new Promise((resolve, reject) => {
      const tx = db.transaction(store, 'readonly');
      const r = tx.objectStore(store).count();
      r.onsuccess = () => resolve(r.result);
      r.onerror = () => reject(r.error);
    });
  }

  function idbClearAndFill(tracks) {
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORE_NAME, 'readwrite');
      const s = tx.objectStore(STORE_NAME);
      s.clear();
      tracks.forEach(t => s.add(t));
      tx.oncomplete = () => resolve();
      tx.onerror = () => reject(tx.error);
    });
  }

  function idbSearch(query, limit) {
    return new Promise((resolve, reject) => {
      const terms = query.trim().toLowerCase().split(/\s+/);
      const results = [];
      const tx = db.transaction(STORE_NAME, 'readonly');
      const req = tx.objectStore(STORE_NAME).openCursor();

      req.onsuccess = (e) => {
        const cursor = e.target.result;
        if (!cursor) { resolve(results); return; }
        if (results.length >= limit) { resolve(results); return; }
        const item = cursor.value;
        const haystack = ((item.a || '') + ' ' + (item.t || '') + ' ' + (item.b || '')).toLowerCase();
        if (terms.every(t => haystack.includes(t))) {
          results.push(item);
        }
        cursor.continue();
      };
      req.onerror = () => reject(req.error);
    });
  }

  // ── Catalog loading ────────────────────────────────────────

  async function loadCatalog() {
    requestResults.innerHTML = '<div class="request-loading">LOADING CATALOG...</div>';

    try {
      db = await openDB();
    } catch (err) {
      console.warn('[' + STATION.name + '] IndexedDB unavailable, falling back to memory');
      return loadCatalogFallback();
    }

    // Check if we have cached data
    const lastFetch = await idbGet(META_STORE, 'lastFetch').catch(() => null);
    const count = await idbCount(STORE_NAME).catch(() => 0);

    if (count > 0 && lastFetch) {
      // We have cached data — use it immediately
      trackCount = count;
      reqLoaded = true;
      requestEmpty.querySelector('span:last-child').textContent =
        'Search ' + trackCount.toLocaleString() + ' requestable tracks';
      showRequestResults('');

      // Background refresh if stale
      if (Date.now() - lastFetch > STALE_MS) {
        fetchAndStoreCatalog().catch(() => {});
      }
      return;
    }

    // First visit — must fetch
    await fetchAndStoreCatalog();
  }

  async function fetchAndStoreCatalog() {
    try {
      const res = await fetch(STATION.catalogUrl, { cache: 'no-cache' });
      if (!res.ok) throw new Error('HTTP ' + res.status);
      const tracks = await res.json();

      await idbClearAndFill(tracks);
      await idbPut(META_STORE, Date.now(), 'lastFetch');

      trackCount = tracks.length;
      reqLoaded = true;
      requestEmpty.querySelector('span:last-child').textContent =
        'Search ' + trackCount.toLocaleString() + ' requestable tracks';
      showRequestResults(requestSearch.value || '');
    } catch (err) {
      console.warn('[' + STATION.name + '] Catalog fetch failed:', err);
      if (!reqLoaded) {
        requestResults.innerHTML = '<div class="request-empty"><span class="empty-icon">&#x26A1;</span><span>Eep! Could not load the catalog. Try again in a bit!</span></div>';
      }
    }
  }

  // Fallback for browsers without IndexedDB (rare but possible)
  let fallbackCache = null;
  async function loadCatalogFallback() {
    try {
      const res = await fetch(STATION.catalogUrl, { cache: 'no-cache' });
      if (!res.ok) throw new Error('HTTP ' + res.status);
      fallbackCache = await res.json();
      trackCount = fallbackCache.length;
      reqLoaded = true;
      requestEmpty.querySelector('span:last-child').textContent =
        'Search ' + trackCount.toLocaleString() + ' requestable tracks';
      showRequestResults('');
    } catch (err) {
      console.warn('[' + STATION.name + '] Catalog load failed:', err);
      requestResults.innerHTML = '<div class="request-empty"><span class="empty-icon">&#x26A1;</span><span>Eep! Could not load the catalog. Try again in a bit!</span></div>';
    }
  }

  // ── Search & render ────────────────────────────────────────

  async function showRequestResults(query) {
    const q = query.trim().toLowerCase();

    if (!q) {
      requestResults.innerHTML = '';
      requestResults.appendChild(requestEmpty);
      requestEmpty.style.display = 'flex';
      searchCount.textContent = '';
      return;
    }

    requestEmpty.style.display = 'none';

    let matches;
    if (fallbackCache) {
      // In-memory fallback path
      const terms = q.split(/\s+/);
      matches = fallbackCache.filter(item => {
        const haystack = ((item.a || '') + ' ' + (item.t || '') + ' ' + (item.b || '')).toLowerCase();
        return terms.every(t => haystack.includes(t));
      }).slice(0, 50);
    } else {
      // IndexedDB search
      matches = await idbSearch(q, 50);
    }

    searchCount.textContent = matches.length + (matches.length === 50 ? '+' : '') + ' found';

    if (matches.length === 0) {
      requestResults.innerHTML = '<div class="request-empty"><span class="empty-icon">&#x1F50D;</span><span>No matches \u2014 try different keywords</span></div>';
      return;
    }

    const frag = document.createDocumentFragment();
    matches.forEach((item, idx) => {
      const div = document.createElement('div');
      div.className = 'request-item';
      div.style.opacity = '0';
      div.style.transition = 'opacity 0.2s ease ' + (idx * 0.025) + 's';

      const artUrl = fixArtUrl(item.art);
      let artEl;
      if (artUrl) {
        artEl = document.createElement('img');
        artEl.className = 'request-item-art';
        artEl.src = artUrl;
        artEl.alt = '';
        artEl.loading = 'lazy';
        artEl.onerror = function() {
          const ph = document.createElement('div');
          ph.className = 'request-item-art-ph';
          ph.textContent = '\u266A';
          this.parentNode.replaceChild(ph, this);
        };
      } else {
        artEl = document.createElement('div');
        artEl.className = 'request-item-art-ph';
        artEl.textContent = '\u266A';
      }

      const info = document.createElement('div');
      info.className = 'request-item-info';
      info.innerHTML = '<div class="request-item-title">' + escHtml(item.t || '?') + '</div>' +
        '<div class="request-item-meta"><span class="artist">' + escHtml(item.a || '?') + '</span>' +
        (item.b ? ' &mdash; ' + escHtml(item.b) : '') + '</div>';

      const btn = document.createElement('button');
      btn.className = 'request-item-btn';
      btn.textContent = 'REQUEST';
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        submitRequest(item.url || item.id, btn, item);
      });

      div.appendChild(artEl);
      div.appendChild(info);
      div.appendChild(btn);
      div.addEventListener('click', () => btn.click());
      frag.appendChild(div);

      requestAnimationFrame(() => { requestAnimationFrame(() => { div.style.opacity = '1'; }); });
    });

    requestResults.innerHTML = '';
    requestResults.appendChild(frag);
  }

  // ── Request submission ─────────────────────────────────────

  async function submitRequest(reqUrl, btnEl, song) {
    btnEl.textContent = '...';
    btnEl.style.pointerEvents = 'none';

    try {
      const url = reqUrl.startsWith('/') ? reqUrl : '/api/station/1/request/' + reqUrl;
      const res = await fetch(url, { method: 'POST' });

      if (res.ok) {
        btnEl.textContent = 'SENT \u2713';
        btnEl.classList.add('sent');
        showToast('Requested: ' + (song.a || '') + ' \u2014 ' + (song.t || ''), false);
      } else {
        let msg = 'Request failed';
        try { msg = (await res.json()).message || msg; } catch(e) {}
        btnEl.textContent = 'NOPE';
        btnEl.classList.add('failed');
        showToast(msg, true);
        setTimeout(() => { btnEl.textContent = 'REQUEST'; btnEl.className = 'request-item-btn'; btnEl.style.pointerEvents = ''; }, 3000);
      }
    } catch (err) {
      btnEl.textContent = 'ERROR';
      btnEl.classList.add('failed');
      showToast('Network error \u2014 try again', true);
      setTimeout(() => { btnEl.textContent = 'REQUEST'; btnEl.className = 'request-item-btn'; btnEl.style.pointerEvents = ''; }, 3000);
    }
  }

  function showToast(msg, isError) {
    requestToast.textContent = msg;
    requestToast.className = 'request-toast show' + (isError ? ' error' : '');
    setTimeout(() => { requestToast.className = 'request-toast'; }, 3000);
  }

  // ── Panel toggle & search input ────────────────────────────

  function toggleRequestPanel() {
    const isOpen = requestPanel.classList.contains('open');
    if (isOpen) {
      requestPanel.classList.remove('open');
      requestToggle.innerHTML = '&#x1F4FB; Request a Song';
    } else {
      requestPanel.classList.add('open');
      requestToggle.innerHTML = '&#x1F4FB; Close Requests';
      setTimeout(() => {
        requestSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
        requestSearch.focus();
      }, 50);
      if (!reqLoaded) loadCatalog();
    }
  }

  requestToggle.addEventListener('click', toggleRequestPanel);
  requestClose.addEventListener('click', () => {
    requestPanel.classList.remove('open');
    requestToggle.innerHTML = '&#x1F4FB; Request a Song';
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && requestPanel.classList.contains('open')) {
      requestPanel.classList.remove('open');
      requestToggle.innerHTML = '&#x1F4FB; Request a Song';
    }
  });

  requestSearch.addEventListener('input', () => {
    clearTimeout(reqDebounce);
    reqDebounce = setTimeout(() => showRequestResults(requestSearch.value), 150);
  });
})();

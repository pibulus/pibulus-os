function fmtTime(s) {
  if (!s || s < 0) return '--:--';
  const m = Math.floor(s / 60);
  const sec = Math.floor(s % 60);
  return m + ':' + String(sec).padStart(2, '0');
}

function fixArtUrl(url) {
  if (!url) return null;
  try {
    const p = new URL(url);
    return p.pathname + p.search;
  } catch (e) { return url; }
}

function escHtml(s) {
  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#x27;');
}

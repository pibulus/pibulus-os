#!/usr/bin/env sh
set -eu

DIST="/app/client/dist"
MARKER="pibulus-abs-polish"

[ -d "$DIST" ] || exit 0

node <<'NODE'
const fs = require("fs");
const path = require("path");
const dist = "/app/client/dist";

const polish = String.raw`<style id="pibulus-abs-polish">
  h1.text-xl.mr-6.hidden.lg\:block.hover\:underline { font-size: 0 !important; }
  h1.text-xl.mr-6.hidden.lg\:block.hover\:underline::after { content: "Audiobooks"; font-size: 1.25rem; }
  a[href*="/config/stats"],
  a[href*="github.com/advplyr/audiobookshelf/releases"],
  p.underline.font-mono.text-xs.text-center.text-gray-300.leading-3.mb-1.cursor-pointer { display: none !important; }
  @media (max-width: 700px) {
    nav a, button { min-width: 44px; min-height: 44px; }
    input[type="text"], input[type="search"], input[type="password"] { font-size: 16px !important; }
  }
</style>
<script id="pibulus-abs-polish-script">
(() => {
  const appName = "Audiobooks";
  const currentVersion = (window.__NUXT__ && window.__NUXT__.config && window.__NUXT__.config.version) || "2.33.1";
  try {
    localStorage.setItem("lastVerCheck", String(Date.now()));
    localStorage.setItem("versionData", JSON.stringify({ hasUpdate: false, currentVersion, latestVersion: currentVersion, releasesToShow: [] }));
  } catch (_) {}

  const polish = () => {
    if (document.title !== appName) document.title = appName;
    document.querySelectorAll("h1").forEach((el) => {
      if ((el.textContent || "").trim().toLowerCase() === "audiobookshelf") el.textContent = appName;
    });
    document.querySelectorAll("a[href*='/config/stats']").forEach((el) => el.remove());
    document.querySelectorAll("a[href*='github.com/advplyr/audiobookshelf/releases']").forEach((el) => el.remove());
    document.querySelectorAll("p").forEach((el) => {
      const text = (el.textContent || "").trim();
      if (/^v\\d+\\.\\d+\\.\\d+/.test(text) && el.className.includes("font-mono")) el.remove();
    });
  };

  polish();
  setInterval(polish, 1000);
})();
</script>`;

function* walk(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const next = path.join(dir, entry.name);
    if (entry.isDirectory()) yield* walk(next);
    else if (entry.isFile() && entry.name === "index.html") yield next;
  }
}

for (const index of walk(dist)) {
  let html = fs.readFileSync(index, "utf8");
  if (html.includes("pibulus-abs-polish")) continue;

  fs.copyFileSync(index, `${index}.pibulus.bak`);
  html = html
    .replace(/Audiobookshelf/g, "Audiobooks")
    .replace("</head>", `${polish}</head>`);

  fs.writeFileSync(index, html);
}
NODE

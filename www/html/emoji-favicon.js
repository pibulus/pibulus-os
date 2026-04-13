(() => {
  const rules = [
    [/^\/kpab\//, "📻"],
    [/^\/arcade\//, "🕹️"],
    [/^\/pico\//, "👾"],
    [/^\/conspiracy\//, "🛸"],
    [/^\/palestine\//, "🍉"],
    [/^\/crates\//, "🎼"],
    [/^\/loops\//, "🎛️"],
    [/^\/drop\//, "📦"],
    [/^\/wall\//, "🧱"],
    [/^\/fiction\//, "📖"],
    [/^\/textworlds\//, "🧙"],
    [/^\/terminal\//, "💻"],
    [/^\/deck\//, "🖥️"],
    [/^\/mission-control\//, "🛰️"],
    [/^\/$/, "🐈"],
  ];

  function emojiForPath(path) {
    const match = rules.find(([pattern]) => pattern.test(path));
    return match ? match[1] : "🐈";
  }

  function setEmojiFavicon(emoji) {
    const svg =
      `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">` +
      `<text y=".9em" x="50" text-anchor="middle" font-size="88">${emoji}</text>` +
      `</svg>`;
    const href = `data:image/svg+xml,${encodeURIComponent(svg)}`;
    let link = document.querySelector('link[rel~="icon"]');
    if (!link) {
      link = document.createElement("link");
      link.rel = "icon";
      document.head.appendChild(link);
    }
    link.type = "image/svg+xml";
    link.href = href;
  }

  setEmojiFavicon(emojiForPath(window.location.pathname));
})();

(() => {
  const ARCHIVE_EXTS = [".zip", ".cbz", ".7z", ".rar", ".iso"];

  function archiveExt(name) {
    const match = String(name || "").toLowerCase().match(/\.[a-z0-9]+$/);
    return match ? match[0] : "";
  }

  function isArchive(name) {
    return ARCHIVE_EXTS.includes(archiveExt(name));
  }

  function esc(value) {
    return String(value).replace(/[&<>"']/g, (char) => ({
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      '"': "&quot;",
      "'": "&#39;",
    })[char]);
  }

  function bytes(value) {
    const n = Number(value || 0);
    if (n > 1073741824) return `${(n / 1073741824).toFixed(1)} GB`;
    if (n > 1048576) return `${(n / 1048576).toFixed(0)} MB`;
    if (n > 1024) return `${(n / 1024).toFixed(0)} KB`;
    return n ? `${n} B` : "";
  }

  function displayName(name) {
    const cleaner = window.cleanName || window.cleanDisplayName;
    return cleaner ? cleaner(name) : String(name || "");
  }

  function iconForArchiveEntry(name, isDir) {
    if (isDir) return "\u{1F4C1}";
    const lower = String(name || "").toLowerCase();
    if (/\.(mp4|mkv|avi|webm)$/.test(lower)) return "\u{1F3AC}";
    if (/\.(mp3|flac|ogg|m4a|wav|opus)$/.test(lower)) return "\u{1F3B5}";
    if (/\.(jpg|jpeg|png|gif|webp)$/.test(lower)) return "\u{1F5BC}";
    if (/\.(pdf|epub|mobi|txt|djvu)$/.test(lower)) return "\u{1F4C4}";
    if (isArchive(lower)) return "\u{1F4E6}";
    return "\u{1F4CE}";
  }

  function archiveFileUrl(fileUrl, entryPath) {
    return `/archive/file?file=${encodeURIComponent(fileUrl)}&entry=${encodeURIComponent(entryPath)}`;
  }

  function renderBreadcrumbs(mount, innerPath) {
    const parts = innerPath ? innerPath.split("/").filter(Boolean) : [];
    let html = `<a data-inner="" data-sound-hover="hover" data-sound-click="click">${esc(mount.rootLabel)}</a>`;
    let acc = "";
    parts.forEach((part, index) => {
      acc += `${acc ? "/" : ""}${part}`;
      html += '<span class="sep">/</span>';
      if (index === parts.length - 1) {
        html += `<span>${esc(part)}</span>`;
      } else {
        html += `<a data-inner="${esc(acc)}" data-sound-hover="hover" data-sound-click="click">${esc(part)}</a>`;
      }
    });
    return html;
  }

  function renderError(mount, message) {
    mount.items.innerHTML = `<div class="loading">${esc(message || "archive unavailable")}</div>`;
  }

  function loadArchivePath(mount, innerPath) {
    mount.innerPath = innerPath || "";
    mount.breadcrumbs.innerHTML = renderBreadcrumbs(mount, mount.innerPath);
    mount.items.innerHTML = '<div class="loading">reading archive...</div>';

    fetch(`/archive/list?file=${encodeURIComponent(mount.fileUrl)}&inner=${encodeURIComponent(mount.innerPath)}`, { cache: "no-store" })
      .then((res) => res.ok ? res.json() : res.json().then((data) => Promise.reject(data)))
      .then((data) => {
        const items = data.items || [];
        mount.count.textContent = `${items.length} item${items.length === 1 ? "" : "s"}`;
        mount.items.innerHTML = "";
        if (!items.length) {
          mount.items.innerHTML = '<div class="loading">empty archive folder</div>';
          return;
        }
        items.forEach((entry) => {
          const isDir = entry.type === "directory";
          const row = document.createElement("a");
          row.className = `file-item${isDir ? " is-folder" : ""}`;
          row.setAttribute("data-sound-hover", "hover");
          row.setAttribute("data-sound-click", "click");

          if (isDir) {
            row.onclick = () => loadArchivePath(mount, entry.path);
          } else {
            const url = archiveFileUrl(mount.fileUrl, entry.path);
            if (window.canInlinePlay && window.canInlinePlay(entry.name)) {
              row.onclick = () => window.openPreview(url, entry.name);
            } else {
              row.href = url;
              row.download = entry.name;
            }
          }

          row.innerHTML =
            `<span class="file-icon">${iconForArchiveEntry(entry.name, isDir)}</span>` +
            '<span class="file-info">' +
              `<span class="file-name">${esc(displayName(entry.name))}</span>` +
              `<span class="file-meta">${isDir ? "folder" : bytes(entry.size)}</span>` +
            '</span>' +
            `<span class="file-action">${isDir ? "OPEN" : ((window.canInlinePlay && window.canInlinePlay(entry.name)) ? "VIEW" : "GET")}</span>`;
          mount.items.appendChild(row);
        });
      })
      .catch((err) => renderError(mount, err && err.error ? err.error : "archive unavailable"));
  }

  function openArchive(fileUrl, archiveName) {
    const content = document.getElementById("preview-content");
    if (!content) return;
    const mountId = `archive-${Date.now()}`;
    content.innerHTML =
      `<div class="preview-title">${esc(displayName(archiveName))}</div>` +
      `<div class="breadcrumbs" id="${mountId}-crumbs"></div>` +
      `<div class="count" id="${mountId}-count"></div>` +
      `<div class="file-list" id="${mountId}-items" style="width:min(92vw,820px);max-height:min(70vh,calc(100dvh - 12rem));overflow:auto;"></div>` +
      '<div class="preview-actions">' +
        `<a class="btn btn-primary" href="${fileUrl}" download style="text-decoration:none;" data-sound-hover="hover" data-sound-click="click">Download Archive</a>` +
        '<button class="btn" onclick="closeModal(\'preview-modal\')" data-sound-hover="hover" data-sound-click="click">Close</button>' +
      '</div>';

    const mount = {
      fileUrl,
      rootLabel: "Archive",
      breadcrumbs: document.getElementById(`${mountId}-crumbs`),
      count: document.getElementById(`${mountId}-count`),
      items: document.getElementById(`${mountId}-items`),
      innerPath: "",
    };
    mount.breadcrumbs.addEventListener("click", (event) => {
      const link = event.target.closest("a[data-inner]");
      if (link) loadArchivePath(mount, link.getAttribute("data-inner") || "");
    });
    document.getElementById("preview-modal").classList.add("active");
    loadArchivePath(mount, "");
  }

  function install() {
    if (window.__archiveBrowserInstalled) return;
    window.__archiveBrowserInstalled = true;
    const originalHandleClick = window.handleClick;
    const originalActionLabel = window.actionLabel;

    window.handleClick = function(entry, isDir) {
      if (!isDir && entry && isArchive(entry.name)) {
        openArchive(window.fileUrl(entry.name), entry.name);
        return;
      }
      originalHandleClick(entry, isDir);
    };

    window.actionLabel = function(entry, isDir) {
      if (!isDir && entry && isArchive(entry.name)) return "OPEN";
      return originalActionLabel(entry, isDir);
    };
  }

  window.ArchiveBrowser = { install, isArchive, openArchive };
  install();
})();

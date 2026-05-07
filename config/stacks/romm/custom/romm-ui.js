(function() {
    if (window.__rommUiCleanup) return;
    window.__rommUiCleanup = true;

    window.EJS_paths = Object.assign({}, window.EJS_paths || {}, {
        "emulator.min.css": "/assets/emulatorjs/data/emulator.css?rev=20260505a",
        "emulator.css": "/assets/emulatorjs/data/emulator.css?rev=20260505a"
    });

    function patchViewportFit() {
        var viewport = document.querySelector('meta[name="viewport"]');
        if (viewport) {
            if (viewport.content.indexOf("viewport-fit") < 0) {
                viewport.content += ",viewport-fit=cover";
            }
            return;
        }

        var meta = document.createElement("meta");
        meta.name = "viewport";
        meta.content = "width=device-width,initial-scale=1,viewport-fit=cover";
        document.head.appendChild(meta);
    }

    var hiddenTabs = {
        manual: 1,
        "game data": 1,
        gamedata: 1,
        "save data": 1,
        "how long to beat": 1,
        timetobeat: 1,
        "additional content": 1,
        additionalcontent: 1,
        "related games": 1,
        "related content": 1,
        relatedgames: 1
    };

    var hiddenLabels = {
        file: 1,
        files: 1,
        info: 1,
        tags: 1,
        "switch version": 1,
        regions: 1,
        languages: 1,
        genres: 1,
        franchises: 1,
        collections: 1,
        companies: 1,
        players: 1,
        "player count": 1,
        "age rating": 1
    };

    function normalize(text) {
        text = (text || "").replace(/\s+/g, " ").trim().toLowerCase();
        if (text.slice(-1) === ":") text = text.slice(0, -1);
        return text;
    }

    function hideNode(node) {
        if (node) node.style.setProperty("display", "none", "important");
    }

    function isHiddenHref(href, prefix) {
        return href === prefix || href.indexOf(prefix + "/") === 0;
    }

    function hideNdsCards() {
        if (window.innerWidth > 960) return;

        document.querySelectorAll("a").forEach(function(anchor) {
            var href = anchor.getAttribute("href") || "";
            if (isHiddenHref(href, "/p/15") || isHiddenHref(href, "/platform/nds")) {
                hideNode(anchor.closest(".v-card") || anchor.closest("[class*=col]") || anchor);
            }
        });

        document.querySelectorAll("span,div,h6,p").forEach(function(element) {
            if (element.childElementCount === 0 && element.textContent.trim() === "Nintendo DS") {
                hideNode(element.closest(".v-card") || element.closest("a") || element.closest("[class*=col]"));
            }
        });
    }

    function hideRommNoise() {
        var path = location.pathname;
        if (!path.startsWith("/rom/") || path.endsWith("/ejs") || path.endsWith("/ejs/")) return;

        document.querySelectorAll(".v-tab,[role=tab],button,a").forEach(function(element) {
            var label = normalize(element.textContent);
            if (hiddenTabs[label]) {
                hideNode(element.closest(".v-slide-group-item,.v-btn,.v-tab,button,a") || element);
            }
        });

        document.querySelectorAll(".text-right.text-medium-emphasis.text-caption.font-italic").forEach(hideNode);
        document.querySelectorAll(".text-caption,.text-overline,.v-list-item-title,dt,th,strong,b,h6,p,span,div").forEach(function(element) {
            if (element.childElementCount > 2) return;
            var label = normalize(element.textContent);
            if (!hiddenLabels[label]) return;
            hideNode(element.closest(".v-list-item,.v-row,.v-col,.d-flex,tr") || element);
        });

        var activeHiddenTab = document.querySelector(".v-tab--selected,.v-btn--active,[role=tab][aria-selected=true]");
        if (activeHiddenTab && hiddenTabs[normalize(activeHiddenTab.textContent)]) {
            var firstVisibleTab = Array.from(document.querySelectorAll(".v-tab,[role=tab]")).find(function(element) {
                return hiddenTabs[normalize(element.textContent)] !== 1 && element.offsetParent !== null;
            });
            if (firstVisibleTab && typeof firstVisibleTab.click === "function") firstVisibleTab.click();
        }
    }

    function run() {
        patchViewportFit();
        hideNdsCards();
        hideRommNoise();
    }

    document.addEventListener("DOMContentLoaded", function() {
        run();
        new MutationObserver(run).observe(document.body, { childList: true, subtree: true });
    });
})();

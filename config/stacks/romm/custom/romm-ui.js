(function() {
    if (window.__rommUiCleanup) return;
    window.__rommUiCleanup = true;

    window.EJS_paths = Object.assign({}, window.EJS_paths || {}, {
        "emulator.min.css": "/assets/emulatorjs/data/emulator.css?rev=20260616g",
        "emulator.css": "/assets/emulatorjs/data/emulator.css?rev=20260616g"
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

    var platformHints = [
        "arcade",
        "game boy",
        "game boy advance",
        "nintendo 64",
        "nintendo entertainment",
        "playstation",
        "scummvm",
        "sega mega",
        "sega genesis",
        "super nintendo",
        "turbografx"
    ];

    var playablePlatformHints = [
        "arcade",
        "game boy",
        "game boy advance",
        "nintendo 64",
        "nintendo entertainment",
        "playstation",
        "sega mega",
        "sega genesis",
        "super nintendo",
        "turbografx"
    ];

    function normalize(text) {
        text = (text || "").replace(/\s+/g, " ").trim().toLowerCase();
        if (text.slice(-1) === ":") text = text.slice(0, -1);
        return text;
    }

    function hideNode(node, reason) {
        if (!node) return;
        node.style.setProperty("display", "none", "important");
        if (reason) node.setAttribute("data-quickcat-hidden", reason);
    }

    function markNode(node, reason) {
        if (!node || !reason) return;
        node.setAttribute("data-quickcat-hidden", reason);
        node.style.removeProperty("display");
    }

    function safely(fn) {
        try {
            fn();
        } catch (error) {
            if (window.console && console.warn) console.warn("[quickcat-romm-ui]", error);
        }
    }

    function platformCardShell(node) {
        if (!node) return null;
        return node.closest(".v-slide-group-item,[class*='v-slide-group-item'],.v-col,[class*='v-col'],li") ||
            node.closest(".v-card,a") ||
            node;
    }

    function isHiddenHref(href, prefix) {
        return href === prefix || href.indexOf(prefix + "/") === 0;
    }

    function isEjsLaunchPage() {
        return /^\/rom\/[^/]+\/ejs\/?$/.test(location.pathname);
    }

    function quickcatAutoplayRequested() {
        if (!isEjsLaunchPage()) return false;
        return new URLSearchParams(location.search).get("quickcat_autoplay") === "1";
    }

    function isRomDetailPage() {
        return /^\/rom\/[^/]+\/?$/.test(location.pathname);
    }

    function currentRomId() {
        var match = location.pathname.match(/^\/rom\/([^/]+)\/?$/);
        return match && match[1];
    }

    function addQueryParam(href, key, value) {
        var url = new URL(href, window.location.origin);
        url.searchParams.set(key, value);
        return url.pathname + url.search + url.hash;
    }

    function isPhoneWidth() {
        return window.innerWidth <= 700;
    }

    function isHomePage() {
        return (location.pathname.replace(/\/+$/, "") || "/") === "/";
    }

    function mergeWindowObject(name, defaults) {
        var current = window[name];
        if (!current || typeof current !== "object" || Array.isArray(current)) current = {};
        Object.keys(defaults).forEach(function(key) {
            if (current[key] == null) current[key] = defaults[key];
        });
        window[name] = current;
    }

    function seedEmulatorDefaults() {
        try {
            var arcadeCore = localStorage.getItem("player:arcade:core");
            if (!arcadeCore || arcadeCore === "mame2003" || arcadeCore === "mame2003_plus") {
                localStorage.setItem("player:arcade:core", "fbneo");
            }
        } catch (error) {}

        mergeWindowObject("EJS_Buttons", {
            screenshot: false,
            screenRecord: false,
            cheat: false,
            cacheManager: false,
            netplay: false,
            saveSavFiles: false,
            loadSavFiles: false,
            exitEmulation: false
        });

        mergeWindowObject("EJS_defaultOptions", {
            "save-state-slot": "1",
            "save-state-location": "browser",
            "save-save-interval": "60",
            fastForward: "disabled",
            slowMotion: "disabled",
            rewindEnabled: "disabled",
            fps: "disabled",
            vsync: "enabled",
            "menu-bar-button": "hidden"
        });

        if (window.matchMedia && window.matchMedia("(max-width: 960px)").matches) {
            window.EJS_defaultOptions["virtual-gamepad"] = window.EJS_defaultOptions["virtual-gamepad"] || "enabled";
        }

        var hiddenSettings = [
            "webgl2Enabled",
            "fps",
            "vsync",
            "videoRotation",
            "screenshotSource",
            "screenshotFormat",
            "screenshotUpscale",
            "screenRecordFPS",
            "screenRecordFormat",
            "screenRecordUpscale",
            "screenRecordVideoBitrate",
            "screenRecordAudioBitrate",
            "fastForward",
            "ff-ratio",
            "slowMotion",
            "sm-ratio",
            "rewindEnabled",
            "rewind-granularity",
            "menubarBehavior",
            "altKeyboardInput",
            "lockMouse",
            "menu-bar-button"
        ];
        if (!Array.isArray(window.EJS_hideSettings)) window.EJS_hideSettings = [];
        hiddenSettings.forEach(function(setting) {
            if (window.EJS_hideSettings.indexOf(setting) < 0) window.EJS_hideSettings.push(setting);
        });
    }

    function hideNdsCards() {
        document.querySelectorAll("a").forEach(function(anchor) {
            var href = anchor.getAttribute("href") || "";
            if (isHiddenHref(href, "/p/15") || isHiddenHref(href, "/platform/nds")) {
                markNode(platformCardShell(anchor), "nds");
            }
        });

        document.querySelectorAll("span,div,h6,p").forEach(function(element) {
            if (element.childElementCount === 0 && element.textContent.trim() === "Nintendo DS") {
                markNode(platformCardShell(element), "nds");
            }
        });
    }

    function elementText(node) {
        return normalize(node && node.textContent);
    }

    function platformSectionScore(node) {
        if (!node || !node.querySelectorAll) return 0;

        var text = elementText(node);
        if (!text) return 0;

        var score = text.indexOf("platforms") >= 0 ? 1 : 0;
        platformHints.forEach(function(hint) {
            if (text.indexOf(hint) >= 0) score += 1;
        });

        score += Math.min(node.querySelectorAll("a[href^='/p/'],a[href^='/platform/']").length, 4);

        if (
            text.indexOf("recently added") >= 0 &&
            text.indexOf("continue playing") >= 0 &&
            text.indexOf("autogenerated collections") >= 0
        ) {
            score -= 20;
        }

        return score;
    }

    function homeRoot() {
        return document.querySelector("main .v-container") ||
            document.querySelector(".v-main .v-container") ||
            document.querySelector("main") ||
            document.querySelector(".v-main") ||
            document.body;
    }

    function findPlatformSection(root) {
        var best = null;
        var bestScore = 0;
        var selector = ".v-card,.v-sheet,section,.v-container > div,.v-row,[class*='section'],[class*='Section']";

        root.querySelectorAll(selector).forEach(function(node) {
            var score = platformSectionScore(node);
            if (score < 4) return;
            if (!best || score > bestScore || (score === bestScore && best.contains(node))) {
                best = node;
                bestScore = score;
            }
        });

        return best;
    }

    function topChildWithin(node, root) {
        var current = node;
        while (current && current.parentElement && current.parentElement !== root && current.parentElement !== document.body) {
            current = current.parentElement;
        }
        return current && current.parentElement === root ? current : null;
    }

    function findStatsStrip(root, platformSection) {
        return Array.from(root.children).find(function(child) {
            if (child === platformSection) return false;
            var text = elementText(child);
            return text.indexOf("size on disk") >= 0 && text.indexOf("games") >= 0 && text.indexOf("saves") >= 0;
        });
    }

    function insertAfter(node, target) {
        if (!node || !target || !target.parentNode || node === target) return;
        target.parentNode.insertBefore(node, target.nextSibling);
    }

    function homeSectionScore(node, phrases) {
        if (!node || !node.querySelectorAll) return 0;
        var text = elementText(node);
        if (!text) return 0;

        var score = 0;
        phrases.forEach(function(phrase) {
            if (text.indexOf(phrase) >= 0) score += 6;
        });
        score += Math.min(node.querySelectorAll(".game-card,a[href^='/rom/'],a[href^='/collection/']").length, 5);

        if (
            text.indexOf("recently added") >= 0 &&
            text.indexOf("continue playing") >= 0 &&
            text.indexOf("autogenerated collections") >= 0
        ) {
            score -= 20;
        }

        return score;
    }

    function findHomeSection(root, phrases) {
        var best = null;
        var bestScore = 0;
        var selector = ".v-card,.v-sheet,section,.v-container > div,.v-row,[class*='section'],[class*='Section']";

        root.querySelectorAll(selector).forEach(function(node) {
            var score = homeSectionScore(node, phrases);
            if (score < 6) return;

            var top = topChildWithin(node, root);
            if (!top || top === root) return;

            var topText = elementText(top);
            if (
                topText.indexOf("platforms") >= 0 &&
                topText.indexOf("recently added") >= 0 &&
                topText.indexOf("autogenerated collections") >= 0
            ) {
                return;
            }
            if (topText.length > 1200 && score < 10) return;

            if (!best || score > bestScore || (score === bestScore && topText.length < elementText(best).length)) {
                best = top;
                bestScore = score;
            }
        });

        return best;
    }

    function hideUpdateNag() {
        var candidates = Array.from(document.querySelectorAll(".v-snackbar,.v-overlay,.v-card,.v-sheet")).filter(function(element) {
            var text = elementText(element);
            return text.indexOf("new version available:") >= 0 && text.indexOf("see what's new") >= 0;
        });
        candidates.sort(function(a, b) {
            return elementText(a).length - elementText(b).length;
        });
        hideNode(candidates[0], "update-nag");
    }

    function promotePlatformsSection() {
        document.body.classList.toggle("quickcat-home", isHomePage());
        document.body.classList.toggle("quickcat-phone-width", isPhoneWidth());
        if (!isHomePage()) {
            document.querySelectorAll('[data-quickcat-home-section], [data-quickcat-platforms-section], #quickcat-smorgasboard').forEach(function(el) {
                el.remove();
            });
            return;
        }

        var root = homeRoot();
        var section = findPlatformSection(root);
        var topSection = section && topChildWithin(section, root);

        var statsStrip = findStatsStrip(root, topSection);
        if (statsStrip) statsStrip.setAttribute("data-quickcat-stats-strip", "true");

        if (topSection) {
            section.setAttribute("data-quickcat-platforms-section", "true");
            topSection.setAttribute("data-quickcat-platforms-section", "true");
            topSection.setAttribute("data-quickcat-home-section", "platforms");

            var target = statsStrip ? statsStrip.nextSibling : root.firstChild;
            if (target && target !== topSection && topSection.previousSibling !== statsStrip) {
                root.insertBefore(topSection, target);
            }
        }

        var continueSection = findHomeSection(root, ["continue playing", "resume playing"]);
        var recentSection = findHomeSection(root, ["recently added", "recently played", "new games"]);
        var generatedSection = findHomeSection(root, ["autogenerated collections", "auto generated collections"]);

        if (continueSection) continueSection.setAttribute("data-quickcat-home-section", "continue");
        if (recentSection) recentSection.setAttribute("data-quickcat-home-section", "recent");
        if (generatedSection) hideNode(generatedSection, "home-autogenerated-collections");

        if (topSection && continueSection && continueSection !== topSection) insertAfter(continueSection, topSection);
        if (recentSection && recentSection !== continueSection && recentSection !== topSection) {
            insertAfter(recentSection, continueSection || topSection || statsStrip || root.firstChild);
        }
    }

    var smorgasboardLoading = false;
    function ensureSmorgasboard() {
        if (!isHomePage()) return;
        var root = homeRoot();
        if (!root) return;

        var existing = document.getElementById('quickcat-smorgasboard');
        if (existing) return;

        var container = document.createElement('div');
        container.id = 'quickcat-smorgasboard';
        container.className = 'v-card v-theme--light v-card--density-default elevation-0 v-card--variant-elevated bg-background ma-2';
        container.setAttribute('data-quickcat-home-section', 'smorgasboard');
        
        container.innerHTML = [
            '<header class="v-toolbar v-toolbar--collapse-start v-toolbar--density-compact v-theme--light v-locale--is-ltr bg-toplayer px-1" style="border-radius: 8px 8px 0 0; background: rgba(16, 19, 26, 0.96) !important; border-bottom: 1px solid rgba(255, 255, 255, 0.08) !important;">',
            '  <div class="v-toolbar__content" style="height: 48px;">',
            '    <div class="v-toolbar-title text-button">',
            '      <div class="v-toolbar-title__placeholder d-flex align-center" style="color: rgba(226, 233, 242, 0.96); font-weight: bold; letter-spacing: 0.05em;">',
            '        <i class="v-icon notranslate v-icon--size-default mdi mdi-dice-multiple mr-2" style="font-size: 20px;"></i>',
            '        <span>Smorgasboard</span>',
            '        <button id="smorgasboard-refresh" class="v-btn v-btn--icon v-theme--light v-btn--density-compact v-btn--size-default v-btn--variant-text ml-auto" title="Refresh" style="color: rgba(226, 233, 242, 0.6); margin-left: auto; border: none; background: transparent; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; width: 36px; height: 36px; border-radius: 50%;">',
            '          <i class="v-icon notranslate v-icon--size-default mdi mdi-refresh" style="font-size: 20px;"></i>',
            '        </button>',
            '      </div>',
            '    </div>',
            '  </div>',
            '</header>',
            '<div class="v-card-text pa-4" style="background: rgba(16, 19, 26, 0.4); border-radius: 0 0 8px 8px;">',
            '  <div class="quickcat-smorgasboard-grid" id="smorgasboard-grid">',
            '    <div class="d-flex align-center justify-center py-8 w-100" style="color: rgba(226, 233, 242, 0.4); grid-column: 1 / -1;">',
            '      <i class="v-icon notranslate v-icon--size-default mdi mdi-loading spin-active mr-2"></i> Loading discoveries...',
            '    </div>',
            '  </div>',
            '</div>'
        ].join('\n');

        root.appendChild(container);
        fetchSmorgasboardGames();
    }

    function fetchSmorgasboardGames() {
        if (smorgasboardLoading) return;
        smorgasboardLoading = true;

        var grid = document.getElementById('smorgasboard-grid');
        var refreshBtn = document.getElementById('smorgasboard-refresh');
        var refreshIcon = refreshBtn ? refreshBtn.querySelector('.mdi-refresh') : null;

        if (refreshIcon) {
            refreshIcon.classList.add('spin-active');
        }

        fetch('/api/roms?limit=1')
            .then(function(res) {
                if (!res.ok) throw new Error('Failed to fetch total count');
                return res.json();
            })
            .then(function(data) {
                var total = data.total || 2500;
                var batchSize = 120;
                var maxOffset = Math.max(0, total - batchSize);
                var randomOffset = Math.floor(Math.random() * maxOffset);

                return fetch('/api/roms?limit=' + batchSize + '&offset=' + randomOffset)
                    .then(function(r) {
                        if (!r.ok) throw new Error('Failed to fetch batch');
                        return r.json();
                    });
            })
            .then(function(data) {
                var items = data.items || data || [];
                // Filter to keep only games with cover art
                var withCover = items.filter(function(game) {
                    return !!(game.path_cover_large || game.path_cover_small || game.url_cover);
                });
                // Shuffle items locally
                var shuffled = withCover.sort(function() {
                    return Math.random() - 0.5;
                });
                var games = shuffled.slice(0, 36);
                renderSmorgasboardGames(games);
            })
            .catch(function(err) {
                if (grid) {
                    grid.innerHTML = [
                        '<div class="d-flex flex-column align-center justify-center py-8 w-100" style="color: rgba(226, 233, 242, 0.4); grid-column: 1 / -1;">',
                        '  <i class="v-icon notranslate v-icon--size-default mdi mdi-alert-circle-outline mb-2" style="font-size: 28px;"></i>',
                        '  <span>Could not load the smorgasboard. Click refresh to try again.</span>',
                        '</div>'
                    ].join('\n');
                }
                if (window.console) console.error('[romm-ui] Smorgasboard error:', err);
            })
            .finally(function() {
                smorgasboardLoading = false;
                if (refreshIcon) {
                    refreshIcon.classList.remove('spin-active');
                }
                
                var newRefreshBtn = document.getElementById('smorgasboard-refresh');
                if (newRefreshBtn && !newRefreshBtn.hasListener) {
                    newRefreshBtn.hasListener = true;
                    newRefreshBtn.addEventListener('click', function(e) {
                        e.preventDefault();
                        e.stopPropagation();
                        fetchSmorgasboardGames();
                    });
                }
            });
    }

    function renderSmorgasboardGames(games) {
        var grid = document.getElementById('smorgasboard-grid');
        if (!grid) return;

        if (games.length === 0) {
            grid.innerHTML = [
                '<div class="d-flex align-center justify-center py-8 w-100" style="color: rgba(226, 233, 242, 0.4); grid-column: 1 / -1;">',
                '  No games found to display.',
                '</div>'
            ].join('\n');
            return;
        }

        var html = games.map(function(game) {
            var coverUrl = game.path_cover_large || game.path_cover_small || game.url_cover;
            var coverHtml = '';
            if (coverUrl) {
                coverHtml = '<img class="v-img__img v-img__img--cover" src="' + coverUrl + '" style="width:100%; height:100%; object-fit:cover;" loading="lazy">';
            } else {
                coverHtml = [
                    '<div class="d-flex flex-column align-center justify-center text-center pa-2 fill-height" style="color: rgba(226, 233, 242, 0.5); height: 100%; background: rgba(22, 26, 35, 0.6); aspect-ratio: 2/3;">',
                    '  <i class="v-icon notranslate v-icon--size-default mdi mdi-gamepad-variant-outline mb-1" style="font-size: 24px; color: rgba(226, 233, 242, 0.4);"></i>',
                    '  <span style="font-size: 11px; line-height: 1.2; font-weight: bold; overflow: hidden; text-overflow: ellipsis; display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical;">' + game.name + '</span>',
                    '</div>'
                ].join('\n');
            }

            var platformHtml = '';
            if (game.platform_slug) {
                platformHtml = [
                    '<div class="v-avatar v-theme--light v-avatar--density-default rounded-0 v-avatar--variant-text ml-1" title="' + (game.platform_display_name || '') + '" style="width: 20px; height: 20px;">',
                    '  <div class="v-responsive v-img">',
                    '    <img class="v-img__img v-img__img--cover" src="/assets/platforms/' + game.platform_slug + '.svg" style="width: 100%; height: 100%;">',
                    '  </div>',
                    '</div>'
                ].join('\n');
            }

            return [
                '<a href="/rom/' + game.id + '" class="v-card v-card--link v-theme--light v-card--density-default v-card--variant-flat game-card bg-transparent transform-scale" aria-label="' + game.name + ' game card" style="display: block; text-decoration: none;">',
                '  <div class="v-card-text pa-0 position-relative" style="height: 100%;">',
                '    <div class="v-responsive v-img pointer transitioning" style="border-radius: 7px; overflow: hidden; border: 1px solid rgba(255,255,255,0.06); aspect-ratio: 2/3; background: rgba(18, 22, 30, 0.92); position: relative;">',
                '      ' + coverHtml,
                '      <div class="position-absolute" style="inset: 0; pointer-events: none; display: flex; flex-direction: column; justify-content: flex-end;">',
                '        <div style="width: 100%; background: linear-gradient(0deg, rgba(10,12,18,0.9) 0%, rgba(10,12,18,0.6) 40%, rgba(10,12,18,0) 100%); padding: 6px 4px 4px 4px;">',
                '          <div class="d-flex align-center">',
                '            ' + platformHtml,
                '            <span class="ml-2 text-truncate" style="font-size: 10px; color: rgba(226, 233, 242, 0.8); font-weight: 500; max-width: calc(100% - 28px);">' + game.name + '</span>',
                '          </div>',
                '        </div>',
                '      </div>',
                '    </div>',
                '  </div>',
                '</a>'
            ].join('\n');
        }).join('\n');

        grid.innerHTML = html;
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

    function playablePlatformOnPage() {
        var text = normalize(document.title + " " + document.body.textContent.slice(0, 5000));
        return playablePlatformHints.some(function(hint) {
            return text.indexOf(hint) >= 0;
        });
    }

    function findArtworkActionHost(artwork) {
        if (!artwork) return null;
        var group = artwork.querySelector(".v-btn-group,[class*='v-btn-group']");
        return group && group.parentElement;
    }

    function gameTitle() {
        return ((document.title || "this game").split("|")[0] || "this game").trim();
    }

    function removePlayCtas() {
        ["quickcat-primary-play", "quickcat-play-fallback"].forEach(function(id) {
            var node = document.getElementById(id);
            if (node) node.remove();
        });
    }

    function ensurePlayFallback() {
        var existing = document.getElementById("quickcat-primary-play");
        var oldFallback = document.getElementById("quickcat-play-fallback");
        var hiddenAction = document.querySelector('[data-quickcat-hidden="rom-action-noise"]');
        document.body.classList.toggle("quickcat-rom-detail", isRomDetailPage());

        if (!isRomDetailPage()) {
            removePlayCtas();
            if (hiddenAction) hiddenAction.style.removeProperty("display");
            return;
        }

        var artwork = document.getElementById("artwork-container");
        if (!artwork) return;

        var nativePlay = document.querySelector('[aria-label^="Play "]');
        if (!nativePlay && !playablePlatformOnPage()) {
            removePlayCtas();
            if (hiddenAction) hiddenAction.style.removeProperty("display");
            return;
        }

        var romId = currentRomId();
        if (!romId) return;

        var actionHost = findArtworkActionHost(artwork);
        var inlinePlay = isPhoneWidth();

        if (nativePlay && hiddenAction && !inlinePlay) hiddenAction.style.removeProperty("display");
        if ((!nativePlay || inlinePlay) && actionHost) hideNode(actionHost, "rom-action-noise");
        if (oldFallback) oldFallback.remove();

        if (!existing) {
            existing = document.createElement("a");
            existing.id = "quickcat-primary-play";
            existing.className = "quickcat-primary-play";
        }

        var playHost = inlinePlay ? artwork : document.body;
        if (existing.parentElement !== playHost) playHost.appendChild(existing);
        existing.classList.toggle("quickcat-primary-play--inline", inlinePlay);

        existing.href = addQueryParam(nativePlay && nativePlay.getAttribute("href") ? nativePlay.getAttribute("href") : "/rom/" + romId + "/ejs", "quickcat_autoplay", "1");
        existing.setAttribute("aria-label", "Play " + gameTitle());
        existing.textContent = "Play this game";
    }

    function findLaunchPlayButton() {
        var preferred = document.querySelector(".play-button");
        if (preferred) return preferred.closest("button,a,.v-btn") || preferred;

        return Array.from(document.querySelectorAll("button,a,.v-btn")).find(function(element) {
            var label = normalize(element.textContent);
            return label === "play" || label === "start now" || label === "start game";
        });
    }

    function maybeAutoplayLaunch() {
        if (!quickcatAutoplayRequested()) {
            document.body.classList.remove("quickcat-ejs-autoplay");
            return;
        }

        if (document.querySelector(".ejs_parent")) {
            document.body.classList.remove("quickcat-ejs-autoplay");
            return;
        }

        document.body.classList.add("quickcat-ejs-autoplay");

        var playButton = findLaunchPlayButton();
        if (!playButton || playButton.disabled || playButton.getAttribute("aria-disabled") === "true") return;

        var key = location.pathname + location.search;
        if (window.__quickcatAutoplayKey === key) return;
        window.__quickcatAutoplayKey = key;
        playButton.setAttribute("data-quickcat-autoplay-target", "true");

        setTimeout(function() {
            if (!quickcatAutoplayRequested() || !playButton.isConnected) return;
            document.body.classList.remove("quickcat-ejs-autoplay");
            playButton.click();
        }, 450);
    }

    function simplifyEjsLaunchPage() {
        if (!isEjsLaunchPage()) {
            document.body.classList.remove("quickcat-ejs-launch");
            document.body.classList.remove("quickcat-ejs-autoplay");
            return;
        }

        document.body.classList.add("quickcat-ejs-launch");
        if (!isPhoneWidth()) return;

        var emptySavePanel = Array.from(document.querySelectorAll(".v-col,.v-card")).filter(function(element) {
            var text = elementText(element);
            return text.indexOf("saves") >= 0 &&
                text.indexOf("states") >= 0 &&
                text.indexOf("no save selected") >= 0 &&
                text.indexOf("no saves available") >= 0;
        }).sort(function(a, b) {
            return elementText(a).length - elementText(b).length;
        })[0];

        if (emptySavePanel) {
            hideNode(emptySavePanel.closest(".v-col") || emptySavePanel, "empty-ejs-saves");
        }

        Array.from(document.querySelectorAll("button,.v-btn")).forEach(function(element) {
            if (normalize(element.textContent) === "full screen") {
                hideNode(element.closest("button,.v-btn") || element, "ejs-fullscreen-toggle");
            }
        });

        Array.from(document.querySelectorAll("button,a,.v-btn,p,span,div")).forEach(function(element) {
            if (element.childElementCount > 1) return;
            var label = normalize(element.textContent);
            if (label === "clear emulatorjs cache" || label === "powered by emulatorjs") {
                hideNode(element.closest("button,a,.v-btn") || element, "ejs-launch-noise");
            }
        });
    }

    function run() {
        safely(seedEmulatorDefaults);
        safely(patchViewportFit);
        safely(ensurePlayFallback);
        safely(maybeAutoplayLaunch);
        safely(promotePlatformsSection);
        safely(ensureSmorgasboard);
        safely(hideNdsCards);
        safely(hideUpdateNag);
        safely(hideRommNoise);
        safely(simplifyEjsLaunchPage);
    }

    var runPending = false;
    function scheduleRun() {
        if (runPending) return;
        runPending = true;
        requestAnimationFrame(function() {
            runPending = false;
            run();
        });
    }

    seedEmulatorDefaults();

    function startCleanup() {
        run();
        new MutationObserver(scheduleRun).observe(document.body, { childList: true, subtree: true });
        window.addEventListener("resize", scheduleRun, { passive: true });

        var attempts = 0;
        var startupPoll = setInterval(function() {
            attempts += 1;
            run();
            if (attempts >= 24) clearInterval(startupPoll);
        }, 500);
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", startCleanup);
    } else {
        startCleanup();
    }
})();

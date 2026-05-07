(function() {
    if (window.__rommEmulatorTouchHook) return;
    window.__rommEmulatorTouchHook = true;

    var buttonClass = "romm_touch_menu_toggle";
    var menuVisibleClass = "romm_touch_menu_visible";
    var mobileMaxWidth = 960;

    function isSmallScreen() {
        return window.innerWidth <= mobileMaxWidth;
    }

    function wrapHook(fn, extension, name) {
        if (typeof fn === "function" && fn.__rommTouchExtension === extension) {
            return fn;
        }

        var wrapped = function() {
            var result;
            if (typeof fn === "function") {
                try {
                    result = fn.apply(this, arguments);
                } catch (error) {
                    console.error("[romm] existing " + name + " hook failed", error);
                }
            }
            extension.apply(this, arguments);
            return result;
        };

        wrapped.__rommTouchExtension = extension;
        return wrapped;
    }

    function patchWindowHook(name, extension) {
        var current = wrapHook(window[name], extension, name);
        Object.defineProperty(window, name, {
            configurable: true,
            get: function() {
                return current;
            },
            set: function(fn) {
                current = wrapHook(fn, extension, name);
            }
        });
    }

    function withEmulator(callback, attempt) {
        var emulator = window.EJS_emulator;
        if (emulator) {
            callback(emulator);
            return;
        }
        if ((attempt || 0) > 80) return;
        window.setTimeout(function() {
            withEmulator(callback, (attempt || 0) + 1);
        }, 50);
    }

    function closeMenu(emulator) {
        if (!emulator || !emulator.elements || !emulator.elements.menu) return;
        emulator.elements.menu.classList.remove(menuVisibleClass);
    }

    function ensureMenuButton(emulator) {
        if (!emulator || !emulator.elements || !emulator.elements.parent || !emulator.elements.menu) return null;

        var parent = emulator.elements.parent;
        var menu = emulator.elements.menu;
        var button = parent.querySelector("." + buttonClass);
        if (button) return button;

        button = document.createElement("button");
        button.type = "button";
        button.className = buttonClass;
        button.setAttribute("aria-label", "Open emulator menu");
        button.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512" aria-hidden="true"><path fill="currentColor" d="M0 96C0 78.3 14.3 64 32 64H416C433.7 64 448 78.3 448 96C448 113.7 433.7 128 416 128H32C14.3 128 0 113.7 0 96zM0 256C0 238.3 14.3 224 32 224H416C433.7 224 448 238.3 448 256C448 273.7 433.7 288 416 288H32C14.3 288 0 273.7 0 256zM448 416C448 433.7 433.7 448 416 448H32C14.3 448 0 433.7 0 416C0 398.3 14.3 384 32 384H416C433.7 384 448 398.3 448 416z"/></svg>';
        button.addEventListener("click", function(event) {
            event.preventDefault();
            event.stopPropagation();
            menu.classList.toggle(menuVisibleClass);
        });

        parent.addEventListener("pointerdown", function(event) {
            if (button.style.display === "none") return;
            if (button.contains(event.target) || menu.contains(event.target)) return;
            closeMenu(emulator);
        }, true);

        menu.addEventListener("click", function(event) {
            var target = event.target.closest("button, a, label, input, select");
            if (!target) return;
            window.setTimeout(function() {
                closeMenu(emulator);
            }, 0);
        });

        parent.appendChild(button);
        return button;
    }

    function syncTouchMenu(emulator) {
        var button = ensureMenuButton(emulator);
        if (!button) return;

        var showButton = isSmallScreen();

        button.style.display = showButton ? "flex" : "none";
        button.setAttribute("aria-hidden", showButton ? "false" : "true");
        if (!showButton) closeMenu(emulator);
    }

    function patchEmulator(emulator) {
        if (!emulator) return;
        if (!emulator.__rommTouchMenuPatched) {
            emulator.__rommTouchMenuPatched = true;

            if (typeof emulator.changeSettingOption === "function") {
                var originalChangeSettingOption = emulator.changeSettingOption.bind(emulator);
                emulator.changeSettingOption = function(option, value, save) {
                    var result = originalChangeSettingOption(option, value, save);
                    if (option === "virtual-gamepad" || option === "menu-bar-button") {
                        syncTouchMenu(emulator);
                    }
                    return result;
                };
            }

            window.addEventListener("resize", function() {
                syncTouchMenu(emulator);
            }, { passive: true });
        }

        syncTouchMenu(emulator);
    }

    patchWindowHook("EJS_ready", function() {
        withEmulator(patchEmulator, 0);
    });

    patchWindowHook("EJS_onGameStart", function() {
        withEmulator(patchEmulator, 0);
    });
})();

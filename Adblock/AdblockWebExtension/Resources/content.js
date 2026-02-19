//document.body.style.border = "5px solid red";
(function() {
    if (window.__adblockPickerLoaded) return;
    window.__adblockPickerLoaded = true;

    // ====== ELEMENT PICKER ======
    let pickerActive = false;
    let highlightedEl = null;
    let overlay = null;

    function createOverlay() {
        overlay = document.createElement("div");
        overlay.id = "adblock-picker-overlay";
        overlay.setAttribute("style", "position:fixed;top:0;left:0;right:0;z-index:2147483647;");
        overlay.innerHTML = `
            <div style="display:flex;justify-content:space-between;align-items:center;padding:12px 16px;background:rgba(0,0,0,0.9);color:white;font-family:-apple-system,sans-serif;font-size:14px;">
                <span>Tap an element to hide it</span>
                <button id="adblock-picker-done" style="background:#ff3b30;color:white;border:none;border-radius:8px;padding:6px 14px;font-size:14px;font-weight:600;">✕ Done</button>
            </div>
        `;
        document.body.appendChild(overlay);
        document.getElementById("adblock-picker-done").addEventListener("click", deactivatePicker);
    }

    function activatePicker() {
            if (pickerActive) return;
            pickerActive = true;
            createOverlay();
            document.addEventListener("touchstart", onPickerTouchStart, { capture: true, passive: false });
            document.addEventListener("touchend", onPickerTouchEnd, { capture: true, passive: false });
            document.addEventListener("click", onPickerBlockClick, true);
        }

        function deactivatePicker() {
            pickerActive = false;
            if (highlightedEl) {
                highlightedEl.style.outline = "";
                highlightedEl.style.outlineOffset = "";
                highlightedEl.style.backgroundColor = "";
                highlightedEl = null;
            }
            if (overlay) {
                overlay.remove();
                overlay = null;
            }
            document.removeEventListener("touchstart", onPickerTouchStart, { capture: true, passive: false });
            document.removeEventListener("touchend", onPickerTouchEnd, { capture: true, passive: false });
            document.removeEventListener("click", onPickerBlockClick, true);
        }

        function onPickerBlockClick(e) {
            if (!pickerActive) return;
            if (e.target.closest("#adblock-picker-overlay")) return;
            e.preventDefault();
            e.stopPropagation();
            e.stopImmediatePropagation();
            return false;
        }

        function onPickerTouchStart(e) {
            if (!pickerActive) return;
            if (e.target.closest("#adblock-picker-overlay")) return;
            e.preventDefault();
            e.stopPropagation();
            e.stopImmediatePropagation();
        }

        function onPickerTouchEnd(e) {
            if (!pickerActive) return;
            if (e.target.closest("#adblock-picker-overlay")) return;
            
            e.preventDefault();
            e.stopPropagation();
            e.stopImmediatePropagation();
            
            const touch = e.changedTouches[0];
            const el = document.elementFromPoint(touch.clientX, touch.clientY);
            
            if (!el || el.closest("#adblock-picker-overlay")) return;
            
            // Пропускаем элементы, которые уже скрыты
            const computedStyle = window.getComputedStyle(el);
            if (computedStyle.display === "none" || computedStyle.visibility === "hidden") {
                console.log("[ADBLOCK] Element already hidden, skipping");
                return;
            }
            
            console.log("[ADBLOCK] tapped:", el.tagName, el.className);
            
            if (el === highlightedEl) {
                const selector = generateSelector(el);
                if (selector) {
                    // Visual Blocker работает независимо от состояния блокировки
                    // Пользователь вручную выбирает элементы для скрытия
                    console.log("[ADBLOCK] Hiding element with selector:", selector);
                    
                    // Скрываем элемент сразу
                    el.style.display = "none";
                    
                    // Сохраняем правило
                    saveCustomRule(selector, window.location.hostname)
                        .then(success => {
                            if (success) {
                                console.log("[ADBLOCK] Rule saved for:", window.location.hostname);
                                // Подсчитываем только если блокировка включена
                                checkIsEnabled().then(isEnabled => {
                                    if (isEnabled) {
                                        countBlocked(1);
                                    }
                                });
                            } else {
                                console.error("[ADBLOCK] Failed to save rule, element still hidden");
                            }
                        });
                } else {
                    console.log("[ADBLOCK] Failed to generate selector for element");
                }
                highlightedEl = null;
                return;
            }
            
            if (highlightedEl) {
                highlightedEl.style.outline = "";
                highlightedEl.style.outlineOffset = "";
                highlightedEl.style.backgroundColor = "";
            }
            el.style.outline = "3px solid #ff3b30";
            el.style.outlineOffset = "2px";
            el.style.backgroundColor = "rgba(255, 59, 48, 0.15)";
            highlightedEl = el;
        }

    function generateSelector(el) {
        if (el.id) {
            return `#${CSS.escape(el.id)}`;
        }
        if (el.classList.length > 0) {
            const classes = Array.from(el.classList)
                .filter(c => c !== "adblock-highlight")
                .map(c => `.${CSS.escape(c)}`)
                .join("");
            if (classes && document.querySelectorAll(classes).length === 1) {
                return classes;
            }
        }
        const path = [];
        let current = el;
        while (current && current !== document.body) {
            let selector = current.tagName.toLowerCase();
            if (current.id) {
                selector = `#${CSS.escape(current.id)}`;
                path.unshift(selector);
                break;
            }
            const parent = current.parentElement;
            if (parent) {
                const siblings = Array.from(parent.children).filter(c => c.tagName === current.tagName);
                if (siblings.length > 1) {
                    const index = siblings.indexOf(current) + 1;
                    selector += `:nth-of-type(${index})`;
                }
            }
            path.unshift(selector);
            current = current.parentElement;
        }
        return path.join(" > ");
    }

    function saveCustomRule(selector, hostname) {
        return browser.runtime.sendMessage({ type: "saveRule", selector, hostname })
            .then(response => {
                if (response && response.ok) {
                    console.log("[ADBLOCK] Rule successfully saved");
                    return true;
                } else {
                    console.error("[ADBLOCK] Failed to save rule");
                    return false;
                }
            })
            .catch(error => {
                console.error("[ADBLOCK] Error saving rule:", error);
                return false;
            });
    }

    function checkIsEnabled() {
        return new Promise((resolve) => {
            browser.runtime.sendNativeMessage(
                browser.runtime.id,
                { type: "getIsEnabled" }
            ).then(response => {
                resolve(response && response.isEnabled === true);
            }).catch(() => {
                // Если не удалось получить состояние, считаем что блокировка включена (fallback)
                resolve(true);
            });
        });
    }

    function applyCustomRules() {
        // Визуальные правила (custom rules) применяются всегда,
        // так как это пользовательский выбор элементов для скрытия
        browser.runtime.sendMessage({ type: "getRules", hostname: window.location.hostname })
            .then(response => {
                if (response && response.rules && response.rules.length > 0) {
                    const style = document.createElement("style");
                    style.id = "adblock-custom-rules";
                    style.textContent = response.rules
                        .map(r => `${r.selector} { display: none !important; }`)
                        .join("\n");
                    document.head.appendChild(style);
                    // Подсчитываем только если блокировка включена
                    checkIsEnabled().then(isEnabled => {
                        if (isEnabled) {
                            countBlocked(response.rules.length);
                        }
                    });
                }
            })
            .catch(() => {});
    }

    function countBlocked(count) {
        // Проверяем состояние блокировки перед подсчетом
        checkIsEnabled().then(isEnabled => {
            if (isEnabled) {
                browser.runtime.sendMessage({ type: "blocked", count });
            }
        });
    }

    function countBlockedResources() {
        checkIsEnabled().then(isEnabled => {
            if (!isEnabled) {
                return;
            }
            
            let blocked = 0;
            document.querySelectorAll("img").forEach(img => {
                if (!img.complete || img.naturalWidth === 0) {
                    if (img.src && !img.src.startsWith("data:")) blocked++;
                }
            });
            document.querySelectorAll("iframe[src]").forEach(iframe => {
                try { if (!iframe.contentDocument && iframe.src) blocked++; }
                catch (e) { blocked++; }
            });
            if (blocked > 0) countBlocked(blocked);
        });
    }

    // Функция удаления правил больше не нужна,
    // так как визуальные правила применяются всегда

    // ====== POLLING ======
    let lastIsEnabledState = null;
    
    // Инициализируем состояние при первой загрузке
    checkIsEnabled().then(isEnabled => {
        lastIsEnabledState = isEnabled;
    });
    
    setInterval(() => {
        // Проверяем состояние picker
        browser.storage.local.get("shouldActivatePicker").then(data => {
            if (data.shouldActivatePicker) {
                console.log("[ADBLOCK] Picker activating from storage!");
                activatePicker();
                browser.storage.local.set({ shouldActivatePicker: false });
            }
        }).catch(() => {});
        
        // Визуальные правила применяются всегда, независимо от состояния блокировки
        // Проверяем состояние только для подсчета статистики
        checkIsEnabled().then(isEnabled => {
            lastIsEnabledState = isEnabled;
        });
    }, 1000);

    // ====== INIT ======
    applyCustomRules();
    window.addEventListener("load", () => {
        setTimeout(countBlockedResources, 2000);
    });

})();

let customRules = {};

browser.storage.local.get("customRules").then(data => {
    customRules = data.customRules || {};
});

browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
    
    if (message.type === "startPicker") {
        browser.storage.local.set({ shouldActivatePicker: true }).then(() => {
            console.log("[ADBLOCK BG] picker flag saved to storage");
            sendResponse({ ok: true });
        });
        return true;
    }
    
    if (message.type === "checkPicker") {
        browser.storage.local.get("shouldActivatePicker").then(data => {
            const result = !!data.shouldActivatePicker;
            if (result) {
                browser.storage.local.set({ shouldActivatePicker: false });
            }
            sendResponse({ activate: result });
        });
        return true;
    }
    
    if (message.type === "saveRule") {
        const hostname = message.hostname;
        if (!customRules[hostname]) {
            customRules[hostname] = [];
        }
        const exists = customRules[hostname].some(r => r.selector === message.selector);
        if (!exists) {
            customRules[hostname].push({ selector: message.selector });
            browser.storage.local.set({ customRules });
        }
        sendResponse({ ok: true });
        return true;
    }
    
    if (message.type === "getRules") {
        const rules = customRules[message.hostname] || [];
        sendResponse({ rules });
        return true;
    }
    
    if (message.type === "blocked") {
        const count = message.count || 1;
        browser.runtime.sendNativeMessage(
            browser.runtime.id,
            { type: "blocked", count: count }
        ).catch(() => {});
        sendResponse({ ok: true });
        return true;
    }
    
    return true;
});

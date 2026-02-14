console.log("🔥 background started");

browser.runtime.onMessage.addListener((message, sender, sendResponse) => {

    if (message.type === "blocked") {

        console.log("📩 sending to native:", message);

        browser.runtime.sendNativeMessage(
            browser.runtime.id,
            message
        ).then(response => {
            console.log("✅ native responded:", response);
        }).catch(error => {
            console.error("❌ native error:", error);
        });

        sendResponse({ ok: true });
        return true;
    }
});

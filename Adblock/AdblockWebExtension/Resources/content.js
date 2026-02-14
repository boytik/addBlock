console.log("🔥 content injected");

browser.runtime.sendNativeMessage(
    browser.runtime.id,
    {
        type: "blocked",
        payload: {
            kind: "ad",
            url: window.location.href,
            timestamp: Date.now()
        }
    }
).then(response => {
    console.log("✅ native responded:", response);
}).catch(error => {
    console.error("❌ native error:", error);
});

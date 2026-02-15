browser.runtime.onMessage.addListener((message) => {

    if (message.type === "blocked") {

        browser.runtime.sendNativeMessage(
            browser.runtime.id,
            { type: "blocked" }
        ).catch(error => {
            console.log("Native error:", error);
        });
    }

    return true;
});

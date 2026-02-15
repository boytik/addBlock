document.body.style.border = "5px solid red";

browser.runtime.sendMessage({ type: "blocked" });

//function reportBlocked() {
//    browser.runtime.sendMessage({
//        type: "blocked"
//    });
//}
//document.body.style.border = "5px solid red";
//browser.runtime.sendNativeMessage(
//    browser.runtime.id,
//    { type: "blocked" }
//);
//function checkElement(node) {
//    if (!(node instanceof Element)) return;
//
//    const styles = window.getComputedStyle(node);
//    const isFixed = styles.position === "fixed";
//    const zIndex = parseInt(styles.zIndex) || 0;
//
//    const rect = node.getBoundingClientRect();
//    const coversScreen =
//        rect.width >= window.innerWidth * 0.9 &&
//        rect.height >= window.innerHeight * 0.95;
//
//    if (isFixed && zIndex > 1000 && coversScreen) {
//        node.remove();
//        reportBlocked();
//    }
//}
//
//const observer = new MutationObserver((mutations) => {
//    for (const mutation of mutations) {
//        for (const node of mutation.addedNodes) {
//            checkElement(node);
//        }
//    }
//});
//
//observer.observe(document.documentElement, {
//    childList: true,
//    subtree: true
//});
//
//document.addEventListener("DOMContentLoaded", () => {
//    document.querySelectorAll("*").forEach(checkElement);
//});

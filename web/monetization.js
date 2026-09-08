/**
 * monetization.js
 *
 * Wrapper around the GameMonetize SDK (https://gamemonetize.com).
 *
 * HOW TO INTEGRATE
 * ─────────────────
 * 1. Sign up at gamemonetize.com and create a game entry to get a Game ID.
 * 2. Replace PLACEHOLDER_GAME_ID below with your actual Game ID.
 * 3. Uncomment the SDK <script> tag at the bottom of this file — it loads
 *    the real SDK from GameMonetize's CDN and triggers window.SDK_OPTIONS.
 * 4. Remove or adjust the DEMO MODE block (search for "DEMO MODE") which
 *    currently skips the SDK and calls startEmulator() directly so the page
 *    works without a real Game ID during development.
 *
 * CALLBACK REFERENCE (GameMonetize SDK)
 * ────────────────────────────────────────
 *   pauseGame()   — called before an ad plays  (pause emulator audio/logic)
 *   resumeGame()  — called after an ad ends    (resume emulator)
 *   onInit()      — SDK is ready               (safe to show banners / call SDK.showBanner)
 *   onError(e)    — SDK failed to load         (degrade gracefully)
 *
 * SDK METHODS (available after onInit fires)
 * ────────────────────────────────────────────
 *   SDK.showBanner()         — refresh / show banner ads
 *   SDK.showInterstitial()   — request a fullscreen interstitial ad
 *                              (call at natural break points: level end, game over)
 */

/* ── Config ──────────────────────────────────────────────────────────────── */

var GAME_ID = 'PLACEHOLDER_GAME_ID'; // ← replace with your GameMonetize Game ID

/* ── Emulator pause / resume helpers ─────────────────────────────────────── */
// These are called by the SDK around ad playback.
// Wire to the emulator's own pause API when EmulatorJS exposes it.

function pauseGame() {
    // TODO: pause emulator audio and logic while ad plays
    // Example (if EmulatorJS exposes a global): EJS_emulator.pause();
}

function resumeGame() {
    // TODO: resume emulator after ad ends
    // Example: EJS_emulator.play();
}

/* ── SDK lifecycle callbacks ─────────────────────────────────────────────── */

function onInit(data) {
    // SDK has loaded successfully.
    // Show banner ads in the designated slots.
    // SDK.showBanner() will populate whatever element the SDK targets.

    // TODO: uncomment when real SDK is active
    // SDK.showBanner();

    // Hide the interstitial overlay and start the emulator.
    hideInterstitial();
    startEmulator();
}

function onError(data) {
    // SDK failed — degrade gracefully: skip ads and start the game.
    console.warn('[Monetization] SDK error:', data);
    hideInterstitial();
    startEmulator();
}

/* ── Interstitial (preroll) ──────────────────────────────────────────────── */
// Show the interstitial overlay before the emulator starts.
// The SDK will inject its content into #ad-interstitial-slot.
// When the ad ends the SDK calls resumeGame() → we hide the overlay + launch.

function showInterstitial() {
    document.getElementById('ad-interstitial').classList.add('active');
    pauseGame();

    // TODO: uncomment when real SDK is active
    // SDK.showInterstitial();
}

function hideInterstitial() {
    document.getElementById('ad-interstitial').classList.remove('active');
    resumeGame();
}

// Manual skip button — always available as fallback.
document.getElementById('ad-skip').addEventListener('click', function () {
    hideInterstitial();
    startEmulator();
});

/* ── Mid-session interstitials ───────────────────────────────────────────── */
// Call Monetization.requestInterstitial() at natural break points
// (e.g. game over, level cleared).  The SDK decides whether to show an ad.

var Monetization = {
    requestInterstitial: function () {
        pauseGame();
        // TODO: uncomment when real SDK is active
        // SDK.showInterstitial();
        // The SDK calls resumeGame() when the ad ends.
        // If no ad is available the SDK calls resumeGame() immediately.
        resumeGame(); // remove this line once real SDK is active
    }
};

/* ══════════════════════════════════════════════════════════════════════════
   DEMO MODE — remove this block when the real SDK is integrated.
   Currently skips ads and starts the emulator immediately.
   ══════════════════════════════════════════════════════════════════════════ */
(function demoMode() {
    // startEmulator is defined in a <script> block later in index.html,
    // so defer until the DOM is fully parsed before calling it.
    document.addEventListener('DOMContentLoaded', function () {
        startEmulator();
    });
})();
/* ══════════════════════════════════════════════════════════════════════════ */

/* ── GameMonetize SDK loader ─────────────────────────────────────────────── */
// Uncomment this block to activate the real SDK.
// The SDK script must load AFTER window.SDK_OPTIONS is defined.

/*
window.SDK_OPTIONS = {
    "gameId":                 GAME_ID,
    "userId":                 "",
    "advertisementSettings":  {},
    "resumeGame":             resumeGame,
    "pauseGame":              pauseGame,
    "onInit":                 onInit,
    "onError":                onError
};

(function loadSDK() {
    var s = document.createElement('script');
    s.src = 'https://api.gamemonetize.com/gmapi.js';
    s.onerror = function () { onError('Failed to load SDK script'); };
    document.head.appendChild(s);
})();
*/

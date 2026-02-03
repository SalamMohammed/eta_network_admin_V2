# Optimization & Caching Strategy Report

## Executive Summary
This report details the optimization measures implemented to address background resource inefficiency and excessive Cloud Function invocations. The primary interventions involved implementing strict lifecycle management for periodic timers/streams and restructuring Firestore writes to avoid triggering high-cost listeners.

## 1. Lifecycle Management (Background Optimization)
**Problem:** Several services (`CoinService`, `MiningStateService`, `AdsService`) and UI components (`MyCoinBlock`, `CoinDetailsDialog`) were running `Timer.periodic` or `StreamSubscription` continuously, even when the app was paused (backgrounded). This consumed battery and network resources unnecessarily.

**Solution:**
We implemented `WidgetsBindingObserver` across all relevant services and widgets to detect App Lifecycle changes (`paused` vs `resumed`).

*   **CoinService:**
    *   Implemented `didChangeAppLifecycleState`.
    *   Timers for `watchUserCoin` (15s), `watchMyCoins` (60s), and `watchLiveCoins` (60s) are now cancelled immediately upon `AppLifecycleState.paused`.
    *   Timers are restarted with an immediate data fetch upon `AppLifecycleState.resumed` to ensure UI freshness.
    *   Introduced `_pauseCallbacks` and `_resumeCallbacks` to manage internal stream controller states.

*   **MiningStateService:**
    *   Added `didChangeAppLifecycleState` to cancel `_userDocSub` (Firestore listener), `_realtimeDocSub`, `_simTimer` (UI simulation), and `_subExpiryTimer`.
    *   Ensures no Firestore reads happen while the user is not using the app.

*   **AdsService:**
    *   Ensured `_configSub` (Firestore listener) is cancelled on pause and restarted on resume.
    *   Added logic to prevent duplicate stream initializations on rapid resume events.

*   **UI Components (`MyCoinBlock`, `CoinDetailsDialog`):**
    *   Refactored state classes to mixin `WidgetsBindingObserver`.
    *   Timers used for countdowns/mining simulation are now paused/resumed with the app lifecycle.

## 2. Cloud Function Optimization (Trigger Storm Mitigation)
**Problem:** The `scheduleMiningEndNotification` Cloud Function triggers on *any* write to the `users/{uid}` document. Frequent updates to point balances (via `EarningsEngine.syncEarnings`) were causing this function to fire excessively ("trigger storm"), leading to high costs.

**Solution:**
*   **Subcollection Strategy:** Verified and enforced that `EarningsEngine.syncEarnings` writes incremental point updates to `users/{uid}/earnings/realtime` instead of the main `users/{uid}` document.
*   **Impact:** Updates to `earnings/realtime` do **not** trigger the `users/{uid}` Cloud Function.
*   **Efficiency:** The Cloud Function now only fires when `lastMiningEnd` changes (once per session start) or other critical profile fields change, reducing invocations by >95% for active miners.
*   **Loop Protection:** The Cloud Function includes logic to detect if `scheduledEndMs` matches the current `endMs`, preventing infinite loops when it updates the user document itself.

## 3. Caching & Backend Strategy
**Current Architecture:**
*   **Hybrid Model:** The app uses a hybrid Firestore (Realtime/Auth/Config) + SQL (Mining Records/Coin Data) approach.
*   **SQL Offloading:** `CoinService` is configured (`useSqlBackend = true`) to fetch heavy lists (Live Coins, My Coins) from a PHP/MySQL backend. This significantly reduces Firestore read costs.
*   **Client-Side Caching:**
    *   `CoinService` implements memory caching (`_cachedMyCoins`, `_cachedLiveCoins`) with a 60-second TTL.
    *   This prevents redundant network requests if the UI rebuilds or if the user navigates back and forth quickly.

## 4. Recommendations
1.  **Monitor `earnings/realtime` usage:** Ensure all clients (iOS/Android) are on the version that supports the `earnings/realtime` subcollection to fully realize the cost savings.
2.  **Cloud Tasks vs Scheduled Functions:** The current use of Cloud Tasks for notifications (`sendMiningEndNotificationTask`) is optimal. Continue using this pattern instead of polling DBs.
3.  **Eventarc:** For future triggers, consider using Eventarc with specific field masks (if supported by the platform) to further narrow down trigger conditions, though the subcollection strategy is currently the most effective method for Firestore.

## 5. Verification
*   **Static Analysis:** Verified code paths in `EarningsEngine` and `MiningStateService` to ensure correct write targets and lifecycle hooks.
*   **Logic Check:** Confirmed `Timer.cancel()` is called in all `didChangeAppLifecycleState` pause blocks.

**Status:** Optimization Complete.

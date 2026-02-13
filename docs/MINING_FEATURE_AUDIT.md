# Mining Main ETA Feature Audit

## 1. Executive Summary
The Mining Main ETA feature relies on a **hybrid synchronization model**: it uses local simulation for immediate UI feedback (5-second ticker) and periodic Firestore synchronization for data persistence. The system is designed to be "offline-first" friendly but maintains **4 active real-time listeners** when the app is in the foreground.

**Critical Finding**: The system is generally robust with write-throttling (10 minutes), but the **Referral Count Query** in `MiningStateService` executes a potentially expensive aggregation query (`count()`) on the entire `users` collection every 10 minutes per active user.

---

## 2. Firestore Interaction Map

### A. Read Operations (Data Fetching)
This section details how the app retrieves data from Firestore. It is categorized by "Continuous Monitoring" (always active when app is open) and "On-Demand Checks" (triggered by specific events).

#### 1. Continuous Monitoring (Real-time Listeners)
These listeners are active whenever the app is in the foreground. They instantly update the UI when data changes on the server.
*   **User Profile Stream** (`MiningStateService`): Listens to `users/{uid}` to track mining status, rank, and profile changes.
*   **Real-time Earnings Stream** (`MiningStateService`): Listens to `users/{uid}/earnings/realtime` for the latest point balance updates.
*   **My Coins Stream** (`CoinService`): Watches `users/{uid}/coins/*` to show the user's specific coin holdings.
*   **Live Market Stream** (`CoinService`): Watches `user_coins` (filtered) to display the top 50 active coins in the marketplace.

#### 2. On-Demand Checks (Periodic/Triggered)
These reads happen only when specific conditions are met, such as opening the app or a 10-minute timer expiring.
*   **Manager Status Check** (`MiningStateService`): Checks `managers/{id}` every 10 minutes to verify if the user's manager is still active.
*   **App Configuration** (`MiningStateService`): Fetches `app_config/general` on app launch/resume to get global settings.
*   **Active Referral Count** (`MiningStateService`): Runs an aggregation query on `users` every 10 minutes to count how many invited friends are currently mining.
*   **Earnings Verification** (`EarningsEngine`): Reads `users/{uid}/earnings/realtime` inside a transaction before saving to ensure points are added correctly.

### B. Write Operations (Data Saving)
This section details when and why the app writes data to Firestore.

#### 1. Scheduled Saves
*   **Sync Earnings** (`EarningsEngine`):
    *   **Target**: `users/{uid}/earnings/realtime`
    *   **Frequency**: Every 10 minutes (throttled).
    *   **Purpose**: Persists the points accumulated locally during the last 10 minutes.

#### 2. User Actions & Events
*   **Stop Mining** (`MiningStateService`):
    *   **Target**: `users/{uid}`
    *   **Trigger**: User clicks "Stop Mining".
    *   **Purpose**: Updates `lastMiningEnd` to officially end the session.
*   **Ad Rewards** (`EarningsEngine`):
    *   **Target**: `users/{uid}/earnings/realtime` and `point_logs/{newDoc}`
    *   **Trigger**: User finishes watching a rewarded video ad.
    *   **Purpose**: Increases the mining rate and logs the bonus transaction.

### C. Delete Operations
*No explicit delete operations were found in the mining logic.*

---

## 3. Synchronization Behavior

### Sync Frequency
1.  **App Start / Resume**: Immediate `_refresh()` call.
    -   Fetches config, manager data, and runs `syncEarnings()`.
    -   Attaches 4 real-time listeners.
2.  **Foreground Loop**:
    -   **UI Updates**: Local `Timer` runs every **5 seconds** (`_simTimer`) to update the display score (`_displayTotal`). **Does NOT touch Firestore**.
    -   **Data Persistence**: `EarningsEngine.syncEarnings()` is called. It uses a **local throttle (`_lastLocalWrites`)** to prevent writing to Firestore more than once every **10 minutes**, unless the mining session has naturally ended.
3.  **App Pause**:
    -   All listeners (`_userDocSub`, `_realtimeDocSub`) and timers (`_simTimer`) are **cancelled**.
    -   Firestore calls completely cease.

### Precise Conditions for Cessation
Firestore calls stop completely when:
1.  **Lifecycle State**: App enters `AppLifecycleState.paused` (backgrounded).
2.  **User Logout**: `reset()` is called, cancelling all subscriptions.
3.  **Throttle Active**: Between 10-minute write intervals, `syncEarnings` performs **0 writes** (returns locally calculated projection).

---

## 4. Critical Code Analysis & Findings

### A. Performance Bottlenecks
1.  **Referral Count Aggregation (`MiningStateService.dart`: Lines 218-227)**
    ```dart
    final countQuery = await FirestoreHelper.instance
        .collection(FirestoreConstants.users)
        .where(FirestoreUserFields.invitedBy, isEqualTo: uid)
        .where(FirestoreUserFields.lastMiningEnd, isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .count().get();
    ```
    -   **Issue**: This runs a `count()` aggregation on the global `users` collection. While Firestore optimizes `count()`, it still requires an index scan. As the user base grows, this becomes an O(N) operation on the index for *every active user* every 10 minutes.
    -   **Recommendation**: Denormalize this count. Store `activeReferrals` on the user document and update it via a Scheduled Cloud Function or trigger when referrals start/stop mining.

2.  **Live Coins Query (`CoinService.dart`: Lines 180)**
    ```dart
    .where(FirestoreUserCoinFields.isActive, whereIn: [true, '1', 1])
    ```
    -   **Issue**: The `whereIn` clause suggests data inconsistency (boolean vs string vs int). This forces the query engine to check multiple index entries.
    -   **Recommendation**: Normalize `isActive` to a strict `boolean` during write operations.

### B. Inefficient Query Patterns
1.  **Redundant Config Fetch (`MiningStateService.dart`: Line 207)**
    -   `ConfigService().getGeneralConfig()` is called on every `_refresh()`. While `ConfigService` might have internal caching, `MiningStateService` should explicitly cache this for the session duration (or longer) since app config rarely changes.

### C. Race Conditions
1.  **Display Total Conflict (`MiningStateService.dart`)**
    -   `_displayTotal` is updated by:
        1.  `_simTimer` (Local extrapolation every 5s).
        2.  `_realtimeDocSub` (Firestore listener push).
        3.  `syncEarnings` (Function return value).
    -   **Risk**: If a Firestore write takes >5s to propagate back via the listener, the local timer might drift significantly from the "truth". When the listener finally updates `_totalPoints`, the user might see a "jump" (rollback or jump forward).
    -   **Mitigation**: The code attempts to handle this by resetting `_simBase` on listener update (Lines 587-591), but high latency could still cause visual jitter.

### D. Architectural Flaws
1.  **Service Responsibility Leakage**:
    -   `MiningStateService` directly manages Firestore subscriptions. Ideally, `UserService` should own the single source of truth for the User document stream, and `MiningStateService` should just listen to `UserService.stream`. Currently, both services might be fetching/listening to the same data (though `UserService` tries to handle "Live Mode", `MiningStateService` creates its *own* subscription in `_startUserDocListener`).

---

## 5. Audit Metrics

| Metric | Value | Notes |
| :--- | :--- | :--- |
| **Idle Reads / Min** | ~0.0 | No reads when idle/throttled. |
| **Active Writes / Hour** | 6 | 1 write every 10 mins (throttled). |
| **Active Reads / Hour** | Variable | Depends on `_refresh` triggers. Approx 6-10. |
| **Listener Count** | 4 | High. Consider merging User + Realtime docs. |
| **Memory Leaks** | Low Risk | `dispose` and `didChangeAppLifecycleState` correctly cancel all timers and subs. |


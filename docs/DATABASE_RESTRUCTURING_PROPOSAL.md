# Database Restructuring Proposal: Consolidated Document Model

This proposal outlines the transition from a fragmented collection-based architecture to a consolidated document-based model, optimized for Firestore's 1MB limit and operational cost reduction.

## 1. Core Architecture Design

### I. User Consolidated Document (`users/{uid}`)
*Consolidates profile, settings, and real-time state.*
- **Feasibility**: High. Estimated size ~5KB-10KB.
- **Structure**:
  ```json
  {
    "profile": { "username": "...", "avatar": "...", "email": "..." },
    "mining": { "active": true, "rate": 1.5, "points": 1250.5 },
    "portfolio": { "btc": { "bal": 0.01 }, "eth": { "bal": 0.5 } },
    "settings": { "notifications": true, "theme": "dark" }
  }
  ```

### II. Referral System Architecture (`referrals/{uid}`)
*We adopt **Option A** (One document per inviter) with a strict overflow strategy.*
- **Feasibility**: Moderate. A user with 10,000 referrals would exceed 1MB.
- **Scalability Strategy**: 
  - Store only the last 100 referrals in the `active` array for UI performance.
  - Move older referrals to a sub-collection `referrals/{uid}/archive/{batchId}`.
  - Store a `summary` object in the main doc with total counts and rewards.

### III. Global Coins Ledger (`app_stats/coin_ledger`)
- **CRITICAL WARNING**: Storing *all* users' coin data in a single document is **NOT feasible**. With 100,000 users, this would exceed 1MB instantly.
- **Revised Approach**: Use a **Sharded Ledger**.
  - `coin_ledgers/shard_0...N`: Each shard holds ~1,000 user balances.
  - Enables global queries while staying within limits.

### IV. Master Configuration (`app_config/master`)
- **Feasibility**: High. Consolidates `general`, `referrals`, `streak`, `ranks`, `manager`, `legal`, and `ads`.
- **Benefit**: Reduces app-start reads from 8 to 1.

---

## 2. Technical Specifications

### Indexing Strategy
- **Users**: Index `profile.username` (unique) and `mining.points` (ranking).
- **Referrals**: Index `inviterId` and `timestamp` on the archive sub-collection.
- **Ledger**: Index `userId` across shards using a Collection Group index.

### Size Management
- **Hierarchical Keys**: Use short keys (e.g., `p` for `profile`, `m` for `mining`) to save bytes in large arrays.
- **Pruning**: Activity logs older than 30 days are moved to BigQuery or deleted.

---

## 3. Cloud Functions & Security

### Sync Triggers
- `onUserUpdate`: If `mining.active` changes, trigger a function to update the global `active_miners_count` in `app_stats/global`.
- `onReferral`: Automatically calculates rewards and updates the inviter's `referrals/{uid}` document.

### Security Rules (v2)
```javascript
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
      allow read: if request.auth.token.admin == true;
    }
    match /app_config/master {
      allow read: if request.auth != null;
      allow write: if request.auth.token.admin == true;
    }
  }
}
```

---

## 4. Migration & Risk Assessment

### Phased Rollout
1. **Beta Phase**: Implement "Master Config" and "User Consolidation" for new users only.
2. **Backfill Phase**: Background process migrates existing user data into the consolidated format.
3. **Cutover**: Switch production read paths to the new documents.

### Risks
- **Hotspots**: High-frequency writes to a single consolidated user doc (e.g., every 5 seconds) can cause contention. 
  - **Mitigation**: Maintain the **10-minute throttle** for Firestore writes.
- **Size Bloat**: Managed coin portfolios could grow unexpectedly.
  - **Mitigation**: Limit the number of "Active Managed Coins" to 100 per user.

---

## 5. Performance Benchmarks (Expected)

| Metric | Current | Consolidated | Change |
| :--- | :--- | :--- | :--- |
| **App Start Reads** | 12-15 | 2 | **-85% Cost** |
| **Mining Sync Latency** | 200ms | 150ms | **-25% Latency** |
| **Data Consistency** | Fragmented | Atomic | **High Reliability** |

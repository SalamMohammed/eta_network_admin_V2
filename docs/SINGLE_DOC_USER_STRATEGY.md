# Single Document User Architecture Strategy

## 1. Executive Summary & Verification
**Verification of Constraint**: Firestore enforces a strict **1 MiB (1,048,576 bytes)** limit per document. This includes the size of all field names, field values, and some metadata overhead. In a typical JSON representation, this roughly equates to 500-800 pages of plain text.

**Strategy**: By consolidating fragmented user data (`users/{uid}`, `earnings/realtime`, `coins/*`) into a single hierarchical document, we can significantly reduce read operations (1 read vs. 3-5 reads per session load) and simplify transactional consistency.

**Feasibility**:
-   **Profile Data**: ~0.5 KB
-   **Mining/Earnings State**: ~0.2 KB
-   **Managed Coins**: Even with 50 active coins, size is ~2 KB.
-   **Total Estimated Size**: < 5 KB per user.
-   **Headroom**: > 99% of document space remains available.

---

## 2. Consolidated Schema Design
We will replace the current multi-collection structure with a single, sectioned document.

### Proposed JSON Structure
```json
{
  "uid": "user_123",
  "meta": {
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-02T10:00:00Z",
    "lastSyncedAt": "2024-01-02T10:00:00Z",
    "fcmToken": "token_xyz"
  },
  "profile": {
    "username": "CryptoKing",
    "email": "user@example.com",
    "avatarUrl": "https://...",
    "country": "US",
    "referralCode": "REF123",
    "invitedBy": "user_999"
  },
  "status": {
    "role": "pro",
    "rank": "Guardian",
    "isBanned": false,
    "subscription": {
      "planId": "monthly_pro",
      "expiresAt": "2024-02-01T00:00:00Z",
      "autoRenew": true
    }
  },
  "mining": {
    "state": {
      "isActive": true,
      "lastStart": "2024-01-02T09:00:00Z",
      "lastEnd": "2024-01-02T13:00:00Z",
      "currentSessionId": "sess_001"
    },
    "earnings": {
      "totalPoints": 1500.50,
      "hourlyRate": 12.5,
      "baseRate": 1.0,
      "boosts": {
        "ads": 0.5,
        "referral": 2.0,
        "streak": 1.5
      }
    },
    "portfolio": {
      "coin_btc": {
        "symbol": "BTC",
        "balance": 0.005,
        "hourlyRate": 0.0001,
        "isActive": true
      },
      "coin_eth": {
        "symbol": "ETH",
        "balance": 0.5,
        "hourlyRate": 0.01,
        "isActive": true
      }
    }
  },
  "stats": {
    "referralCount": 15,
    "activeReferrals": 5,
    "streakDays": 12,
    "lastStreakUpdate": "2024-01-02"
  }
}
```

---

## 3. Key Indexing & Access Strategy

### Methodology
Firestore allows querying nested fields using **Dot Notation**. We do not need top-level flattening.

1.  **Primary Indexing**:
    -   `profile.email` (ASC): For login/lookup.
    -   `profile.username` (ASC): For search.
    -   `profile.referralCode` (ASC): For referral lookup.
    -   `status.role` (ASC): For filtering admins/users.

2.  **Portfolio Querying**:
    -   To find users mining a specific coin: Create an index on `mining.portfolio.coin_ID.isActive`.
    -   *Limitation*: You cannot dynamically index *every* possible coin ID if they are dynamic keys.
    -   *Solution*: If you need to query "Users mining BTC", store a summary array: `mining.activeCoinIds: ["btc", "eth"]` and index that array.

3.  **Sub-Document Retrieval**:
    -   Firestore client SDKs always retrieve the **full document**. You cannot partially fetch just `profile`.
    -   **Impact**: Since the doc is small (<5KB), retrieving the full doc is efficient and cheaper than 3 separate reads.

---

## 4. Implementation Plan

### Phase 1: Migration Strategy
1.  **Double-Write**: Update app code to write to BOTH old paths (`users/{uid}/earnings`) and new path (`users/{uid}` merged fields).
2.  **Backfill Script**:
    -   Iterate all users.
    -   Fetch `users/{uid}`, `users/{uid}/earnings/realtime`, `users/{uid}/coins`.
    -   Merge into memory.
    -   Write back to `users/{uid}` using `SetOptions(merge: true)`.
3.  **Cutover**: Update reads to consume only `users/{uid}`. Remove old collections.

### Phase 2: Batch Update Strategy (Partial Updates)
To update just the earnings without overwriting the profile, use dot notation in `update()`:

```dart
// Example: Updating only mining stats
FirebaseFirestore.instance.collection('users').doc(uid).update({
  'mining.earnings.totalPoints': FieldValue.increment(10),
  'mining.state.lastEnd': Timestamp.now(),
  'stats.streakDays': 13
});
```

### Phase 3: Cache Invalidation
-   **Current State**: Different services cache different parts of user data.
-   **New State**: `UserService` becomes the **Sole Source of Truth**.
-   **Protocol**:
    -   `UserService` holds a `BehaviorSubject<UserDoc>` that streams the full user object.
    -   `MiningStateService`, `CoinService`, `ProfilePage` all subscribe to this single stream.
    -   This eliminates sync bugs where "Profile says X but Mining says Y".

### Phase 4: Monitoring
-   **Size Guard**: Add a Cloud Function trigger `onWrite` to `users/{uid}`.
    -   Serialize data to JSON.
    -   Check `size > 800KB`.
    -   If warning threshold met, log critical alert.

---

## 5. Performance & Cost Analysis

### Operation Reduction Calculation

| Scenario | Old Architecture (Reads) | New Architecture (Reads) | Improvement |
| :--- | :--- | :--- | :--- |
| **App Start** | 1 (User) + 1 (Earnings) + 1 (Coins) = **3** | **1** (Full Doc) | **300% Efficiency** |
| **Profile View** | 1 (User) | **0** (Already Cached) | **Infinite** |
| **Mining Sync** | 1 (Write to Earnings) | 1 (Write to User) | Neutral (Same Cost) |
| **Referral Check**| 1 (User) + N (Referrals) | 1 (User) | **High** (if stats used) |

### Limitations (The "Unbounded" Risk)
-   **Referrals**: Do **NOT** store the list of 10,000 invitees in the main doc. Keep `referrals` collection for the raw list. Store only aggregate stats (`count`) in the main doc.
-   **Logs**: Keep `point_logs` separate. History is unbounded.

---

## 6. Testing Procedures
1.  **Size Stress Test**: Generate a user with max allowed fields (max string lengths, max coin portfolio). Assert write success.
2.  **Concurrency Test**: Simulate `MiningService` updating points while `ProfileService` updates avatar URL simultaneously.
    -   *Expected Result*: Both updates succeed (fields are orthogonal).
    -   *Mechanism*: Use `update()` with dot notation, NOT `set()`.
3.  **Migration Integrity**: Run backfill on staging. Compare `old_total_points` vs `new_total_points` for 100% match.

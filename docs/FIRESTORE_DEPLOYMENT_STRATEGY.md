# Firestore Deployment Strategy: Configuration & Constants

## 1. Feasibility Analysis

### Objective
Deploy all Firestore documents and fields defined in `lib/shared/firestore_constants.dart` to the actual Firestore database.

### Findings
*   **Key Availability:** `firestore_constants.dart` provides a robust set of keys for collections, documents, and fields.
*   **Value Limitation:** The constants file defines *keys* (schema structure) but not *values* (configuration data). To deploy meaningful data, a **Seed Data Manifest** must be created that maps these keys to default values.
*   **Type Inference:** Data types for these fields have been inferred from usage in:
    *   `app_config_page.dart` (General, Referrals, Streak, UserCoin)
    *   `rank_engine.dart` (Ranks)
    *   `manager_page.dart` (Manager)
    *   `ads_monetization_page.dart` (Ads)
    *   `settings_legal_page.dart` (Legal)

### Conclusion
Deploying the *structure* is feasible and highly recommended to ensure the database schema matches the application code. However, a "Seed Data" layer is required to provide the actual configuration values.

## 2. Deployment Strategy Components

### A. Seed Data Manifest (`SchemaSeedData`)
A structured data object (in Dart) that uses `FirestoreConstants` keys to define the initial state of the database. This ensures type safety and alignment with the code.

### B. Validation Script (`validateSchema`)
**Purpose:** Verify that the `Seed Data` matches the expected structure and types before any database operations.
**Logic:**
1.  Iterate through each configuration group (General, Referrals, etc.).
2.  Check for required keys defined in `FirestoreConstants`.
3.  Validate data types (e.g., `double` for rates, `int` for counts).
4.  Report any missing keys or type mismatches.

### C. Automated Deployment Script (`deploySchema`)
**Purpose:** Apply the `Seed Data` to Firestore.
**Logic:**
1.  **Backup:** Read existing configuration (if any) into memory.
2.  **Deploy:** Write the `Seed Data` to Firestore using `SetOptions(merge: true)` to preserve existing fields not in the seed, or `SetOptions(merge: false)` for a hard reset (configurable).
3.  **Verification:** Read back the written data to ensure consistency.

### D. Error Handling
*   **Pre-flight Checks:** Validate permissions and connectivity.
*   **Atomic Operations:** Use `WriteBatch` where possible (though `app_config` is multiple documents, so sequential writes or multiple batches may be needed).
*   **Exception Catching:** Catch `FirebaseException` (permission-denied, unavailable) and abort immediately.

### E. Rollback Mechanism
**Trigger:** If any step of the deployment fails or verification fails.
**Logic:**
1.  The `deploySchema` function maintains a `backup` map of the pre-deployment state.
2.  On failure, it iterates through the `backup` and restores the original data to Firestore.
3.  If restoration fails, it outputs a critical alert with the JSON dump of the backup for manual restoration.

### F. Testing Procedures
1.  **Dry Run:** Run the deployment in "Dry Run" mode (logs operations without writing).
2.  **Staging Test:** Deploy to a `test` project (e.g., `eta-network-test`) first.
3.  **Verification:** Use the `validateSchema` script on the *live* database to confirm it matches the `Seed Data`.

## 3. Limitations & Constraints

### Firestore Constraints
*   **Document Size:** Max 1MB. Configuration documents are well within this limit.
*   **Collection Depth:** Subcollections can be nested up to 100 levels (not an issue here).
*   **Write Rate:** 1 write/sec per document (sustained). Deployment is a one-time or rare operation, so this is acceptable.

### Application Constraints
*   **Data Types:** Firestore supports specific types (String, Number, Boolean, Map, Array, Timestamp). Dart `int` and `double` both map to Firestore `number`. Special care must be taken to preserve precision (e.g., storing explicit `double` for currency/rates).
*   **Naming Conventions:** Keys in `firestore_constants.dart` must match exactly. Changing a constant value in code will break access to existing data unless a migration script is run.
*   **"Missing" Values:** If a constant is defined but not present in the database, the app code generally handles it with a default fallback (e.g., `?? 0.0`). The deployment script ensures these values exist in the DB to avoid fallback reliance.

## 4. Implementation Plan

We will implement a `SchemaDeploymentService` in `lib/services/` that encapsulates this logic, allowing it to be run from the Admin Dashboard or a test harness.

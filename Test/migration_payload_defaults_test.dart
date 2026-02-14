import 'package:flutter_test/flutter_test.dart';
import 'package:eta_network_admin/services/earnings_engine.dart';
import 'package:eta_network_admin/shared/firestore_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('Migration payload defaults', () {
    test('fills defaults when missing in realtime/live', () {
      final realtime = <String, dynamic>{
        // Leave out lastSyncedAt, rate components to force defaults
        FirestoreUserFields.totalPoints: 12.5,
        'hourlyRate1': 0.7, // legacy alias
      };
      final live = <String, dynamic>{
        // No fields present here
      };
      final payload = EarningsEngine.debugBuildMigrationPayload(realtime, live);
      // Validate required keys exist
      expect(payload.containsKey(FirestoreUserFields.totalPoints), isTrue);
      expect(payload.containsKey(FirestoreUserFields.hourlyRate), isTrue);
      expect(payload.containsKey(FirestoreUserFields.lastSyncedAt), isTrue);
      // Validate values
      expect(payload[FirestoreUserFields.totalPoints], 12.5);
      expect(payload[FirestoreUserFields.hourlyRate], 0.7);
      // lastSyncedAt should default to a Timestamp
      expect(payload[FirestoreUserFields.lastSyncedAt], isA<Timestamp>());
      // Rate components default to 0.0
      expect(payload[FirestoreUserFields.rateBase], 0.0);
      expect(payload[FirestoreUserFields.rateStreak], 0.0);
      expect(payload[FirestoreUserFields.rateRank], 0.0);
      expect(payload[FirestoreUserFields.rateReferral], 0.0);
      expect(payload[FirestoreUserFields.rateManager], 0.0);
      expect(payload[FirestoreUserFields.rateAds], 0.0);
      // Lists default to empty
      expect(payload[FirestoreUserFields.managedCoinSelections], isA<List>());
      expect(
        (payload[FirestoreUserFields.managedCoinSelections] as List).isEmpty,
        isTrue,
      );
    });
  });
}

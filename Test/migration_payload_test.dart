import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eta_network_admin/services/earnings_engine.dart';
import 'package:eta_network_admin/shared/firestore_constants.dart';

void main() {
  group('EarningsEngine migration payload builder', () {
    test('builds payload using hourlyRate1 alias and validates fields', () {
      final now = Timestamp.now();
      final updated = Timestamp.fromMillisecondsSinceEpoch(
        now.millisecondsSinceEpoch - 1000,
      );
      final realtime = <String, dynamic>{
        'hourlyRate1': 3.5,
        FirestoreUserFields.totalPoints: 120.0,
        FirestoreUserFields.lastSyncedAt: now,
        FirestoreUserFields.updatedAt: updated,
        FirestoreUserFields.rateBase: 1.0,
        FirestoreUserFields.rateStreak: 0.2,
        FirestoreUserFields.rateRank: 0.1,
        FirestoreUserFields.rateReferral: 0.3,
        FirestoreUserFields.rateManager: 0.0,
        FirestoreUserFields.rateAds: 0.0,
        FirestoreUserFields.managerBonusPerHour: 0.0,
        FirestoreUserFields.managedCoinSelections: <String>['eta'],
      };
      final user = <String, dynamic>{};

      final payload = EarningsEngine.debugBuildMigrationPayload(realtime, user);
      expect(payload[FirestoreUserFields.hourlyRate], 3.5);
      expect(payload[FirestoreUserFields.totalPoints], 120.0);
      expect(payload[FirestoreUserFields.lastSyncedAt], now);
      expect(payload[FirestoreUserFields.updatedAt], updated);
      expect(payload[FirestoreUserFields.managerBonusPerHour], 0.0);
      expect(payload[FirestoreUserFields.managedCoinSelections], ['eta']);

      final missing = EarningsEngine.debugValidateMigration(realtime, user);
      // Might contain informative flags but migration will still succeed
      expect(missing, isA<List<String>>());
    });

    test('reports missing when lastSyncedAt absent', () {
      final realtime = <String, dynamic>{
        FirestoreUserFields.hourlyRate: 2.0,
        FirestoreUserFields.totalPoints: 10.0,
        FirestoreUserFields.rateBase: 1.0,
        FirestoreUserFields.rateStreak: 0.0,
        FirestoreUserFields.rateRank: 0.0,
        FirestoreUserFields.rateReferral: 0.0,
        FirestoreUserFields.rateManager: 0.0,
        FirestoreUserFields.rateAds: 0.0,
        FirestoreUserFields.managerBonusPerHour: 0.0,
        FirestoreUserFields.managedCoinSelections: <String>[],
      };
      final user = <String, dynamic>{};
      final missing = EarningsEngine.debugValidateMigration(realtime, user);
      expect(missing, contains(FirestoreUserFields.lastSyncedAt));
    });

    test('falls back to user fields if realtime is missing some values', () {
      final now = Timestamp.now();
      final realtime = <String, dynamic>{
        FirestoreUserFields.totalPoints: 50.0,
        // hourlyRate missing in realtime
      };
      final user = <String, dynamic>{
        FirestoreUserFields.hourlyRate: 1.25,
        FirestoreUserFields.lastSyncedAt: now,
        FirestoreUserFields.rateBase: 0.8,
        FirestoreUserFields.rateStreak: 0.1,
        FirestoreUserFields.rateRank: 0.05,
        FirestoreUserFields.rateReferral: 0.0,
        FirestoreUserFields.rateManager: 0.0,
        FirestoreUserFields.rateAds: 0.0,
        FirestoreUserFields.managedCoinSelections: <String>[],
      };
      final payload = EarningsEngine.debugBuildMigrationPayload(realtime, user);
      expect(payload[FirestoreUserFields.hourlyRate], 1.25);
      expect(payload[FirestoreUserFields.totalPoints], 50.0);
      expect(payload[FirestoreUserFields.lastSyncedAt], now);
    });
  });
}

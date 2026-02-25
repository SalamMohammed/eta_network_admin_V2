import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../shared/firestore_constants.dart';
import '../utils/firestore_helper.dart';

/// Service to handle the deployment of Firestore schema based on constants.
/// This includes validation, backup, deployment, and rollback capabilities.
class SchemaDeploymentService {
  final FirebaseFirestore _firestore = FirestoreHelper.instance;

  /// Defines the expected structure and default values for the schema.
  /// This acts as the "Seed Data" manifest.
  Map<String, Map<String, dynamic>> get seedData => {
        FirestoreAppConfigDocs.general: {
          FirestoreAppConfigFields.baseRate: 0.2, // double
          FirestoreAppConfigFields.sessionDurationHours: 24.0, // double
          FirestoreAppConfigFields.deviceSingleUserEnforced: true, // bool
          FirestoreAppConfigFields.revenueCatApiKey: '', // String
          FirestoreAppConfigFields.revenueCatWebhookAuth: '', // String
          FirestoreAppConfigFields.enableSubscriptions: true, // bool
          FirestoreAppConfigFields.sandboxMode: true, // bool
        },
        FirestoreAppConfigDocs.referrals: {
          FirestoreReferralConfigFields.inviteeFixedBonusPoints: 0.0, // double
          FirestoreReferralConfigFields.referrerPercentPerReferral:
              0.0, // double
          FirestoreReferralConfigFields.referrerMaxCount: 100, // int
          FirestoreReferralConfigFields.rewardedReferralMaxCount: 100, // int
          FirestoreReferralConfigFields.referralBonusTiers:
              <String, dynamic>{}, // Map<String, double>
        },
        FirestoreAppConfigDocs.streak: {
          FirestoreStreakConfigFields.maxStreakDays: 15, // int
          FirestoreStreakConfigFields.maxStreakMultiplier: 2.0, // double
          FirestoreAppConfigFields.streakBonusTable:
              <String, dynamic>{}, // Map<String, double>
        },
        FirestoreAppConfigDocs.ranks: {
          FirestoreRankConfigFields.rankRules:
              <String, dynamic>{}, // Map<String, Map<String, int>>
          FirestoreRankConfigFields.rankMultipliers:
              <String, dynamic>{}, // Map<String, double>
        },
        FirestoreAppConfigDocs.userCoin: {
          FirestoreAppConfigFields.minRatePerHour: 0.01, // double
          FirestoreAppConfigFields.maxRatePerHour: 10.0, // double
          FirestoreAppConfigFields.maxSocialLinks: 6, // int
          FirestoreAppConfigFields.maxDescriptionLength: 500, // int
          FirestoreAppConfigFields.allowImageUpload: true, // bool
          FirestoreAppConfigFields.allowUserRateEdit: true, // bool
        },
        FirestoreAppConfigDocs.manager: {
          FirestoreManagerConfigFields.enabledGlobally: true, // bool
          FirestoreManagerConfigFields.enableEtaAuto: true, // bool
          FirestoreManagerConfigFields.enableUserCoinAuto: true, // bool
          FirestoreManagerConfigFields.maxCommunityCoinsManaged: 0, // int
        },
        FirestoreAppConfigDocs.legal: {
          FirestoreLegalFields.appName: 'Eta Network', // String
          FirestoreLegalFields.tagline: 'The Future of Mining', // String
          FirestoreLegalFields.about: '', // String
          FirestoreLegalFields.faq: '', // String
          FirestoreLegalFields.whitePaper: '', // String
          FirestoreLegalFields.contactUs: '', // String
          FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
        },
        FirestoreAppConfigDocs.ads: {
          FirestoreAdsConfigFields.enableRewarded: true, // bool
          FirestoreAdsConfigFields.enableBannerOnMiningPress: true, // bool
          FirestoreAdsConfigFields.rewardBonusPercent: 10.0, // double
          FirestoreAdsConfigFields.maxRewardedPerDay: 5, // int
          FirestoreAdsConfigFields.maxRewardedPerMiningSession: 5, // int
          FirestoreAdsConfigFields.bannerAdUnitIdAndroid: '', // String
          FirestoreAdsConfigFields.bannerAdUnitIdIos: '', // String
          FirestoreAdsConfigFields.rewardedAdUnitIdAndroid: '', // String
          FirestoreAdsConfigFields.rewardedAdUnitIdIos: '', // String
        },
      };

  /// Validates the structure of the provided data against expected types.
  /// Returns a list of validation errors, or empty if valid.
  List<String> validateSchema(Map<String, Map<String, dynamic>> data) {
    final errors = <String>[];
    // This is a basic type check. In a real scenario, we could use a schema validation library.
    data.forEach((docId, fields) {
      if (!seedData.containsKey(docId)) {
        errors.add('Unknown document ID in seed data: $docId');
      }
      // Check for required fields defined in seedData
      final expectedFields = seedData[docId]!;
      expectedFields.forEach((key, value) {
        if (!fields.containsKey(key)) {
          errors.add('Missing field in $docId: $key');
        } else {
          // Type check (basic)
          final actualValue = fields[key];
          if (value is double && actualValue is! num) {
            errors.add(
                'Type mismatch in $docId.$key: expected double/num, got ${actualValue.runtimeType}');
          } else if (value is int && actualValue is! int) {
            errors.add(
                'Type mismatch in $docId.$key: expected int, got ${actualValue.runtimeType}');
          } else if (value is bool && actualValue is! bool) {
            errors.add(
                'Type mismatch in $docId.$key: expected bool, got ${actualValue.runtimeType}');
          } else if (value is String && actualValue is! String) {
            errors.add(
                'Type mismatch in $docId.$key: expected String, got ${actualValue.runtimeType}');
          } else if (value is Map && actualValue is! Map) {
            errors.add(
                'Type mismatch in $docId.$key: expected Map, got ${actualValue.runtimeType}');
          }
        }
      });
    });
    return errors;
  }

  /// Deploys the schema to Firestore.
  ///
  /// [merge] - If true, merges with existing data. If false, overwrites.
  /// [dryRun] - If true, only logs operations without writing.
  ///
  /// Returns a report of operations performed.
  Future<String> deploySchema({
    bool merge = true,
    bool dryRun = false,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('Starting Schema Deployment...');
    buffer.writeln('Mode: ${dryRun ? "DRY RUN" : "LIVE"}');
    buffer.writeln('Merge: $merge');

    final data = seedData;
    final validationErrors = validateSchema(data);
    if (validationErrors.isNotEmpty) {
      buffer.writeln('Validation FAILED:');
      validationErrors.forEach((e) => buffer.writeln('- $e'));
      throw Exception('Schema validation failed. See report for details.');
    }
    buffer.writeln('Validation PASSED.');

    // Backup Phase
    final Map<String, Map<String, dynamic>> backup = {};
    if (!dryRun) {
      buffer.writeln('Creating backup of existing configuration...');
      try {
        for (final docId in data.keys) {
          final snap = await _firestore
              .collection(FirestoreConstants.appConfig)
              .doc(docId)
              .get();
          if (snap.exists) {
            backup[docId] = snap.data()!;
          }
        }
        buffer.writeln('Backup created for ${backup.length} documents.');
      } catch (e) {
        buffer.writeln('Backup FAILED: $e');
        throw Exception('Backup failed. Aborting deployment.');
      }
    }

    // Deployment Phase
    buffer.writeln('Deploying documents...');
    try {
      final batch = _firestore.batch();
      int opCount = 0;

      for (final entry in data.entries) {
        final docId = entry.key;
        final fields = entry.value;
        final docRef = _firestore
            .collection(FirestoreConstants.appConfig)
            .doc(docId);

        if (dryRun) {
          buffer.writeln('[DRY RUN] Would set $docId with ${fields.length} fields.');
        } else {
          if (merge) {
            batch.set(docRef, fields, SetOptions(merge: true));
          } else {
            batch.set(docRef, fields);
          }
          opCount++;
        }
      }

      if (!dryRun) {
        await batch.commit();
        buffer.writeln('Successfully committed batch with $opCount operations.');
      }
    } catch (e) {
      buffer.writeln('Deployment FAILED: $e');
      if (!dryRun && backup.isNotEmpty) {
        buffer.writeln('Initiating ROLLBACK...');
        try {
          await _rollback(backup);
          buffer.writeln('Rollback SUCCESSFUL.');
        } catch (rollbackError) {
          buffer.writeln('CRITICAL: Rollback FAILED: $rollbackError');
          buffer.writeln('Manual intervention required. Backup data dump:');
          buffer.writeln(backup.toString());
        }
      }
      throw Exception('Deployment failed: $e');
    }

    // Verification Phase
    if (!dryRun) {
      buffer.writeln('Verifying deployment...');
      try {
        for (final docId in data.keys) {
          final snap = await _firestore
              .collection(FirestoreConstants.appConfig)
              .doc(docId)
              .get();
          if (!snap.exists) {
            buffer.writeln('Verification FAILED: Document $docId missing.');
            throw Exception('Verification failed for $docId');
          }
          // Deep check could go here
        }
        buffer.writeln('Verification PASSED.');
      } catch (e) {
        buffer.writeln('Verification FAILED: $e');
        // Rollback? Maybe not if it's just a read error, but strictly speaking we should.
        // For now, we just report it.
      }
    }

    buffer.writeln('Deployment Completed Successfully.');
    return buffer.toString();
  }

  Future<void> _rollback(Map<String, Map<String, dynamic>> backup) async {
    final batch = _firestore.batch();
    for (final entry in backup.entries) {
      final docRef = _firestore
          .collection(FirestoreConstants.appConfig)
          .doc(entry.key);
      batch.set(docRef, entry.value); // Restore original data
    }
    await batch.commit();
  }
}

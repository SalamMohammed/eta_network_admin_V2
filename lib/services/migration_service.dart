import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../shared/firestore_constants.dart';
import '../utils/firestore_helper.dart';

class MigrationService {
  // Absolute paths provided by the user (Used as default on Windows/Desktop)
  static const String _userCoinsPath =
      r'd:\EtaNetwork\eta_network_admin\lib\mobile\External Folder\Migration\user_coins.json';
  static const String _miningRecordsPath =
      r'd:\EtaNetwork\eta_network_admin\lib\mobile\External Folder\Migration\mining_records.json';

  /// Main entry point to run the migration
  static Future<void> runMigration() async {
    debugPrint('[MigrationService] Starting migration...');
    try {
      List<dynamic> userCoinsRows = [];
      List<dynamic> miningRecordsRows = [];

      if (kIsWeb) {
        debugPrint(
          '[MigrationService] Running on Web. Prompting for BOTH files...',
        );
        // On Web, prompt for both files at once to avoid "user activation" issues
        // with sequential pickers after async operations.
        final result = await FilePicker.platform.pickFiles(
          dialogTitle: 'Select BOTH user_coins.json AND mining_records.json',
          type: FileType.custom,
          allowedExtensions: ['json'],
          allowMultiple: true,
          withData: true,
        );

        if (result != null && result.files.isNotEmpty) {
          debugPrint(
            '[MigrationService] Selected ${result.files.length} files.',
          );
          for (final file in result.files) {
            final bytes = file.bytes;
            if (bytes == null) {
              debugPrint(
                '[MigrationService] File ${file.name} has no bytes. Skipping.',
              );
              continue;
            }
            final content = utf8.decode(bytes);
            debugPrint(
              '[MigrationService] Parsing file: ${file.name} (${bytes.length} bytes)',
            );

            // Try to identify and extract data from this file
            if (userCoinsRows.isEmpty) {
              debugPrint(
                '[MigrationService] Checking if ${file.name} is user_coins...',
              );
              final data = _extractTableData(content, 'user_coins');
              if (data.isNotEmpty) {
                userCoinsRows = data;
                debugPrint(
                  '[MigrationService] MATCH: Identified ${file.name} as user_coins (${data.length} rows)',
                );
                continue; // Found match, move to next file
              } else {
                debugPrint(
                  '[MigrationService] ${file.name} is NOT user_coins.',
                );
              }
            }

            if (miningRecordsRows.isEmpty) {
              debugPrint(
                '[MigrationService] Checking if ${file.name} is mining_records...',
              );
              final data = _extractTableData(content, 'mining_records');
              if (data.isNotEmpty) {
                miningRecordsRows = data;
                debugPrint(
                  '[MigrationService] MATCH: Identified ${file.name} as mining_records (${data.length} rows)',
                );
                continue;
              } else {
                debugPrint(
                  '[MigrationService] ${file.name} is NOT mining_records.',
                );
              }
            }
          }
        } else {
          debugPrint('[MigrationService] No files selected.');
          return;
        }
      } else {
        // Desktop / Mobile: Load sequentially (hardcoded paths or single pickers)
        userCoinsRows = await _loadData(_userCoinsPath, 'user_coins');
        if (userCoinsRows.isEmpty) {
          debugPrint('[MigrationService] No user_coins data loaded. Aborting.');
          return;
        }

        miningRecordsRows = await _loadData(
          _miningRecordsPath,
          'mining_records',
        );
        if (miningRecordsRows.isEmpty) {
          debugPrint(
            '[MigrationService] No mining_records data loaded. Aborting.',
          );
          return;
        }
      }

      // Final check
      if (userCoinsRows.isEmpty) {
        debugPrint(
          '[MigrationService] Failed to load user_coins. Please ensure you selected the correct file.',
        );
        return;
      }
      if (miningRecordsRows.isEmpty) {
        debugPrint(
          '[MigrationService] Failed to load mining_records. Please ensure you selected the correct file.',
        );
        return;
      }

      // 1. Migrate User Coins
      final coinCache = await _migrateUserCoins(userCoinsRows);

      // 2. Migrate Mining Records
      debugPrint('[MigrationService] Coin Cache Size: ${coinCache.length}');
      await _migrateMiningRecords(miningRecordsRows, coinCache);

      debugPrint('[MigrationService] Migration completed successfully!');
    } catch (e, stack) {
      debugPrint('[MigrationService] Error during migration: $e\n$stack');
    }
  }

  /// Helper to load data from File (Desktop) or FilePicker (Fallback)
  static Future<List<dynamic>> _loadData(String path, String tableName) async {
    String? jsonContent;
    final file = File(path);
    bool exists = false;
    try {
      exists = await file.exists();
    } catch (e) {
      // Ignored
    }

    if (exists) {
      debugPrint('[MigrationService] Loading $tableName from $path...');
      jsonContent = await file.readAsString();
    } else {
      debugPrint(
        '[MigrationService] File not found at $path. Prompting user...',
      );
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select $tableName.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedPath = result.files.first.path;
        if (pickedPath != null) {
          jsonContent = await File(pickedPath).readAsString();
        }
      }
    }

    if (jsonContent == null) return [];
    return _extractTableData(jsonContent, tableName);
  }

  /// Parses JSON content and attempts to extract data for the given [tableName].
  static List<dynamic> _extractTableData(String jsonContent, String tableName) {
    try {
      final dynamic decoded = jsonDecode(jsonContent);

      if (decoded is! List) {
        debugPrint(
          '[MigrationService] JSON is not a list. It is ${decoded.runtimeType}.',
        );
        return [];
      }

      final json = decoded as List;

      // Strategy 1: Look for PHPMyAdmin export format (wrapper objects)
      final foundTables = <String>[];
      for (final item in json) {
        if (item is Map) {
          if (item.containsKey('type') && item.containsKey('name')) {
            final type = item['type'];
            final name = item['name'];
            if (type == 'table') {
              foundTables.add(name.toString());
            }
          }

          if (item['type'] == 'table' && item['name'] == tableName) {
            return item['data'] as List;
          }
        }
      }

      // Strategy 2: Check if the list itself is the data (Direct Export)
      if (json.isNotEmpty && json.first is Map) {
        final firstRow = json.first as Map;
        bool isMatch = false;

        if (tableName == 'user_coins') {
          // Check for characteristic fields of user_coins
          // "ownerId" is unique to user_coins
          if (firstRow.containsKey('ownerId')) {
            isMatch = true;
          }
        } else if (tableName == 'mining_records') {
          // Check for characteristic fields of mining_records
          // "uid" and "coinOwnerId" are characteristic
          if (firstRow.containsKey('uid') &&
              firstRow.containsKey('coinOwnerId')) {
            isMatch = true;
          }
        }

        if (isMatch) {
          return json;
        }
      }

      // If we are here, no match found
      if (foundTables.isNotEmpty) {
        debugPrint(
          '[MigrationService] Found tables in JSON: $foundTables. Expected: "$tableName".',
        );
      } else {
        debugPrint(
          '[MigrationService] No tables found in JSON for "$tableName".',
        );
      }
    } catch (e) {
      debugPrint('[MigrationService] Error parsing JSON for $tableName: $e');
    }

    return [];
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    final s = value.toString().toLowerCase();
    return s == '1' || s == 'true' || s == 'yes';
  }

  static Future<Map<String, Map<String, dynamic>>> _migrateUserCoins(
    List<dynamic> rows,
  ) async {
    debugPrint('[MigrationService] Migrating ${rows.length} user_coins...');

    final Map<String, Map<String, dynamic>> coinCache = {};

    await _batchWrite(rows, (batch, row) {
      final r = row as Map<String, dynamic>;
      final ownerId = r['ownerId'] as String;

      // Store in cache for mining records migration
      coinCache[ownerId] = r;

      final docRef = FirestoreHelper.instance
          .collection(FirestoreConstants.userCoins)
          .doc(ownerId);

      final data = {
        FirestoreUserCoinFields.ownerId: ownerId,
        FirestoreUserCoinFields.name: r['name'],
        FirestoreUserCoinFields.symbol: r['symbol'],
        FirestoreUserCoinFields.imageUrl: r['imageUrl'],
        FirestoreUserCoinFields.description: r['description'],
        FirestoreUserCoinFields.baseRatePerHour:
            double.tryParse(r['baseRatePerHour'].toString()) ?? 0.0,
        FirestoreUserCoinFields.isActive: _parseBool(r['isActive']),
        FirestoreUserCoinFields.minersCount:
            int.tryParse(r['minersCount'].toString()) ?? 0,
        FirestoreUserCoinFields.createdAt: _parseDate(r['createdAt']),
        FirestoreUserCoinFields.updatedAt: _parseDate(r['updatedAt']),
        FirestoreUserCoinFields.socialLinks: _parseSocialLinks(
          r['socialLinks'],
        ),
      };
      batch.set(docRef, data);
    });

    return coinCache;
  }

  static Future<void> _migrateMiningRecords(
    List<dynamic> rows,
    Map<String, Map<String, dynamic>> coinCache,
  ) async {
    debugPrint('[MigrationService] Migrating ${rows.length} mining records...');

    int processed = 0;
    await _batchWrite(rows, (batch, row) {
      final r = row as Map<String, dynamic>;
      final uid = r['uid'] as String?;
      final coinOwnerId = r['coinOwnerId'] as String?;

      if (uid == null || coinOwnerId == null) {
        debugPrint('[MigrationService] Skipping invalid mining record: $r');
        return;
      }

      final docRef = FirestoreHelper.instance
          .collection(FirestoreConstants.users)
          .doc(uid)
          .collection(FirestoreUserSubCollections.coins)
          .doc(coinOwnerId);

      // Get coin details from cache
      final coinDetails = coinCache[coinOwnerId] ?? {};
      if (coinDetails.isEmpty) {
        debugPrint(
          '[MigrationService] Warning: Coin details not found for $coinOwnerId in cache.',
        );
      }

      final data = {
        FirestoreUserCoinMiningFields.ownerId: coinOwnerId,

        // Enriched fields from user_coins
        FirestoreUserCoinMiningFields.name: coinDetails['name'] ?? '',
        FirestoreUserCoinMiningFields.symbol: coinDetails['symbol'] ?? '',
        FirestoreUserCoinMiningFields.imageUrl: coinDetails['imageUrl'] ?? '',
        FirestoreUserCoinMiningFields.description:
            coinDetails['description'] ?? '',
        FirestoreUserCoinMiningFields.socialLinks: _parseSocialLinks(
          coinDetails['socialLinks'],
        ),

        // Mining stats
        FirestoreUserCoinMiningFields.totalPoints:
            double.tryParse(r['totalPoints'].toString()) ?? 0.0,
        FirestoreUserCoinMiningFields.hourlyRate:
            double.tryParse(r['hourlyRate'].toString()) ?? 0.0,
        FirestoreUserCoinMiningFields.lastMiningStart: _parseDate(
          r['lastMiningStart'],
        ),
        FirestoreUserCoinMiningFields.lastMiningEnd: _parseDate(
          r['lastMiningEnd'],
        ),
        FirestoreUserCoinMiningFields.lastSyncedAt: _parseDate(
          r['lastSyncedAt'],
        ),

        // Use createdAt/updatedAt from the mining record itself
        'createdAt': _parseDate(r['createdAt']),
        'updatedAt': _parseDate(r['updatedAt']),
      };

      batch.set(docRef, data, SetOptions(merge: true));
      processed++;
    });
    debugPrint(
      '[MigrationService] Scheduled $processed mining records for write.',
    );
  }

  // Helper to handle batch chunking
  static Future<void> _batchWrite(
    List<dynamic> items,
    Function(WriteBatch batch, dynamic item) action,
  ) async {
    const int batchSize = 400;
    for (var i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize < items.length) ? i + batchSize : items.length;
      final chunk = items.sublist(i, end);
      final batch = FirestoreHelper.instance.batch();

      for (final item in chunk) {
        action(batch, item);
      }

      await batch.commit();
      debugPrint('[MigrationService] Committed batch ${i ~/ batchSize + 1}');
    }
  }

  /// Phase 1: Consolidate App Configuration into a Master Document
  static Future<void> consolidateMasterConfig() async {
    debugPrint('[MigrationService] Starting Master Config consolidation...');
    try {
      final List<String> configDocs = [
        FirestoreAppConfigDocs.general,
        FirestoreAppConfigDocs.referrals,
        FirestoreAppConfigDocs.streak,
        FirestoreAppConfigDocs.ranks,
        FirestoreAppConfigDocs.userCoin,
        FirestoreAppConfigDocs.manager,
        FirestoreAppConfigDocs.legal,
        FirestoreAppConfigDocs.ads,
      ];
      final Map<String, dynamic> masterData = {};
      for (final docId in configDocs) {
        final doc = await FirestoreHelper.instance
            .collection(FirestoreConstants.appConfig)
            .doc(docId)
            .get();
        if (doc.exists) {
          masterData[docId] = doc.data();
          debugPrint('[MigrationService] Added $docId to Master Config');
        }
      }
      if (masterData.isNotEmpty) {
        await FirestoreHelper.instance
            .collection(FirestoreConstants.appConfig)
            .doc(FirestoreAppConfigDocs.master)
            .set(masterData);
        debugPrint('[MigrationService] Successfully deployed Master Config!');
      } else {
        debugPrint(
          '[MigrationService] No config documents found to consolidate.',
        );
      }
    } catch (e) {
      debugPrint('[MigrationService] Error consolidating Master Config: $e');
    }
  }

  static Future<void> consolidateUser(String uid) async {
    debugPrint('[MigrationService] Consolidating user: $uid');
    try {
      final userDoc = await FirestoreHelper.instance
          .collection(FirestoreConstants.users)
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        debugPrint('[MigrationService] User $uid not found');
        return;
      }

      final data = userDoc.data() ?? {};

      // Helper to extract value from legacy root or already consolidated nested maps
      dynamic getValue(String field, String category) {
        // 1. Check root (Legacy)
        if (data.containsKey(field) && data[field] != null) {
          return data[field];
        }
        // 2. Check category map (Already consolidated)
        if (data.containsKey(category) && data[category] is Map) {
          final catMap = data[category] as Map<String, dynamic>;
          if (catMap.containsKey(field)) {
            return catMap[field];
          }
        }
        return null;
      }

      final Map<String, dynamic> consolidated = {};

      // 1. Meta (Auth & Profile)
      consolidated[FirestoreUserFields.meta] = {
        FirestoreUserFields.uid: getValue(
          FirestoreUserFields.uid,
          FirestoreUserFields.meta,
        ),
        FirestoreUserFields.email: getValue(
          FirestoreUserFields.email,
          FirestoreUserFields.meta,
        ),
        FirestoreUserFields.username: getValue(
          FirestoreUserFields.username,
          FirestoreUserFields.meta,
        ),
        FirestoreUserFields.name: getValue(
          FirestoreUserFields.name,
          FirestoreUserFields.meta,
        ),
        FirestoreUserFields.thumbnailUrl: getValue(
          FirestoreUserFields.thumbnailUrl,
          FirestoreUserFields.meta,
        ),
        FirestoreUserFields.fcmToken: getValue(
          FirestoreUserFields.fcmToken,
          FirestoreUserFields.meta,
        ),
        FirestoreUserFields.country: getValue(
          FirestoreUserFields.country,
          FirestoreUserFields.meta,
        ),
        FirestoreUserFields.address: getValue(
          FirestoreUserFields.address,
          FirestoreUserFields.meta,
        ),
        FirestoreUserFields.gender: getValue(
          FirestoreUserFields.gender,
          FirestoreUserFields.meta,
        ),
        FirestoreUserFields.age: getValue(
          FirestoreUserFields.age,
          FirestoreUserFields.meta,
        ),
        FirestoreUserFields.deviceId: getValue(
          FirestoreUserFields.deviceId,
          FirestoreUserFields.meta,
        ),
        FirestoreUserFields.createdAt: getValue(
          FirestoreUserFields.createdAt,
          FirestoreUserFields.meta,
        ),
        FirestoreUserFields.updatedAt: getValue(
          FirestoreUserFields.updatedAt,
          FirestoreUserFields.meta,
        ),
      };

      // 2. Stats (Gamification)
      consolidated[FirestoreUserFields.stats] = {
        FirestoreUserFields.rank: getValue(
          FirestoreUserFields.rank,
          FirestoreUserFields.stats,
        ),
        FirestoreUserFields.role: getValue(
          FirestoreUserFields.role,
          FirestoreUserFields.stats,
        ),
        FirestoreUserFields.totalPoints: getValue(
          FirestoreUserFields.totalPoints,
          FirestoreUserFields.stats,
        ),
        FirestoreUserFields.totalSessions: getValue(
          FirestoreUserFields.totalSessions,
          FirestoreUserFields.stats,
        ),
        FirestoreUserFields.streakDays: getValue(
          FirestoreUserFields.streakDays,
          FirestoreUserFields.stats,
        ),
        FirestoreUserFields.streakLastUpdatedDay: getValue(
          FirestoreUserFields.streakLastUpdatedDay,
          FirestoreUserFields.stats,
        ),
        FirestoreUserFields.referralCode: getValue(
          FirestoreUserFields.referralCode,
          FirestoreUserFields.stats,
        ),
        FirestoreUserFields.invitedBy: getValue(
          FirestoreUserFields.invitedBy,
          FirestoreUserFields.stats,
        ),
        FirestoreUserFields.referralLocked: getValue(
          FirestoreUserFields.referralLocked,
          FirestoreUserFields.stats,
        ),
      };

      // 3. Mining State
      consolidated[FirestoreUserFields.mining] = {
        FirestoreUserFields.lastMiningStart: getValue(
          FirestoreUserFields.lastMiningStart,
          FirestoreUserFields.mining,
        ),
        FirestoreUserFields.lastMiningEnd: getValue(
          FirestoreUserFields.lastMiningEnd,
          FirestoreUserFields.mining,
        ),
        FirestoreUserFields.lastSyncedAt: getValue(
          FirestoreUserFields.lastSyncedAt,
          FirestoreUserFields.mining,
        ),
        FirestoreUserFields.hourlyRate: getValue(
          FirestoreUserFields.hourlyRate,
          FirestoreUserFields.mining,
        ),
        // Rates Breakdown
        FirestoreUserFields.rateBase: getValue(
          FirestoreUserFields.rateBase,
          FirestoreUserFields.mining,
        ),
        FirestoreUserFields.rateStreak: getValue(
          FirestoreUserFields.rateStreak,
          FirestoreUserFields.mining,
        ),
        FirestoreUserFields.rateRank: getValue(
          FirestoreUserFields.rateRank,
          FirestoreUserFields.mining,
        ),
        FirestoreUserFields.rateReferral: getValue(
          FirestoreUserFields.rateReferral,
          FirestoreUserFields.mining,
        ),
        FirestoreUserFields.rateManager: getValue(
          FirestoreUserFields.rateManager,
          FirestoreUserFields.mining,
        ),
        FirestoreUserFields.rateAds: getValue(
          FirestoreUserFields.rateAds,
          FirestoreUserFields.mining,
        ),
      };

      // 4. Manager Configuration
      consolidated[FirestoreUserFields.manager] = {
        FirestoreUserFields.managerEnabled: getValue(
          FirestoreUserFields.managerEnabled,
          FirestoreUserFields.manager,
        ),
        FirestoreUserFields.activeManagerId: getValue(
          FirestoreUserFields.activeManagerId,
          FirestoreUserFields.manager,
        ),
        FirestoreUserFields.managedCoinSelections: getValue(
          FirestoreUserFields.managedCoinSelections,
          FirestoreUserFields.manager,
        ),
        FirestoreUserFields.managerBonusPerHour: getValue(
          FirestoreUserFields.managerBonusPerHour,
          FirestoreUserFields.manager,
        ),
      };

      // 5. Wallet/Subscription
      consolidated[FirestoreUserFields.wallet] = {
        FirestoreUserFields.subscription: getValue(
          FirestoreUserFields.subscription,
          FirestoreUserFields.wallet,
        ),
      };

      // 6. Referrals (Phase 3)
      final referralsQs = await FirestoreHelper.instance
          .collection(FirestoreConstants.referrals)
          .where(FirestoreReferralFields.inviterId, isEqualTo: uid)
          .orderBy(FirestoreReferralFields.timestamp, descending: true)
          .limit(10)
          .get();

      final List<Map<String, dynamic>> recentReferrals = [];
      for (final doc in referralsQs.docs) {
        final rData = doc.data();
        recentReferrals.add({
          'uid': rData[FirestoreReferralFields.inviteeId],
          'username':
              rData[FirestoreReferralFields.inviteeUsername] ?? 'Anonymous',
          'timestamp': _parseDate(
            rData[FirestoreReferralFields.timestamp],
          )?.toDate().toIso8601String(),
          'isActive': _parseBool(rData[FirestoreReferralFields.isActive]),
        });
      }

      // Accurate counts using count() queries
      final totalReferralsQs = await FirestoreHelper.instance
          .collection(FirestoreConstants.referrals)
          .where(FirestoreReferralFields.inviterId, isEqualTo: uid)
          .count()
          .get();

      final activeReferralsQs = await FirestoreHelper.instance
          .collection(FirestoreConstants.referrals)
          .where(FirestoreReferralFields.inviterId, isEqualTo: uid)
          .where(FirestoreReferralFields.isActive, isEqualTo: true)
          .count()
          .get();

      consolidated[FirestoreUserFields.referrals] = {
        FirestoreUserFields.totalReferrals: totalReferralsQs.count,
        FirestoreUserFields.activeReferrals: activeReferralsQs.count,
        FirestoreUserFields.recentReferrals: recentReferrals,
      };

      // Perform Update
      await FirestoreHelper.instance
          .collection(FirestoreConstants.users)
          .doc(uid)
          .update(consolidated);

      debugPrint('[MigrationService] Successfully consolidated user $uid');
    } catch (e) {
      debugPrint('[MigrationService] Error consolidating user $uid: $e');
    }
  }

  static Future<void> migrateAllUsers({int limit = 100}) async {
    debugPrint(
      '[MigrationService] Starting batch user consolidation (limit: $limit)...',
    );
    try {
      final qs = await FirestoreHelper.instance
          .collection(FirestoreConstants.users)
          .limit(limit)
          .get();

      int count = 0;
      for (final doc in qs.docs) {
        await consolidateUser(doc.id);
        count++;
      }
      debugPrint(
        '[MigrationService] Batch consolidation complete. Processed $count users.',
      );
    } catch (e) {
      debugPrint('[MigrationService] Error in batch user consolidation: $e');
    }
  }

  static Future<void> consolidateGlobalStats() async {
    debugPrint('[MigrationService] Consolidating global stats using optimized aggregate queries...');
    try {
      // 1. Total Users (Phase 3 Standard: Aggregate Query)
      final usersCountQs = await FirestoreHelper.instance
          .collection(FirestoreConstants.users)
          .count()
          .get();
      final int totalUsers = usersCountQs.count ?? 0;

      // 2. Total Points (Phase 3 Standard: Aggregate Sum)
      // We sum both legacy root points and consolidated stats points
      final pointsAggregate = await FirestoreHelper.instance
          .collection(FirestoreConstants.users)
          .aggregate(
            sum(FirestoreUserFields.totalPoints),
            sum('${FirestoreUserFields.stats}.${FirestoreUserFields.totalPoints}'),
          )
          .get();

      final double totalPoints =
          (pointsAggregate.getSum(FirestoreUserFields.totalPoints) ?? 0)
                  .toDouble() +
              (pointsAggregate.getSum(
                        '${FirestoreUserFields.stats}.${FirestoreUserFields.totalPoints}',
                      ) ??
                      0)
                  .toDouble();

      // 3. Active Miners (Phase 3 Standard: Aggregate Count with Filters)
      final now = DateTime.now();
      
      // Count legacy active miners
      final legacyActiveQs = await FirestoreHelper.instance
          .collection(FirestoreConstants.users)
          .where(FirestoreUserFields.lastMiningEnd, isGreaterThan: now)
          .count()
          .get();

      // Count consolidated active miners
      final consolidatedActiveQs = await FirestoreHelper.instance
          .collection(FirestoreConstants.users)
          .where(
            '${FirestoreUserFields.mining}.${FirestoreUserFields.lastMiningEnd}',
            isGreaterThan: now,
          )
          .count()
          .get();

      final int activeMiners =
          (legacyActiveQs.count ?? 0) + (consolidatedActiveQs.count ?? 0);

      // 4. Update Global Stats Doc
      await FirestoreHelper.instance
          .collection(FirestoreConstants.appStats)
          .doc(FirestoreAppStatsDocs.global)
          .set({
        'totalUsers': totalUsers,
        'totalPoints': totalPoints,
        'activeMiners': activeMiners,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint(
        '[MigrationService] Global stats updated: $totalUsers users, $totalPoints points, $activeMiners active miners',
      );
    } catch (e) {
      debugPrint('[MigrationService] Error consolidating global stats: $e');
    }
  }

  static Timestamp? _parseDate(dynamic value) {
    if (value == null ||
        value.toString().isEmpty ||
        value.toString() == 'null') {
      return null;
    }

    if (value is Timestamp) return value;
    if (value is DateTime) return Timestamp.fromDate(value);

    try {
      // Format: "2026-02-10 17:30:12" -> ISO "2026-02-10T17:30:12"
      final String str = value.toString().replaceAll(' ', 'T');
      return Timestamp.fromDate(DateTime.parse(str));
    } catch (e) {
      debugPrint('[MigrationService] Date parse error for $value: $e');
      return null;
    }
  }

  static List<dynamic> _parseSocialLinks(dynamic value) {
    if (value == null || value.toString().isEmpty || value.toString() == '[]') {
      return [];
    }
    try {
      if (value is String) {
        return jsonDecode(value);
      }
      return value as List;
    } catch (e) {
      debugPrint('[MigrationService] Social links parse error: $e');
      return [];
    }
  }
}

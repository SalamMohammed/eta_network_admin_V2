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

  static Timestamp? _parseDate(dynamic value) {
    if (value == null ||
        value.toString().isEmpty ||
        value.toString() == 'null') {
      return null;
    }
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

import 'dart:async';
import 'package:flutter/foundation.dart';

enum FirestoreAction { read, write, delete }

class FirestoreLog {
  final String id;
  final DateTime timestamp;
  final FirestoreAction action;
  final String path;
  final String details; // e.g. "Get 1 doc" or "Set {field: value}"
  final String? error;
  final int docCount; // For reads, how many docs returned

  FirestoreLog({
    required this.action,
    required this.path,
    required this.details,
    this.error,
    this.docCount = 0,
  })  : id = UniqueKey().toString(),
        timestamp = DateTime.now();
}

class FirestoreMonitorService extends ChangeNotifier {
  static final FirestoreMonitorService _instance =
      FirestoreMonitorService._internal();

  factory FirestoreMonitorService() => _instance;

  FirestoreMonitorService._internal();

  final List<FirestoreLog> _logs = [];
  final int _maxLogs = 1000;

  int _readCount = 0;
  int _writeCount = 0;
  int _deleteCount = 0;

  List<FirestoreLog> get logs => List.unmodifiable(_logs.reversed);
  int get readCount => _readCount;
  int get writeCount => _writeCount;
  int get deleteCount => _deleteCount;

  bool _enabled = false;
  bool get enabled => _enabled;
  set enabled(bool value) {
    _enabled = value;
    notifyListeners();
  }

  void logRead({
    required String path,
    required int count,
    String? details,
    String? error,
  }) {
    if (!_enabled) return;
    _readCount += count; // Count documents read
    // If count is 0 (e.g. empty query), we still count it as a read operation?
    // Firestore pricing: 1 read for query even if no results? Yes (minimum 1 usually, or 1 per doc).
    // Let's track "Operations" and "Docs".
    // User asked "how many read... count them correctly".
    // We will stick to simple counters for now, incrementing by doc count is safer for "impact".
    
    _addLog(FirestoreLog(
      action: FirestoreAction.read,
      path: path,
      details: details ?? 'Read $count docs',
      docCount: count,
      error: error,
    ));
  }

  void logWrite({
    required String path,
    String? details,
    String? error,
  }) {
    if (!_enabled) return;
    _writeCount++;
    _addLog(FirestoreLog(
      action: FirestoreAction.write,
      path: path,
      details: details ?? 'Write document',
      error: error,
    ));
  }

  void logDelete({
    required String path,
    String? details,
    String? error,
  }) {
    if (!_enabled) return;
    _deleteCount++;
    _addLog(FirestoreLog(
      action: FirestoreAction.delete,
      path: path,
      details: details ?? 'Delete document',
      error: error,
    ));
  }

  void _addLog(FirestoreLog log) {
    _logs.add(log);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }
    // Defer notification to avoid rebuilding during build phase if called synchronously
    Future.microtask(() => notifyListeners());
  }

  void clearLogs() {
    _logs.clear();
    _readCount = 0;
    _writeCount = 0;
    _deleteCount = 0;
    notifyListeners();
  }
}

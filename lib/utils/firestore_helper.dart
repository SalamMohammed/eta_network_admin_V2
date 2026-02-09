import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:eta_network_admin/services/firestore_monitor_service.dart';

/// A wrapper helper to replace FirebaseFirestore.instance usage.
///
/// Usage:
/// Replace `FirebaseFirestore.instance` with `FirestoreHelper.instance`.
class FirestoreHelper {
  static final FirebaseFirestore _realInstance = FirebaseFirestore.instance;
  static final MonitoredFirestore _monitoredInstance = MonitoredFirestore(
    _realInstance,
  );

  static MonitoredFirestore get instance => _monitoredInstance;
}

class MonitoredFirestore implements FirebaseFirestore {
  final FirebaseFirestore _delegate;
  final FirestoreMonitorService _monitor = FirestoreMonitorService();

  MonitoredFirestore(this._delegate);

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return MonitoredCollectionReference(
      _delegate.collection(collectionPath),
      this,
    );
  }

  @override
  DocumentReference<Map<String, dynamic>> doc(String documentPath) {
    return MonitoredDocumentReference(_delegate.doc(documentPath), this);
  }

  @override
  WriteBatch batch() {
    return MonitoredWriteBatch(_delegate.batch(), _monitor);
  }

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) {
    // Transaction logging is tricky because we can't easily intercept the Transaction object passed to handler
    // without wrapping it too. For now, we delegate directly but log the start.
    // Ideally we wrap the Transaction object too.
    return _delegate.runTransaction(
      (transaction) async {
        // We should wrap the transaction object to log reads/writes inside it.
        // But Transaction class is sealed/hard to implement?
        // Let's check if we can wrap it.
        final monitoredTransaction = MonitoredTransaction(
          transaction,
          _monitor,
        );
        return transactionHandler(monitoredTransaction);
      },
      timeout: timeout,
      maxAttempts: maxAttempts,
    );
  }

  // Forwarding other properties/methods
  @override
  FirebaseApp get app => _delegate.app;

  @override
  Settings get settings => _delegate.settings;

  @override
  set settings(Settings settings) => _delegate.settings = settings;

  @override
  CollectionReference<Map<String, dynamic>> collectionGroup(
    String collectionPath,
  ) {
    return MonitoredCollectionReference(
      _delegate.collectionGroup(collectionPath)
          as CollectionReference<Map<String, dynamic>>,
      this,
    );
  }

  @override
  Future<void> clearPersistence() => _delegate.clearPersistence();

  @override
  Future<void> enableNetwork() => _delegate.enableNetwork();

  @override
  Future<void> disableNetwork() => _delegate.disableNetwork();

  @override
  Future<void> terminate() => _delegate.terminate();

  @override
  Future<void> waitForPendingWrites() => _delegate.waitForPendingWrites();

  @override
  Stream<void> snapshotsInSync() => _delegate.snapshotsInSync();

  @override
  LoadBundleTask loadBundle(Uint8List bundle) => _delegate.loadBundle(bundle);

  @override
  // ignore: override_on_non_overriding_member
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class MonitoredCollectionReference<T> implements CollectionReference<T> {
  final CollectionReference<T> _delegate;
  final MonitoredFirestore _firestore;

  MonitoredCollectionReference(this._delegate, this._firestore);

  @override
  String get id => _delegate.id;

  @override
  String get path => _delegate.path;

  @override
  DocumentReference<T> doc([String? path]) {
    return MonitoredDocumentReference(_delegate.doc(path), _firestore);
  }

  @override
  Future<DocumentReference<T>> add(T data) async {
    final result = await _delegate.add(data);
    FirestoreMonitorService().logWrite(
      path: result.path,
      details: 'Add document',
    );
    return MonitoredDocumentReference(result, _firestore);
  }

  // Query implementation forwarding
  @override
  Future<QuerySnapshot<T>> get([GetOptions? options]) async {
    final snapshot = await _delegate.get(options);
    FirestoreMonitorService().logRead(
      path: path,
      count: snapshot.docs.length,
      details: 'Query Get: ${snapshot.docs.length} docs',
    );
    return snapshot;
  }

  @override
  Stream<QuerySnapshot<T>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    return _delegate
        .snapshots(
          includeMetadataChanges: includeMetadataChanges,
          source: source,
        )
        .map((snapshot) {
          FirestoreMonitorService().logRead(
            path: path,
            count: snapshot.docs.length,
            details: 'Query Stream Update: ${snapshot.docs.length} docs',
          );
          return snapshot;
        });
  }

  @override
  Query<T> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    return MonitoredQuery(
      _delegate.where(
        field,
        isEqualTo: isEqualTo,
        isNotEqualTo: isNotEqualTo,
        isLessThan: isLessThan,
        isLessThanOrEqualTo: isLessThanOrEqualTo,
        isGreaterThan: isGreaterThan,
        isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
        arrayContains: arrayContains,
        arrayContainsAny: arrayContainsAny,
        whereIn: whereIn,
        whereNotIn: whereNotIn,
        isNull: isNull,
      ),
      _firestore,
    );
  }

  @override
  Query<T> orderBy(Object field, {bool descending = false}) {
    return MonitoredQuery(
      _delegate.orderBy(field, descending: descending),
      _firestore,
    );
  }

  @override
  Query<T> limit(int limit) {
    return MonitoredQuery(_delegate.limit(limit), _firestore);
  }

  @override
  Query<T> limitToLast(int limit) {
    return MonitoredQuery(_delegate.limitToLast(limit), _firestore);
  }

  @override
  Query<T> startAfter(Iterable<Object?> values) =>
      MonitoredQuery(_delegate.startAfter(values), _firestore);

  @override
  Query<T> startAfterDocument(DocumentSnapshot documentSnapshot) =>
      MonitoredQuery(
        _delegate.startAfterDocument(documentSnapshot),
        _firestore,
      );

  @override
  Query<T> startAt(Iterable<Object?> values) =>
      MonitoredQuery(_delegate.startAt(values), _firestore);

  @override
  Query<T> startAtDocument(DocumentSnapshot documentSnapshot) =>
      MonitoredQuery(_delegate.startAtDocument(documentSnapshot), _firestore);

  @override
  Query<T> endAt(Iterable<Object?> values) =>
      MonitoredQuery(_delegate.endAt(values), _firestore);

  @override
  Query<T> endAtDocument(DocumentSnapshot documentSnapshot) =>
      MonitoredQuery(_delegate.endAtDocument(documentSnapshot), _firestore);

  @override
  Query<T> endBefore(Iterable<Object?> values) =>
      MonitoredQuery(_delegate.endBefore(values), _firestore);

  @override
  Query<T> endBeforeDocument(DocumentSnapshot documentSnapshot) =>
      MonitoredQuery(_delegate.endBeforeDocument(documentSnapshot), _firestore);

  @override
  AggregateQuery aggregate(
    AggregateField aggregateField1, [
    AggregateField? aggregateField2,
    AggregateField? aggregateField3,
    AggregateField? aggregateField4,
    AggregateField? aggregateField5,
    AggregateField? aggregateField6,
    AggregateField? aggregateField7,
    AggregateField? aggregateField8,
    AggregateField? aggregateField9,
    AggregateField? aggregateField10,
    AggregateField? aggregateField11,
    AggregateField? aggregateField12,
    AggregateField? aggregateField13,
    AggregateField? aggregateField14,
    AggregateField? aggregateField15,
    AggregateField? aggregateField16,
    AggregateField? aggregateField17,
    AggregateField? aggregateField18,
    AggregateField? aggregateField19,
    AggregateField? aggregateField20,
    AggregateField? aggregateField21,
    AggregateField? aggregateField22,
    AggregateField? aggregateField23,
    AggregateField? aggregateField24,
    AggregateField? aggregateField25,
    AggregateField? aggregateField26,
    AggregateField? aggregateField27,
    AggregateField? aggregateField28,
    AggregateField? aggregateField29,
    AggregateField? aggregateField30,
  ]) {
    return MonitoredAggregateQuery(
      _delegate.aggregate(
        aggregateField1,
        aggregateField2,
        aggregateField3,
        aggregateField4,
        aggregateField5,
        aggregateField6,
        aggregateField7,
        aggregateField8,
        aggregateField9,
        aggregateField10,
        aggregateField11,
        aggregateField12,
        aggregateField13,
        aggregateField14,
        aggregateField15,
        aggregateField16,
        aggregateField17,
        aggregateField18,
        aggregateField19,
        aggregateField20,
        aggregateField21,
        aggregateField22,
        aggregateField23,
        aggregateField24,
        aggregateField25,
        aggregateField26,
        aggregateField27,
        aggregateField28,
        aggregateField29,
        aggregateField30,
      ),
      _firestore,
    );
  }

  @override
  AggregateQuery count() =>
      MonitoredAggregateQuery(_delegate.count(), _firestore);

  @override
  FirebaseFirestore get firestore => _firestore;

  @override
  CollectionReference<R> withConverter<R>({
    required FromFirestore<R> fromFirestore,
    required ToFirestore<R> toFirestore,
  }) {
    return MonitoredCollectionReference(
      _delegate.withConverter(
        fromFirestore: fromFirestore,
        toFirestore: toFirestore,
      ),
      _firestore,
    );
  }

  @override
  DocumentReference<Map<String, dynamic>>? get parent {
    final p = _delegate.parent;
    if (p == null) return null;
    return MonitoredDocumentReference(p, _firestore);
  }

  @override
  // ignore: override_on_non_overriding_member
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class MonitoredDocumentReference<T> implements DocumentReference<T> {
  final DocumentReference<T> _delegate;
  final MonitoredFirestore _firestore;

  DocumentReference<T> get delegate => _delegate;

  MonitoredDocumentReference(this._delegate, this._firestore);

  @override
  String get id => _delegate.id;

  @override
  String get path => _delegate.path;

  @override
  CollectionReference<T> get parent =>
      MonitoredCollectionReference(_delegate.parent, _firestore);

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return MonitoredCollectionReference(
      _delegate.collection(collectionPath),
      _firestore,
    );
  }

  @override
  Future<void> set(T data, [SetOptions? options]) async {
    await _delegate.set(data, options);
    FirestoreMonitorService().logWrite(path: path, details: 'Set document');
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    await _delegate.update(data);
    FirestoreMonitorService().logWrite(path: path, details: 'Update document');
  }

  @override
  Future<void> delete() async {
    await _delegate.delete();
    FirestoreMonitorService().logDelete(path: path, details: 'Delete document');
  }

  @override
  Future<DocumentSnapshot<T>> get([GetOptions? options]) async {
    final snap = await _delegate.get(options);
    FirestoreMonitorService().logRead(
      path: path,
      count: 1,
      details: 'Get document ${snap.exists ? "(Found)" : "(Missing)"}',
    );
    return snap;
  }

  @override
  Stream<DocumentSnapshot<T>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    return _delegate
        .snapshots(
          includeMetadataChanges: includeMetadataChanges,
          source: source,
        )
        .map((snap) {
          FirestoreMonitorService().logRead(
            path: path,
            count: 1,
            details: 'Stream document update',
          );
          return snap;
        });
  }

  @override
  FirebaseFirestore get firestore => _firestore;

  @override
  DocumentReference<R> withConverter<R>({
    required FromFirestore<R> fromFirestore,
    required ToFirestore<R> toFirestore,
  }) {
    return MonitoredDocumentReference(
      _delegate.withConverter(
        fromFirestore: fromFirestore,
        toFirestore: toFirestore,
      ),
      _firestore,
    );
  }

  @override
  // ignore: override_on_non_overriding_member
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class MonitoredQuery<T> implements Query<T> {
  final Query<T> _delegate;
  final MonitoredFirestore _firestore;

  MonitoredQuery(this._delegate, this._firestore);

  @override
  Future<QuerySnapshot<T>> get([GetOptions? options]) async {
    final snap = await _delegate.get(options);
    FirestoreMonitorService().logRead(
      path:
          'Query', // Queries don't always have a simple path, but usually belong to a collection
      count: snap.docs.length,
      details: 'Query Get: ${snap.docs.length} docs',
    );
    return snap;
  }

  @override
  Stream<QuerySnapshot<T>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    return _delegate
        .snapshots(
          includeMetadataChanges: includeMetadataChanges,
          source: source,
        )
        .map((snap) {
          FirestoreMonitorService().logRead(
            path: 'Query',
            count: snap.docs.length,
            details: 'Query Stream: ${snap.docs.length} docs',
          );
          return snap;
        });
  }

  @override
  AggregateQuery aggregate(
    AggregateField aggregateField1, [
    AggregateField? aggregateField2,
    AggregateField? aggregateField3,
    AggregateField? aggregateField4,
    AggregateField? aggregateField5,
    AggregateField? aggregateField6,
    AggregateField? aggregateField7,
    AggregateField? aggregateField8,
    AggregateField? aggregateField9,
    AggregateField? aggregateField10,
    AggregateField? aggregateField11,
    AggregateField? aggregateField12,
    AggregateField? aggregateField13,
    AggregateField? aggregateField14,
    AggregateField? aggregateField15,
    AggregateField? aggregateField16,
    AggregateField? aggregateField17,
    AggregateField? aggregateField18,
    AggregateField? aggregateField19,
    AggregateField? aggregateField20,
    AggregateField? aggregateField21,
    AggregateField? aggregateField22,
    AggregateField? aggregateField23,
    AggregateField? aggregateField24,
    AggregateField? aggregateField25,
    AggregateField? aggregateField26,
    AggregateField? aggregateField27,
    AggregateField? aggregateField28,
    AggregateField? aggregateField29,
    AggregateField? aggregateField30,
  ]) {
    return MonitoredAggregateQuery(
      _delegate.aggregate(
        aggregateField1,
        aggregateField2,
        aggregateField3,
        aggregateField4,
        aggregateField5,
        aggregateField6,
        aggregateField7,
        aggregateField8,
        aggregateField9,
        aggregateField10,
        aggregateField11,
        aggregateField12,
        aggregateField13,
        aggregateField14,
        aggregateField15,
        aggregateField16,
        aggregateField17,
        aggregateField18,
        aggregateField19,
        aggregateField20,
        aggregateField21,
        aggregateField22,
        aggregateField23,
        aggregateField24,
        aggregateField25,
        aggregateField26,
        aggregateField27,
        aggregateField28,
        aggregateField29,
        aggregateField30,
      ),
      _firestore,
    );
  }

  @override
  AggregateQuery count() =>
      MonitoredAggregateQuery(_delegate.count(), _firestore);

  @override
  Query<T> limit(int limit) =>
      MonitoredQuery(_delegate.limit(limit), _firestore);

  @override
  Query<T> limitToLast(int limit) =>
      MonitoredQuery(_delegate.limitToLast(limit), _firestore);

  @override
  Query<T> orderBy(Object field, {bool descending = false}) => MonitoredQuery(
    _delegate.orderBy(field, descending: descending),
    _firestore,
  );

  @override
  Query<T> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    return MonitoredQuery(
      _delegate.where(
        field,
        isEqualTo: isEqualTo,
        isNotEqualTo: isNotEqualTo,
        isLessThan: isLessThan,
        isLessThanOrEqualTo: isLessThanOrEqualTo,
        isGreaterThan: isGreaterThan,
        isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
        arrayContains: arrayContains,
        arrayContainsAny: arrayContainsAny,
        whereIn: whereIn,
        whereNotIn: whereNotIn,
        isNull: isNull,
      ),
      _firestore,
    );
  }

  @override
  Query<T> startAfter(Iterable<Object?> values) =>
      MonitoredQuery(_delegate.startAfter(values), _firestore);

  @override
  Query<T> startAfterDocument(DocumentSnapshot documentSnapshot) =>
      MonitoredQuery(
        _delegate.startAfterDocument(documentSnapshot),
        _firestore,
      );

  @override
  Query<T> startAt(Iterable<Object?> values) =>
      MonitoredQuery(_delegate.startAt(values), _firestore);

  @override
  Query<T> startAtDocument(DocumentSnapshot documentSnapshot) =>
      MonitoredQuery(_delegate.startAtDocument(documentSnapshot), _firestore);

  @override
  Query<T> endAt(Iterable<Object?> values) =>
      MonitoredQuery(_delegate.endAt(values), _firestore);

  @override
  Query<T> endAtDocument(DocumentSnapshot documentSnapshot) =>
      MonitoredQuery(_delegate.endAtDocument(documentSnapshot), _firestore);

  @override
  Query<T> endBefore(Iterable<Object?> values) =>
      MonitoredQuery(_delegate.endBefore(values), _firestore);

  @override
  Query<T> endBeforeDocument(DocumentSnapshot documentSnapshot) =>
      MonitoredQuery(_delegate.endBeforeDocument(documentSnapshot), _firestore);

  @override
  FirebaseFirestore get firestore => _firestore;

  @override
  Query<R> withConverter<R>({
    required FromFirestore<R> fromFirestore,
    required ToFirestore<R> toFirestore,
  }) {
    return MonitoredQuery(
      _delegate.withConverter(
        fromFirestore: fromFirestore,
        toFirestore: toFirestore,
      ),
      _firestore,
    );
  }

  @override
  Map<String, dynamic> get parameters => _delegate.parameters;
}

class MonitoredWriteBatch implements WriteBatch {
  final WriteBatch _delegate;
  final FirestoreMonitorService _monitor;
  int _ops = 0;

  MonitoredWriteBatch(this._delegate, this._monitor);

  @override
  void set<T>(DocumentReference<T> document, T data, [SetOptions? options]) {
    final ref = document is MonitoredDocumentReference<T>
        ? document.delegate
        : document;
    _delegate.set(ref, data, options);
    _ops++;
    _monitor.logWrite(path: document.path, details: 'Batch Set (Pending)');
  }

  @override
  void update(DocumentReference document, Map<String, Object?> data) {
    final ref = document is MonitoredDocumentReference
        ? document.delegate
        : document;
    _delegate.update(ref, data);
    _ops++;
    _monitor.logWrite(path: document.path, details: 'Batch Update (Pending)');
  }

  @override
  void delete(DocumentReference document) {
    final ref = document is MonitoredDocumentReference
        ? document.delegate
        : document;
    _delegate.delete(ref);
    _ops++;
    _monitor.logDelete(path: document.path, details: 'Batch Delete (Pending)');
  }

  @override
  Future<void> commit() async {
    await _delegate.commit();
    // We already logged the pending ops, but we could log a "Commit" event too.
    _monitor.logWrite(path: 'Batch', details: 'Committed $_ops operations');
  }
}

class MonitoredTransaction implements Transaction {
  final Transaction _delegate;
  final FirestoreMonitorService _monitor;

  MonitoredTransaction(this._delegate, this._monitor);

  @override
  Future<DocumentSnapshot<T>> get<T>(
    DocumentReference<T> documentReference,
  ) async {
    final ref = documentReference is MonitoredDocumentReference<T>
        ? documentReference.delegate
        : documentReference;
    final snap = await _delegate.get(ref);
    _monitor.logRead(
      path: documentReference.path,
      count: 1,
      details: 'Transaction Get',
    );
    return snap;
  }

  @override
  Transaction set<T>(
    DocumentReference<T> documentReference,
    T data, [
    SetOptions? options,
  ]) {
    final ref = documentReference is MonitoredDocumentReference<T>
        ? documentReference.delegate
        : documentReference;
    _delegate.set(ref, data, options);
    _monitor.logWrite(path: documentReference.path, details: 'Transaction Set');
    return this;
  }

  @override
  Transaction update(
    DocumentReference documentReference,
    Map<String, dynamic> data,
  ) {
    final ref = documentReference is MonitoredDocumentReference
        ? documentReference.delegate
        : documentReference;
    _delegate.update(ref, data);
    _monitor.logWrite(
      path: documentReference.path,
      details: 'Transaction Update',
    );
    return this;
  }

  @override
  Transaction delete(DocumentReference documentReference) {
    final ref = documentReference is MonitoredDocumentReference
        ? documentReference.delegate
        : documentReference;
    _delegate.delete(ref);
    _monitor.logDelete(
      path: documentReference.path,
      details: 'Transaction Delete',
    );
    return this;
  }
}

class MonitoredAggregateQuery implements AggregateQuery {
  final AggregateQuery _delegate;
  final MonitoredFirestore _firestore;

  MonitoredAggregateQuery(this._delegate, this._firestore);

  @override
  Future<AggregateQuerySnapshot> get({
    AggregateSource source = AggregateSource.server,
  }) async {
    final snap = await _delegate.get(source: source);
    FirestoreMonitorService().logRead(
      path: 'AggregateQuery',
      count: 1,
      details: 'Count Query: ${snap.count}',
    );
    return snap;
  }

  @override
  Query<Object?> get query => MonitoredQuery(_delegate.query, _firestore);

  @override
  AggregateQuery count() =>
      MonitoredAggregateQuery(_delegate.count(), _firestore);
}

// lib/services/job_notification_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:assignment29/services/notification_service.dart';

class JobNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collection = 'jobs';
  static const String _statusField = 'status';
  static const String _assignedField = 'assignedMechanic';
  static const String _pendingLower = 'pending';

  static const bool _filterByCurrentUser = true;
  static const bool _skipInitialSnapshot = true;

  static bool _started = false;
  static String? _currentUid;
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  static bool _skippedOnce = false;
  static final Map<String, String?> _lastStatusCache = {};

  static Future<void> start() async {
    final user = FirebaseAuth.instance.currentUser;
    if (_filterByCurrentUser && user == null) {
      await stop();
      return;
    }
    if (_started && _currentUid == user?.uid) return;

    await stop();
    _started = true;
    _currentUid = user?.uid;

    await NotificationService.initialize();

    Query<Map<String, dynamic>> base = _firestore.collection(_collection);
    if (_filterByCurrentUser) {
      base = base.where(_assignedField, isEqualTo: _currentUid);
    }

    await _notifyExistingPendingOnce(base);

    _sub = base.snapshots().listen((snap) {
      if (_skipInitialSnapshot && !_skippedOnce) {
        _skippedOnce = true;
        for (final d in snap.docs) {
          _lastStatusCache[d.id] = (d.data()[_statusField] ?? '').toString();
        }
        return;
      }

      for (final change in snap.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;

        final current = (data[_statusField] ?? '').toString();
        final previous = _lastStatusCache[change.doc.id] ?? '';
        final currentLower = current.trim().toLowerCase();
        final previousLower = previous.trim().toLowerCase();

        if (change.type == DocumentChangeType.added && currentLower == _pendingLower) {
          final title = 'New Pending Job';
          final body = '${data['vehicle'] ?? 'Vehicle'} • ${data['jobDescription'] ?? 'Service required'}';
          NotificationService.showNotification(
            id: _stableId('added_${change.doc.id}'),
            title: title,
            body: body,
            payload: 'pending_job_${change.doc.id}',
          );
        } else if (previousLower != _pendingLower && currentLower == _pendingLower) {
          final title = 'Job Pending';
          final body = '${data['vehicle'] ?? 'Vehicle'} • ${data['jobDescription'] ?? 'Service required'}';
          NotificationService.showNotification(
            id: _stableId('pending_${change.doc.id}'),
            title: title,
            body: body,
            payload: 'pending_job_${change.doc.id}',
          );
        }

        _lastStatusCache[change.doc.id] = current;
      }
    });
  }

  static Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _skippedOnce = false;
    _lastStatusCache.clear();
    _started = false;
    _currentUid = null;
  }

  static Future<void> _notifyExistingPendingOnce(Query<Map<String, dynamic>> base) async {
    final snap = await base.get();
    for (final d in snap.docs) {
      final data = d.data();
      final status = (data[_statusField] ?? '').toString().trim().toLowerCase();
      if (status == _pendingLower) {
        final title = 'Pending Job';
        final body = '${data['vehicle'] ?? 'Vehicle'} • ${data['jobDescription'] ?? 'Service required'}';
        NotificationService.showNotification(
          id: _stableId('backfill_${d.id}'),
          title: title,
          body: body,
          payload: 'pending_job_${d.id}',
        );
        _lastStatusCache[d.id] = data[_statusField]?.toString();
      } else {
        _lastStatusCache[d.id] = data[_statusField]?.toString();
      }
    }
  }

  static int _stableId(String key) => key.hashCode & 0x7fffffff;
}

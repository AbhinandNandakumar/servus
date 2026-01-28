// lib/services/notification_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification data model
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? jobId;
  final DateTime createdAt;
  final bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.jobId,
    required this.createdAt,
    this.read = false,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? '',
      jobId: data['jobId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] ?? false,
    );
  }
}

/// Callback type for new notifications
typedef NotificationCallback = void Function(AppNotification notification);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? _currentUserId;
  String? _currentUserType;
  StreamSubscription? _notificationSubscription;

  // Callbacks for UI updates
  final List<NotificationCallback> _listeners = [];

  // Unread count
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (kDebugMode) {
      print('NotificationService initialized');
      if (kIsWeb) {
        print('Running on web - using Firestore-based notifications');
      }
    }
  }

  /// Register user/worker for notifications
  Future<void> registerForNotifications({
    required String userId,
    required String userType,
  }) async {
    _currentUserId = userId;
    _currentUserType = userType;

    // Start listening for notifications
    _startListeningForNotifications();

    if (kDebugMode) {
      print('Registered for notifications: $userType - $userId');
    }
  }

  /// Add a listener for new notifications
  void addListener(NotificationCallback callback) {
    _listeners.add(callback);
  }

  /// Remove a listener
  void removeListener(NotificationCallback callback) {
    _listeners.remove(callback);
  }

  /// Start listening for new notifications from Firestore
  void _startListeningForNotifications() {
    if (_currentUserId == null || _currentUserType == null) return;

    // Cancel existing subscription
    _notificationSubscription?.cancel();

    final collection = _currentUserType == 'worker'
        ? 'worker_notifications'
        : 'customer_notifications';

    _notificationSubscription = _db
        .collection(collection)
        .doc(_currentUserId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .listen((snapshot) {
      // Count unread
      _unreadCount = snapshot.docs.where((doc) {
        final data = doc.data();
        return data['read'] != true;
      }).length;

      // Notify listeners about new notifications
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final notification = AppNotification.fromFirestore(change.doc);

          // Only notify for recent notifications (within last 30 seconds)
          final now = DateTime.now();
          if (now.difference(notification.createdAt).inSeconds < 30) {
            for (final listener in _listeners) {
              listener(notification);
            }
          }
        }
      }
    });
  }

  /// Get all notifications for current user
  Future<List<AppNotification>> getNotifications() async {
    if (_currentUserId == null || _currentUserType == null) return [];

    final collection = _currentUserType == 'worker'
        ? 'worker_notifications'
        : 'customer_notifications';

    final snapshot = await _db
        .collection(collection)
        .doc(_currentUserId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .map((doc) => AppNotification.fromFirestore(doc))
        .toList();
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    if (_currentUserId == null || _currentUserType == null) return;

    final collection = _currentUserType == 'worker'
        ? 'worker_notifications'
        : 'customer_notifications';

    await _db
        .collection(collection)
        .doc(_currentUserId)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_currentUserId == null || _currentUserType == null) return;

    final collection = _currentUserType == 'worker'
        ? 'worker_notifications'
        : 'customer_notifications';

    final snapshot = await _db
        .collection(collection)
        .doc(_currentUserId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();

    _unreadCount = 0;
  }

  /// Unregister from notifications (e.g., on logout)
  Future<void> unregisterFromNotifications() async {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _currentUserId = null;
    _currentUserType = null;
    _unreadCount = 0;
    _listeners.clear();
  }

  /// Show an in-app notification (for immediate feedback)
  void showLocalNotification({
    required String title,
    required String body,
    String? type,
    String? jobId,
  }) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: type ?? 'info',
      jobId: jobId,
      createdAt: DateTime.now(),
    );

    for (final listener in _listeners) {
      listener(notification);
    }
  }
}

/// Background message handler placeholder (needed for mobile)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(dynamic message) async {
  if (kDebugMode) {
    print('Background message received');
  }
}

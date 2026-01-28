// lib/worker/widgets/notification_overlay.dart
import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

class NotificationOverlay extends StatefulWidget {
  final Widget child;

  const NotificationOverlay({Key? key, required this.child}) : super(key: key);

  @override
  State<NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<NotificationOverlay>
    with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  AppNotification? _currentNotification;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Listen for notifications
    _notificationService.addListener(_handleNotification);
  }

  @override
  void dispose() {
    _notificationService.removeListener(_handleNotification);
    _animationController.dispose();
    super.dispose();
  }

  void _handleNotification(AppNotification notification) {
    setState(() {
      _currentNotification = notification;
    });
    _animationController.forward();

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _currentNotification?.id == notification.id) {
        _dismissNotification();
      }
    });
  }

  void _dismissNotification() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _currentNotification = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_currentNotification != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: SlideTransition(
                position: _slideAnimation,
                child: GestureDetector(
                  onTap: _dismissNotification,
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity != null &&
                        details.primaryVelocity! < 0) {
                      _dismissNotification();
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _getNotificationColor().withAlpha(26),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getNotificationIcon(),
                            color: _getNotificationColor(),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentNotification!.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF1E3A5F),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentNotification!.body,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _dismissNotification,
                          icon: Icon(
                            Icons.close,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _getNotificationColor() {
    switch (_currentNotification?.type) {
      case 'new_booking':
        return const Color(0xFF2196F3);
      case 'job_status_update':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF1E3A5F);
    }
  }

  IconData _getNotificationIcon() {
    switch (_currentNotification?.type) {
      case 'new_booking':
        return Icons.work_outline;
      case 'job_status_update':
        return Icons.update;
      default:
        return Icons.notifications_outlined;
    }
  }
}

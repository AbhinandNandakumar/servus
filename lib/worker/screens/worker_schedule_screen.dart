import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class WorkerScheduleScreen extends StatefulWidget {
  final String workerId;

  const WorkerScheduleScreen({super.key, required this.workerId});

  @override
  State<WorkerScheduleScreen> createState() => _WorkerScheduleScreenState();
}

class _WorkerScheduleScreenState extends State<WorkerScheduleScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, dynamic> _availability = {};
  bool _isLoading = true;

  // Calendar state
  late DateTime _currentMonth;
  final List<String> _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final availability =
        await _firestoreService.getWorkerAvailability(widget.workerId);
    setState(() {
      _availability = availability;
      _isLoading = false;
    });
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${_monthNames[date.month - 1]}-${date.day}';
  }

  bool _isPast(DateTime date) {
    final today = DateTime.now();
    return date.isBefore(DateTime(today.year, today.month, today.day));
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  int get _availableDaysCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _availability.keys.where((key) {
      // Parse date key back to check if it's in the future
      try {
        final parts = key.split('-');
        final year = int.parse(parts[0]);
        final monthIndex = _monthNames.indexOf(parts[1]);
        final day = int.parse(parts[2]);
        if (monthIndex < 0) return false;
        final date = DateTime(year, monthIndex + 1, day);
        return !date.isBefore(today);
      } catch (_) {
        return false;
      }
    }).length;
  }

  Future<void> _showAvailabilityPicker(DateTime date) async {
    final key = _dateKey(date);
    final existing = _availability[key];
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);

    if (existing != null) {
      startTime = _parseTimeOfDay(existing['startTime'] ?? '09:00 AM');
      endTime = _parseTimeOfDay(existing['endTime'] ?? '05:00 PM');
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.calendar_today,
                            color: Color(0xFF4CAF50), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_weekdays[date.weekday % 7]}, ${_monthNames[date.month - 1]} ${date.day}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A5F),
                            ),
                          ),
                          Text(
                            existing != null
                                ? 'Edit availability'
                                : 'Set availability',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Start time
                  _buildTimeTile(
                    label: 'Start Time',
                    time: startTime,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (picked != null) {
                        setSheetState(() => startTime = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // End time
                  _buildTimeTile(
                    label: 'End Time',
                    time: endTime,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: endTime,
                      );
                      if (picked != null) {
                        setSheetState(() => endTime = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Validate end > start
                        final startMinutes =
                            startTime.hour * 60 + startTime.minute;
                        final endMinutes = endTime.hour * 60 + endTime.minute;
                        if (endMinutes <= startMinutes) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('End time must be after start time'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final success =
                            await _firestoreService.setWorkerAvailability(
                          widget.workerId,
                          key,
                          {
                            'startTime': _formatTimeOfDay(startTime),
                            'endTime': _formatTimeOfDay(endTime),
                          },
                        );
                        if (success) {
                          await _loadAvailability();
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check, size: 20),
                      label: const Text('Save Availability'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                  // Remove button (only if existing)
                  if (existing != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final success =
                              await _firestoreService.removeWorkerAvailability(
                            widget.workerId,
                            key,
                          );
                          if (success) {
                            await _loadAvailability();
                          }
                          if (context.mounted) Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close, size: 20),
                        label: const Text('Remove Availability'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeTile({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const Spacer(),
            Text(
              _formatTimeOfDay(time),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A5F),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  TimeOfDay _parseTimeOfDay(String timeStr) {
    final parts = timeStr.split(' ');
    final timeParts = parts[0].split(':');
    var hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final isPm = parts[1].toUpperCase() == 'PM';

    if (isPm && hour != 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;

    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E3A5F)))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildMonthNav()),
                SliverToBoxAdapter(child: _buildCalendarGrid()),
                SliverToBoxAdapter(child: _buildUpcomingList()),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A5F), Color(0xFF2D5478)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'My Schedule',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(26),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withAlpha(51)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_available,
                        color: Colors.white, size: 28),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_availableDaysCount days available',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Tap a date to set your hours',
                          style: TextStyle(
                            color: Colors.white.withAlpha(179),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthNav() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              final now = DateTime.now();
              final prevMonth = DateTime(
                  _currentMonth.year, _currentMonth.month - 1);
              // Don't go before current month
              if (prevMonth.year > now.year ||
                  (prevMonth.year == now.year &&
                      prevMonth.month >= now.month)) {
                setState(() => _currentMonth = prevMonth);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chevron_left,
                  color: Color(0xFF1E3A5F), size: 24),
            ),
          ),
          Text(
            '${_monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A5F),
            ),
          ),
          GestureDetector(
            onTap: () {
              final now = DateTime.now();
              final nextMonth = DateTime(
                  _currentMonth.year, _currentMonth.month + 1);
              // Don't go more than 2 months ahead
              final maxMonth = DateTime(now.year, now.month + 2);
              if (nextMonth.isBefore(maxMonth) ||
                  nextMonth.isAtSameMomentAs(maxMonth)) {
                setState(() => _currentMonth = nextMonth);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chevron_right,
                  color: Color(0xFF1E3A5F), size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0 = Sun

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Weekday headers
          Row(
            children: _weekdays
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Calendar cells
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startWeekday) {
                return const SizedBox();
              }

              final day = index - startWeekday + 1;
              final date = DateTime(
                  _currentMonth.year, _currentMonth.month, day);
              final key = _dateKey(date);
              final hasAvailability = _availability.containsKey(key);
              final isPast = _isPast(date);
              final isToday = _isToday(date);

              return GestureDetector(
                onTap: isPast ? null : () => _showAvailabilityPicker(date),
                child: Container(
                  decoration: BoxDecoration(
                    color: hasAvailability && !isPast
                        ? const Color(0xFF4CAF50).withAlpha(26)
                        : isToday
                            ? const Color(0xFF1E3A5F).withAlpha(13)
                            : null,
                    borderRadius: BorderRadius.circular(10),
                    border: isToday
                        ? Border.all(
                            color: const Color(0xFF1E3A5F), width: 1.5)
                        : hasAvailability && !isPast
                            ? Border.all(
                                color:
                                    const Color(0xFF4CAF50).withAlpha(128),
                                width: 1)
                            : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.w500,
                          color: isPast
                              ? Colors.grey[300]
                              : hasAvailability
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFF1E3A5F),
                        ),
                      ),
                      if (hasAvailability && !isPast) ...[
                        const SizedBox(height: 2),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingList() {
    // Show upcoming available dates as a list
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final upcomingEntries = <MapEntry<String, dynamic>>[];
    for (final entry in _availability.entries) {
      try {
        final parts = entry.key.split('-');
        final year = int.parse(parts[0]);
        final monthIndex = _monthNames.indexOf(parts[1]);
        final day = int.parse(parts[2]);
        if (monthIndex < 0) continue;
        final date = DateTime(year, monthIndex + 1, day);
        if (!date.isBefore(today)) {
          upcomingEntries.add(entry);
        }
      } catch (_) {
        continue;
      }
    }

    // Sort by date
    upcomingEntries.sort((a, b) {
      final aParts = a.key.split('-');
      final bParts = b.key.split('-');
      final aDate = DateTime(int.parse(aParts[0]),
          _monthNames.indexOf(aParts[1]) + 1, int.parse(aParts[2]));
      final bDate = DateTime(int.parse(bParts[0]),
          _monthNames.indexOf(bParts[1]) + 1, int.parse(bParts[2]));
      return aDate.compareTo(bDate);
    });

    if (upcomingEntries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(Icons.event_busy, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                'No upcoming availability',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap dates on the calendar to set your hours',
                style: TextStyle(fontSize: 13, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Availability',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 12),
          ...upcomingEntries.take(7).map((entry) {
            final data = entry.value as Map<String, dynamic>;
            final parts = entry.key.split('-');
            final monthIndex = _monthNames.indexOf(parts[1]);
            final date = DateTime(
                int.parse(parts[0]), monthIndex + 1, int.parse(parts[2]));

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF4CAF50).withAlpha(51)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withAlpha(26),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${date.day}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        Text(
                          _weekdays[date.weekday % 7],
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_monthNames[date.month - 1]} ${date.day}, ${date.year}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF1E3A5F),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${data['startTime']} - ${data['endTime']}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.edit_outlined,
                      color: Colors.grey[400], size: 20),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// lib/worker/screens/worker_jobs.dart
import 'package:flutter/material.dart';
import '../services/worker_service.dart';
import '../widgets/job_card.dart';

class WorkerJobsScreen extends StatefulWidget {
  final String workerId;

  const WorkerJobsScreen({Key? key, required this.workerId}) : super(key: key);

  @override
  _WorkerJobsScreenState createState() => _WorkerJobsScreenState();
}

class _WorkerJobsScreenState extends State<WorkerJobsScreen>
    with SingleTickerProviderStateMixin {
  final WorkerService _workerService = WorkerService();
  List<Map<String, dynamic>> _jobs = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  late TabController _tabController;

  final List<Map<String, dynamic>> _filters = [
    {'label': 'All', 'icon': Icons.list_alt_rounded},
    {'label': 'Pending', 'icon': Icons.schedule},
    {'label': 'Accepted', 'icon': Icons.check_circle_outline},
    {'label': 'Completed', 'icon': Icons.verified},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
    _workerService.setWorkerId(widget.workerId);
    _loadJobs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);

    List<Map<String, dynamic>> jobs;
    switch (_selectedFilter) {
      case 'Pending':
        jobs = await _workerService.getAvailableJobs();
        break;
      case 'Accepted':
        jobs = await _workerService.getAcceptedJobs();
        break;
      case 'Completed':
        jobs = await _workerService.getCompletedJobs();
        break;
      default:
        jobs = await _workerService.getWorkerJobs();
    }

    setState(() {
      _jobs = jobs;
      _isLoading = false;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFE53935) : const Color(0xFF43A047),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _acceptJob(String jobId) async {
    final success = await _workerService.acceptJob(jobId);
    if (success) {
      _showSnackBar('Job accepted successfully!');
      _loadJobs();
    } else {
      _showSnackBar('Failed to accept job', isError: true);
    }
  }

  Future<void> _rejectJob(String jobId) async {
    final reason = await _showRejectDialog();
    if (reason != null) {
      final success = await _workerService.rejectJob(jobId, reason);
      if (success) {
        _showSnackBar('Job declined');
        _loadJobs();
      } else {
        _showSnackBar('Failed to decline job', isError: true);
      }
    }
  }

  Future<void> _startJob(String jobId) async {
    final success = await _workerService.startJob(jobId);
    if (success) {
      _showSnackBar('Job started! Good luck!');
      _loadJobs();
    } else {
      _showSnackBar('Failed to start job', isError: true);
    }
  }

  Future<void> _completeJob(String jobId) async {
    final success = await _workerService.completeJob(jobId);
    if (success) {
      _showSnackBar('Job completed! Great work!');
      _loadJobs();
    } else {
      _showSnackBar('Failed to complete job', isError: true);
    }
  }

  Future<String?> _showRejectDialog() async {
    String reason = '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.cancel_outlined, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Decline Job'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please provide a reason for declining this job (optional):',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => reason = value,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter reason...',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reason),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverToBoxAdapter(
            child: _buildHeader(),
          ),

          // Filter Tabs
          SliverToBoxAdapter(
            child: _buildFilterTabs(),
          ),

          // Jobs List
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF1E3A5F)),
                  ),
                )
              : _jobs.isEmpty
                  ? SliverFillRemaining(
                      child: _buildEmptyState(),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final job = _jobs[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: JobCard(
                                job: job,
                                onAccept: () => _acceptJob(job['id']),
                                onReject: () => _rejectJob(job['id']),
                                onStart: () => _startJob(job['id']),
                                onComplete: () => _completeJob(job['id']),
                              ),
                            );
                          },
                          childCount: _jobs.length,
                        ),
                      ),
                    ),
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
          colors: [
            Color(0xFF1E3A5F),
            Color(0xFF2D5478),
          ],
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
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'My Jobs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Jobs Count Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(26),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withAlpha(51)),
                ),
                child: Row(
                  children: [
                    _buildSummaryItem('${_jobs.length}', 'Total'),
                    _buildSummaryDivider(),
                    _buildSummaryItem(
                      '${_jobs.where((j) => j['status'] == 'pending').length}',
                      'Pending',
                    ),
                    _buildSummaryDivider(),
                    _buildSummaryItem(
                      '${_jobs.where((j) => j['status'] == 'accepted' || j['status'] == 'in_progress').length}',
                      'Active',
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

  Widget _buildSummaryItem(String count, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(179),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withAlpha(51),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: _filters.map((filter) {
            final isSelected = filter['label'] == _selectedFilter;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedFilter = filter['label']);
                _loadJobs();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1E3A5F) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF1E3A5F).withAlpha(51),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      filter['icon'],
                      size: 18,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      filter['label'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F).withAlpha(13),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Icon(
              _selectedFilter == 'Pending'
                  ? Icons.inbox_outlined
                  : _selectedFilter == 'Completed'
                      ? Icons.task_alt
                      : Icons.work_off_outlined,
              size: 64,
              color: const Color(0xFF1E3A5F).withAlpha(128),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _getEmptyTitle(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getEmptySubtitle(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadJobs,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A5F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getEmptyTitle() {
    switch (_selectedFilter) {
      case 'Pending':
        return 'No Pending Jobs';
      case 'Accepted':
        return 'No Active Jobs';
      case 'Completed':
        return 'No Completed Jobs';
      default:
        return 'No Jobs Yet';
    }
  }

  String _getEmptySubtitle() {
    switch (_selectedFilter) {
      case 'Pending':
        return 'New job requests will appear here';
      case 'Accepted':
        return 'Jobs you accept will appear here';
      case 'Completed':
        return 'Your completed jobs will appear here';
      default:
        return 'Your job history will appear here';
    }
  }
}

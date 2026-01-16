import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class StaffPerformanceDetailsDialog extends StatefulWidget {
  final String staffId;
  final String? staffName;

  const StaffPerformanceDetailsDialog({
    super.key,
    required this.staffId,
    this.staffName,
  });

  @override
  State<StaffPerformanceDetailsDialog> createState() =>
      _StaffPerformanceDetailsDialogState();
}

class _StaffPerformanceDetailsDialogState
    extends State<StaffPerformanceDetailsDialog> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _performanceData;
  String? _error;
  String _staffName = '';

  @override
  void initState() {
    super.initState();
    _staffName = widget.staffName ?? 'Staff Member';
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load Performance Data
      final performanceResponse = await _apiService.getStaffPerformance(
        staffId: widget.staffId,
      );

      // If name is not provided, try to fetch it
      if (widget.staffName == null) {
        try {
          final staffResponse = await _apiService.getStaffById(
            staffId: widget.staffId,
          );
          if (staffResponse['fullName'] != null) {
            _staffName = staffResponse['fullName'];
          }
        } catch (_) {
          // Ignore name fetch error, fallback used
        }
      }

      setState(() {
        _performanceData = performanceResponse;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? 16 : 24),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 900,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text('Error: $_error'))
                  : _buildContent(isMobile),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primary.withOpacity(0.1),
            child: Text(
              _staffName.isNotEmpty ? _staffName[0].toUpperCase() : 'S',
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _staffName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.gray900,
                  ),
                ),
                Text(
                  'Performance Metrics',
                  style: const TextStyle(fontSize: 14, color: AppTheme.gray600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            color: AppTheme.gray500,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isMobile) {
    if (_performanceData == null || _performanceData!['performance'] == null) {
      return const Center(child: Text('No performance data available'));
    }

    final performance = _performanceData!['performance'];
    final ratios = performance['ratios'] ?? {};
    final description = performance['description'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width < 600 ? 2 : 5;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildMetricCard(
                    'Total Assigned',
                    performance['totalTasksAssigned']?.toString() ?? '0',
                    Icons.assignment,
                    Colors.blue,
                  ),
                  _buildMetricCard(
                    'Accepted',
                    performance['totalAccepted']?.toString() ?? '0',
                    Icons.check_circle_outline,
                    Colors.purple,
                  ),
                  _buildMetricCard(
                    'Submitted',
                    performance['totalSubmitted']?.toString() ?? '0',
                    Icons.upload_file,
                    Colors.orange,
                  ),
                  _buildMetricCard(
                    'Approved',
                    performance['totalApproved']?.toString() ?? '0',
                    Icons.verified,
                    Colors.green,
                  ),
                  _buildMetricCard(
                    'On Time',
                    performance['totalOnTime']?.toString() ?? '0',
                    Icons.timer,
                    Colors.teal,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          // Ratios Section
          const Text(
            'Performance Ratios',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.gray900,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              // 2 columns on mobile, 4 on desktop
              final isSmall = width < 600;

              return Wrap(
                spacing: 24,
                runSpacing: 24,
                alignment: WrapAlignment.start,
                children: [
                  _buildCircularRatio(
                    'Acceptance',
                    ratios['acceptanceRatio'] ?? '0%',
                    Colors.purple,
                    width: isSmall ? (width - 24) / 2 : (width - 72) / 4,
                  ),
                  _buildCircularRatio(
                    'Submission',
                    ratios['submissionRatio'] ?? '0%',
                    Colors.orange,
                    width: isSmall ? (width - 24) / 2 : (width - 72) / 4,
                  ),
                  _buildCircularRatio(
                    'Approval',
                    ratios['approvalRatio'] ?? '0%',
                    Colors.green,
                    width: isSmall ? (width - 24) / 2 : (width - 72) / 4,
                  ),
                  _buildCircularRatio(
                    'On Time',
                    ratios['onTimeCompletionRatio'] ?? '0%',
                    Colors.teal,
                    width: isSmall ? (width - 24) / 2 : (width - 72) / 4,
                  ),
                ],
              );
            },
          ),

          if (description.isNotEmpty) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.gray50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.gray200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: AppTheme.gray600,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.gray900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (description['onTimeNote'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        '• ${description['onTimeNote']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.gray700,
                          height: 1.5,
                        ),
                      ),
                    ),
                  // Add other notes if present in description map
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.gray600,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircularRatio(
    String title,
    String percentageStr,
    Color color, {
    double? width,
  }) {
    // Parse percentage string "0.00%" -> double
    double percentage = 0;
    try {
      percentage = double.parse(percentageStr.replaceAll('%', '')) / 100;
    } catch (_) {}

    return SizedBox(
      width: width,
      child: Column(
        children: [
          SizedBox(
            height: 100,
            width: 100,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    height: 100,
                    width: 100,
                    child: CircularProgressIndicator(
                      value: percentage,
                      backgroundColor: AppTheme.gray100,
                      color: color,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        percentageStr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.gray700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

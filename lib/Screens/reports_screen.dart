import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // Temporary report data.
  // Later this will come from Firebase Firestore.
  final List<Map<String, dynamic>> _reports = [
    {
      'id': 'report001',
      'userId': 'user001',
      'userEmail': 'user@gmail.com',
      'type': 'Song Report',
      'songId': 'song001',
      'songName': 'Blinding Lights',
      'reason': 'Wrong song information',
      'description': 'The artist information shown for this song is incorrect.',
      'date': '06 Oct 2026, 10:30 AM',
      'status': 'Pending',
    },
    {
      'id': 'report002',
      'userId': 'user002',
      'userEmail': 'musicuser@gmail.com',
      'type': 'Song Report',
      'songId': 'song003',
      'songName': 'Shape of You',
      'reason': 'Audio problem',
      'description': 'The song stops playing after a few seconds.',
      'date': '06 Oct 2026, 11:15 AM',
      'status': 'Pending',
    },
    {
      'id': 'report003',
      'userId': 'user003',
      'userEmail': 'testuser@gmail.com',
      'type': 'User Report',
      'songId': '-',
      'songName': '-',
      'reason': 'Inappropriate behavior',
      'description': 'This user is posting inappropriate content.',
      'date': '05 Oct 2026, 06:45 PM',
      'status': 'Reviewed',
    },
  ];

  // ==========================================================
  // MARK REPORT AS RESOLVED
  // ==========================================================

  void _markAsResolved(int index) {
    setState(() {
      _reports[index]['status'] = 'Resolved';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report marked as resolved'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================================
  // REPORT DETAILS
  // ==========================================================

  void _showReportDetails(int index) {
    final report = _reports[index];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final textColor = AppTheme.text(context);
        final subtitleColor = AppTheme.subtitleColor(context);

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          decoration: BoxDecoration(
            color: AppTheme.card(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        height: 45,
                        width: 45,
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.report_problem_rounded,
                          color: Colors.redAccent,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          'Report Details',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.close_rounded, color: subtitleColor),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  _detailRow(context, 'Report ID', report['id']),

                  _detailRow(context, 'Report Type', report['type']),

                  _detailRow(context, 'User ID', report['userId']),

                  _detailRow(context, 'User Email', report['userEmail']),

                  _detailRow(context, 'Song ID', report['songId']),

                  _detailRow(context, 'Song Name', report['songName']),

                  _detailRow(context, 'Reason', report['reason']),

                  _detailRow(context, 'Date', report['date']),

                  const SizedBox(height: 15),

                  Text(
                    'Description',
                    style: TextStyle(color: subtitleColor, fontSize: 13),
                  ),

                  const SizedBox(height: 7),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      report['description'],
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  _statusChip(context, report['status']),

                  if (report['status'] != 'Resolved') ...[
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _markAsResolved(index);
                        },
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text('Mark as Resolved'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppTheme.radius12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);

    final pendingReports = _reports
        .where((report) => report['status'] == 'Pending')
        .length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),

        child: SafeArea(
          child: Column(
            children: [
              // ==================================================
              // HEADER
              // ==================================================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),

                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: textColor,
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: 5),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reports',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            'Review reports submitted by users',
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // ==================================================
              // SUMMARY
              // ==================================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),

                child: Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        context,
                        'Total Reports',
                        '${_reports.length}',
                        Icons.report_rounded,
                        AppTheme.primary,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _summaryCard(
                        context,
                        'Pending',
                        '$pendingReports',
                        Icons.pending_actions_rounded,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ==================================================
              // TITLE
              // ==================================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),

                child: Row(
                  children: [
                    Text(
                      'All Reports',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Spacer(),

                    Text(
                      '${_reports.length} reports',
                      style: TextStyle(color: subtitleColor, fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // REPORT LIST
              // ==================================================
              Expanded(
                child: _reports.isEmpty
                    ? _emptyState(context, textColor, subtitleColor)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),

                        itemCount: _reports.length,

                        itemBuilder: (context, index) {
                          return _reportCard(context, index, _reports[index]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // REPORT CARD
  // ==========================================================

  Widget _reportCard(
    BuildContext context,
    int index,
    Map<String, dynamic> report,
  ) {
    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);

    final isResolved = report['status'] == 'Resolved';

    return GestureDetector(
      onTap: () {
        _showReportDetails(index);
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 12),

        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: AppTheme.radius12,

          border: Border.all(color: subtitleColor.withOpacity(.08)),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ================================================
            // TOP ROW
            // ================================================
            Row(
              children: [
                Container(
                  height: 45,
                  width: 45,

                  decoration: BoxDecoration(
                    color: isResolved
                        ? Colors.green.withOpacity(.10)
                        : Colors.redAccent.withOpacity(.10),
                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: Icon(
                    isResolved
                        ? Icons.check_circle_rounded
                        : Icons.report_problem_rounded,
                    color: isResolved ? Colors.green : Colors.redAccent,
                    size: 23,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        report['reason'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Report ID: ${report['id']}',
                        style: TextStyle(color: subtitleColor, fontSize: 11),
                      ),
                    ],
                  ),
                ),

                _statusChip(context, report['status']),
              ],
            ),

            const SizedBox(height: 14),

            // ================================================
            // SONG / USER INFORMATION
            // ================================================
            Container(
              padding: const EdgeInsets.all(12),

              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),

              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 17,
                        color: subtitleColor,
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          report['userEmail'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: subtitleColor, fontSize: 12),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(
                        Icons.music_note_rounded,
                        size: 17,
                        color: subtitleColor,
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          report['songName'] == '-'
                              ? 'No song attached'
                              : '${report['songName']} (${report['songId']})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: subtitleColor, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ================================================
            // DATE + VIEW
            // ================================================
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 14, color: subtitleColor),

                const SizedBox(width: 5),

                Text(
                  report['date'],
                  style: TextStyle(color: subtitleColor, fontSize: 11),
                ),

                const Spacer(),

                Text(
                  'View Details',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(width: 4),

                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: AppTheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // SUMMARY CARD
  // ==========================================================

  Widget _summaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);

    return Container(
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: AppTheme.radius12,
        border: Border.all(color: subtitleColor.withOpacity(.08)),
      ),

      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,

            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(10),
            ),

            child: Icon(icon, color: color, size: 20),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  title,
                  style: TextStyle(color: subtitleColor, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // STATUS CHIP
  // ==========================================================

  Widget _statusChip(BuildContext context, String status) {
    Color color;

    switch (status) {
      case 'Resolved':
        color = Colors.green;
        break;

      case 'Reviewed':
        color = Colors.blue;
        break;

      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),

      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ==========================================================
  // DETAIL ROW
  // ==========================================================

  Widget _detailRow(BuildContext context, String label, String value) {
    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          SizedBox(
            width: 90,

            child: Text(
              label,
              style: TextStyle(color: subtitleColor, fontSize: 12),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // EMPTY STATE
  // ==========================================================

  Widget _emptyState(
    BuildContext context,
    Color textColor,
    Color subtitleColor,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Container(
            height: 80,
            width: 80,

            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(.10),
              shape: BoxShape.circle,
            ),

            child: Icon(
              Icons.report_off_rounded,
              color: AppTheme.primary,
              size: 38,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'No Reports',
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            'There are no reports submitted by users.',
            style: TextStyle(color: subtitleColor, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

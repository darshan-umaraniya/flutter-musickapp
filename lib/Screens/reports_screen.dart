import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final Set<String> _busyReports = {};
  final Set<String> _busySongs = {};

  String _date(dynamic value) {
    if (value is Timestamp) {
      final d = value.toDate().toLocal();
      final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
      final minute = d.minute.toString().padLeft(2, '0');
      final period = d.hour >= 12 ? 'PM' : 'AM';
      return '${d.day}/${d.month}/${d.year} $hour:$minute $period';
    }
    if (value is String && value.isNotEmpty) return value;
    return 'Date unavailable';
  }

  Future<void> _updateStatus(String id, String status) async {
    if (_busyReports.contains(id)) return;

    setState(() => _busyReports.add(id));

    try {
      await _db.collection('reports').doc(id).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report status updated to $status')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Status update failed: $e')));
    } finally {
      if (mounted) setState(() => _busyReports.remove(id));
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    String action = 'Confirm',
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppTheme.card(context),
            title: Text(title, style: TextStyle(color: AppTheme.text(context))),
            content: Text(
              message,
              style: TextStyle(color: AppTheme.subtitleColor(context)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(action),
              ),
            ],
          ),
        ) ??
        false;
  }

  // Block a reported Audius song in the app's removal collection.
  Future<void> _removeSong(String reportId, Map<String, dynamic> report) async {
    final songId = (report['songId'] ?? '').toString().trim();

    if (songId.isEmpty || songId == '-') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This report has no song ID.')),
      );
      return;
    }

    if (_busySongs.contains(songId)) return;

    final songName = (report['songName'] ?? 'Unknown song').toString();
    final artist = (report['artist'] ?? 'Unknown artist').toString();

    final confirmed = await _confirm(
      title: 'Remove song from Stresa?',
      message:
          'Song: $songName\nArtist: $artist\nSong ID: $songId\n\n'
          'The song ID will be saved to removedSongs, and this report '
          'will be marked Resolved.',
      action: 'Remove Song',
    );

    if (!confirmed || !mounted) return;

    setState(() => _busySongs.add(songId));

    try {
      await _db.collection('removedSongs').doc(songId).set({
        'songId': songId,
        'songName': songName,
        'artist': artist,
        'removed': true,
        'removedAt': FieldValue.serverTimestamp(),
        'sourceReportId': reportId,
      });

      await _db.collection('reports').doc(reportId).update({
        'status': 'Resolved',
        'resolution': 'Song removed from Stresa',
        'resolvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$songName removed; report marked Resolved.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not remove song: $e')));
    } finally {
      if (mounted) setState(() => _busySongs.remove(songId));
    }
  }

  Future<void> _deleteReport(String id) async {
    final confirmed = await _confirm(
      title: 'Delete report?',
      message:
          'This permanently deletes the report document. '
          'It does not remove the reported song.',
      action: 'Delete Report',
    );

    if (!confirmed || !mounted) return;

    try {
      await _db.collection('reports').doc(id).delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report deleted successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not delete report: $e')));
    }
  }

  void _showDetails(String id, Map<String, dynamic> report) {
    final status = (report['status'] ?? 'Pending').toString();
    final songId = (report['songId'] ?? '').toString();
    final hasSong = songId.isNotEmpty && songId != '-';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final textColor = AppTheme.text(sheetContext);
        final subtitleColor = AppTheme.subtitleColor(sheetContext);

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * .85,
          ),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppTheme.card(sheetContext),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Report Details',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: Icon(Icons.close, color: subtitleColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _detail(sheetContext, 'Report ID', id),
                  _detail(
                    sheetContext,
                    'Type',
                    (report['type'] ?? 'Song Report').toString(),
                  ),
                  _detail(
                    sheetContext,
                    'User ID',
                    (report['userId'] ?? '-').toString(),
                  ),
                  _detail(
                    sheetContext,
                    'User Name',
                    (report['userName'] ?? '-').toString(),
                  ),
                  _detail(
                    sheetContext,
                    'User Email',
                    (report['userEmail'] ?? '-').toString(),
                  ),
                  _detail(sheetContext, 'Song ID', hasSong ? songId : '-'),
                  _detail(
                    sheetContext,
                    'Song Name',
                    (report['songName'] ?? '-').toString(),
                  ),
                  _detail(
                    sheetContext,
                    'Artist',
                    (report['artist'] ?? '-').toString(),
                  ),
                  _detail(
                    sheetContext,
                    'Reason',
                    (report['reason'] ?? '-').toString(),
                  ),
                  _detail(sheetContext, 'Date', _date(report['date'])),
                  _detail(sheetContext, 'Current Status', status),
                  const SizedBox(height: 8),
                  Text('Description', style: TextStyle(color: subtitleColor)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: Theme.of(sheetContext).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (report['description'] ?? 'No description').toString(),
                      style: TextStyle(color: textColor, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Update Status',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _statusButton(sheetContext, id, 'Pending', Colors.orange),
                      _statusButton(sheetContext, id, 'Reviewed', Colors.blue),
                      _statusButton(sheetContext, id, 'Resolved', Colors.green),
                    ],
                  ),
                  if (hasSong) ...[
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _busySongs.contains(songId)
                            ? null
                            : () => _removeSong(id, report),
                        icon: const Icon(Icons.delete_forever_rounded),
                        label: Text(
                          _busySongs.contains(songId)
                              ? 'Removing Song...'
                              : 'Remove Song from Stresa',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await _deleteReport(id);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete Report Only'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statusButton(
    BuildContext sheetContext,
    String id,
    String status,
    Color color,
  ) {
    return OutlinedButton(
      onPressed: _busyReports.contains(id)
          ? null
          : () async {
              await _updateStatus(id, status);
              if (sheetContext.mounted) {
                Navigator.pop(sheetContext);
              }
            },
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(.6)),
      ),
      child: Text(status),
    );
  }

  Widget _detail(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.subtitleColor(context),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: AppTheme.text(context), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(BuildContext context, String status) {
    final color = switch (status.toLowerCase()) {
      'resolved' => Colors.green,
      'reviewed' => Colors.blue,
      _ => Colors.orange,
    };

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

  Widget _summary(
    BuildContext context,
    String label,
    int value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: AppTheme.radius12,
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    color: AppTheme.text(context),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.subtitleColor(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoLine(BuildContext context, IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.subtitleColor(context)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.subtitleColor(context),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 20, 15),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: textColor,
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
                          Text(
                            'Review reports and manage songs',
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _db.collection('reports').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Unable to load reports.\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: textColor),
                          ),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      );
                    }

                    final reports = snapshot.data?.docs.toList() ?? [];

                    reports.sort((a, b) {
                      final aDate = a.data()['date'];
                      final bDate = b.data()['date'];
                      final aTime = aDate is Timestamp
                          ? aDate.millisecondsSinceEpoch
                          : 0;
                      final bTime = bDate is Timestamp
                          ? bDate.millisecondsSinceEpoch
                          : 0;
                      return bTime.compareTo(aTime);
                    });

                    final pending = reports.where((doc) {
                      return (doc.data()['status'] ?? 'Pending') == 'Pending';
                    }).length;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: _summary(
                                  context,
                                  'Total Reports',
                                  reports.length,
                                  Icons.report_rounded,
                                  AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _summary(
                                  context,
                                  'Pending',
                                  pending,
                                  Icons.pending_actions_rounded,
                                  Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
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
                                '${reports.length} reports',
                                style: TextStyle(color: subtitleColor),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: reports.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.report_off_rounded,
                                        color: AppTheme.primary,
                                        size: 55,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No Reports',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    24,
                                  ),
                                  itemCount: reports.length,
                                  itemBuilder: (context, index) {
                                    final doc = reports[index];
                                    final report = doc.data();
                                    final status =
                                        (report['status'] ?? 'Pending')
                                            .toString();
                                    final songName = (report['songName'] ?? '-')
                                        .toString();
                                    final songId = (report['songId'] ?? '-')
                                        .toString();

                                    return GestureDetector(
                                      onTap: () => _showDetails(doc.id, report),
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        padding: const EdgeInsets.all(15),
                                        decoration: BoxDecoration(
                                          color: AppTheme.card(context),
                                          borderRadius: AppTheme.radius12,
                                          border: Border.all(
                                            color: subtitleColor.withOpacity(
                                              .08,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  status == 'Resolved'
                                                      ? Icons.check_circle
                                                      : Icons.report_problem,
                                                  color: status == 'Resolved'
                                                      ? Colors.green
                                                      : Colors.redAccent,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    (report['reason'] ??
                                                            'User report')
                                                        .toString(),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: textColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                _statusChip(context, status),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            _infoLine(
                                              context,
                                              Icons.person_outline,
                                              (report['userEmail'] ?? '-')
                                                  .toString(),
                                            ),
                                            const SizedBox(height: 8),
                                            _infoLine(
                                              context,
                                              Icons.music_note,
                                              songId.isEmpty || songId == '-'
                                                  ? 'No song attached'
                                                  : '$songName ($songId)',
                                            ),
                                            const SizedBox(height: 8),
                                            _infoLine(
                                              context,
                                              Icons.access_time,
                                              _date(report['date']),
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    'Tap to view actions',
                                                    style: TextStyle(
                                                      color: AppTheme.primary,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.arrow_forward_ios,
                                                  size: 12,
                                                  color: AppTheme.primary,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

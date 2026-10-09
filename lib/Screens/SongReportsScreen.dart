import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class SongReportsScreen extends StatelessWidget {
  const SongReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Song Reports')),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('reports').onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load reports.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final value = snapshot.data?.snapshot.value;

          if (value == null) {
            return const Center(child: Text('No song reports yet.'));
          }

          if (value is! Map) {
            return const Center(child: Text('Invalid report data.'));
          }

          final reports = <Map<String, dynamic>>[];

          for (final entry in value.entries) {
            if (entry.value is Map) {
              final report = Map<String, dynamic>.from(
                (entry.value as Map).map(
                  (key, value) => MapEntry(key.toString(), value),
                ),
              );

              report['_key'] = entry.key.toString();
              reports.add(report);
            }
          }

          reports.sort((a, b) {
            final aDate = int.tryParse(a['date']?.toString() ?? '') ?? 0;
            final bDate = int.tryParse(b['date']?.toString() ?? '') ?? 0;
            return bDate.compareTo(aDate);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final key = report['_key'] as String;

              final status = report['status']?.toString() ?? 'Pending';

              final dateValue = report['date'];
              String formattedDate = 'Unknown';

              if (dateValue is num) {
                formattedDate = DateTime.fromMillisecondsSinceEpoch(
                  dateValue.toInt(),
                ).toLocal().toString();
              } else if (dateValue != null) {
                formattedDate = dateValue.toString();
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.report_problem_rounded,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              report['songName']?.toString() ?? 'Unknown Song',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _detail('Artist', report['artist']),
                      _detail('Song ID', report['songId']),
                      _detail('Reported by', report['userName']),
                      _detail('Email', report['userEmail']),
                      _detail('User ID', report['userId']),
                      _detail('Reason', report['reason']),
                      _detail('Description', report['description']),
                      _detail('Date', formattedDate),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'Status:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButton<String>(
                              value:
                                  [
                                    'Pending',
                                    'Reviewed',
                                    'Resolved',
                                    'Rejected',
                                  ].contains(status)
                                  ? status
                                  : 'Pending',
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(
                                  value: 'Pending',
                                  child: Text('Pending'),
                                ),
                                DropdownMenuItem(
                                  value: 'Reviewed',
                                  child: Text('Reviewed'),
                                ),
                                DropdownMenuItem(
                                  value: 'Resolved',
                                  child: Text('Resolved'),
                                ),
                                DropdownMenuItem(
                                  value: 'Rejected',
                                  child: Text('Rejected'),
                                ),
                              ],
                              onChanged: (newStatus) async {
                                if (newStatus == null) return;

                                try {
                                  await FirebaseDatabase.instance
                                      .ref('reports/$key/status')
                                      .set(newStatus);

                                  if (!context.mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Status changed to $newStatus',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Could not update status: $e',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _detail(String label, dynamic value) {
    final text = value?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text('$label: ${text.isEmpty ? 'Not provided' : text}'),
    );
  }
}

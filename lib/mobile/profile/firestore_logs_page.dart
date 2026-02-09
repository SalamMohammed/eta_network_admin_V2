import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:eta_network_admin/services/firestore_monitor_service.dart';
import 'package:intl/intl.dart';

class FirestoreLogsPage extends StatelessWidget {
  const FirestoreLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportLogs(context),
            tooltip: 'Export CSV',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              FirestoreMonitorService().clearLogs();
            },
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: FirestoreMonitorService(),
        builder: (context, child) {
          final service = FirestoreMonitorService();
          final logs = service.logs;

          return Column(
            children: [
              _buildStatsHeader(service),
              const Divider(height: 1),
              Expanded(
                child: logs.isEmpty
                    ? const Center(child: Text('No logs yet'))
                    : ListView.builder(
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          return _buildLogItem(log);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader(FirestoreMonitorService service) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.withValues(alpha: 0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Reads', service.readCount, Colors.blue),
          _buildStatItem('Writes', service.writeCount, Colors.orange),
          _buildStatItem('Deletes', service.deleteCount, Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLogItem(FirestoreLog log) {
    Color color;
    IconData icon;
    switch (log.action) {
      case FirestoreAction.read:
        color = Colors.blue;
        icon = Icons.visibility;
        break;
      case FirestoreAction.write:
        color = Colors.orange;
        icon = Icons.edit;
        break;
      case FirestoreAction.delete:
        color = Colors.red;
        icon = Icons.delete_outline;
        break;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: SelectableText(
        log.path,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(log.details, style: const TextStyle(fontSize: 12)),
          Text(
            DateFormat('HH:mm:ss.SSS').format(log.timestamp),
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
          if (log.error != null)
            Text(
              'Error: ${log.error}',
              style: const TextStyle(color: Colors.red, fontSize: 11),
            ),
        ],
      ),
      dense: true,
    );
  }

  Future<void> _exportLogs(BuildContext context) async {
    final logs = FirestoreMonitorService().logs;
    if (logs.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No logs to export')));
      return;
    }

    try {
      final StringBuffer csv = StringBuffer();
      // Header
      csv.writeln('Timestamp,Action,Path,Details,Error');

      for (final log in logs) {
        final time = log.timestamp.toIso8601String();
        final action = log.action.toString().split('.').last;
        final path = _escapeCsv(log.path);
        final details = _escapeCsv(log.details);
        final error = log.error != null ? _escapeCsv(log.error.toString()) : '';

        csv.writeln('$time,$action,$path,$details,$error');
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/firestore_logs.csv');
      await file.writeAsString(csv.toString());

      // Use Share.shareXFiles
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)], text: 'Firestore Logs');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

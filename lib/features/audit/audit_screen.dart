// ignore_for_file: unused_element_parameter
import 'package:flutter/material.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';

/// Audit log view — spec §12.
/// Table/list view of audit log entries. Filter by role, search.
/// Role-1 sees own entries, Role-2 sees all. Export CSV button (Phase 2 stub).
class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  String _selectedRoleFilter = 'All';
  // In-memory entries for display; in production these come from AuditRepository
  final List<_AuditEntry> _entries = [];

  static const _roleFilters = ['All', 'Role-0', 'Role-1', 'Role-2'];

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedRoleFilter == 'All'
        ? _entries
        : _entries.where((e) => e.userRole == _selectedRoleFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV (Phase 2)',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV export coming in Phase 2')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'Filter: ',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                DropdownButton<String>(
                  value: _selectedRoleFilter,
                  items: _roleFilters.map((role) {
                    return DropdownMenuItem(value: role, child: Text(role));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedRoleFilter = value);
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Entries list
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No audit entries',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final entry = filtered[index];
                      return _AuditEntryTile(entry: entry);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// In-memory representation of an audit entry for display.
class _AuditEntry {
  final int id;
  final String userRole;
  final String action;
  final String? targetDevice;
  final String? detailBefore;
  final String? detailAfter;
  final DateTime createdAt;

  const _AuditEntry({
    required this.id,
    required this.userRole,
    required this.action,
    this.targetDevice,
    this.detailBefore,
    this.detailAfter,
    required this.createdAt,
  });
}

class _AuditEntryTile extends StatelessWidget {
  final _AuditEntry entry;

  const _AuditEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _roleColor(entry.userRole),
        radius: 16,
        child: Text(
          entry.userRole.replaceAll('Role-', 'R'),
          style: const TextStyle(fontSize: 11, color: Colors.white),
        ),
      ),
      title: Text(
        entry.action,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      subtitle: Text(
        '${entry.targetDevice ?? 'N/A'} • ${_formatTime(entry.createdAt)}',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: entry.detailAfter != null
          ? const Icon(Icons.chevron_right, color: AppColors.textSecondary)
          : null,
    );
  }

  Color _roleColor(String role) {
    return switch (role) {
      'Role-0' => AppColors.stale,
      'Role-1' => AppColors.warning,
      'Role-2' => AppColors.error,
      _ => AppColors.textSecondary,
    };
  }

  String _formatTime(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

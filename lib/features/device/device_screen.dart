import 'package:flutter/material.dart';
import 'package:ble_qos_app/core/capability/capability_model.dart';
import 'package:ble_qos_app/core/capability/capability_negotiator.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';
import 'dashboard/dashboard_tab.dart';
import 'control/control_tab.dart';
import 'ha/ha_tab.dart';
import 'admin/admin_tab.dart';

/// Capability-driven device screen — spec §5.
/// Builds TabBar dynamically from negotiated capabilities.
class DeviceScreen extends StatelessWidget {
  final String deviceId;
  final List<Capability> capabilities;
  final bool showControlTab;
  final bool showAdminTab;

  const DeviceScreen({
    super.key,
    required this.deviceId,
    this.capabilities = const [],
    this.showControlTab = false,
    this.showAdminTab = false,
  });

  @override
  Widget build(BuildContext context) {
    final result = CapabilityNegotiator.negotiate(capabilities);
    final tabs = <_TabEntry>[];

    // Add capability-driven tabs
    for (final tabLabel in result.enabledTabs) {
      final widget = _widgetForTab(tabLabel);
      if (widget != null) {
        tabs.add(_TabEntry(label: tabLabel, widget: widget));
      }
    }

    // Add permission-gated tabs (Control/Admin not from capabilities)
    if (showControlTab) {
      tabs.add(_TabEntry(
        label: 'Control',
        widget: ControlTab(deviceId: deviceId),
      ));
    }
    if (showAdminTab) {
      tabs.add(_TabEntry(
        label: 'Admin',
        widget: AdminTab(deviceId: deviceId),
      ));
    }

    if (tabs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(deviceId)),
        body: const Center(
          child: Text(
            'No compatible capabilities',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    if (tabs.length == 1) {
      return Scaffold(
        appBar: AppBar(title: Text(deviceId)),
        body: tabs.first.widget,
      );
    }

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(deviceId),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: tabs.map((t) => Tab(text: t.label)).toList(),
          ),
        ),
        body: TabBarView(
          children: tabs.map((t) => t.widget).toList(),
        ),
      ),
    );
  }

  Widget? _widgetForTab(String tabLabel) {
    return switch (tabLabel) {
      'Dashboard' => DashboardTab(deviceId: deviceId),
      'HA' => HaTab(deviceId: deviceId),
      'Roster' => _PlaceholderTab(label: 'Roster', deviceId: deviceId),
      'Sync' => _PlaceholderTab(label: 'Sync', deviceId: deviceId),
      'Demo' => _PlaceholderTab(label: 'Demo', deviceId: deviceId),
      _ => null,
    };
  }
}

class _TabEntry {
  final String label;
  final Widget widget;

  const _TabEntry({required this.label, required this.widget});
}

/// Placeholder for capability tabs not yet implemented.
class _PlaceholderTab extends StatelessWidget {
  final String label;
  final String deviceId;

  const _PlaceholderTab({required this.label, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$label (coming soon)',
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ble_qos_app/core/ble/ble_connector.dart';
import 'package:ble_qos_app/core/ble/ble_models.dart';
import 'package:ble_qos_app/core/capability/capability_model.dart';
import 'package:ble_qos_app/core/capability/capability_negotiator.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';
import 'package:ble_qos_app/core/providers/metrics_provider.dart';
import 'package:ble_qos_app/widgets/connection_state_indicator.dart';
import 'package:ble_qos_app/widgets/connection_error_screen.dart';
import 'dashboard/dashboard_tab.dart';
import 'control/control_tab.dart';
import 'ha/ha_tab.dart';
import 'admin/admin_tab.dart';

/// Capability-driven device screen with ConnectionStateIndicator — spec §5.
/// Builds TabBar dynamically from negotiated capabilities.
/// Watches BleConnectionState and shows error screen on disconnection.
class DeviceScreen extends ConsumerWidget {
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

  /// Build the common AppBar with ConnectionStateIndicator.
  AppBar _buildAppBar(BleConnectionState bleState, {PreferredSizeWidget? bottom}) {
    return AppBar(
      title: Text(deviceId),
      actions: [ConnectionStateIndicator(state: bleState)],
      bottom: bottom,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(bleConnectionStateProvider);
    // While stream hasn't emitted yet, check connector state directly
    final bleState = connectionState.valueOrNull ?? ref.read(bleConnectorProvider).state;

    // Show loading while connecting/handshaking
    if (bleState == BleConnectionState.connecting || bleState == BleConnectionState.handshaking) {
      return Scaffold(
        appBar: _buildAppBar(bleState),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show error screen if connection lost or errored
    if (bleState == BleConnectionState.error || bleState == BleConnectionState.disconnected) {
      return Scaffold(
        appBar: _buildAppBar(bleState),
        body: ConnectionErrorScreen(
          message: bleState == BleConnectionState.error
              ? 'Connection to device failed'
              : 'Device disconnected',
          onRetry: () {
            final reconnect = ref.read(bleReconnectProvider);
            reconnect.cancel(); // reset any previous backoff
            final connector = ref.read(bleConnectorProvider);
            connector.connect(deviceId);
          },
        ),
      );
    }

    // Start PING keep-alive to prevent firmware phone_idle timeout
    ref.watch(pingKeepAliveProvider);

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
        appBar: _buildAppBar(bleState),
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
        appBar: _buildAppBar(bleState),
        body: tabs.first.widget,
      );
    }

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: _buildAppBar(
          bleState,
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

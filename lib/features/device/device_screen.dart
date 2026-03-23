import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ble_qos_app/core/ble/ble_connector.dart';
import 'package:ble_qos_app/core/ble/ble_models.dart';
import 'package:ble_qos_app/core/capability/capability_negotiator.dart';
import 'package:ble_qos_app/core/capability/capability_reader.dart';
import 'package:ble_qos_app/core/capability/capability_registry.dart';
import 'package:ble_qos_app/core/capability/degradation_info.dart';
import 'package:ble_qos_app/core/auth/auth_session.dart';
import 'package:ble_qos_app/core/auth/permission_guard.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';
import 'package:ble_qos_app/core/providers/auth_provider.dart';
import 'package:ble_qos_app/core/providers/device_provider.dart';
import 'package:ble_qos_app/core/providers/metrics_provider.dart';
import 'package:ble_qos_app/widgets/connection_state_indicator.dart';
import 'package:ble_qos_app/widgets/connection_error_screen.dart';
import 'dashboard/dashboard_tab.dart';
import 'control/control_tab.dart';
import 'ha/ha_tab.dart';
import 'admin/admin_tab.dart';
import 'roster/ed_roster_tab.dart';

/// Capability-driven device screen with ConnectionStateIndicator — spec §5.
/// Builds TabBar dynamically from negotiated capabilities based on device role.
/// Watches BleConnectionState and shows error screen on disconnection.
class DeviceScreen extends ConsumerWidget {
  final String deviceId;
  final bool showControlTab;
  final bool showAdminTab;

  const DeviceScreen({
    super.key,
    required this.deviceId,
    this.showControlTab = false,
    this.showAdminTab = false,
  });

  /// Build the common AppBar with ConnectionStateIndicator.
  /// Shows device name instead of StableId (UUIDv4 is not user-friendly).
  AppBar _buildAppBar(BleConnectionState bleState, WidgetRef ref, {PreferredSizeWidget? bottom}) {
    final connDevice = ref.watch(connectedDeviceProvider);
    final title = connDevice?.name ?? deviceId;
    final fwVer = ref.watch(fwVersionProvider).valueOrNull;
    final devInfo = ref.watch(deviceInfoProvider).valueOrNull;
    final subtitle = [
      if (fwVer != null) 'FW ${fwVer.label}',
      if (devInfo != null) devInfo.uptimeLabel,
    ].join(' · ');
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          if (subtitle.isNotEmpty)
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
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
        appBar: _buildAppBar(bleState, ref),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show error screen if connection lost or errored
    if (bleState == BleConnectionState.error || bleState == BleConnectionState.disconnected) {
      return Scaffold(
        appBar: _buildAppBar(bleState, ref),
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

    // Get capabilities via GATT read → role fallback negotiation order
    final connDevice = ref.watch(connectedDeviceProvider);
    final capResult = ref.watch(capabilityNegotiationProvider);
    final result = capResult.valueOrNull ??
        CapabilityNegotiator.negotiate(
          CapabilityRegistry.fallbackForRole(connDevice?.role ?? 0),
        );
    final tabs = <_TabEntry>[];

    // Build degradation lookup for warning badges
    final degradationMap = <String, DegradationInfo>{};
    for (final d in result.degraded) {
      degradationMap[d.tabLabel] = d;
    }

    // Add capability-driven tabs (including degraded ones with warning badges)
    for (final tabLabel in result.enabledTabs) {
      final widget = _widgetForTab(tabLabel);
      if (widget != null) {
        tabs.add(_TabEntry(label: tabLabel, widget: widget));
      }
    }
    // Add degraded tabs with warning badge
    for (final d in result.degraded) {
      final widget = _widgetForTab(d.tabLabel);
      if (widget != null) {
        tabs.add(_TabEntry(
          label: '⚠ ${d.tabLabel}',
          widget: widget,
          degradation: d,
        ));
      }
    }

    // Add permission-gated tabs based on auth role (spec §3.2)
    final authRole = ref.watch(authSessionProvider).currentRole;
    if (showControlTab && PermissionGuard.canWrite(authRole, GattAction.ctrl)) {
      tabs.add(_TabEntry(
        label: 'Control',
        widget: ControlTab(deviceId: deviceId),
      ));
    }
    if (showAdminTab && authRole == AuthRole.engineer) {
      tabs.add(_TabEntry(
        label: 'Admin',
        widget: AdminTab(deviceId: deviceId),
      ));
    }

    if (tabs.isEmpty) {
      // Limited Mode: all caps incompatible or no caps at all
      return Scaffold(
        appBar: _buildAppBar(bleState, ref),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber, color: Colors.orange, size: 48),
              const SizedBox(height: 16),
              Text(
                result.isLimitedMode
                    ? 'Limited Mode — device capabilities incompatible'
                    : 'No compatible capabilities',
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              if (result.degraded.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...result.degraded.map((d) => Text(
                  d.message,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                )),
              ],
            ],
          ),
        ),
      );
    }

    if (tabs.length == 1) {
      return Scaffold(
        appBar: _buildAppBar(bleState, ref),
        body: tabs.first.widget,
      );
    }

    final session = ref.watch(authSessionProvider);

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: _buildAppBar(
          bleState,
          ref,
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: tabs.map((t) => Tab(
              child: t.degradation != null
                  ? Tooltip(
                      message: t.degradation!.message,
                      child: Text(t.label),
                    )
                  : Text(t.label),
            )).toList(),
          ),
        ),
        body: Column(
          children: [
            if (session.isWarning)
              _SessionWarningBanner(
                remainingSeconds: session.remainingSeconds,
                onLockNow: () => session.lockNow(),
              ),
            Expanded(
              child: TabBarView(
                children: tabs.map((t) => t.widget).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _widgetForTab(String tabLabel) {
    return switch (tabLabel) {
      'Dashboard' => DashboardTab(deviceId: deviceId),
      'HA' => HaTab(deviceId: deviceId),
      'Roster' => EdRosterTab(deviceId: deviceId),
      'Sync' => _PlaceholderTab(label: 'Sync', deviceId: deviceId),
      'Demo' => _PlaceholderTab(label: 'Demo', deviceId: deviceId),
      _ => null,
    };
  }
}

class _TabEntry {
  final String label;
  final Widget widget;
  final DegradationInfo? degradation;

  const _TabEntry({
    required this.label,
    required this.widget,
    this.degradation,
  });
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

/// Warning banner shown when engineer/maintenance session is about to expire.
class _SessionWarningBanner extends StatelessWidget {
  final int remainingSeconds;
  final VoidCallback onLockNow;

  const _SessionWarningBanner({
    required this.remainingSeconds,
    required this.onLockNow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.warning.withValues(alpha: 0.2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.timer, color: AppColors.warning, size: 18),
          const SizedBox(width: 8),
          Text(
            'Session expires in ${remainingSeconds}s',
            style: const TextStyle(color: AppColors.warning, fontSize: 13),
          ),
          const Spacer(),
          TextButton(
            onPressed: onLockNow,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.warning,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Lock Now'),
          ),
        ],
      ),
    );
  }
}

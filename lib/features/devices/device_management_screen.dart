import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/device_models.dart';
import '../../providers/app_providers.dart';
import '../../services/websocket_service.dart';
import '../../theme/app_colors.dart';
import '../pairing/pairing_discover_screen.dart';

class DeviceManagementScreen extends ConsumerWidget {
  const DeviceManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(pairedDevicesProvider);
    final activeDevice = ref.watch(activeDeviceProvider);
    final connectionStatus = ref.watch(connectionStatusProvider).value ?? ConnectionStatus.offline;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paired Devices'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add New PC', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PairingDiscoverScreen()),
          );
        },
      ),
      body: SafeArea(
        child: devices.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(0.12),
                        ),
                        child: const Icon(
                          Icons.devices_other_rounded,
                          size: 54,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'No Paired Devices',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pair your Windows PC to start controlling it remotely over your Wi-Fi network.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Pair a PC Now'),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PairingDiscoverScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: devices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final device = devices[index];
                  final isActive = activeDevice?.id == device.id;
                  final isOnline = isActive && connectionStatus == ConnectionStatus.connected;
                  final lastSeen = DateFormat('MMM d, h:mm a').format(device.lastConnected);

                  return Dismissible(
                    key: Key(device.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      alignment: Alignment.centerRight,
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Forget',
                            style: TextStyle(
                              color: AppColors.onErrorContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.delete_outline_rounded, color: AppColors.onErrorContainer),
                        ],
                      ),
                    ),
                    confirmDismiss: (dir) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Forget Device?'),
                          content: Text('Remove "${device.name}" from paired PCs?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Forget'),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) {
                      ref.read(pairedDevicesProvider.notifier).removeDevice(device.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Forgot ${device.name}')),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primaryContainer.withOpacity(0.12)
                            : AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive ? AppColors.primaryContainer : AppColors.outlineVariant,
                          width: isActive ? 1.5 : 0.8,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            device.type == DeviceType.laptop
                                ? Icons.laptop_windows_rounded
                                : Icons.desktop_windows_rounded,
                            color: AppColors.primary,
                            size: 26,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                device.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                            if (isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isOnline ? AppColors.tertiary : AppColors.outline,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isOnline ? 'Active' : 'Offline',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '${device.ip}:${device.port}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Last connected: $lastSeen',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.outline,
                              ),
                            ),
                          ],
                        ),
                        trailing: isActive && isOnline
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.tertiary)
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  ref.read(activeDeviceProvider.notifier).state = device;
                                  ref.read(pairedDevicesProvider.notifier).connectToDevice(device);
                                },
                                child: const Text('Connect'),
                              ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

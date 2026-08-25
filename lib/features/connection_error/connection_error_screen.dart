import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../services/websocket_service.dart';
import '../../theme/app_colors.dart';
import '../devices/device_management_screen.dart';

class ConnectionErrorScreen extends ConsumerStatefulWidget {
  const ConnectionErrorScreen({super.key});

  @override
  ConsumerState<ConnectionErrorScreen> createState() =>
      _ConnectionErrorScreenState();
}

class _ConnectionErrorScreenState extends ConsumerState<ConnectionErrorScreen> {
  bool _isRetrying = false;

  void _retryConnection() async {
    final activeDevice = ref.read(activeDeviceProvider);
    if (activeDevice == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DeviceManagementScreen()),
      );
      return;
    }

    setState(() => _isRetrying = true);
    final ws = ref.read(webSocketServiceProvider);
    final connected = await ws.connect(activeDevice);
    setState(() => _isRetrying = false);

    if (connected) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to ${activeDevice.name}'),
          backgroundColor: AppColors.tertiaryContainer,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection failed. Please check PC status.'),
          backgroundColor: AppColors.errorContainer,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeDevice = ref.watch(activeDeviceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Connection Offline'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const Spacer(),
              // Offline illustration icon
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.errorContainer.withOpacity(0.2),
                  border: Border.all(color: AppColors.error.withOpacity(0.6), width: 2),
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 56,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                activeDevice != null
                    ? 'Cannot Reach ${activeDevice.name}'
                    : 'No PC Connected',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                activeDevice != null
                    ? 'The connection to ${activeDevice.ip}:${activeDevice.port} was lost or refused.'
                    : 'Please select or pair a Windows PC to continue.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Checklist Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.outlineVariant, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Troubleshooting Checklist',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ChecklistItem(text: 'Ensure PCRemote companion is running on your PC'),
                    const SizedBox(height: 10),
                    _ChecklistItem(text: 'Verify both Phone and PC are on the same Wi-Fi network'),
                    const SizedBox(height: 10),
                    _ChecklistItem(text: 'Check Windows Firewall is not blocking port 8765'),
                  ],
                ),
              ),

              const Spacer(),

              // Retry Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isRetrying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(_isRetrying ? 'Reconnecting...' : 'Retry Connection'),
                  onPressed: _isRetrying ? null : _retryConnection,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const DeviceManagementScreen(),
                      ),
                    );
                  },
                  child: const Text('Switch or Pair PC'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final String text;

  const _ChecklistItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          color: AppColors.primary,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.3),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/device_models.dart';
import '../../providers/app_providers.dart';
import '../../services/discovery_service.dart';
import '../../theme/app_colors.dart';
import 'pairing_qr_scan_screen.dart';
import 'pairing_pin_screen.dart';
import 'pairing_success_screen.dart';

class PairingDiscoverScreen extends ConsumerStatefulWidget {
  const PairingDiscoverScreen({super.key});

  @override
  ConsumerState<PairingDiscoverScreen> createState() =>
      _PairingDiscoverScreenState();
}

class _PairingDiscoverScreenState extends ConsumerState<PairingDiscoverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController =
      TextEditingController(text: '8765');
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Start network scan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(discoveryServiceProvider).startDiscovery();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _connectToPC(PairedDevice device) async {
    setState(() => _isConnecting = true);
    final ws = ref.read(webSocketServiceProvider);
    final success = await ws.connect(device);
    setState(() => _isConnecting = false);

    if (success) {
      ref.read(activeDeviceProvider.notifier).state = device;
      await ref.read(pairedDevicesProvider.notifier).addDevice(device);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PairingSuccessScreen(device: device),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not connect to ${device.name} (${device.ip})'),
          backgroundColor: AppColors.errorContainer,
        ),
      );
    }
  }

  void _showManualIpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: const Text(
          'Connect via IP Address',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _ipController,
              keyboardType: TextInputType.datetime,
              decoration: InputDecoration(
                labelText: 'PC IP Address',
                hintText: 'e.g. 192.168.1.100',
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _portController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Port',
                hintText: '8765',
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final ip = _ipController.text.trim();
              final port = int.tryParse(_portController.text.trim()) ?? 8765;
              if (ip.isNotEmpty) {
                final device = PairedDevice(
                  id: 'pc_$ip',
                  name: 'Manual PC ($ip)',
                  ip: ip,
                  port: port,
                  lastConnected: DateTime.now(),
                );
                _connectToPC(device);
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final discovery = ref.watch(discoveryServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pair with PC'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Rescan Network',
            onPressed: () => discovery.startDiscovery(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // Radar scanning illustration
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 130 + (_pulseController.value * 50),
                          height: 130 + (_pulseController.value * 50),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryContainer
                                .withOpacity((1 - _pulseController.value) * 0.25),
                          ),
                        );
                      },
                    ),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceContainerHigh,
                        border: Border.all(
                          color: AppColors.primaryContainer.withOpacity(0.6),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.wifi_find_rounded,
                        size: 46,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Searching on Local Wi-Fi...',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ensure PCRemote companion is running on your Windows PC',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),

              // Discovered PCs list
              Expanded(
                child: StreamBuilder<List<DiscoveredPC>>(
                  stream: discovery.discoveredPCsStream,
                  builder: (context, snapshot) {
                    final pcs = snapshot.data ?? [];

                    if (_isConnecting) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: AppColors.primaryContainer),
                            SizedBox(height: 16),
                            Text('Connecting to PC...', style: TextStyle(color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                      );
                    }

                    if (pcs.isEmpty) {
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.outlineVariant, width: 0.8),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.devices_other_rounded,
                                size: 40,
                                color: AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No PCs detected yet',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Try scanning the QR code or enter the PIN shown on your PC',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                icon: const Icon(Icons.edit_road_rounded, size: 18),
                                label: const Text('Enter IP Manually'),
                                onPressed: _showManualIpDialog,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: pcs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final pc = pcs[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.outlineVariant, width: 0.8),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                pc.type == DeviceType.laptop
                                    ? Icons.laptop_windows_rounded
                                    : Icons.desktop_windows_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text(
                              pc.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              '${pc.ip}:${pc.port}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              onPressed: () => _connectToPC(pc.toPairedDevice()),
                              child: const Text('Connect'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Bottom Buttons: QR Scan and PIN Fallback
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('Scan QR'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PairingQrScanScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.pin_rounded),
                      label: const Text('Enter PIN'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PairingPinScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/device_models.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_colors.dart';
import 'pairing_pin_screen.dart';
import 'pairing_success_screen.dart';

class PairingQrScanScreen extends ConsumerStatefulWidget {
  const PairingQrScanScreen({super.key});

  @override
  ConsumerState<PairingQrScanScreen> createState() => _PairingQrScanScreenState();
}

class _PairingQrScanScreenState extends ConsumerState<PairingQrScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  bool _isProcessing = false;
  bool _isTorchOn = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      // Parse QR code payload (JSON or token formatted)
      // Example format: {"id":"pc_1","name":"Desktop-Office","ip":"192.168.1.100","port":8765,"token":"auth_token_xyz"}
      Map<String, dynamic> data;
      if (rawValue.startsWith('{')) {
        data = json.decode(rawValue) as Map<String, dynamic>;
      } else {
        // Assume raw IP:port:token format
        final parts = rawValue.split(':');
        data = {
          'id': 'pc_${parts[0]}',
          'name': 'Windows PC',
          'ip': parts[0],
          'port': parts.length > 1 ? int.tryParse(parts[1]) ?? 8765 : 8765,
          'token': parts.length > 2 ? parts[2] : null,
        };
      }

      final device = PairedDevice.fromMap(data);
      final ws = ref.read(webSocketServiceProvider);
      final connected = await ws.connect(device);

      if (connected) {
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
            content: Text('Failed to pair with ${device.ip}:${device.port}'),
            backgroundColor: AppColors.errorContainer,
          ),
        );
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid QR Code format'),
          backgroundColor: AppColors.errorContainer,
        ),
      );
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded),
            onPressed: () {
              _scannerController.toggleTorch();
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Camera View
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // Dark overlay with transparent center
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.65),
              BlendMode.srcOut,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Viewfinder Frame
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary, width: 2.5),
            ),
          ),

          // Instructions and PIN fallback
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Point your camera at the QR code on the PCRemote Windows app',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const PairingPinScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Or Enter 6-Digit PIN Manually',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}

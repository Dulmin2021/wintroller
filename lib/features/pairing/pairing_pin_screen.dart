import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/device_models.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_colors.dart';
import 'pairing_success_screen.dart';

class PairingPinScreen extends ConsumerStatefulWidget {
  final String? prefilledIp;

  const PairingPinScreen({super.key, this.prefilledIp});

  @override
  ConsumerState<PairingPinScreen> createState() => _PairingPinScreenState();
}

class _PairingPinScreenState extends ConsumerState<PairingPinScreen> {
  final TextEditingController _ipController = TextEditingController();
  final List<TextEditingController> _pinControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _ipController.text = widget.prefilledIp ?? '192.168.1.100';
  }

  @override
  void dispose() {
    _ipController.dispose();
    for (final c in _pinControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _pin => _pinControllers.map((c) => c.text).join();

  void _onPinDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_pin.length == 6) {
          _verifyAndPair();
        }
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
    setState(() => _errorMessage = null);
  }

  Future<void> _verifyAndPair() async {
    final ip = _ipController.text.trim();
    final pin = _pin;

    if (ip.isEmpty) {
      setState(() => _errorMessage = 'Please enter PC IP address');
      return;
    }

    if (pin.length < 6) {
      setState(() => _errorMessage = 'Please enter complete 6-digit PIN');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final device = PairedDevice(
      id: 'pc_$ip',
      name: 'Windows PC',
      ip: ip,
      port: 8765,
      lastConnected: DateTime.now(),
    );

    final ws = ref.read(webSocketServiceProvider);
    final connected = await ws.connect(device);

    if (!connected) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not reach PC at $ip:8765. Make sure PCRemote companion is running.';
      });
      return;
    }

    final repo = ref.read(pcRemoteRepositoryProvider);
    final response = await repo.verifyPin(pin);

    setState(() => _isLoading = false);

    if (response.success) {
      final token = response.data is Map ? response.data['token'] as String? : null;
      final hostName = response.data is Map ? response.data['name'] as String? ?? 'Windows PC' : 'Windows PC';

      final pairedPc = device.copyWith(name: hostName, token: token);
      ref.read(activeDeviceProvider.notifier).state = pairedPc;
      await ref.read(pairedDevicesProvider.notifier).addDevice(pairedPc);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PairingSuccessScreen(device: pairedPc),
        ),
      );
    } else {
      setState(() {
        _errorMessage = response.error ?? 'Invalid PIN. Please check the code on your PC screen.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Enter Pairing PIN'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.dialpad_rounded,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Enter 6-Digit PIN',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Look at the PCRemote window on your PC screen and enter the PIN shown there.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // PC IP Field
              TextField(
                controller: _ipController,
                keyboardType: TextInputType.datetime,
                style: const TextStyle(color: AppColors.onSurface),
                decoration: InputDecoration(
                  labelText: 'PC IP Address on Wi-Fi',
                  prefixIcon: const Icon(Icons.wifi_rounded, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.outlineVariant),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 6 PIN digit boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    height: 58,
                    child: TextField(
                      controller: _pinControllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.surfaceContainer,
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.outlineVariant),
                        ),
                      ),
                      onChanged: (val) => _onPinDigitChanged(index, val),
                    ),
                  );
                }),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.onErrorContainer, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isLoading ? null : _verifyAndPair,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Verify & Connect',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_colors.dart';

class KeyboardControlScreen extends ConsumerStatefulWidget {
  const KeyboardControlScreen({super.key});

  @override
  ConsumerState<KeyboardControlScreen> createState() =>
      _KeyboardControlScreenState();
}

class _KeyboardControlScreenState extends ConsumerState<KeyboardControlScreen> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _sendLive = true;
  String _lastText = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _triggerHaptic() {
    if (ref.read(hapticsProvider)) {
      HapticFeedback.lightImpact();
    }
  }

  void _onTextChanged(String newText) {
    if (!_sendLive) return;

    final repo = ref.read(pcRemoteRepositoryProvider);

    if (newText.length > _lastText.length) {
      // User typed new characters
      final added = newText.substring(_lastText.length);
      repo.sendKeyboardType(added);
    } else if (newText.length < _lastText.length) {
      // User pressed backspace
      final count = _lastText.length - newText.length;
      for (int i = 0; i < count; i++) {
        repo.sendKeyboardKey('backspace');
      }
    }
    _lastText = newText;
  }

  void _sendManualSubmit() {
    final text = _inputController.text;
    if (text.isNotEmpty) {
      final repo = ref.read(pcRemoteRepositoryProvider);
      repo.sendKeyboardType(text);
      _inputController.clear();
      _lastText = '';
      _triggerHaptic();
    }
  }

  void _sendSpecialKey(String keycode) {
    _triggerHaptic();
    ref.read(pcRemoteRepositoryProvider).sendKeyboardKey(keycode);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Keyboard Remote'),
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard_outlined),
            tooltip: 'Toggle Soft Keyboard',
            onPressed: () {
              if (_focusNode.hasFocus) {
                _focusNode.unfocus();
              } else {
                _focusNode.requestFocus();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mode Toggle (Live vs Batch Submit)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineVariant, width: 0.8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bolt_rounded, color: AppColors.keyboardAccent, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Send as you type',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _sendLive,
                      activeColor: AppColors.keyboardAccent,
                      onChanged: (val) {
                        setState(() {
                          _sendLive = val;
                          _inputController.clear();
                          _lastText = '';
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Active Text Input Area
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.outlineVariant, width: 0.8),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _inputController,
                      focusNode: _focusNode,
                      maxLines: 3,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: _sendLive
                            ? 'Tap here & type to send keystrokes live...'
                            : 'Type text here, then tap Send to PC...',
                        hintStyle: TextStyle(
                          color: AppColors.onSurfaceVariant.withOpacity(0.6),
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: _onTextChanged,
                      onSubmitted: (_) {
                        if (!_sendLive) {
                          _sendManualSubmit();
                        }
                      },
                    ),
                    if (!_sendLive) ...[
                      const Divider(color: AppColors.outlineVariant),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.keyboardAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          ),
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: const Text('Send to PC'),
                          onPressed: _sendManualSubmit,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Quick Function Keys',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              // Special Keys - Row 1
              Row(
                children: [
                  Expanded(child: _KeyButton(label: 'Esc', onTap: () => _sendSpecialKey('escape'))),
                  const SizedBox(width: 8),
                  Expanded(child: _KeyButton(label: 'Tab', onTap: () => _sendSpecialKey('tab'))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KeyButton(
                      label: 'Win ⊞',
                      isAccent: true,
                      onTap: () => _sendSpecialKey('win'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _KeyButton(label: 'Ctrl', onTap: () => _sendSpecialKey('ctrl'))),
                  const SizedBox(width: 8),
                  Expanded(child: _KeyButton(label: 'Alt', onTap: () => _sendSpecialKey('alt'))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KeyButton(
                      label: 'Del',
                      isDestructive: true,
                      onTap: () => _sendSpecialKey('delete'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Special Keys - Row 2
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _KeyButton(
                      label: 'Backspace ⌫',
                      onTap: () => _sendSpecialKey('backspace'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: _KeyButton(
                      label: 'Space',
                      onTap: () => _sendSpecialKey('space'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: _KeyButton(
                      label: 'Enter ↵',
                      isAccent: true,
                      onTap: () => _sendSpecialKey('enter'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                'Navigation D-Pad',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 14),

              // Arrow Keys D-Pad
              Center(
                child: SizedBox(
                  width: 220,
                  child: Column(
                    children: [
                      _KeyButton(
                        label: '▲ Up',
                        onTap: () => _sendSpecialKey('up'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _KeyButton(
                              label: '◀ Left',
                              onTap: () => _sendSpecialKey('left'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _KeyButton(
                              label: '▼ Down',
                              onTap: () => _sendSpecialKey('down'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _KeyButton(
                              label: 'Right ▶',
                              onTap: () => _sendSpecialKey('right'),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isAccent;
  final bool isDestructive;

  const _KeyButton({
    required this.label,
    required this.onTap,
    this.isAccent = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.surfaceContainerHigh;
    Color fg = AppColors.onSurface;

    if (isAccent) {
      bg = AppColors.keyboardAccent.withOpacity(0.2);
      fg = AppColors.keyboardAccent;
    } else if (isDestructive) {
      bg = AppColors.errorContainer.withOpacity(0.3);
      fg = AppColors.error;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isAccent
                  ? AppColors.keyboardAccent.withOpacity(0.5)
                  : isDestructive
                      ? AppColors.error.withOpacity(0.5)
                      : AppColors.outlineVariant,
              width: 0.8,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

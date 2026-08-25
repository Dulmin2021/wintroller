import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_providers.dart';
import '../../services/websocket_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/alien_icons.dart';
import '../../widgets/hud_frame.dart';
import '../settings/settings_screen.dart';

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
      final added = newText.substring(_lastText.length);
      repo.sendKeyboardType(added);
    } else if (newText.length < _lastText.length) {
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
    final colors = AppColors.of(context);
    final themeStyle = ref.watch(themeStyleProvider);
    final isAlienHud = themeStyle == AppThemeStyle.alienHud;
    final connectionStatus = ref.watch(connectionStatusProvider).value ?? ConnectionStatus.offline;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.onSurface, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 6),
                  if (isAlienHud) const AlienEmblem(size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WINTROLLER',
                          style: isAlienHud
                              ? GoogleFonts.orbitron(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: colors.primary,
                                  letterSpacing: 2.0,
                                )
                              : TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: colors.onSurface,
                                ),
                        ),
                        Text(
                          isAlienHud ? 'ALIEN REMOTE INTERFACE' : 'Keyboard Controller',
                          style: isAlienHud
                              ? GoogleFonts.orbitron(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: colors.primary.withOpacity(0.7),
                                  letterSpacing: 1.5,
                                )
                              : TextStyle(
                                  fontSize: 12,
                                  color: colors.onSurfaceVariant,
                                ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.primary, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: connectionStatus == ConnectionStatus.connected
                                ? colors.primary
                                : colors.error,
                            boxShadow: [
                              BoxShadow(color: colors.primary.withOpacity(0.8), blurRadius: 4),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          connectionStatus == ConnectionStatus.connected ? 'CONNECTED' : 'OFFLINE',
                          style: GoogleFonts.orbitron(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: connectionStatus == ConnectionStatus.connected
                                ? colors.primary
                                : colors.error,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Breadcrumb Path
            if (isAlienHud)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '> SYS_CTRL  /  KEYBOARD_INPUT',
                    style: GoogleFonts.shareTechMono(
                      fontSize: 12,
                      color: colors.primary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Terminal IN_BUF HUD Card
                    if (isAlienHud)
                      HudFrame(
                        chamferSize: 14,
                        borderColor: colors.primary,
                        backgroundColor: colors.surfaceContainer,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'IN_BUF',
                              style: GoogleFonts.shareTechMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: colors.onSurfaceVariant,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '\$ sys.execute("',
                                  style: GoogleFonts.shareTechMono(
                                    fontSize: 15,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _inputController,
                                    focusNode: _focusNode,
                                    style: GoogleFonts.shareTechMono(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: colors.primary,
                                    ),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      hintText: 'type command...',
                                      hintStyle: GoogleFonts.shareTechMono(
                                        fontSize: 14,
                                        color: colors.primary.withOpacity(0.3),
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    onChanged: _onTextChanged,
                                    onSubmitted: (_) => _sendManualSubmit(),
                                  ),
                                ),
                                Container(
                                  width: 8,
                                  height: 18,
                                  color: colors.primary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Divider(color: colors.outlineVariant, height: 1),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'STATUS: READY',
                                  style: GoogleFonts.shareTechMono(
                                    fontSize: 11,
                                    color: colors.onSurfaceVariant,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _sendManualSubmit,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: colors.primary.withOpacity(0.12),
                                      border: Border.all(color: colors.primary, width: 0.8),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'SEND CMD [ENTER]',
                                      style: GoogleFonts.shareTechMono(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: colors.primary,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colors.outlineVariant, width: 0.8),
                        ),
                        child: TextField(
                          controller: _inputController,
                          focusNode: _focusNode,
                          maxLines: 2,
                          style: TextStyle(fontSize: 16, color: colors.onSurface),
                          decoration: InputDecoration(
                            hintText: 'Tap here to type keystrokes...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: colors.onSurfaceVariant.withOpacity(0.6)),
                          ),
                          onChanged: _onTextChanged,
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Section Divider: TACTICAL MACROS
                    Center(
                      child: Row(
                        children: [
                          Expanded(child: Container(height: 1, color: colors.primary.withOpacity(0.35))),
                          const SizedBox(width: 12),
                          Text(
                            isAlienHud ? 'TACTICAL MACROS' : 'Quick Function Keys',
                            style: isAlienHud
                                ? GoogleFonts.orbitron(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: colors.primary,
                                    letterSpacing: 1.4,
                                  )
                                : TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.onSurface),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Container(height: 1, color: colors.primary.withOpacity(0.35))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Row 1: ESC, TAB, BACKSPACE
                    Row(
                      children: [
                        Expanded(child: _AlienKeyTile(label: 'ESC', onTap: () => _sendSpecialKey('escape'))),
                        const SizedBox(width: 8),
                        Expanded(child: _AlienKeyTile(label: 'TAB', onTap: () => _sendSpecialKey('tab'))),
                        const SizedBox(width: 8),
                        Expanded(child: _AlienKeyTile(label: 'BACKSPACE', onTap: () => _sendSpecialKey('backspace'))),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Row 2: CTRL, WIN, ALT, DEL
                    Row(
                      children: [
                        Expanded(child: _AlienKeyTile(label: 'CTRL', onTap: () => _sendSpecialKey('ctrl'))),
                        const SizedBox(width: 8),
                        Expanded(child: _AlienKeyTile(label: 'WIN', onTap: () => _sendSpecialKey('win'))),
                        const SizedBox(width: 8),
                        Expanded(child: _AlienKeyTile(label: 'ALT', onTap: () => _sendSpecialKey('alt'))),
                        const SizedBox(width: 8),
                        Expanded(child: _AlienKeyTile(label: 'DEL', isDestructive: true, onTap: () => _sendSpecialKey('delete'))),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Row 3 & 4: Navigation Cluster and Wide Space / Enter
                    Row(
                      children: [
                        // Left: Arrow Keys
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Spacer(),
                                  Expanded(
                                    flex: 2,
                                    child: _AlienKeyTile(label: '^', onTap: () => _sendSpecialKey('up')),
                                  ),
                                  const Spacer(),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(child: _AlienKeyTile(label: '<', onTap: () => _sendSpecialKey('left'))),
                                  const SizedBox(width: 6),
                                  Expanded(child: _AlienKeyTile(label: 'v', onTap: () => _sendSpecialKey('down'))),
                                  const SizedBox(width: 6),
                                  Expanded(child: _AlienKeyTile(label: '>', onTap: () => _sendSpecialKey('right'))),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Right: SPACE and ENTER
                        Expanded(
                          flex: 6,
                          child: Column(
                            children: [
                              _AlienKeyTile(
                                label: 'SPACE',
                                onTap: () => _sendSpecialKey('space'),
                              ),
                              const SizedBox(height: 6),
                              _AlienKeyTile(
                                label: 'ENTER',
                                isPrimary: true,
                                onTap: () => _sendSpecialKey('enter'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom Sci-Fi Cybernetic Dock
            if (isAlienHud)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: HudFrame(
                  chamferSize: 14,
                  borderColor: colors.primary,
                  backgroundColor: colors.surfaceContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: HudRadarCircle(
                          size: 24,
                          color: colors.primary,
                          child: Icon(Icons.gps_fixed_rounded, color: colors.primary, size: 12),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      // Selected Alien Keyboard Active Core
                      GestureDetector(
                        onTap: () {
                          if (_focusNode.hasFocus) {
                            _focusNode.unfocus();
                          } else {
                            _focusNode.requestFocus();
                          }
                        },
                        child: HudRadarCircle(
                          size: 44,
                          color: colors.primary,
                          child: Icon(Icons.keyboard_rounded, color: colors.primary, size: 24),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.play_arrow_rounded, color: colors.primary, size: 24),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(Icons.bar_chart_rounded, color: colors.primary, size: 24),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(Icons.settings_outlined, color: colors.primary, size: 24),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AlienKeyTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isDestructive;

  const _AlienKeyTile({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    Color border = colors.primary.withOpacity(0.65);
    Color fg = colors.primary;
    Color bg = colors.surfaceContainer;

    if (isPrimary) {
      border = colors.primary;
      bg = colors.primary.withOpacity(0.2);
    } else if (isDestructive) {
      border = colors.error.withOpacity(0.8);
      fg = colors.error;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        splashColor: colors.primary.withOpacity(0.3),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: border, width: 0.9),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.orbitron(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: fg,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

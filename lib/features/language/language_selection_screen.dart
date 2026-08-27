import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../services/language_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../pro/plan_selection_screen.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  final bool isInitialOnboarding;

  const LanguageSelectionScreen({
    super.key,
    this.isInitialOnboarding = false,
  });

  @override
  ConsumerState<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends ConsumerState<LanguageSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  late String _selectedCode;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedCode = ref.read(languageProvider).languageCode;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onConfirmLanguage() async {
    HapticFeedback.mediumImpact();
    await ref.read(languageProvider.notifier).setLanguage(_selectedCode);
    final storage = ref.read(storageServiceProvider);
    await storage.setLanguageSelected(true);

    if (!mounted) return;

    if (widget.isInitialOnboarding) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const PlanSelectionScreen(isInitialOnboarding: true),
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final langCode = _selectedCode;

    final filteredLanguages = supportedLanguages.where((lang) {
      final query = _searchQuery.toLowerCase();
      return lang.name.toLowerCase().contains(query) ||
          lang.nativeName.toLowerCase().contains(query) ||
          lang.country.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1326),
        elevation: 0,
        leading: widget.isInitialOnboarding
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFADC6FF), size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: Text(
          'Wintroller',
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFADC6FF),
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  Text(
                    AppStrings.get('select_language', langCode),
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFDAE2FD),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.get('select_language_subtitle', langCode),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFFC2C6D6),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(color: Colors.white),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                },
                decoration: InputDecoration(
                  hintText: AppStrings.get('search_languages', langCode),
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF8C909F), fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFADC6FF)),
                  filled: true,
                  fillColor: const Color(0xFF171F33),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF424754)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF424754)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFADC6FF), width: 1.5),
                  ),
                ),
              ),
            ),

            // Languages Grid List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: filteredLanguages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final lang = filteredLanguages[index];
                  final isSelected = lang.code == _selectedCode;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedCode = lang.code;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF222A3D) : const Color(0xFF131B2E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFADC6FF) : const Color(0xFF2D3449),
                          width: isSelected ? 1.8 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFADC6FF).withOpacity(0.15),
                                  blurRadius: 12,
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          // Flag Circle
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF222A3D),
                              border: Border.all(color: const Color(0xFF424754), width: 0.8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              lang.flagEmoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.nativeName,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? const Color(0xFFADC6FF) : const Color(0xFFDAE2FD),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${lang.name} • ${lang.country}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF8C909F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFFADC6FF),
                              size: 22,
                            )
                          else
                            const Icon(
                              Icons.radio_button_unchecked_rounded,
                              color: Color(0xFF424754),
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Continue Floating Action Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFADC6FF),
                    foregroundColor: const Color(0xFF002E6A),
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _onConfirmLanguage,
                  child: Text(
                    AppStrings.get('continue', langCode),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

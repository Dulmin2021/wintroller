import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../services/language_service.dart';

class ContactUsScreen extends ConsumerStatefulWidget {
  const ContactUsScreen({super.key});

  @override
  ConsumerState<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends ConsumerState<ContactUsScreen> {
  final TextEditingController _messageController = TextEditingController();
  String _selectedSubject = 'bug';
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendFeedback() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your feedback message.'),
          backgroundColor: Color(0xFF93000A),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isSending = true;
    });

    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    final langCode = ref.read(languageProvider).languageCode;
    _messageController.clear();
    setState(() {
      _isSending = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF00FF66), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppStrings.get('feedback_sent', langCode),
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF131B2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final langCode = ref.watch(languageProvider).languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1326),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFADC6FF), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppStrings.get('contact_support', langCode),
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFADC6FF),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131B2E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF424754), width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subject Label
                        Text(
                          AppStrings.get('subject', langCode),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFC2C6D6),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subject Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF222A3D),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF424754)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedSubject,
                              dropdownColor: const Color(0xFF222A3D),
                              icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFFADC6FF)),
                              isExpanded: true,
                              style: GoogleFonts.inter(color: const Color(0xFFDAE2FD), fontSize: 14),
                              items: [
                                DropdownMenuItem(
                                  value: 'bug',
                                  child: Text(AppStrings.get('bug_report', langCode)),
                                ),
                                DropdownMenuItem(
                                  value: 'feature',
                                  child: Text(AppStrings.get('feature_request', langCode)),
                                ),
                                DropdownMenuItem(
                                  value: 'general',
                                  child: Text(AppStrings.get('general_feedback', langCode)),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedSubject = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Message Label
                        Text(
                          AppStrings.get('message', langCode),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFC2C6D6),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Message Input
                        TextField(
                          controller: _messageController,
                          maxLines: 6,
                          style: GoogleFonts.inter(color: const Color(0xFFDAE2FD), fontSize: 14),
                          decoration: InputDecoration(
                            hintText: AppStrings.get('describe_issue', langCode),
                            hintStyle: GoogleFonts.inter(color: const Color(0xFF8C909F), fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFF222A3D),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF424754)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF424754)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFADC6FF), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Send Feedback Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFADC6FF),
                              foregroundColor: const Color(0xFF002E6A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 6,
                            ),
                            onPressed: _isSending ? null : _sendFeedback,
                            child: _isSending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF002E6A)),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.send_rounded, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        AppStrings.get('send_feedback', langCode),
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Your feedback directly shapes future Wintroller releases.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF8C909F),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

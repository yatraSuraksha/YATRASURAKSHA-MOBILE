import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yatra_suraksha_app/l10n/app_localizations.dart';
import '../../const/app_colors.dart';
import '../../backend/providers/document_selection_provider.dart';
import '../../backend/providers/verification_method_provider.dart';
import 'verification_method_page.dart';

class DocumentSelectionPage extends StatefulWidget {
  const DocumentSelectionPage({super.key});

  @override
  State<DocumentSelectionPage> createState() => _DocumentSelectionPageState();
}

class _DocumentSelectionPageState extends State<DocumentSelectionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Header Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.identityVerification ??
                              'Identity Verification',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppLocalizations.of(context)
                                  ?.chooseIdentityDocument ??
                              'Choose your identity document to begin the secure verification process',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.secondaryText,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Content Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Document Options
                        _buildDocumentCard(
                          type: 'aadhaar',
                          title: AppLocalizations.of(context)?.aadhaarCard ??
                              'Aadhaar Card',
                          subtitle: AppLocalizations.of(context)
                                  ?.indianNationalIdentityCard ??
                              'Indian National Identity Card',
                          description: AppLocalizations.of(context)
                                  ?.governmentIssued12DigitId ??
                              'Government-issued 12-digit unique identification',
                          icon: Icons.credit_card_rounded,
                          features: [
                            AppLocalizations.of(context)?.quickVerification ??
                                'Quick Verification',
                            AppLocalizations.of(context)?.otpBased ??
                                'OTP Based',
                            AppLocalizations.of(context)?.instantResults ??
                                'Instant Results'
                          ],
                        ),

                        const SizedBox(height: 24),

                        _buildDocumentCard(
                          type: 'passport',
                          title: AppLocalizations.of(context)?.passport ??
                              'Passport',
                          subtitle: AppLocalizations.of(context)
                                  ?.internationalTravelDocument ??
                              'International Travel Document',
                          description: AppLocalizations.of(context)
                                  ?.governmentIssuedTravelDocument ??
                              'Government-issued travel and identity document',
                          icon: Icons.menu_book_rounded,
                          features: [
                            AppLocalizations.of(context)?.globalRecognition ??
                                'Global Recognition',
                            AppLocalizations.of(context)?.photoVerification ??
                                'Photo Verification',
                            AppLocalizations.of(context)?.secure ?? 'Secure'
                          ],
                        ),

                        const SizedBox(height: 50),

                        // Continue Button
                        Consumer<DocumentSelectionProvider>(
                          builder: (context, provider, child) {
                            return provider.hasSelection
                                ? AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _navigateToVerificationMethod,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        elevation: 4,
                                        shadowColor:
                                            AppColors.primary.withOpacity(0.3),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            AppLocalizations.of(context)
                                                    ?.continueButton ??
                                                'Continue',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                              Icons.arrow_forward_rounded),
                                        ],
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink();
                          },
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCard({
    required String type,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required List<String> features,
  }) {
    return Consumer<DocumentSelectionProvider>(
      builder: (context, provider, child) {
        final isSelected = provider.isDocumentSelected(type);

        return GestureDetector(
          onTap: () {
            provider.selectDocumentType(type);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withAlpha(20)
                  : AppColors.grey50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.grey300,
                width: 0.7,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon Container
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.primary : AppColors.grey300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: 28,
                        color:
                            isSelected ? Colors.white : AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Title and Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Description
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.secondaryText,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 16),

                // Features
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: features
                      .map((feature) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.grey200,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              feature,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? AppColors.white
                                    : AppColors.secondaryText,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToVerificationMethod() {
    final provider =
        Provider.of<DocumentSelectionProvider>(context, listen: false);
    final verificationProvider =
        Provider.of<VerificationMethodProvider>(context, listen: false);

    if (provider.selectedDocumentType != null) {
      verificationProvider.setDocumentType(provider.selectedDocumentType!);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerificationMethodPage(
            documentType: provider.selectedDocumentType!,
          ),
        ),
      );
    }
  }
}

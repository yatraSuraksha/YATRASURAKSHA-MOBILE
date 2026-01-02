import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yatra_suraksha_app/l10n/app_localizations.dart';
import '../../const/app_colors.dart';
import '../../backend/providers/verification_method_provider.dart';
import '../../backend/providers/document_input_provider.dart';
import 'document_input_page.dart';

class VerificationMethodPage extends StatefulWidget {
  final String documentType;

  const VerificationMethodPage({
    super.key,
    required this.documentType,
  });

  @override
  State<VerificationMethodPage> createState() => _VerificationMethodPageState();
}

class _VerificationMethodPageState extends State<VerificationMethodPage>
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

    // Set document type in provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VerificationMethodProvider>(context, listen: false)
          .setDocumentType(widget.documentType);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VerificationMethodProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.primaryText,
            elevation: 0,
            title: Text(
              '${provider.documentDisplayName} Verification',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            centerTitle: true,
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)
                                    ?.howWouldYouLikeToVerify ??
                                'How would you like to verify?',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)
                                    ?.pickMethodThatWorksBest ??
                                'Pick the method that works best for you',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.secondaryText,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Method Cards
                          _buildMethodCard(
                            method: 'manual',
                            title: _getMethodTitle('manual'),
                            subtitle: _getMethodSubtitle('manual'),
                            description:
                                provider.getMethodDescription('manual'),
                            icon: Icons.keyboard_rounded,
                            color: AppColors.info,
                            features: _getMethodFeatures('manual'),
                            estimatedTime: _getMethodEstimatedTime('manual'),
                          ),

                          const SizedBox(height: 20),

                          _buildMethodCard(
                            method: 'scan',
                            title: _getMethodTitle('scan'),
                            subtitle: _getMethodSubtitle('scan'),
                            description: provider.getMethodDescription('scan'),
                            icon: Icons.camera_alt_rounded,
                            color: AppColors.warning,
                            features: _getMethodFeatures('scan'),
                            estimatedTime: _getMethodEstimatedTime('scan'),
                          ),

                          const SizedBox(height: 20),

                          _buildMethodCard(
                            method: 'upload',
                            title: _getMethodTitle('upload'),
                            subtitle: _getMethodSubtitle('upload'),
                            description:
                                provider.getMethodDescription('upload'),
                            icon: Icons.photo_library_rounded,
                            color: AppColors.success,
                            features: _getMethodFeatures('upload'),
                            estimatedTime: _getMethodEstimatedTime('upload'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Continue Button
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: provider.hasSelection
                        ? SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _navigateToDocumentInput,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                  Icon(Icons.arrow_forward_rounded),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMethodCard({
    required String method,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color color,
    required List<String> features,
    required String estimatedTime,
  }) {
    return Consumer<VerificationMethodProvider>(
      builder: (context, provider, child) {
        final isSelected = provider.isMethodSelected(method);

        return GestureDetector(
          onTap: () {
            provider.selectMethod(method);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.1) : AppColors.grey50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? color : AppColors.grey300,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Icon Container
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? color : AppColors.grey300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: 24,
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? color : AppColors.primaryText,
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

                const SizedBox(height: 14),

                // Description
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.secondaryText,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 14),

                // Features and Time
                Row(
                  children: [
                    // Features
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: features
                            .map((feature) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color.withOpacity(0.2)
                                        : AppColors.grey200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    feature,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? color
                                          : AppColors.secondaryText,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),

                    // Estimated Time
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            estimatedTime,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToDocumentInput() {
    final verificationProvider =
        Provider.of<VerificationMethodProvider>(context, listen: false);
    final documentInputProvider =
        Provider.of<DocumentInputProvider>(context, listen: false);

    if (verificationProvider.selectedMethod != null) {
      documentInputProvider.setDocumentType(widget.documentType);
      documentInputProvider
          .setVerificationMethod(verificationProvider.selectedMethod!);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentInputPage(
            documentType: widget.documentType,
            verificationMethod: verificationProvider.selectedMethod!,
          ),
        ),
      );
    }
  }

  String _getMethodTitle(String method) {
    switch (method) {
      case 'manual':
        return AppLocalizations.of(context)?.manualEntry ?? 'Manual Entry';
      case 'scan':
        return AppLocalizations.of(context)?.documentScanner ??
            'Document Scanner';
      case 'upload':
        return AppLocalizations.of(context)?.uploadPhoto ?? 'Upload Photo';
      default:
        return '';
    }
  }

  String _getMethodSubtitle(String method) {
    switch (method) {
      case 'manual':
        return AppLocalizations.of(context)?.typeDocumentNumber ??
            'Type your document number';
      case 'scan':
        return AppLocalizations.of(context)?.useCameraToScan ??
            'Use camera to scan document';
      case 'upload':
        return AppLocalizations.of(context)?.chooseFromGallery ??
            'Choose from gallery';
      default:
        return '';
    }
  }

  List<String> _getMethodFeatures(String method) {
    switch (method) {
      case 'manual':
        return [
          AppLocalizations.of(context)?.quickAndEasy ?? 'Quick & Easy',
          AppLocalizations.of(context)?.noCameraRequired ??
              'No Camera Required',
          AppLocalizations.of(context)?.instant ?? 'Instant'
        ];
      case 'scan':
        return [
          AppLocalizations.of(context)?.autoDetect ?? 'Auto-Detect',
          AppLocalizations.of(context)?.realTimeProcessing ??
              'Real-time Processing',
          AppLocalizations.of(context)?.highAccuracy ?? 'High Accuracy'
        ];
      case 'upload':
        return [
          AppLocalizations.of(context)?.useExistingPhotos ??
              'Use Existing Photos',
          AppLocalizations.of(context)?.multipleAttempts ?? 'Multiple Attempts',
          AppLocalizations.of(context)?.clearQuality ?? 'Clear Quality'
        ];
      default:
        return [];
    }
  }

  String _getMethodEstimatedTime(String method) {
    switch (method) {
      case 'manual':
        return AppLocalizations.of(context)?.oneToTwoMinutes ?? '1-2 minutes';
      case 'scan':
        return AppLocalizations.of(context)?.twoToThreeMinutes ?? '2-3 minutes';
      case 'upload':
        return AppLocalizations.of(context)?.threeToFiveMinutes ??
            '3-5 minutes';
      default:
        return '';
    }
  }
}

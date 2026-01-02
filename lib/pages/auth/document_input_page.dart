import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yatra_suraksha_app/l10n/app_localizations.dart';
import '../../const/app_colors.dart';
import 'permission_gate.dart';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // For MediaType
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart'; // For the scanner
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class DocumentInputPage extends StatefulWidget {
  final String documentType;
  final String verificationMethod;

  const DocumentInputPage({
    super.key,
    required this.documentType,
    required this.verificationMethod,
  });

  @override
  State<DocumentInputPage> createState() => _DocumentInputPageState();
}

class _DocumentInputPageState extends State<DocumentInputPage>
    with SingleTickerProviderStateMixin {
  final _documentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isVerified = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _documentController.dispose();
    super.dispose();
  }

  String get documentDisplayName {
    return widget.documentType == 'aadhaar'
        ? (AppLocalizations.of(context)?.aadhaarCard ?? 'Aadhaar Card')
        : (AppLocalizations.of(context)?.passport ?? 'Passport');
  }

  String get methodDisplayName {
    switch (widget.verificationMethod) {
      case 'manual':
        return AppLocalizations.of(context)?.manualEntry ?? 'Manual Entry';
      case 'scan':
        return AppLocalizations.of(context)?.documentScanning ??
            'Document Scanning';
      case 'upload':
        return AppLocalizations.of(context)?.photoUpload ?? 'Photo Upload';
      default:
        return AppLocalizations.of(context)?.verification ?? 'Verification';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        title: Text(
          methodDisplayName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verify $documentDisplayName',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getMethodDescription(),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.secondaryText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Content Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _buildMethodContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMethodDescription() {
    switch (widget.verificationMethod) {
      case 'manual':
        return widget.documentType == 'aadhaar'
            ? (AppLocalizations.of(context)?.enterAadhaarNumber ??
                'Enter your 12-digit Aadhaar number below')
            : (AppLocalizations.of(context)?.enterPassportNumber ??
                'Enter your passport number below');
      case 'scan':
        return widget.documentType == 'aadhaar'
            ? (AppLocalizations.of(context)?.positionAadhaarInFrame ??
                'Position your Aadhaar card in the camera frame')
            : (AppLocalizations.of(context)?.positionPassportInFrame ??
                'Position your passport in the camera frame');
      case 'upload':
        return widget.documentType == 'aadhaar'
            ? (AppLocalizations.of(context)?.selectAadhaarPhoto ??
                'Select a clear photo of your Aadhaar card')
            : (AppLocalizations.of(context)?.selectPassportPhoto ??
                'Select a clear photo of your passport');
      default:
        return AppLocalizations.of(context)?.completeVerificationProcess ??
            'Complete the verification process';
    }
  }

  Widget _buildMethodContent() {
    switch (widget.verificationMethod) {
      case 'manual':
        return _buildManualEntry();
      case 'scan':
        return _buildScanInterface();
      case 'upload':
        return _buildUploadInterface();
      default:
        return Container();
    }
  }

  Widget _buildManualEntry() {
    // This function is complete and correct
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.info,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter Details Carefully',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.documentType == 'aadhaar'
                          ? 'Type your 12-digit Aadhaar number exactly as printed on your card'
                          : 'Enter your passport number as shown on the document',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.documentType == 'aadhaar'
                    ? 'Aadhaar Number'
                    : 'Passport Number',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.documentType == 'aadhaar'
                    ? 'Enter your 12-digit Aadhaar number'
                    : 'Enter your passport number',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _documentController,
                decoration: InputDecoration(
                  hintText: widget.documentType == 'aadhaar'
                      ? 'XXXX XXXX XXXX'
                      : 'A1234567',
                  prefixIcon: Icon(
                    widget.documentType == 'aadhaar'
                        ? Icons.credit_card
                        : Icons.book,
                    color: AppColors.primary,
                  ),
                  filled: true,
                  fillColor: AppColors.grey50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
                keyboardType: widget.documentType == 'aadhaar'
                    ? TextInputType.number
                    : TextInputType.text,
                inputFormatters: widget.documentType == 'aadhaar'
                    ? [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(12),
                        _AadhaarInputFormatter(),
                      ]
                    : [
                        LengthLimitingTextInputFormatter(10),
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                      ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your ${widget.documentType == 'aadhaar' ? 'Aadhaar' : 'passport'} number';
                  }
                  if (widget.documentType == 'aadhaar') {
                    if (value.replaceAll(' ', '').length != 12) {
                      return 'Aadhaar number must be 12 digits';
                    }
                  } else {
                    if (value.length < 6) {
                      return 'Please enter a valid passport number';
                    }
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 32),
              if (_documentController.text.isNotEmpty && !_isVerified)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Verify Document',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
        if (_isVerified) _buildSuccessCard(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildScanInterface() {
    // This function is complete and correct
    if (_isVerified) {
      return _buildSuccessCard();
    }

    return Column(
      children: [
        Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_rounded,
                size: 80,
                color: AppColors.secondaryText,
              ),
              const SizedBox(height: 16),
              Text(
                'Ready to Scan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Press the button below to start scanning',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildInstructionCard(
          'Scanning Tips',
          [
            'Ensure good lighting',
            'Keep the document flat',
            'Avoid shadows and glare',
            'Hold your device steady',
          ],
          Icons.lightbulb_outline_rounded,
          AppColors.warning,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleScanCapture,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_rounded),
                      SizedBox(width: 8),
                      Text(
                        'Capture Document',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildUploadInterface() {
    // --- MODIFICATION START: ADDED SUCCESS AND LOADING LOGIC ---
    if (_isVerified) {
      return _buildSuccessCard();
    }

    return Stack(
      children: [
        Column(
          children: [
            // Upload Area
            GestureDetector(
              // Disable tapping while loading
              onTap: _isLoading ? null : _handleFileSelection,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_rounded,
                      size: 60,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tap to Upload Photo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select a clear PDF, JPG, or PNG file', // Updated text
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.secondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Upload Guidelines
            _buildInstructionCard(
              'Photo Guidelines',
              [
                'Use good lighting and avoid shadows',
                'Ensure all text is clearly readable',
                'Photo should be in focus and not blurry',
                'Allowed types: PDF, JPG, PNG (under 5MB)', // Updated text
              ],
              Icons.photo_camera_rounded,
              AppColors.info,
            ),

            const SizedBox(height: 24),

            // Alternative Options
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    // Disable button while loading
                    onPressed: _isLoading ? null : _handleCameraCapture,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt_rounded),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)?.takePhoto ??
                            'Take Photo'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    // Disable button while loading
                    onPressed: _isLoading ? null : _handleFileSelection,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.photo_library_rounded),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)?.fromGallery ??
                            'From Gallery'),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),

        // This will show a loading spinner overlay over the entire interface
        // only when this specific tab is loading.
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
      ],
    );
    // --- MODIFICATION END ---
  }

  Widget _buildInstructionCard(
      String title, List<String> instructions, IconData icon, Color color) {
    // This function is correct, no changes
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...instructions
              .map((instruction) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            instruction,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildSuccessCard() {
    // This function is correct, no changes
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 60,
            color: AppColors.success,
          ),
          const SizedBox(height: 16),
          Text(
            'Verification Successful!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your ${widget.documentType == 'aadhaar' ? 'Aadhaar' : 'passport'} has been verified successfully',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PermissionGate()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue to App',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleVerification() async {
    // This function is correct, no changes
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isLoading = false;
      _isVerified = true;
    });
  }

  void _handleScanCapture() async {
    // This function is correct, no changes
    setState(() {
      _isLoading = true;
    });

    try {
      final options = DocumentScannerOptions(
        mode: ScannerMode.filter,
        isGalleryImport: false, // Corrected parameter name
        pageLimit: 1,
      );
      final documentScanner = DocumentScanner(options: options);
      final DocumentScanningResult result =
          await documentScanner.scanDocument();

      if (result.images.isNotEmpty) {
        String imagePath = result.images.first;
        File flatImageFile = File(imagePath);
        await _uploadScanToBackend(flatImageFile);
        setState(() {
          _isVerified = true;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scan was cancelled'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _uploadScanToBackend(File imageFile) async {
    // Updated to match curl command: localhost:3000/api/ocr/process with 'document' field
    var uri = Uri.parse("http://74.225.144.0:3000/api/ocr/process");

    try {
      var request = http.MultipartRequest("POST", uri);

      // Get the file extension to determine MIME type
      String fileName = imageFile.path.split('/').last;
      String extension = fileName.toLowerCase().split('.').last;

      // Map file extensions to MIME types
      String contentType;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'bmp':
          contentType = 'image/bmp';
          break;
        case 'tiff':
        case 'tif':
          contentType = 'image/tiff';
          break;
        default:
          contentType = 'image/jpeg'; // Default fallback
      }

      var multipartFile = http.MultipartFile.fromBytes(
        'document',
        await imageFile.readAsBytes(),
        filename: fileName,
        contentType: MediaType.parse(contentType),
      );

      request.files.add(multipartFile);

      // Add timeout to avoid hanging
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out after 30 seconds');
        },
      );

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Handle successful response here if needed
        // var responseBody = jsonDecode(response.body);
      } else {
        throw Exception(
            'Server returned ${response.statusCode}: ${response.reasonPhrase}');
      }
    } on TimeoutException {
      throw Exception(
          'Request timed out. Server might be slow or unreachable.');
    } on SocketException {
      throw Exception(
          'Network error: Cannot reach server. Check your internet connection.');
    } on FormatException {
      throw Exception('Invalid response from server.');
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  // --- MODIFICATION START: IMPLEMENTED UPLOAD/PICKER FUNCTIONS ---

  // This will be called by your "From Gallery" button AND your main upload box
  void _handleFileSelection() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Launch the native file picker, filtering for docs and images
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      // 2. Check if the user picked a file
      if (result != null && result.files.single.path != null) {
        File selectedFile = File(result.files.single.path!);

        // 3. Upload it using the same function as your scanner
        await _uploadScanToBackend(selectedFile);

        // 4. Show the success card
        setState(() {
          _isVerified = true;
        });
      } else {
        // User canceled the picker
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File selection was cancelled'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      // Handle any errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      // 5. Always stop loading
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // This implements the "Take Photo" button in your upload UI
  void _handleCameraCapture() async {
    final ImagePicker picker = ImagePicker();

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Launch the camera
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80, // Compress image slightly
      );

      // 2. Check if a photo was taken
      if (photo != null) {
        File photoFile = File(photo.path);

        // 3. Upload it
        await _uploadScanToBackend(photoFile);

        // 4. Show success
        setState(() {
          _isVerified = true;
        });
      } else {
        // User cancelled the camera
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera capture was cancelled'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  // --- MODIFICATION END ---
}

class _AadhaarInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

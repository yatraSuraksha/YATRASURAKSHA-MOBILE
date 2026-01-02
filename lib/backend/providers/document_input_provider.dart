import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

class DocumentInputProvider with ChangeNotifier {
  String? _documentType;
  String? _verificationMethod;
  String _documentNumber = '';
  bool _isLoading = false;
  bool _isVerified = false;
  bool _isAnimating = false;
  File? _selectedImage;
  String? _errorMessage;

  // Form validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _documentController = TextEditingController();

  // Getters
  String? get documentType => _documentType;
  String? get verificationMethod => _verificationMethod;
  String get documentNumber => _documentNumber;
  bool get isLoading => _isLoading;
  bool get isVerified => _isVerified;
  bool get isAnimating => _isAnimating;
  File? get selectedImage => _selectedImage;
  String? get errorMessage => _errorMessage;
  GlobalKey<FormState> get formKey => _formKey;
  TextEditingController get documentController => _documentController;

  String get documentDisplayName {
    return _documentType == 'aadhaar' ? 'Aadhaar Card' : 'Passport';
  }

  // Setters
  void setDocumentType(String documentType) {
    _documentType = documentType;
    notifyListeners();
  }

  void setVerificationMethod(String method) {
    _verificationMethod = method;
    notifyListeners();
  }

  void setDocumentNumber(String number) {
    _documentNumber = number;
    _documentController.text = number;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setVerified(bool verified) {
    _isVerified = verified;
    notifyListeners();
  }

  void setAnimating(bool animating) {
    _isAnimating = animating;
    notifyListeners();
  }

  void setSelectedImage(File? image) {
    _selectedImage = image;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Method descriptions
  String getMethodDescription() {
    switch (_verificationMethod) {
      case 'manual':
        return 'Enter your ${_documentType == 'aadhaar' ? '12-digit Aadhaar' : 'passport'} number below';
      case 'scan':
        return 'Position your ${_documentType == 'aadhaar' ? 'Aadhaar card' : 'passport'} in the camera frame';
      case 'upload':
        return 'Upload a clear photo of your ${_documentType == 'aadhaar' ? 'Aadhaar card' : 'passport'}';
      default:
        return '';
    }
  }

  // Validation
  String? validateDocument(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your ${_documentType == 'aadhaar' ? 'Aadhaar' : 'passport'} number';
    }
    if (_documentType == 'aadhaar') {
      if (value.replaceAll(' ', '').length != 12) {
        return 'Aadhaar number must be 12 digits';
      }
    } else {
      if (value.length < 6) {
        return 'Please enter a valid passport number';
      }
    }
    return null;
  }

  // Document verification
  Future<void> handleVerification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setLoading(true);
    clearError();

    try {
      // Simulate verification process
      await Future.delayed(const Duration(seconds: 2));
      setVerified(true);
    } catch (e) {
      setError('Verification failed: ${e.toString()}');
    } finally {
      setLoading(false);
    }
  }

  // File handling
  Future<void> handleFileSelection() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        setSelectedImage(file);
        await _uploadScanToBackend(file);
      }
    } catch (e) {
      setError('Failed to select file: ${e.toString()}');
    }
  }

  Future<void> handleCameraCapture() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        final file = File(image.path);
        setSelectedImage(file);
        await _uploadScanToBackend(file);
      }
    } catch (e) {
      setError('Failed to capture image: ${e.toString()}');
    }
  }

  Future<void> handleScanCapture() async {
    try {
      final documentScanner = DocumentScanner(
        options: DocumentScannerOptions(
          documentFormat: DocumentFormat.jpeg,
          mode: ScannerMode.full,
        ),
      );
      final result = await documentScanner.scanDocument();

      if (result.images.isNotEmpty) {
        final file = File(result.images.first);
        setSelectedImage(file);
        await _uploadScanToBackend(file);
      }
    } catch (e) {
      setError('Failed to scan document: ${e.toString()}');
    }
  }

  // OCR Upload
  Future<void> _uploadScanToBackend(File imageFile) async {
    var uri = Uri.parse("http://74.225.144.0:3000/api/ocr/process");
    
    try {
      setLoading(true);
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
        setVerified(true);
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.reasonPhrase}');
      }
    } on TimeoutException {
      setError('Request timed out. Server might be slow or unreachable.');
    } on SocketException {
      setError('Network error: Cannot reach server. Check your internet connection.');
    } on FormatException {
      setError('Invalid response from server.');
    } catch (e) {
      setError('Upload failed: $e');
    } finally {
      setLoading(false);
    }
  }

  // Reset provider to initial state
  void reset() {
    _documentType = null;
    _verificationMethod = null;
    _documentNumber = '';
    _isLoading = false;
    _isVerified = false;
    _isAnimating = false;
    _selectedImage = null;
    _errorMessage = null;
    _documentController.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _documentController.dispose();
    super.dispose();
  }
}
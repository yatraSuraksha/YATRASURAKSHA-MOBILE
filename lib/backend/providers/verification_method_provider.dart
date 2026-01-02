import 'package:flutter/foundation.dart';

class VerificationMethodProvider with ChangeNotifier {
  String? _selectedMethod;
  String? _documentType;
  bool _isAnimating = false;

  String? get selectedMethod => _selectedMethod;
  String? get documentType => _documentType;
  bool get isAnimating => _isAnimating;
  bool get hasSelection => _selectedMethod != null;

  String get documentDisplayName {
    return _documentType == 'aadhaar' ? 'Aadhaar Card' : 'Passport';
  }

  void setDocumentType(String documentType) {
    _documentType = documentType;
    notifyListeners();
  }

  void selectMethod(String method) {
    if (_selectedMethod != method) {
      _selectedMethod = method;
      notifyListeners();
    }
  }

  void clearSelection() {
    _selectedMethod = null;
    notifyListeners();
  }

  void setAnimating(bool animating) {
    if (_isAnimating != animating) {
      _isAnimating = animating;
      notifyListeners();
    }
  }

  bool isMethodSelected(String method) {
    return _selectedMethod == method;
  }

  // Method information helpers
  String getMethodTitle(String method) {
    switch (method) {
      case 'manual':
        return 'Manual Entry';
      case 'scan':
        return 'Document Scanner';
      case 'upload':
        return 'Upload Photo';
      default:
        return '';
    }
  }

  String getMethodSubtitle(String method) {
    switch (method) {
      case 'manual':
        return 'Type your document number';
      case 'scan':
        return 'Use camera to scan document';
      case 'upload':
        return 'Choose from gallery';
      default:
        return '';
    }
  }

  String getMethodDescription(String method) {
    switch (method) {
      case 'manual':
        return 'Enter your ${_documentType == 'aadhaar' ? '12-digit Aadhaar' : 'passport'} number manually';
      case 'scan':
        return 'Use your camera to scan the ${_documentType == 'aadhaar' ? 'Aadhaar card' : 'passport'} automatically';
      case 'upload':
        return 'Upload a clear photo of your ${_documentType == 'aadhaar' ? 'Aadhaar card' : 'passport'} from gallery';
      default:
        return '';
    }
  }

  List<String> getMethodFeatures(String method) {
    switch (method) {
      case 'manual':
        return ['Quick & Easy', 'No Camera Required', 'Instant'];
      case 'scan':
        return ['Auto-Detect', 'Real-time Processing', 'High Accuracy'];
      case 'upload':
        return ['Use Existing Photos', 'Multiple Attempts', 'Clear Quality'];
      default:
        return [];
    }
  }

  String getMethodEstimatedTime(String method) {
    switch (method) {
      case 'manual':
        return '1-2 minutes';
      case 'scan':
        return '2-3 minutes';
      case 'upload':
        return '3-5 minutes';
      default:
        return '';
    }
  }

  // Reset provider to initial state
  void reset() {
    _selectedMethod = null;
    _documentType = null;
    _isAnimating = false;
    notifyListeners();
  }
}
import 'package:flutter/foundation.dart';

class DocumentSelectionProvider with ChangeNotifier {
  String? _selectedDocumentType;
  bool _isAnimating = false;

  String? get selectedDocumentType => _selectedDocumentType;
  bool get isAnimating => _isAnimating;
  bool get hasSelection => _selectedDocumentType != null;

  void selectDocumentType(String documentType) {
    if (_selectedDocumentType != documentType) {
      _selectedDocumentType = documentType;
      notifyListeners();
    }
  }

  void clearSelection() {
    _selectedDocumentType = null;
    notifyListeners();
  }

  void setAnimating(bool animating) {
    if (_isAnimating != animating) {
      _isAnimating = animating;
      notifyListeners();
    }
  }

  bool isDocumentSelected(String documentType) {
    return _selectedDocumentType == documentType;
  }

  // Reset provider to initial state
  void reset() {
    _selectedDocumentType = null;
    _isAnimating = false;
    notifyListeners();
  }
}
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TripDetailsProvider with ChangeNotifier {
  // Form validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final TextEditingController _numberOfDaysController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final List<TextEditingController> _dayStayControllers = [];

  // State variables
  DateTime? _selectedStartDate;
  int _dayCount = 0;
  
  // Location suggestions
  List<String> _locationSuggestions = [];
  bool _showLocationSuggestions = false;
  List<String> _locationsList = [];
  bool _isFetchingLocations = true;
  String? _locationError;
  
  // Daily stay suggestions
  List<List<String>> _dayStaySuggestions = [];
  List<bool> _showDayStaySuggestions = [];

  // Loading states
  bool _isSubmitting = false;

  // Getters
  GlobalKey<FormState> get formKey => _formKey;
  TextEditingController get numberOfDaysController => _numberOfDaysController;
  TextEditingController get locationController => _locationController;
  TextEditingController get startDateController => _startDateController;
  List<TextEditingController> get dayStayControllers => _dayStayControllers;

  DateTime? get selectedStartDate => _selectedStartDate;
  int get dayCount => _dayCount;
  List<String> get locationSuggestions => _locationSuggestions;
  bool get showLocationSuggestions => _showLocationSuggestions;
  List<String> get locationsList => _locationsList;
  bool get isFetchingLocations => _isFetchingLocations;
  String? get locationError => _locationError;
  List<List<String>> get dayStaySuggestions => _dayStaySuggestions;
  List<bool> get showDayStaySuggestions => _showDayStaySuggestions;
  bool get isSubmitting => _isSubmitting;

  // Initialize provider
  void initialize() {
    fetchLocations();
  }

  // Fetch locations from API
  Future<void> fetchLocations() async {
    try {
      _isFetchingLocations = true;
      _locationError = null;
      notifyListeners();

      // Using the same API endpoint as your existing code
      final url = Uri.parse('https://countriesnow.space/api/v0.1/countries/cities');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'country': 'india'}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['error'] == false && data['data'] != null) {
          final List<dynamic> citiesData = data['data'];
          final List<String> loadedLocations = citiesData.cast<String>();

          // Sort the list alphabetically for better UX
          loadedLocations.sort();
          
          _locationsList = loadedLocations;
        } else {
          throw Exception('API returned error or no data');
        }
      } else {
        throw Exception('Failed to load cities from API. Status: ${response.statusCode}');
      }
    } catch (e) {
      _locationError = 'Failed to fetch locations: ${e.toString()}';
      // Fallback to comprehensive default cities if API fails
      _locationsList = [
        'Mumbai', 'Delhi', 'Bangalore', 'Hyderabad', 'Ahmedabad', 'Chennai', 
        'Kolkata', 'Pune', 'Jaipur', 'Surat', 'Lucknow', 'Kanpur', 'Nagpur', 
        'Indore', 'Thane', 'Bhopal', 'Visakhapatnam', 'Patna', 'Vadodara', 
        'Ghaziabad', 'Ludhiana', 'Agra', 'Nashik', 'Faridabad', 'Meerut', 
        'Rajkot', 'Varanasi', 'Srinagar', 'Aurangabad', 'Dhanbad', 'Amritsar', 
        'Allahabad', 'Ranchi', 'Howrah', 'Coimbatore', 'Jabalpur', 'Gwalior', 
        'Vijayawada', 'Jodhpur', 'Madurai', 'Raipur', 'Kota', 'Chandigarh', 
        'Guwahati', 'Solapur', 'Tiruchirappalli', 'Bareilly', 'Mysore', 
        'Tiruppur', 'Gurgaon', 'Aligarh', 'Jalandhar', 'Bhubaneswar', 'Salem'
      ];
    } finally {
      _isFetchingLocations = false;
      notifyListeners();
    }
  }

  // Location search and suggestions
  void searchLocations(String query) {
    if (query.isEmpty) {
      _locationSuggestions = [];
      _showLocationSuggestions = false;
    } else {
      _locationSuggestions = _locationsList
          .where((location) => location.toLowerCase().contains(query.toLowerCase()))
          .take(5)
          .toList();
      _showLocationSuggestions = _locationSuggestions.isNotEmpty;
    }
    notifyListeners();
  }

  void selectLocation(String location) {
    _locationController.text = location;
    _showLocationSuggestions = false;
    notifyListeners();
  }

  void hideLocationSuggestions() {
    _showLocationSuggestions = false;
    notifyListeners();
  }

  // Date handling
  Future<void> selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _selectedStartDate) {
      _selectedStartDate = picked;
      _startDateController.text = "${picked.day}/${picked.month}/${picked.year}";
      notifyListeners();
    }
  }

  // Day count management
  void updateDayCount() {
    final text = _numberOfDaysController.text;
    final newDayCount = int.tryParse(text) ?? 0;
    
    if (newDayCount != _dayCount) {
      _dayCount = newDayCount;
      _updateDayStayControllers();
      notifyListeners();
    }
  }

  void _updateDayStayControllers() {
    // Remove excess controllers
    while (_dayStayControllers.length > _dayCount) {
      final controller = _dayStayControllers.removeLast();
      controller.dispose();
    }

    // Add new controllers
    while (_dayStayControllers.length < _dayCount) {
      _dayStayControllers.add(TextEditingController());
    }

    // Update suggestions arrays
    _dayStaySuggestions = List.generate(_dayCount, (index) => <String>[]);
    _showDayStaySuggestions = List.generate(_dayCount, (index) => false);
  }

  // Day stay suggestions
  void searchDayStay(int dayIndex, String query) {
    if (dayIndex >= 0 && dayIndex < _dayCount) {
      if (query.isEmpty) {
        _dayStaySuggestions[dayIndex] = [];
        _showDayStaySuggestions[dayIndex] = false;
      } else {
        _dayStaySuggestions[dayIndex] = _locationsList
            .where((location) => location.toLowerCase().contains(query.toLowerCase()))
            .take(5)
            .toList();
        _showDayStaySuggestions[dayIndex] = _dayStaySuggestions[dayIndex].isNotEmpty;
      }
      notifyListeners();
    }
  }

  void selectDayStay(int dayIndex, String location) {
    if (dayIndex >= 0 && dayIndex < _dayStayControllers.length) {
      _dayStayControllers[dayIndex].text = location;
      _showDayStaySuggestions[dayIndex] = false;
      notifyListeners();
    }
  }

  void hideDayStaySuggestions(int dayIndex) {
    if (dayIndex >= 0 && dayIndex < _showDayStaySuggestions.length) {
      _showDayStaySuggestions[dayIndex] = false;
      notifyListeners();
    }
  }

  // Form validation
  String? validateRequiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  String? validateNumberOfDays(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter number of days';
    }
    final days = int.tryParse(value);
    if (days == null || days <= 0) {
      return 'Please enter a valid number of days';
    }
    if (days > 30) {
      return 'Maximum 30 days allowed';
    }
    return null;
  }

  String? validateStartDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select start date';
    }
    if (_selectedStartDate == null) {
      return 'Please select a valid date';
    }
    return null;
  }

  // Form submission
  Future<bool> submitTrip() async {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      // Don't reset form immediately, let UI handle it
      return true;
      
    } catch (e) {
      // Handle error
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // Reset form
  void resetForm() {
    _numberOfDaysController.clear();
    _locationController.clear();
    _startDateController.clear();
    
    for (final controller in _dayStayControllers) {
      controller.dispose();
    }
    _dayStayControllers.clear();
    
    _selectedStartDate = null;
    _dayCount = 0;
    _locationSuggestions = [];
    _showLocationSuggestions = false;
    _dayStaySuggestions = [];
    _showDayStaySuggestions = [];
    _isSubmitting = false;
    
    notifyListeners();
  }

  @override
  void dispose() {
    _numberOfDaysController.dispose();
    _locationController.dispose();
    _startDateController.dispose();
    
    for (final controller in _dayStayControllers) {
      controller.dispose();
    }
    _dayStayControllers.clear();
    
    super.dispose();
  }
}
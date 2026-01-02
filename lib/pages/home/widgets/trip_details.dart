import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../const/app_colors.dart';
import '../../../backend/providers/trip_details_provider.dart';

class TripDetails extends StatefulWidget {
  const TripDetails({super.key});

  @override
  State<TripDetails> createState() => _TripDetailsState();
}

class _TripDetailsState extends State<TripDetails> {
  @override
  void initState() {
    super.initState();
    // Initialize the provider when the widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TripDetailsProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TripDetailsProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: provider.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryText),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Basic Details',
                      icon: Icons.map_rounded,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildLocationDropdown(provider),
                          const SizedBox(height: 20),
                          _buildStartDateInput(provider),
                          const SizedBox(height: 20),
                          _buildNumberOfDaysInput(provider),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),

                    // Dynamically Generated Section
                    if (provider.dayCount > 0)
                      _buildSectionCard(
                        title: 'Daily Itinerary',
                        icon: Icons.hotel_rounded,
                        child: SizedBox(
                          height: provider.dayCount <= 3 ? provider.dayCount * 80.0 : 240.0,
                          child: ListView.builder(
                            itemCount: provider.dayCount,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: _buildDayStayAutocomplete(provider, index),
                              );
                            },
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: provider.isSubmitting 
                            ? null 
                            : () async {
                                final success = await provider.submitTrip();
                                if (success && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Trip details saved successfully!'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              },
                        icon: provider.isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline_rounded),
                        label: Text(provider.isSubmitting ? 'Saving...' : 'Save Trip Plan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Add bottom padding to prevent overlap with navigation bar
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationDropdown(TripDetailsProvider provider) {
    // Show loading indicator while fetching
    if (provider.isFetchingLocations) {
      return Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text("Fetching locations...", style: TextStyle(color: AppColors.secondaryText)),
          ],
        ),
      );
    }
    
    // Show error message if something went wrong
    if (provider.locationError != null) {
      return Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withOpacity(0.5))
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 12),
            Text("Error loading locations", style: TextStyle(color: AppColors.error)),
          ],
        ),
      );
    }
    
    // Text field with suggestions below
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: provider.locationController,
          decoration: _buildInputDecoration(
            labelText: 'Starting Location',
            hintText: 'Type to search locations...',
            prefixIcon: Icons.flag_rounded,
          ),
          validator: (value) => provider.validateRequiredField(value, 'starting location'),
          onChanged: (value) => provider.searchLocations(value),
          onTap: () => provider.hideLocationSuggestions(),
        ),
        if (provider.showLocationSuggestions && provider.locationSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: provider.locationSuggestions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  dense: true,
                  title: Text(
                    provider.locationSuggestions[index],
                    style: const TextStyle(fontSize: 14),
                  ),
                  onTap: () => provider.selectLocation(provider.locationSuggestions[index]),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildStartDateInput(TripDetailsProvider provider) {
    return TextFormField(
      controller: provider.startDateController,
      decoration: _buildInputDecoration(
        labelText: 'Start Date',
        hintText: 'Select trip start date',
        prefixIcon: Icons.calendar_today_rounded,
      ),
      readOnly: true,
      validator: (value) => provider.validateStartDate(value),
      onTap: () => provider.selectStartDate(context),
    );
  }

  Widget _buildNumberOfDaysInput(TripDetailsProvider provider) {
    return TextFormField(
      controller: provider.numberOfDaysController,
      decoration: _buildInputDecoration(
        labelText: 'Number of Days',
        hintText: 'e.g., 5',
        prefixIcon: Icons.calendar_today_rounded,
      ),
      keyboardType: TextInputType.number,
      validator: (value) => provider.validateNumberOfDays(value),
      onChanged: (value) => provider.updateDayCount(),
    );
  }

  Widget _buildDayStayAutocomplete(TripDetailsProvider provider, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: provider.dayStayControllers[index],
          decoration: _buildCompactInputDecoration(
            labelText: 'Day ${index + 1}',
            hintText: 'Type location or hotel name...',
            prefixIcon: Icons.location_city_rounded,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Enter stay location for Day ${index + 1}';
            }
            return null;
          },
          onChanged: (value) => provider.searchDayStay(index, value),
        ),
        if (index < provider.showDayStaySuggestions.length && 
            provider.showDayStaySuggestions[index] && 
            index < provider.dayStaySuggestions.length &&
            provider.dayStaySuggestions[index].isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 150),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: provider.dayStaySuggestions[index].length,
              itemBuilder: (context, suggestionIndex) {
                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    provider.dayStaySuggestions[index][suggestionIndex],
                    style: const TextStyle(fontSize: 13),
                  ),
                  onTap: () => provider.selectDayStay(index, provider.dayStaySuggestions[index][suggestionIndex]),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    String? hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: AppColors.primary),
      filled: true,
      fillColor: AppColors.grey50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  InputDecoration _buildCompactInputDecoration({
    required String labelText,
    String? hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: AppColors.grey50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      isDense: true,
    );
  }
}
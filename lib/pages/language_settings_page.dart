import 'package:flutter/material.dart';
import 'package:yatra_suraksha_app/pages/components/language_selection_widget.dart';
import 'package:yatra_suraksha_app/l10n/app_localizations.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.settings ?? 'Settings'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n?.language ?? 'Language',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            LanguageBottomSheet.show(context);
                          },
                          icon: const Icon(Icons.language),
                          label:
                              Text(l10n?.selectLanguage ?? 'Select Language'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const LanguageSelectionWidget(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Demo section to show translated text
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demo Translation',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDemoItem(Icons.home, l10n?.home ?? 'Home'),
                    _buildDemoItem(Icons.person, l10n?.profile ?? 'Profile'),
                    _buildDemoItem(
                        Icons.location_on, l10n?.location ?? 'Location'),
                    _buildDemoItem(
                        Icons.description, l10n?.documents ?? 'Documents'),
                    _buildDemoItem(
                        Icons.verified, l10n?.verification ?? 'Verification'),
                    _buildDemoItem(Icons.trip_origin, l10n?.trip ?? 'Trip'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          LanguageBottomSheet.show(context);
        },
        child: const Icon(Icons.language),
      ),
    );
  }

  Widget _buildDemoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}

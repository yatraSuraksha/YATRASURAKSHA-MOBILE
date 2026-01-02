import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yatra_suraksha_app/backend/providers/locale_provider.dart';
import 'package:yatra_suraksha_app/l10n/app_localizations.dart';

class LanguageSelectionWidget extends StatelessWidget {
  const LanguageSelectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LocaleProvider>(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n?.language ?? 'Language',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Make the language list scrollable and limit its height to prevent overflow
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height *
                0.5, // Max 50% of screen height
          ),
          child: SingleChildScrollView(
            child: Column(
              children: L10n.all.map((locale) {
                final isSelected = provider.locale == locale;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true, // Make tiles more compact
                  leading: Text(
                    L10n.getFlag(locale.languageCode),
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    L10n.getName(locale.languageCode),
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis, // Prevent text overflow
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.green, size: 20)
                      : null,
                  onTap: () {
                    provider.setLocale(locale);
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class LanguageBottomSheet extends StatelessWidget {
  const LanguageBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow the sheet to be sized based on content
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height *
            0.8, // Max 80% of screen height
      ),
      builder: (context) => const LanguageBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n?.selectLanguage ?? 'Select Language',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Wrap in Flexible to prevent overflow
            Flexible(
              child: const LanguageSelectionWidget(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

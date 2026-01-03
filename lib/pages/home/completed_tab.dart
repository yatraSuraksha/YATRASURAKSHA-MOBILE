import 'package:flutter/material.dart';
import 'package:yatra_suraksha_app/l10n/app_localizations.dart';

class CompletedTab extends StatelessWidget {
  const CompletedTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.completed ?? 'Completed'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Text(
          l10n?.completedTabContent ?? 'Completed Tab Content',
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

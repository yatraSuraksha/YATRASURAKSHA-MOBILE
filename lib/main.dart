import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:yatra_suraksha_app/backend/providers/auth_provider.dart';
import 'package:yatra_suraksha_app/backend/providers/location_provider.dart';
import 'package:yatra_suraksha_app/backend/providers/locale_provider.dart';
import 'package:yatra_suraksha_app/const/app_theme.dart';
import 'package:yatra_suraksha_app/backend/providers/document_selection_provider.dart';
import 'package:yatra_suraksha_app/backend/providers/verification_method_provider.dart';
import 'package:yatra_suraksha_app/backend/providers/document_input_provider.dart';
import 'package:yatra_suraksha_app/backend/providers/trip_details_provider.dart';
import 'package:yatra_suraksha_app/firebase_options.dart';
import 'package:yatra_suraksha_app/pages/navigation/splash_screen.dart';
import 'package:yatra_suraksha_app/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // Failed to load .env file, using default configuration
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Get effective locale for Material/Cupertino components
  /// Falls back to supported locales for unsupported regional languages
  Locale _getEffectiveLocale(Locale userLocale) {
    // Languages not supported by Flutter's Material/Cupertino components
    const unsupportedLanguages = ['lus', 'mni'];

    if (unsupportedLanguages.contains(userLocale.languageCode)) {
      // Fall back to Hindi for Indian regional languages
      return const Locale('hi');
    }

    // For other potentially unsupported languages, check and fallback
    if (userLocale.languageCode == 'as') {
      return const Locale('bn'); // Assamese -> Bengali (similar script)
    }

    if (userLocale.languageCode == 'ne') {
      return const Locale('hi'); // Nepali -> Hindi (similar script)
    }

    return userLocale;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => DocumentSelectionProvider()),
        ChangeNotifierProvider(create: (_) => VerificationMethodProvider()),
        ChangeNotifierProvider(create: (_) => DocumentInputProvider()),
        ChangeNotifierProvider(create: (_) => CustomAuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(
            create: (_) => TripDetailsProvider()..initialize()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            title: 'Yatra Suraksha',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            locale: _getEffectiveLocale(localeProvider.locale),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              // If the locale is supported, use it
              if (locale != null &&
                  supportedLocales.any((supported) =>
                      supported.languageCode == locale.languageCode)) {
                return locale;
              }

              // Default to English if locale is null or unsupported
              return const Locale('en');
            },
            supportedLocales: const [
              Locale('en'), // English
              Locale('hi'), // Hindi
              Locale('bn'), // Bengali
              Locale('kn'), // Kannada
              Locale('ml'), // Malayalam
              Locale('mr'), // Marathi
              Locale('ta'), // Tamil
              Locale('te'), // Telugu
              Locale('ja'), // Japanese
              Locale('as'), // Assamese
              Locale('lus'), // Mizo/Lushai
              Locale('mni'), // Manipuri
              Locale('ne'), // Nepali
              Locale('fr'), // French
              Locale('es'), // Spanish
              Locale('de'), // German
              Locale('ru'), // Russian
              Locale('zh'), // Chinese
            ],
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

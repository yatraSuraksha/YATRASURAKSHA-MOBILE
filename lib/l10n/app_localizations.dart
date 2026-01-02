import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_as.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_lus.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mni.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ne.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('as'),
    Locale('bn'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('ja'),
    Locale('kn'),
    Locale('lus'),
    Locale('ml'),
    Locale('mni'),
    Locale('mr'),
    Locale('ne'),
    Locale('ru'),
    Locale('ta'),
    Locale('te'),
    Locale('zh')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Yatra Suraksha'**
  String get appTitle;

  /// Welcome message
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Profile tab
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Settings tab
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Hindi language option
  ///
  /// In en, this message translates to:
  /// **'हिंदी'**
  String get hindi;

  /// Login button
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Logout button
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Email field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Sign up button
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Select language dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Location
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// Documents
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// General verification text
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verification;

  /// Trip
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get trip;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Confirm button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Success message
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Tourist profile section header
  ///
  /// In en, this message translates to:
  /// **'Tourist Profile'**
  String get touristProfile;

  /// Tourist ID field
  ///
  /// In en, this message translates to:
  /// **'Tourist ID'**
  String get touristId;

  /// Digital ID field
  ///
  /// In en, this message translates to:
  /// **'Digital ID'**
  String get digitalId;

  /// Status field
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// KYC Status field
  ///
  /// In en, this message translates to:
  /// **'KYC Status'**
  String get kycStatus;

  /// Safety Score field
  ///
  /// In en, this message translates to:
  /// **'Safety Score'**
  String get safetyScore;

  /// Refresh profile button
  ///
  /// In en, this message translates to:
  /// **'Refresh Profile'**
  String get refreshProfile;

  /// Refresh profile description
  ///
  /// In en, this message translates to:
  /// **'Update your profile information'**
  String get updateProfileInfo;

  /// Logout description
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get signOutAccount;

  /// Language setting description
  ///
  /// In en, this message translates to:
  /// **'Change app language'**
  String get changeAppLanguage;

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Yatra Suraksha'**
  String get appName;

  /// Application tagline
  ///
  /// In en, this message translates to:
  /// **'Safe Travel, Secure Journey'**
  String get appTagline;

  /// Version text
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Not available text
  ///
  /// In en, this message translates to:
  /// **'Not Available'**
  String get notAvailable;

  /// Unknown status text
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// Refreshing profile message
  ///
  /// In en, this message translates to:
  /// **'Refreshing profile...'**
  String get refreshingProfile;

  /// Profile refreshed success message
  ///
  /// In en, this message translates to:
  /// **'Profile refreshed!'**
  String get profileRefreshed;

  /// Safety Map tab
  ///
  /// In en, this message translates to:
  /// **'Safety Map'**
  String get safetyMap;

  /// Trips tab
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get trips;

  /// Current location label
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// Emergency help question
  ///
  /// In en, this message translates to:
  /// **'Emergency help Needed ?'**
  String get emergencyHelpNeeded;

  /// Instruction for SOS button
  ///
  /// In en, this message translates to:
  /// **'Double tap the button to Call'**
  String get doubleTapToCall;

  /// SOS emergency button
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sos;

  /// Emergency SOS dialog title
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS'**
  String get emergencySOS;

  /// Emergency SOS dialog description
  ///
  /// In en, this message translates to:
  /// **'This will send an emergency alert with your location to emergency services and your emergency contacts.'**
  String get emergencySOSDescription;

  /// Send SOS button
  ///
  /// In en, this message translates to:
  /// **'Send SOS'**
  String get sendSOS;

  /// Emergency contacts section
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts'**
  String get emergencyContacts;

  /// Emergency option - feeling unsafe
  ///
  /// In en, this message translates to:
  /// **'I am feeling unsafe'**
  String get feelingUnsafe;

  /// Emergency option - medical help
  ///
  /// In en, this message translates to:
  /// **'Need Medical Help'**
  String get needMedicalHelp;

  /// Emergency option - police help
  ///
  /// In en, this message translates to:
  /// **'Need Police Help'**
  String get needPoliceHelp;

  /// Emergency option - injury
  ///
  /// In en, this message translates to:
  /// **'I had an Injury'**
  String get hadInjury;

  /// SOS sent success message
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS sent successfully!'**
  String get emergencySOSSent;

  /// Login page welcome title
  ///
  /// In en, this message translates to:
  /// **'Welcome to Safe Travel'**
  String get welcomeToSafeTravel;

  /// Login page description
  ///
  /// In en, this message translates to:
  /// **'Your trusted companion for secure and monitored travel experiences. Join thousands of travelers who prioritize safety.'**
  String get trustedCompanionDescription;

  /// Features section title
  ///
  /// In en, this message translates to:
  /// **'Why Choose Yatra Suraksha?'**
  String get whyChooseYatraSuraksha;

  /// Feature title
  ///
  /// In en, this message translates to:
  /// **'Real-time Location Tracking'**
  String get realTimeLocationTracking;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'Stay connected with your loved ones'**
  String get stayConnectedWithLovedOnes;

  /// Feature title for document verification
  ///
  /// In en, this message translates to:
  /// **'Document Verification'**
  String get documentVerificationFeature;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'Secure identity verification process'**
  String get secureIdentityVerification;

  /// Feature title
  ///
  /// In en, this message translates to:
  /// **'24/7 Emergency Support'**
  String get emergencySupport247;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'Round-the-clock assistance when needed'**
  String get roundTheClockAssistance;

  /// Google login button text
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Loading text during login
  ///
  /// In en, this message translates to:
  /// **'Signing you in...'**
  String get signingYouIn;

  /// Document selection page title
  ///
  /// In en, this message translates to:
  /// **'Identity Verification'**
  String get identityVerification;

  /// Document selection page description
  ///
  /// In en, this message translates to:
  /// **'Choose your identity document to begin the secure verification process'**
  String get chooseIdentityDocument;

  /// Aadhaar card document type
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Card'**
  String get aadhaarCard;

  /// Aadhaar card subtitle
  ///
  /// In en, this message translates to:
  /// **'Indian National Identity Card'**
  String get indianNationalIdentityCard;

  /// Aadhaar card description
  ///
  /// In en, this message translates to:
  /// **'Government-issued 12-digit unique identification'**
  String get governmentIssued12DigitId;

  /// Aadhaar feature
  ///
  /// In en, this message translates to:
  /// **'Quick Verification'**
  String get quickVerification;

  /// Aadhaar feature
  ///
  /// In en, this message translates to:
  /// **'OTP Based'**
  String get otpBased;

  /// Aadhaar feature
  ///
  /// In en, this message translates to:
  /// **'Instant Results'**
  String get instantResults;

  /// Passport document type
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get passport;

  /// Passport subtitle
  ///
  /// In en, this message translates to:
  /// **'International Travel Document'**
  String get internationalTravelDocument;

  /// Passport description
  ///
  /// In en, this message translates to:
  /// **'Government-issued travel and identity document'**
  String get governmentIssuedTravelDocument;

  /// Passport feature
  ///
  /// In en, this message translates to:
  /// **'Global Recognition'**
  String get globalRecognition;

  /// Passport feature
  ///
  /// In en, this message translates to:
  /// **'Photo Verification'**
  String get photoVerification;

  /// Document feature
  ///
  /// In en, this message translates to:
  /// **'Secure'**
  String get secure;

  /// Continue button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Manual entry verification method
  ///
  /// In en, this message translates to:
  /// **'Manual Entry'**
  String get manualEntry;

  /// Document scanning verification method
  ///
  /// In en, this message translates to:
  /// **'Document Scanning'**
  String get documentScanning;

  /// Photo upload verification method
  ///
  /// In en, this message translates to:
  /// **'Photo Upload'**
  String get photoUpload;

  /// Verify document title
  ///
  /// In en, this message translates to:
  /// **'Verify {document}'**
  String verifyDocument(String document);

  /// Instruction for entering Aadhaar number
  ///
  /// In en, this message translates to:
  /// **'Enter your 12-digit Aadhaar number below'**
  String get enterAadhaarNumber;

  /// Instruction for entering passport number
  ///
  /// In en, this message translates to:
  /// **'Enter your passport number below'**
  String get enterPassportNumber;

  /// Instruction for scanning Aadhaar
  ///
  /// In en, this message translates to:
  /// **'Position your Aadhaar card in the camera frame'**
  String get positionAadhaarInFrame;

  /// Instruction for scanning passport
  ///
  /// In en, this message translates to:
  /// **'Position your passport in the camera frame'**
  String get positionPassportInFrame;

  /// Instruction for uploading Aadhaar photo
  ///
  /// In en, this message translates to:
  /// **'Select a clear photo of your Aadhaar card'**
  String get selectAadhaarPhoto;

  /// Instruction for uploading passport photo
  ///
  /// In en, this message translates to:
  /// **'Select a clear photo of your passport'**
  String get selectPassportPhoto;

  /// General verification completion text
  ///
  /// In en, this message translates to:
  /// **'Complete the verification process'**
  String get completeVerificationProcess;

  /// Document verification page title
  ///
  /// In en, this message translates to:
  /// **'{document} Verification'**
  String documentVerification(String document);

  /// Verification method selection question
  ///
  /// In en, this message translates to:
  /// **'How would you like to verify?'**
  String get howWouldYouLikeToVerify;

  /// Verification method selection subtitle
  ///
  /// In en, this message translates to:
  /// **'Pick the method that works best for you'**
  String get pickMethodThatWorksBest;

  /// Document scanner method title
  ///
  /// In en, this message translates to:
  /// **'Document Scanner'**
  String get documentScanner;

  /// Upload photo method title
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get uploadPhoto;

  /// Manual entry subtitle
  ///
  /// In en, this message translates to:
  /// **'Type your document number'**
  String get typeDocumentNumber;

  /// Scanner subtitle
  ///
  /// In en, this message translates to:
  /// **'Use camera to scan document'**
  String get useCameraToScan;

  /// Upload subtitle
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'Quick & Easy'**
  String get quickAndEasy;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'No Camera Required'**
  String get noCameraRequired;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'Instant'**
  String get instant;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'Auto-Detect'**
  String get autoDetect;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'Real-time Processing'**
  String get realTimeProcessing;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'High Accuracy'**
  String get highAccuracy;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'Use Existing Photos'**
  String get useExistingPhotos;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'Multiple Attempts'**
  String get multipleAttempts;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'Clear Quality'**
  String get clearQuality;

  /// Estimated time
  ///
  /// In en, this message translates to:
  /// **'1-2 minutes'**
  String get oneToTwoMinutes;

  /// Estimated time
  ///
  /// In en, this message translates to:
  /// **'2-3 minutes'**
  String get twoToThreeMinutes;

  /// Estimated time
  ///
  /// In en, this message translates to:
  /// **'3-5 minutes'**
  String get threeToFiveMinutes;

  /// Logout confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutDialogTitle;

  /// Logout confirmation dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutDialogMessage;

  /// Signing out loading message
  ///
  /// In en, this message translates to:
  /// **'Signing out...'**
  String get signingOut;

  /// Completed tab title
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// Completed tab placeholder content
  ///
  /// In en, this message translates to:
  /// **'Completed Tab Content'**
  String get completedTabContent;

  /// Button to check permissions again
  ///
  /// In en, this message translates to:
  /// **'Check Again'**
  String get checkAgain;

  /// Button to enable location services
  ///
  /// In en, this message translates to:
  /// **'Enable Location Services'**
  String get enableLocationServices;

  /// Button to enable app permissions
  ///
  /// In en, this message translates to:
  /// **'Enable App Permissions'**
  String get enableAppPermissions;

  /// Permission status section title
  ///
  /// In en, this message translates to:
  /// **'Permission Status'**
  String get permissionStatus;

  /// Location services label
  ///
  /// In en, this message translates to:
  /// **'Location Services'**
  String get locationServices;

  /// Background location permission label
  ///
  /// In en, this message translates to:
  /// **'Background Location'**
  String get backgroundLocation;

  /// Take photo button
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// Select from gallery button
  ///
  /// In en, this message translates to:
  /// **'From Gallery'**
  String get fromGallery;

  /// Loading message while detecting location
  ///
  /// In en, this message translates to:
  /// **'Detecting location...'**
  String get detectingLocation;

  /// Error message when location services are disabled
  ///
  /// In en, this message translates to:
  /// **'Location services disabled'**
  String get locationServicesDisabled;

  /// Error message when location permission is denied
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// Error message when unable to get location
  ///
  /// In en, this message translates to:
  /// **'Unable to get location'**
  String get unableToGetLocation;

  /// Success message when location is detected
  ///
  /// In en, this message translates to:
  /// **'Location detected'**
  String get locationDetected;

  /// Police emergency contact
  ///
  /// In en, this message translates to:
  /// **'Police'**
  String get police;

  /// Ambulance emergency contact
  ///
  /// In en, this message translates to:
  /// **'Ambulance'**
  String get ambulance;

  /// Fire emergency contact
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get fire;

  /// Women helpline contact
  ///
  /// In en, this message translates to:
  /// **'Women'**
  String get women;

  /// Child helpline contact
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get child;

  /// Add button
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Contact number field label
  ///
  /// In en, this message translates to:
  /// **'Contact Number'**
  String get contactNumber;

  /// Relation field label
  ///
  /// In en, this message translates to:
  /// **'Relation'**
  String get relation;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'as',
        'bn',
        'de',
        'en',
        'es',
        'fr',
        'hi',
        'ja',
        'kn',
        'lus',
        'ml',
        'mni',
        'mr',
        'ne',
        'ru',
        'ta',
        'te',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'as':
      return AppLocalizationsAs();
    case 'bn':
      return AppLocalizationsBn();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'ja':
      return AppLocalizationsJa();
    case 'kn':
      return AppLocalizationsKn();
    case 'lus':
      return AppLocalizationsLus();
    case 'ml':
      return AppLocalizationsMl();
    case 'mni':
      return AppLocalizationsMni();
    case 'mr':
      return AppLocalizationsMr();
    case 'ne':
      return AppLocalizationsNe();
    case 'ru':
      return AppLocalizationsRu();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

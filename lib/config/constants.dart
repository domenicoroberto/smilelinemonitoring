class AppConstants {
  static const String appName = 'SmileLineMonitoring';
  static const String appVersion = '1.0.0';
  static const String appAuthor = 'SmileLine';

  static const String logoPath = 'assets/images/logo.png';
  static const String logoWhitePath = 'assets/images/logo_white.png';
  static const String iconTimerPath = 'assets/images/icon_timer.png';
  static const String iconSmilePath = 'assets/images/icon_smile.png';

  static const String step1ImagePath = 'assets/images/onboarding/step1.png';
  static const String step2ImagePath = 'assets/images/onboarding/step2.png';
  static const String step3ImagePath = 'assets/images/onboarding/step3.png';

  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  static const Duration snackBarDuration = Duration(seconds: 3);

  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 20.0;

  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 18.0;
  static const double fontSizeHeading2 = 22.0;
  static const double fontSizeHeading1 = 28.0;

  static const int minPasswordLength = 8;
  static const int maxNotesLength = 500;

  static const int defaultDailyWearingHours = 22;
  static const int minStages = 1;
  static const int maxStages = 50;

  static const String userDataBoxKey = 'userDataBox';
  static const String treatmentPlanBoxKey = 'treatmentPlanBox';
  static const String dailyTrackingBoxKey = 'dailyTrackingBox';
  static const String isOnboardingCompleteKey = 'isOnboardingComplete';
  static const String lastSyncDateKey = 'lastSyncDate';

  static const int notificationChannelId = 1;
  static const String notificationChannelName = 'SmileLine Reminders';
  static const String notificationChannelDesc = 'Promemoria cambio allineatore e utilizzo';

  static const String errorGeneric = 'Si è verificato un errore. Riprova più tardi.';
  static const String errorNetwork = 'Errore di connessione. Verifica il tuo internet.';
  static const String errorValidation = 'Controlla i dati inseriti.';
  static const String errorEmptyField = 'Questo campo non può essere vuoto.';
  static const String errorInvalidInput = 'Input non valido.';

  static const String successSaved = 'Salvato con successo!';
  static const String successDeleted = 'Eliminato con successo!';
  static const String successUpdated = 'Aggiornato con successo!';

  static const String labelAlignerWearingHours = 'Ore di utilizzo giornaliere';
  static const String labelTotalStages = 'Numero totale di stadi';
  static const String labelStageADays = 'Giorni Stage A';
  static const String labelStageBDays = 'Giorni Stage B';
  static const String labelStartDate = 'Data di inizio';
  static const String labelNotes = 'Note';

  static const String privacyPolicyUrl = 'https://smileline.example.com/privacy';
  static const String termsOfServiceUrl = 'https://smileline.example.com/terms';
  static const String supportUrl = 'https://smileline.example.com/support';
}
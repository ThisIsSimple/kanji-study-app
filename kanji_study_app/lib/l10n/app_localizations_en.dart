// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Konna Kanji';

  @override
  String get loginSubtitle => 'Japanese study that feels just right';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithKakao => 'Continue with Kakao';

  @override
  String get orDivider => 'or';

  @override
  String get startAsGuest => 'Start as guest';

  @override
  String get guestStartInfo =>
      'Start as a guest now, then link a social account later to keep your data safe.';

  @override
  String guestLoginFailed(Object error) {
    return 'Guest login failed: $error';
  }

  @override
  String googleLoginFailed(Object error) {
    return 'Google login failed: $error';
  }

  @override
  String appleLoginFailed(Object error) {
    return 'Apple login failed: $error';
  }

  @override
  String kakaoLoginFailed(Object error) {
    return 'Kakao login failed: $error';
  }

  @override
  String get home => 'Home';

  @override
  String get kanji => 'Kanji';

  @override
  String get words => 'Words';

  @override
  String get quiz => 'Quiz';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageSettings => 'Language Settings';

  @override
  String get appLanguage => 'App language';

  @override
  String get kanjiMeaningLanguage => 'Kanji meaning language';

  @override
  String get wordMeaningLanguage => 'Word meaning language';

  @override
  String get korean => '한국어';

  @override
  String get japanese => '日本語';

  @override
  String get english => 'English';

  @override
  String get account => 'Account';

  @override
  String get accountDetails => 'Login and account settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationDetails => 'Study reminders and time settings';

  @override
  String get learningGoal => 'Learning Goal';

  @override
  String get learningGoalDetails => 'Daily word count and JLPT target';

  @override
  String get aiSettings => 'AI Settings';

  @override
  String get aiSettingsDetails => 'Manage Gemini API key';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacyDetails => 'Data collection and deletion guide';

  @override
  String get appInfo => 'App Info';

  @override
  String get appInfoDetails => 'Version and developer info';

  @override
  String get filter => 'Filter';

  @override
  String get studyStatus => 'Study status';

  @override
  String get all => 'All';

  @override
  String get notStudied => 'Not studied';

  @override
  String get completed => 'Completed';

  @override
  String get forgotWord => 'Forgotten words';

  @override
  String get forgotKanji => 'Forgotten kanji';

  @override
  String get forgotAction => 'Forgot';

  @override
  String get grade => 'Grade';

  @override
  String get middleSchoolPlus => 'Middle school+';

  @override
  String get done => 'Done';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Exit';

  @override
  String get searchWordsHint => 'Search by Japanese, meaning, or furigana...';

  @override
  String get searchKanjiHint => 'Search by kanji, meaning, or reading...';

  @override
  String searchResultShown(Object value) {
    return 'Showing results for $value';
  }

  @override
  String get noFavoriteWords => 'No favorite words';

  @override
  String get noFavoriteKanji => 'No favorite kanji';

  @override
  String get noSearchResults => 'No results';

  @override
  String get noWordsToStudy => 'No words to study';

  @override
  String get noKanjiToStudy => 'No kanji to study';

  @override
  String favoriteSaveFailed(Object error) {
    return 'Failed to save favorite: $error';
  }

  @override
  String get studyCompletedToast => 'Study completion recorded.';

  @override
  String get studyForgotToast => 'Forgotten item recorded.';

  @override
  String get recording => 'Recording...';

  @override
  String get studyRecords => 'Study records';

  @override
  String get noStudyRecords => 'No study records';

  @override
  String recordSaveFailed(Object error) {
    return 'Failed to save record: $error';
  }

  @override
  String get flashcardStudy => 'Flashcards';

  @override
  String get flashcardCompleted => 'All cards studied.';

  @override
  String get studyCompleteTitle => 'Study Complete!';

  @override
  String get totalCards => 'Total cards';

  @override
  String get correctCount => 'Correct';

  @override
  String get incorrectCount => 'Incorrect';

  @override
  String get accuracy => 'Accuracy';

  @override
  String countItems(int count) {
    return '$count';
  }

  @override
  String countWords(int count) {
    return '$count';
  }

  @override
  String get exitStudy => 'Exit study';

  @override
  String get exitStudyBody =>
      'Exit this flashcard session?\nYour progress will be saved.';

  @override
  String get dontKnow => 'I don\'t know';

  @override
  String get know => 'I know';

  @override
  String get tapToFlip => 'Tap the card to flip';

  @override
  String get cardLoadFailed => 'Could not load this card';

  @override
  String get showStrokeOrder => 'Show stroke order';

  @override
  String get hideStrokeOrder => 'Hide stroke order';

  @override
  String get meaning => 'Meaning';

  @override
  String get radical => 'Radical';

  @override
  String get kunReading => 'Kun reading';

  @override
  String get onReading => 'On reading';

  @override
  String get kanjiCommentary => 'Kanji commentary';

  @override
  String get examples => 'Examples';

  @override
  String get generateExamples => 'Generate examples';

  @override
  String get generatingExamples => 'Generating examples...';

  @override
  String get sourceAi => 'AI generated';

  @override
  String get sourceUser => 'User provided';

  @override
  String get sourceManual => 'Manual entry';

  @override
  String exampleGenerateFailed(Object error) {
    return 'Failed to generate examples: $error';
  }

  @override
  String get noMeaning => 'No meaning available';

  @override
  String get apiKeySaved => 'API key saved.';

  @override
  String get apiKeyHint => 'Enter API key';

  @override
  String get saveApiKey => 'Save API key';

  @override
  String get getApiKey => 'Get API key';

  @override
  String get getApiKeyDetails => 'Free from Google AI Studio';

  @override
  String get aiStudioOpenFailed =>
      'Open aistudio.google.com in your browser to create an API key.';

  @override
  String get aiInfo => 'Use Gemini API to generate examples and study content.';

  @override
  String get apiKeyPrivacy =>
      'The API key is stored on this device and used only when generating examples.';

  @override
  String get studyNotification => 'Study reminders';

  @override
  String get studyNotificationDetails => 'Get reminded to study every day';

  @override
  String get notificationPermissionError =>
      'Please check notification permissions.';

  @override
  String get notificationTime => 'Reminder time';

  @override
  String get notificationInfo =>
      'Use notifications to build a steady study habit. You can receive a daily reminder at the selected time.';

  @override
  String get logout => 'Log out';

  @override
  String get deleteStudyData => 'Delete study data';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get offlineMode => 'Offline mode';

  @override
  String get searchGenericHint => 'Search...';

  @override
  String get delete => 'Delete';

  @override
  String get guestUser => 'Guest user';

  @override
  String get userFallback => 'User';

  @override
  String get guestAccountSubtitle =>
      'Link a social account to keep your data safe';

  @override
  String get signedInWithEmail => 'Signed in with email';

  @override
  String get guestDataLossWarning =>
      'Guest account data may be lost if the app is deleted.';

  @override
  String get logoutGuestWarning =>
      'Logging out of a guest account may delete study records. Continue?';

  @override
  String get logoutConfirmBody => 'Are you sure you want to log out?';

  @override
  String get logoutFailed => 'Failed to log out.';

  @override
  String get deleteStudyDataBody =>
      'Deletes study records, favorites, and AI quiz history. Account login information is kept.';

  @override
  String get studyDataDeleted => 'Study data deleted.';

  @override
  String get deleteStudyDataFailed => 'Failed to delete data.';

  @override
  String get deleteAccountBody =>
      'Deletes your account and study data stored on the server. This cannot be undone.';

  @override
  String get accountDeleteRequested => 'Account deletion requested.';

  @override
  String get deleteAccountUnavailable =>
      'Please check the account deletion server function. No data was deleted.';

  @override
  String get appSubtitle => 'Study Japanese kanji and words together';

  @override
  String get versionLabel => 'Version';

  @override
  String get developerLabel => 'Developer';

  @override
  String get serverStoredData => 'Data stored on the server';

  @override
  String get accountIdentifier => 'Account identifier';

  @override
  String get accountIdentifierBody =>
      'Keep login active and sync study records across devices';

  @override
  String get emailAddress => 'Email address';

  @override
  String get emailAddressBody => 'Show and authenticate social login account';

  @override
  String get learningActivity => 'Learning activity';

  @override
  String get learningActivityBody =>
      'Sync study records, favorites, and quiz results';

  @override
  String get deviceOnlyData => 'Data stored only on this device';

  @override
  String get learningContentCache => 'Study content cache';

  @override
  String get learningContentCacheBody => 'Kanji and word data for offline use';

  @override
  String get geminiApiKey => 'Gemini API key';

  @override
  String get geminiApiKeyBody =>
      'Used for examples and quizzes when you enter one';

  @override
  String get notificationSettings => 'Notification settings';

  @override
  String get notificationSettingsBody =>
      'Daily study reminder time and enabled state';

  @override
  String get privacyInfo =>
      'We do not use data for ad tracking. You can delete account and study data from Settings > Account.';

  @override
  String get selectFlashcardCount => 'Choose how many cards to study';

  @override
  String get enterCount => 'Enter a count';

  @override
  String get invalidNumber => 'Enter a valid number';

  @override
  String get minimumOneCount => 'Choose at least 1 card';

  @override
  String maxCountAllowed(int count) {
    return 'You can choose up to $count cards';
  }

  @override
  String get directInput => 'Or enter directly:';

  @override
  String get countUnit => 'cards';

  @override
  String allWithCount(int count) {
    return 'All ($count)';
  }

  @override
  String get start => 'Start';

  @override
  String get findKanjiByHandwriting => 'Find kanji by handwriting';

  @override
  String get writeOneCharacterFirst => 'Write one character first.';

  @override
  String get noMatchingKanjiCandidates =>
      'No kanji candidates matched the app data.';

  @override
  String get findWordByHandwriting => 'Find words by handwriting';

  @override
  String get writeWordFirst => 'Write a word first.';

  @override
  String get noMatchingWordCandidates =>
      'No word candidates matched the app data.';

  @override
  String get handwritingModelRequired =>
      'Download the Japanese handwriting model first.';

  @override
  String modelStatusFailed(Object error) {
    return 'Could not check model status: $error';
  }

  @override
  String get modelDownloadFailed => 'Failed to download the model.';

  @override
  String modelDownloadError(Object error) {
    return 'An error occurred while downloading the model: $error';
  }

  @override
  String get noRecognitionResults =>
      'No recognition results. Try writing larger and more clearly.';

  @override
  String get handwritingModelDownload => 'Download handwriting model';

  @override
  String get handwritingModelDownloadBody =>
      'Download once, then use it immediately after that.';

  @override
  String get downloadModel => 'Download model';

  @override
  String get recognize => 'Recognize';

  @override
  String get clear => 'Clear';

  @override
  String get recognitionCandidates => 'Candidates';

  @override
  String get aiQuiz => 'AI Quiz';

  @override
  String get recentQuizRecords => 'Recent quiz records';

  @override
  String get generatingQuiz => 'AI is generating a quiz...';

  @override
  String quizGenerateFailed(Object error) {
    return 'Failed to generate quiz: $error';
  }

  @override
  String get apiKeyRequired => 'API key required';

  @override
  String get apiKeyRequiredBody =>
      'A Gemini API key is required to use AI quizzes.\nEnter your API key in Settings.';

  @override
  String get goToSettings => 'Go to settings';

  @override
  String get jpToMeaningQuizTitle => 'JP→Meaning';

  @override
  String get meaningToJpQuizTitle => 'Meaning→JP';

  @override
  String get meaningQuiz => 'Meaning quiz';

  @override
  String get wordQuiz => 'Word quiz';

  @override
  String get furigana => 'Furigana';

  @override
  String get fillBlank => 'Fill in the blank';

  @override
  String correctAnswerCount(int correct, int total) {
    return '$correct/$total correct';
  }

  @override
  String get wordStudy => 'Word study';

  @override
  String get kanjiStudy => 'Kanji study';

  @override
  String get wordFlashcards => 'Word flashcards';

  @override
  String get kanjiFlashcards => 'Kanji flashcards';

  @override
  String get todayRelative => 'Today';

  @override
  String get yesterdayRelative => 'Yesterday';

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get initialDataRequiresInternet =>
      'An internet connection is required to download initial data.';

  @override
  String get learningGoalSaved => 'Learning goal saved.';

  @override
  String get learningGoalSavedLocalOnly =>
      'Learning goal saved. Server sync will be retried later.';

  @override
  String get learningGoalSaveFailed => 'Failed to save learning goal.';

  @override
  String get noTodayWords => 'No words to study today';

  @override
  String get todayGoalSetup => 'Set today\'s learning goal';

  @override
  String get todayGoalSetupBody =>
      'Set a daily word count and target JLPT level to get today\'s recommended words.';

  @override
  String get saveGoal => 'Save goal';

  @override
  String get todayWordStudy => 'Today\'s word study';

  @override
  String dailyGoalSummary(int level, int count) {
    return '$count words around JLPT N$level';
  }

  @override
  String get progress => 'Progress';

  @override
  String get dailyGoalCompleted => 'Today\'s goal is complete.';

  @override
  String remainingWords(int count) {
    return '$count words remaining';
  }

  @override
  String get thisWeek => 'This week';

  @override
  String get todayStudyCompleted => 'Today\'s study complete';

  @override
  String get todayWords => 'Words to study today';

  @override
  String otherWordsCount(int count) {
    return '$count more words';
  }

  @override
  String get startTodayStudy => 'Start today\'s study';

  @override
  String get review => 'Review';

  @override
  String get newWord => 'New word';

  @override
  String get enoughStudyToday => 'You\'ve studied enough today';

  @override
  String get tomorrowRecommendations =>
      'New words will be recommended again tomorrow.';

  @override
  String get noRecommendations =>
      'Could not find words to recommend. Try again when word data is ready.';

  @override
  String get dailyWordCount => 'Daily word count';

  @override
  String get targetJlpt => 'Target JLPT';
}

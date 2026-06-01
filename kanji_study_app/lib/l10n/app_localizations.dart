import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ko, this message translates to:
  /// **'콘나칸지'**
  String get appTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'일본어 공부, 바로 이런 느낌!'**
  String get loginSubtitle;

  /// No description provided for @continueWithGoogle.
  ///
  /// In ko, this message translates to:
  /// **'Google로 계속하기'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In ko, this message translates to:
  /// **'Apple로 계속하기'**
  String get continueWithApple;

  /// No description provided for @continueWithKakao.
  ///
  /// In ko, this message translates to:
  /// **'카카오로 계속하기'**
  String get continueWithKakao;

  /// No description provided for @orDivider.
  ///
  /// In ko, this message translates to:
  /// **'또는'**
  String get orDivider;

  /// No description provided for @startAsGuest.
  ///
  /// In ko, this message translates to:
  /// **'게스트로 시작하기'**
  String get startAsGuest;

  /// No description provided for @guestStartInfo.
  ///
  /// In ko, this message translates to:
  /// **'게스트로 시작하면 나중에 SNS 계정을 연동하여 데이터를 안전하게 보관할 수 있습니다.'**
  String get guestStartInfo;

  /// No description provided for @guestLoginFailed.
  ///
  /// In ko, this message translates to:
  /// **'게스트 로그인 실패: {error}'**
  String guestLoginFailed(Object error);

  /// No description provided for @googleLoginFailed.
  ///
  /// In ko, this message translates to:
  /// **'Google 로그인 실패: {error}'**
  String googleLoginFailed(Object error);

  /// No description provided for @appleLoginFailed.
  ///
  /// In ko, this message translates to:
  /// **'Apple 로그인 실패: {error}'**
  String appleLoginFailed(Object error);

  /// No description provided for @kakaoLoginFailed.
  ///
  /// In ko, this message translates to:
  /// **'카카오 로그인 실패: {error}'**
  String kakaoLoginFailed(Object error);

  /// No description provided for @home.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get home;

  /// No description provided for @kanji.
  ///
  /// In ko, this message translates to:
  /// **'한자'**
  String get kanji;

  /// No description provided for @words.
  ///
  /// In ko, this message translates to:
  /// **'단어'**
  String get words;

  /// No description provided for @quiz.
  ///
  /// In ko, this message translates to:
  /// **'퀴즈'**
  String get quiz;

  /// No description provided for @profile.
  ///
  /// In ko, this message translates to:
  /// **'프로필'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get language;

  /// No description provided for @languageSettings.
  ///
  /// In ko, this message translates to:
  /// **'언어 설정'**
  String get languageSettings;

  /// No description provided for @appLanguage.
  ///
  /// In ko, this message translates to:
  /// **'앱 언어'**
  String get appLanguage;

  /// No description provided for @kanjiMeaningLanguage.
  ///
  /// In ko, this message translates to:
  /// **'한자 뜻 언어'**
  String get kanjiMeaningLanguage;

  /// No description provided for @wordMeaningLanguage.
  ///
  /// In ko, this message translates to:
  /// **'단어 뜻 언어'**
  String get wordMeaningLanguage;

  /// No description provided for @korean.
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get korean;

  /// No description provided for @japanese.
  ///
  /// In ko, this message translates to:
  /// **'日本語'**
  String get japanese;

  /// No description provided for @english.
  ///
  /// In ko, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @account.
  ///
  /// In ko, this message translates to:
  /// **'계정 관리'**
  String get account;

  /// No description provided for @accountDetails.
  ///
  /// In ko, this message translates to:
  /// **'로그인 정보 및 계정 설정'**
  String get accountDetails;

  /// No description provided for @notifications.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get notifications;

  /// No description provided for @notificationDetails.
  ///
  /// In ko, this message translates to:
  /// **'학습 알림 및 시간 설정'**
  String get notificationDetails;

  /// No description provided for @learningGoal.
  ///
  /// In ko, this message translates to:
  /// **'학습 목표'**
  String get learningGoal;

  /// No description provided for @learningGoalDetails.
  ///
  /// In ko, this message translates to:
  /// **'하루 단어 수와 목표 JLPT 설정'**
  String get learningGoalDetails;

  /// No description provided for @aiSettings.
  ///
  /// In ko, this message translates to:
  /// **'AI 설정'**
  String get aiSettings;

  /// No description provided for @aiSettingsDetails.
  ///
  /// In ko, this message translates to:
  /// **'Gemini API 키 관리'**
  String get aiSettingsDetails;

  /// No description provided for @privacy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보'**
  String get privacy;

  /// No description provided for @privacyDetails.
  ///
  /// In ko, this message translates to:
  /// **'수집 데이터 및 삭제 안내'**
  String get privacyDetails;

  /// No description provided for @appInfo.
  ///
  /// In ko, this message translates to:
  /// **'앱 정보'**
  String get appInfo;

  /// No description provided for @appInfoDetails.
  ///
  /// In ko, this message translates to:
  /// **'버전 및 개발자 정보'**
  String get appInfoDetails;

  /// No description provided for @filter.
  ///
  /// In ko, this message translates to:
  /// **'필터'**
  String get filter;

  /// No description provided for @studyStatus.
  ///
  /// In ko, this message translates to:
  /// **'학습 상태'**
  String get studyStatus;

  /// No description provided for @all.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get all;

  /// No description provided for @notStudied.
  ///
  /// In ko, this message translates to:
  /// **'미학습'**
  String get notStudied;

  /// No description provided for @completed.
  ///
  /// In ko, this message translates to:
  /// **'학습 완료'**
  String get completed;

  /// No description provided for @forgotWord.
  ///
  /// In ko, this message translates to:
  /// **'까먹은 단어'**
  String get forgotWord;

  /// No description provided for @forgotKanji.
  ///
  /// In ko, this message translates to:
  /// **'까먹은 한자'**
  String get forgotKanji;

  /// No description provided for @forgotAction.
  ///
  /// In ko, this message translates to:
  /// **'까먹음'**
  String get forgotAction;

  /// No description provided for @grade.
  ///
  /// In ko, this message translates to:
  /// **'학년'**
  String get grade;

  /// No description provided for @middleSchoolPlus.
  ///
  /// In ko, this message translates to:
  /// **'중학교+'**
  String get middleSchoolPlus;

  /// No description provided for @done.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get done;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get close;

  /// No description provided for @searchWordsHint.
  ///
  /// In ko, this message translates to:
  /// **'일본어, 한글, 후리가나로 검색...'**
  String get searchWordsHint;

  /// No description provided for @searchKanjiHint.
  ///
  /// In ko, this message translates to:
  /// **'한자, 의미, 읽기로 검색...'**
  String get searchKanjiHint;

  /// No description provided for @searchResultShown.
  ///
  /// In ko, this message translates to:
  /// **'{value} 검색 결과를 표시합니다'**
  String searchResultShown(Object value);

  /// No description provided for @noFavoriteWords.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기한 단어가 없습니다'**
  String get noFavoriteWords;

  /// No description provided for @noFavoriteKanji.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기한 한자가 없습니다'**
  String get noFavoriteKanji;

  /// No description provided for @noSearchResults.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다'**
  String get noSearchResults;

  /// No description provided for @noWordsToStudy.
  ///
  /// In ko, this message translates to:
  /// **'학습할 단어가 없습니다'**
  String get noWordsToStudy;

  /// No description provided for @noKanjiToStudy.
  ///
  /// In ko, this message translates to:
  /// **'학습할 한자가 없습니다'**
  String get noKanjiToStudy;

  /// No description provided for @favoriteSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기 저장 실패: {error}'**
  String favoriteSaveFailed(Object error);

  /// No description provided for @studyCompletedToast.
  ///
  /// In ko, this message translates to:
  /// **'학습 완료를 기록했습니다!'**
  String get studyCompletedToast;

  /// No description provided for @studyForgotToast.
  ///
  /// In ko, this message translates to:
  /// **'까먹음을 기록했습니다.'**
  String get studyForgotToast;

  /// No description provided for @recording.
  ///
  /// In ko, this message translates to:
  /// **'기록 중...'**
  String get recording;

  /// No description provided for @studyRecords.
  ///
  /// In ko, this message translates to:
  /// **'학습 기록'**
  String get studyRecords;

  /// No description provided for @noStudyRecords.
  ///
  /// In ko, this message translates to:
  /// **'학습 기록이 없습니다'**
  String get noStudyRecords;

  /// No description provided for @recordSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'기록 저장 실패: {error}'**
  String recordSaveFailed(Object error);

  /// No description provided for @flashcardStudy.
  ///
  /// In ko, this message translates to:
  /// **'플래시카드 학습'**
  String get flashcardStudy;

  /// No description provided for @flashcardCompleted.
  ///
  /// In ko, this message translates to:
  /// **'모든 카드를 학습했습니다!'**
  String get flashcardCompleted;

  /// No description provided for @studyCompleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'학습 완료!'**
  String get studyCompleteTitle;

  /// No description provided for @totalCards.
  ///
  /// In ko, this message translates to:
  /// **'총 학습 카드'**
  String get totalCards;

  /// No description provided for @correctCount.
  ///
  /// In ko, this message translates to:
  /// **'맞힌 개수'**
  String get correctCount;

  /// No description provided for @incorrectCount.
  ///
  /// In ko, this message translates to:
  /// **'틀린 개수'**
  String get incorrectCount;

  /// No description provided for @accuracy.
  ///
  /// In ko, this message translates to:
  /// **'정확도'**
  String get accuracy;

  /// No description provided for @countItems.
  ///
  /// In ko, this message translates to:
  /// **'{count}개'**
  String countItems(int count);

  /// No description provided for @exitStudy.
  ///
  /// In ko, this message translates to:
  /// **'학습 종료'**
  String get exitStudy;

  /// No description provided for @exitStudyBody.
  ///
  /// In ko, this message translates to:
  /// **'플래시카드 학습을 종료하시겠습니까?\n진행 상태가 저장됩니다.'**
  String get exitStudyBody;

  /// No description provided for @dontKnow.
  ///
  /// In ko, this message translates to:
  /// **'모르겠어요'**
  String get dontKnow;

  /// No description provided for @know.
  ///
  /// In ko, this message translates to:
  /// **'알았어요'**
  String get know;

  /// No description provided for @tapToFlip.
  ///
  /// In ko, this message translates to:
  /// **'카드를 탭하여 뒤집기'**
  String get tapToFlip;

  /// No description provided for @cardLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'카드를 불러올 수 없습니다'**
  String get cardLoadFailed;

  /// No description provided for @showStrokeOrder.
  ///
  /// In ko, this message translates to:
  /// **'획순 보기'**
  String get showStrokeOrder;

  /// No description provided for @hideStrokeOrder.
  ///
  /// In ko, this message translates to:
  /// **'획순 숨기기'**
  String get hideStrokeOrder;

  /// No description provided for @meaning.
  ///
  /// In ko, this message translates to:
  /// **'의미'**
  String get meaning;

  /// No description provided for @radical.
  ///
  /// In ko, this message translates to:
  /// **'부수'**
  String get radical;

  /// No description provided for @kunReading.
  ///
  /// In ko, this message translates to:
  /// **'훈독'**
  String get kunReading;

  /// No description provided for @onReading.
  ///
  /// In ko, this message translates to:
  /// **'음독'**
  String get onReading;

  /// No description provided for @kanjiCommentary.
  ///
  /// In ko, this message translates to:
  /// **'한자 해설'**
  String get kanjiCommentary;

  /// No description provided for @examples.
  ///
  /// In ko, this message translates to:
  /// **'예문'**
  String get examples;

  /// No description provided for @generateExamples.
  ///
  /// In ko, this message translates to:
  /// **'예문 생성'**
  String get generateExamples;

  /// No description provided for @generatingExamples.
  ///
  /// In ko, this message translates to:
  /// **'예문 생성 중...'**
  String get generatingExamples;

  /// No description provided for @sourceAi.
  ///
  /// In ko, this message translates to:
  /// **'AI 생성'**
  String get sourceAi;

  /// No description provided for @sourceUser.
  ///
  /// In ko, this message translates to:
  /// **'사용자 제공'**
  String get sourceUser;

  /// No description provided for @sourceManual.
  ///
  /// In ko, this message translates to:
  /// **'수동 입력'**
  String get sourceManual;

  /// No description provided for @exampleGenerateFailed.
  ///
  /// In ko, this message translates to:
  /// **'예문 생성 실패: {error}'**
  String exampleGenerateFailed(Object error);

  /// No description provided for @noMeaning.
  ///
  /// In ko, this message translates to:
  /// **'뜻 정보 없음'**
  String get noMeaning;

  /// No description provided for @apiKeySaved.
  ///
  /// In ko, this message translates to:
  /// **'API 키가 저장되었습니다.'**
  String get apiKeySaved;

  /// No description provided for @apiKeyHint.
  ///
  /// In ko, this message translates to:
  /// **'API 키를 입력하세요'**
  String get apiKeyHint;

  /// No description provided for @saveApiKey.
  ///
  /// In ko, this message translates to:
  /// **'API 키 저장'**
  String get saveApiKey;

  /// No description provided for @getApiKey.
  ///
  /// In ko, this message translates to:
  /// **'API 키 받기'**
  String get getApiKey;

  /// No description provided for @getApiKeyDetails.
  ///
  /// In ko, this message translates to:
  /// **'Google AI Studio에서 무료로 발급'**
  String get getApiKeyDetails;

  /// No description provided for @aiStudioOpenFailed.
  ///
  /// In ko, this message translates to:
  /// **'브라우저에서 aistudio.google.com을 방문하여 API 키를 생성하세요.'**
  String get aiStudioOpenFailed;

  /// No description provided for @aiInfo.
  ///
  /// In ko, this message translates to:
  /// **'Gemini API를 사용하여 예문 생성 및 학습 콘텐츠를 만들 수 있습니다.'**
  String get aiInfo;

  /// No description provided for @apiKeyPrivacy.
  ///
  /// In ko, this message translates to:
  /// **'API 키는 기기에 안전하게 저장되며, 예문 생성 요청 시에만 사용됩니다.'**
  String get apiKeyPrivacy;

  /// No description provided for @studyNotification.
  ///
  /// In ko, this message translates to:
  /// **'학습 알림'**
  String get studyNotification;

  /// No description provided for @studyNotificationDetails.
  ///
  /// In ko, this message translates to:
  /// **'매일 학습 시간을 알려드려요'**
  String get studyNotificationDetails;

  /// No description provided for @notificationPermissionError.
  ///
  /// In ko, this message translates to:
  /// **'알림 권한을 확인해주세요.'**
  String get notificationPermissionError;

  /// No description provided for @notificationTime.
  ///
  /// In ko, this message translates to:
  /// **'알림 시간'**
  String get notificationTime;

  /// No description provided for @notificationInfo.
  ///
  /// In ko, this message translates to:
  /// **'알림을 통해 꾸준한 학습 습관을 만들어보세요. 설정한 시간에 매일 학습 알림을 받을 수 있습니다.'**
  String get notificationInfo;

  /// No description provided for @logout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get logout;

  /// No description provided for @deleteStudyData.
  ///
  /// In ko, this message translates to:
  /// **'학습 데이터 삭제'**
  String get deleteStudyData;

  /// No description provided for @deleteAccount.
  ///
  /// In ko, this message translates to:
  /// **'계정 삭제'**
  String get deleteAccount;

  /// No description provided for @offlineMode.
  ///
  /// In ko, this message translates to:
  /// **'오프라인 모드'**
  String get offlineMode;

  /// No description provided for @searchGenericHint.
  ///
  /// In ko, this message translates to:
  /// **'검색...'**
  String get searchGenericHint;

  /// No description provided for @delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get delete;

  /// No description provided for @guestUser.
  ///
  /// In ko, this message translates to:
  /// **'게스트 사용자'**
  String get guestUser;

  /// No description provided for @userFallback.
  ///
  /// In ko, this message translates to:
  /// **'사용자'**
  String get userFallback;

  /// No description provided for @guestAccountSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'소셜 계정 연동으로 데이터를 안전하게 보관하세요'**
  String get guestAccountSubtitle;

  /// No description provided for @signedInWithEmail.
  ///
  /// In ko, this message translates to:
  /// **'이메일로 로그인됨'**
  String get signedInWithEmail;

  /// No description provided for @guestDataLossWarning.
  ///
  /// In ko, this message translates to:
  /// **'게스트 계정은 앱 삭제 시 데이터가 손실될 수 있습니다.'**
  String get guestDataLossWarning;

  /// No description provided for @logoutGuestWarning.
  ///
  /// In ko, this message translates to:
  /// **'게스트 계정에서 로그아웃하면 학습 기록이 삭제될 수 있습니다. 계속하시겠습니까?'**
  String get logoutGuestWarning;

  /// No description provided for @logoutConfirmBody.
  ///
  /// In ko, this message translates to:
  /// **'정말 로그아웃 하시겠습니까?'**
  String get logoutConfirmBody;

  /// No description provided for @logoutFailed.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃 중 오류가 발생했습니다.'**
  String get logoutFailed;

  /// No description provided for @deleteStudyDataBody.
  ///
  /// In ko, this message translates to:
  /// **'학습 기록, 즐겨찾기, AI 퀴즈 기록을 삭제합니다. 계정 로그인 정보는 유지됩니다.'**
  String get deleteStudyDataBody;

  /// No description provided for @studyDataDeleted.
  ///
  /// In ko, this message translates to:
  /// **'학습 데이터가 삭제되었습니다.'**
  String get studyDataDeleted;

  /// No description provided for @deleteStudyDataFailed.
  ///
  /// In ko, this message translates to:
  /// **'데이터 삭제 중 오류가 발생했습니다.'**
  String get deleteStudyDataFailed;

  /// No description provided for @deleteAccountBody.
  ///
  /// In ko, this message translates to:
  /// **'계정과 서버에 저장된 학습 데이터를 삭제합니다. 이 작업은 되돌릴 수 없습니다.'**
  String get deleteAccountBody;

  /// No description provided for @accountDeleteRequested.
  ///
  /// In ko, this message translates to:
  /// **'계정 삭제가 요청되었습니다.'**
  String get accountDeleteRequested;

  /// No description provided for @deleteAccountUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'계정 삭제 서버 기능을 확인해주세요. 데이터는 삭제되지 않았습니다.'**
  String get deleteAccountUnavailable;

  /// No description provided for @appSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'일본어 한자와 단어를 이어서 학습하는 앱'**
  String get appSubtitle;

  /// No description provided for @versionLabel.
  ///
  /// In ko, this message translates to:
  /// **'버전'**
  String get versionLabel;

  /// No description provided for @developerLabel.
  ///
  /// In ko, this message translates to:
  /// **'개발자'**
  String get developerLabel;

  /// No description provided for @serverStoredData.
  ///
  /// In ko, this message translates to:
  /// **'서버에 저장되는 데이터'**
  String get serverStoredData;

  /// No description provided for @accountIdentifier.
  ///
  /// In ko, this message translates to:
  /// **'계정 식별자'**
  String get accountIdentifier;

  /// No description provided for @accountIdentifierBody.
  ///
  /// In ko, this message translates to:
  /// **'로그인 유지, 기기 간 학습 기록 동기화'**
  String get accountIdentifierBody;

  /// No description provided for @emailAddress.
  ///
  /// In ko, this message translates to:
  /// **'이메일 주소'**
  String get emailAddress;

  /// No description provided for @emailAddressBody.
  ///
  /// In ko, this message translates to:
  /// **'소셜 로그인 계정 표시 및 인증'**
  String get emailAddressBody;

  /// No description provided for @learningActivity.
  ///
  /// In ko, this message translates to:
  /// **'학습 활동'**
  String get learningActivity;

  /// No description provided for @learningActivityBody.
  ///
  /// In ko, this message translates to:
  /// **'학습 기록, 즐겨찾기, 퀴즈 결과 동기화'**
  String get learningActivityBody;

  /// No description provided for @deviceOnlyData.
  ///
  /// In ko, this message translates to:
  /// **'기기에만 저장되는 데이터'**
  String get deviceOnlyData;

  /// No description provided for @learningContentCache.
  ///
  /// In ko, this message translates to:
  /// **'학습 콘텐츠 캐시'**
  String get learningContentCache;

  /// No description provided for @learningContentCacheBody.
  ///
  /// In ko, this message translates to:
  /// **'오프라인 사용을 위한 한자/단어 데이터'**
  String get learningContentCacheBody;

  /// No description provided for @geminiApiKey.
  ///
  /// In ko, this message translates to:
  /// **'Gemini API 키'**
  String get geminiApiKey;

  /// No description provided for @geminiApiKeyBody.
  ///
  /// In ko, this message translates to:
  /// **'사용자가 입력한 경우 예문/퀴즈 생성에 사용'**
  String get geminiApiKeyBody;

  /// No description provided for @notificationSettings.
  ///
  /// In ko, this message translates to:
  /// **'알림 설정'**
  String get notificationSettings;

  /// No description provided for @notificationSettingsBody.
  ///
  /// In ko, this message translates to:
  /// **'매일 학습 알림 시간과 사용 여부'**
  String get notificationSettingsBody;

  /// No description provided for @privacyInfo.
  ///
  /// In ko, this message translates to:
  /// **'광고 추적에는 사용하지 않습니다. 계정 및 학습 데이터 삭제는 설정 > 계정 관리에서 시작할 수 있습니다.'**
  String get privacyInfo;

  /// No description provided for @selectFlashcardCount.
  ///
  /// In ko, this message translates to:
  /// **'학습할 카드 개수를 선택하세요'**
  String get selectFlashcardCount;

  /// No description provided for @enterCount.
  ///
  /// In ko, this message translates to:
  /// **'개수를 입력해주세요'**
  String get enterCount;

  /// No description provided for @invalidNumber.
  ///
  /// In ko, this message translates to:
  /// **'올바른 숫자를 입력해주세요'**
  String get invalidNumber;

  /// No description provided for @minimumOneCount.
  ///
  /// In ko, this message translates to:
  /// **'최소 1개 이상 선택해주세요'**
  String get minimumOneCount;

  /// No description provided for @maxCountAllowed.
  ///
  /// In ko, this message translates to:
  /// **'최대 {count}개까지 선택 가능합니다'**
  String maxCountAllowed(int count);

  /// No description provided for @directInput.
  ///
  /// In ko, this message translates to:
  /// **'또는 직접 입력:'**
  String get directInput;

  /// No description provided for @countUnit.
  ///
  /// In ko, this message translates to:
  /// **'개'**
  String get countUnit;

  /// No description provided for @allWithCount.
  ///
  /// In ko, this message translates to:
  /// **'전체 ({count}개)'**
  String allWithCount(int count);

  /// No description provided for @start.
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get start;

  /// No description provided for @findKanjiByHandwriting.
  ///
  /// In ko, this message translates to:
  /// **'손글씨로 한자 찾기'**
  String get findKanjiByHandwriting;

  /// No description provided for @writeOneCharacterFirst.
  ///
  /// In ko, this message translates to:
  /// **'먼저 한 글자를 써주세요.'**
  String get writeOneCharacterFirst;

  /// No description provided for @noMatchingKanjiCandidates.
  ///
  /// In ko, this message translates to:
  /// **'앱 데이터와 일치하는 한자 후보를 찾지 못했습니다.'**
  String get noMatchingKanjiCandidates;

  /// No description provided for @findWordByHandwriting.
  ///
  /// In ko, this message translates to:
  /// **'손글씨로 단어 찾기'**
  String get findWordByHandwriting;

  /// No description provided for @writeWordFirst.
  ///
  /// In ko, this message translates to:
  /// **'먼저 단어를 써주세요.'**
  String get writeWordFirst;

  /// No description provided for @noMatchingWordCandidates.
  ///
  /// In ko, this message translates to:
  /// **'앱 데이터와 일치하는 단어 후보를 찾지 못했습니다.'**
  String get noMatchingWordCandidates;

  /// No description provided for @handwritingModelRequired.
  ///
  /// In ko, this message translates to:
  /// **'일본어 필기 인식 모델을 먼저 내려받아야 합니다.'**
  String get handwritingModelRequired;

  /// No description provided for @modelStatusFailed.
  ///
  /// In ko, this message translates to:
  /// **'모델 상태를 확인하지 못했습니다: {error}'**
  String modelStatusFailed(Object error);

  /// No description provided for @modelDownloadFailed.
  ///
  /// In ko, this message translates to:
  /// **'모델 다운로드에 실패했습니다.'**
  String get modelDownloadFailed;

  /// No description provided for @modelDownloadError.
  ///
  /// In ko, this message translates to:
  /// **'모델 다운로드 중 오류가 발생했습니다: {error}'**
  String modelDownloadError(Object error);

  /// No description provided for @noRecognitionResults.
  ///
  /// In ko, this message translates to:
  /// **'인식 결과가 없습니다. 조금 더 크게 또박또박 써보세요.'**
  String get noRecognitionResults;

  /// No description provided for @handwritingModelDownload.
  ///
  /// In ko, this message translates to:
  /// **'필기 인식 모델 다운로드'**
  String get handwritingModelDownload;

  /// No description provided for @handwritingModelDownloadBody.
  ///
  /// In ko, this message translates to:
  /// **'처음 한 번만 다운로드하면 이후에는 바로 사용할 수 있습니다.'**
  String get handwritingModelDownloadBody;

  /// No description provided for @downloadModel.
  ///
  /// In ko, this message translates to:
  /// **'모델 다운로드'**
  String get downloadModel;

  /// No description provided for @recognize.
  ///
  /// In ko, this message translates to:
  /// **'인식'**
  String get recognize;

  /// No description provided for @clear.
  ///
  /// In ko, this message translates to:
  /// **'지우기'**
  String get clear;

  /// No description provided for @recognitionCandidates.
  ///
  /// In ko, this message translates to:
  /// **'인식 후보'**
  String get recognitionCandidates;

  /// No description provided for @aiQuiz.
  ///
  /// In ko, this message translates to:
  /// **'AI 퀴즈'**
  String get aiQuiz;

  /// No description provided for @recentQuizRecords.
  ///
  /// In ko, this message translates to:
  /// **'최근 퀴즈 기록'**
  String get recentQuizRecords;

  /// No description provided for @generatingQuiz.
  ///
  /// In ko, this message translates to:
  /// **'AI가 퀴즈를 생성하고 있습니다...'**
  String get generatingQuiz;

  /// No description provided for @quizGenerateFailed.
  ///
  /// In ko, this message translates to:
  /// **'퀴즈 생성 실패: {error}'**
  String quizGenerateFailed(Object error);

  /// No description provided for @apiKeyRequired.
  ///
  /// In ko, this message translates to:
  /// **'API 키 필요'**
  String get apiKeyRequired;

  /// No description provided for @apiKeyRequiredBody.
  ///
  /// In ko, this message translates to:
  /// **'AI 퀴즈를 사용하려면 Gemini API 키가 필요합니다.\n설정에서 API 키를 입력해주세요.'**
  String get apiKeyRequiredBody;

  /// No description provided for @goToSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정으로 이동'**
  String get goToSettings;

  /// No description provided for @jpToMeaningQuizTitle.
  ///
  /// In ko, this message translates to:
  /// **'일→한'**
  String get jpToMeaningQuizTitle;

  /// No description provided for @meaningToJpQuizTitle.
  ///
  /// In ko, this message translates to:
  /// **'한→일'**
  String get meaningToJpQuizTitle;

  /// No description provided for @meaningQuiz.
  ///
  /// In ko, this message translates to:
  /// **'뜻 맞추기'**
  String get meaningQuiz;

  /// No description provided for @wordQuiz.
  ///
  /// In ko, this message translates to:
  /// **'단어 맞추기'**
  String get wordQuiz;

  /// No description provided for @furigana.
  ///
  /// In ko, this message translates to:
  /// **'후리가나'**
  String get furigana;

  /// No description provided for @fillBlank.
  ///
  /// In ko, this message translates to:
  /// **'문장 완성'**
  String get fillBlank;

  /// No description provided for @correctAnswerCount.
  ///
  /// In ko, this message translates to:
  /// **'{correct}/{total} 정답'**
  String correctAnswerCount(int correct, int total);

  /// No description provided for @wordStudy.
  ///
  /// In ko, this message translates to:
  /// **'단어 학습'**
  String get wordStudy;

  /// No description provided for @kanjiStudy.
  ///
  /// In ko, this message translates to:
  /// **'한자 학습'**
  String get kanjiStudy;

  /// No description provided for @wordFlashcards.
  ///
  /// In ko, this message translates to:
  /// **'단어 플래시카드'**
  String get wordFlashcards;

  /// No description provided for @kanjiFlashcards.
  ///
  /// In ko, this message translates to:
  /// **'한자 플래시카드'**
  String get kanjiFlashcards;

  /// No description provided for @todayRelative.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get todayRelative;

  /// No description provided for @yesterdayRelative.
  ///
  /// In ko, this message translates to:
  /// **'어제'**
  String get yesterdayRelative;

  /// No description provided for @daysAgo.
  ///
  /// In ko, this message translates to:
  /// **'{count}일 전'**
  String daysAgo(int count);

  /// No description provided for @initialDataRequiresInternet.
  ///
  /// In ko, this message translates to:
  /// **'초기 데이터 다운로드를 위해 인터넷 연결이 필요합니다.'**
  String get initialDataRequiresInternet;

  /// No description provided for @learningGoalSaved.
  ///
  /// In ko, this message translates to:
  /// **'학습 목표를 저장했습니다.'**
  String get learningGoalSaved;

  /// No description provided for @learningGoalSavedLocalOnly.
  ///
  /// In ko, this message translates to:
  /// **'학습 목표를 저장했습니다. 서버 동기화는 나중에 다시 시도됩니다.'**
  String get learningGoalSavedLocalOnly;

  /// No description provided for @learningGoalSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'학습 목표 저장에 실패했습니다.'**
  String get learningGoalSaveFailed;

  /// No description provided for @noTodayWords.
  ///
  /// In ko, this message translates to:
  /// **'오늘 학습할 단어가 없습니다'**
  String get noTodayWords;

  /// No description provided for @todayGoalSetup.
  ///
  /// In ko, this message translates to:
  /// **'오늘 학습 목표 설정'**
  String get todayGoalSetup;

  /// No description provided for @todayGoalSetupBody.
  ///
  /// In ko, this message translates to:
  /// **'하루 단어 수와 목표 JLPT를 설정하면 오늘 학습할 단어를 바로 추천해드릴게요.'**
  String get todayGoalSetupBody;

  /// No description provided for @saveGoal.
  ///
  /// In ko, this message translates to:
  /// **'목표 저장'**
  String get saveGoal;

  /// No description provided for @todayWordStudy.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 단어 학습'**
  String get todayWordStudy;

  /// No description provided for @dailyGoalSummary.
  ///
  /// In ko, this message translates to:
  /// **'JLPT N{level} 중심으로 {count}개'**
  String dailyGoalSummary(int level, int count);

  /// No description provided for @progress.
  ///
  /// In ko, this message translates to:
  /// **'진행도'**
  String get progress;

  /// No description provided for @dailyGoalCompleted.
  ///
  /// In ko, this message translates to:
  /// **'오늘 목표를 완료했습니다.'**
  String get dailyGoalCompleted;

  /// No description provided for @remainingWords.
  ///
  /// In ko, this message translates to:
  /// **'남은 단어 {count}개'**
  String remainingWords(int count);

  /// No description provided for @thisWeek.
  ///
  /// In ko, this message translates to:
  /// **'이번 주'**
  String get thisWeek;

  /// No description provided for @todayStudyCompleted.
  ///
  /// In ko, this message translates to:
  /// **'오늘 학습 완료'**
  String get todayStudyCompleted;

  /// No description provided for @todayWords.
  ///
  /// In ko, this message translates to:
  /// **'오늘 학습할 단어'**
  String get todayWords;

  /// No description provided for @otherWordsCount.
  ///
  /// In ko, this message translates to:
  /// **'외 {count}개 단어'**
  String otherWordsCount(int count);

  /// No description provided for @startTodayStudy.
  ///
  /// In ko, this message translates to:
  /// **'오늘 학습 시작'**
  String get startTodayStudy;

  /// No description provided for @review.
  ///
  /// In ko, this message translates to:
  /// **'복습'**
  String get review;

  /// No description provided for @newWord.
  ///
  /// In ko, this message translates to:
  /// **'새 단어'**
  String get newWord;

  /// No description provided for @enoughStudyToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘은 충분히 학습했어요'**
  String get enoughStudyToday;

  /// No description provided for @tomorrowRecommendations.
  ///
  /// In ko, this message translates to:
  /// **'내일 다시 새로운 단어를 추천해드릴게요.'**
  String get tomorrowRecommendations;

  /// No description provided for @noRecommendations.
  ///
  /// In ko, this message translates to:
  /// **'추천할 단어를 찾지 못했습니다. 단어 데이터가 준비되면 다시 시도해주세요.'**
  String get noRecommendations;

  /// No description provided for @dailyWordCount.
  ///
  /// In ko, this message translates to:
  /// **'하루 단어 수'**
  String get dailyWordCount;

  /// No description provided for @targetJlpt.
  ///
  /// In ko, this message translates to:
  /// **'목표 JLPT'**
  String get targetJlpt;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

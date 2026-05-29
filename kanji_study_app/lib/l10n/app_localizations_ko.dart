// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '콘나칸지';

  @override
  String get home => '홈';

  @override
  String get kanji => '한자';

  @override
  String get words => '단어';

  @override
  String get quiz => '퀴즈';

  @override
  String get profile => '프로필';

  @override
  String get settings => '설정';

  @override
  String get language => '언어';

  @override
  String get languageSettings => '언어 설정';

  @override
  String get appLanguage => '앱 언어';

  @override
  String get kanjiMeaningLanguage => '한자 뜻 언어';

  @override
  String get wordMeaningLanguage => '단어 뜻 언어';

  @override
  String get korean => '한국어';

  @override
  String get japanese => '日本語';

  @override
  String get english => 'English';

  @override
  String get account => '계정 관리';

  @override
  String get accountDetails => '로그인 정보 및 계정 설정';

  @override
  String get notifications => '알림';

  @override
  String get notificationDetails => '학습 알림 및 시간 설정';

  @override
  String get learningGoal => '학습 목표';

  @override
  String get learningGoalDetails => '하루 단어 수와 목표 JLPT 설정';

  @override
  String get aiSettings => 'AI 설정';

  @override
  String get aiSettingsDetails => 'Gemini API 키 관리';

  @override
  String get privacy => '개인정보';

  @override
  String get privacyDetails => '수집 데이터 및 삭제 안내';

  @override
  String get appInfo => '앱 정보';

  @override
  String get appInfoDetails => '버전 및 개발자 정보';

  @override
  String get filter => '필터';

  @override
  String get studyStatus => '학습 상태';

  @override
  String get all => '전체';

  @override
  String get notStudied => '미학습';

  @override
  String get completed => '학습 완료';

  @override
  String get forgotWord => '까먹은 단어';

  @override
  String get forgotKanji => '까먹은 한자';

  @override
  String get forgotAction => '까먹음';

  @override
  String get grade => '학년';

  @override
  String get middleSchoolPlus => '중학교+';

  @override
  String get done => '완료';

  @override
  String get cancel => '취소';

  @override
  String get close => '종료';

  @override
  String get searchWordsHint => '일본어, 한글, 후리가나로 검색...';

  @override
  String get searchKanjiHint => '한자, 의미, 읽기로 검색...';

  @override
  String searchResultShown(Object value) {
    return '$value 검색 결과를 표시합니다';
  }

  @override
  String get noFavoriteWords => '즐겨찾기한 단어가 없습니다';

  @override
  String get noFavoriteKanji => '즐겨찾기한 한자가 없습니다';

  @override
  String get noSearchResults => '검색 결과가 없습니다';

  @override
  String get noWordsToStudy => '학습할 단어가 없습니다';

  @override
  String get noKanjiToStudy => '학습할 한자가 없습니다';

  @override
  String favoriteSaveFailed(Object error) {
    return '즐겨찾기 저장 실패: $error';
  }

  @override
  String get studyCompletedToast => '학습 완료를 기록했습니다!';

  @override
  String get studyForgotToast => '까먹음을 기록했습니다.';

  @override
  String get recording => '기록 중...';

  @override
  String get studyRecords => '학습 기록';

  @override
  String get noStudyRecords => '학습 기록이 없습니다';

  @override
  String recordSaveFailed(Object error) {
    return '기록 저장 실패: $error';
  }

  @override
  String get flashcardStudy => '플래시카드 학습';

  @override
  String get flashcardCompleted => '모든 카드를 학습했습니다!';

  @override
  String get studyCompleteTitle => '학습 완료!';

  @override
  String get totalCards => '총 학습 카드';

  @override
  String get correctCount => '맞힌 개수';

  @override
  String get incorrectCount => '틀린 개수';

  @override
  String get accuracy => '정확도';

  @override
  String countItems(int count) {
    return '$count개';
  }

  @override
  String get exitStudy => '학습 종료';

  @override
  String get exitStudyBody => '플래시카드 학습을 종료하시겠습니까?\n진행 상태가 저장됩니다.';

  @override
  String get dontKnow => '모르겠어요';

  @override
  String get know => '알았어요';

  @override
  String get tapToFlip => '카드를 탭하여 뒤집기';

  @override
  String get cardLoadFailed => '카드를 불러올 수 없습니다';

  @override
  String get showStrokeOrder => '획순 보기';

  @override
  String get hideStrokeOrder => '획순 숨기기';

  @override
  String get meaning => '의미';

  @override
  String get radical => '부수';

  @override
  String get kunReading => '훈독';

  @override
  String get onReading => '음독';

  @override
  String get kanjiCommentary => '한자 해설';

  @override
  String get examples => '예문';

  @override
  String get generateExamples => '예문 생성';

  @override
  String get generatingExamples => '예문 생성 중...';

  @override
  String get sourceAi => 'AI 생성';

  @override
  String get sourceUser => '사용자 제공';

  @override
  String get sourceManual => '수동 입력';

  @override
  String exampleGenerateFailed(Object error) {
    return '예문 생성 실패: $error';
  }

  @override
  String get noMeaning => '뜻 정보 없음';

  @override
  String get apiKeySaved => 'API 키가 저장되었습니다.';

  @override
  String get apiKeyHint => 'API 키를 입력하세요';

  @override
  String get saveApiKey => 'API 키 저장';

  @override
  String get getApiKey => 'API 키 받기';

  @override
  String get getApiKeyDetails => 'Google AI Studio에서 무료로 발급';

  @override
  String get aiStudioOpenFailed =>
      '브라우저에서 aistudio.google.com을 방문하여 API 키를 생성하세요.';

  @override
  String get aiInfo => 'Gemini API를 사용하여 예문 생성 및 학습 콘텐츠를 만들 수 있습니다.';

  @override
  String get apiKeyPrivacy => 'API 키는 기기에 안전하게 저장되며, 예문 생성 요청 시에만 사용됩니다.';

  @override
  String get studyNotification => '학습 알림';

  @override
  String get studyNotificationDetails => '매일 학습 시간을 알려드려요';

  @override
  String get notificationPermissionError => '알림 권한을 확인해주세요.';

  @override
  String get notificationTime => '알림 시간';

  @override
  String get notificationInfo =>
      '알림을 통해 꾸준한 학습 습관을 만들어보세요. 설정한 시간에 매일 학습 알림을 받을 수 있습니다.';

  @override
  String get logout => '로그아웃';

  @override
  String get deleteStudyData => '학습 데이터 삭제';

  @override
  String get deleteAccount => '계정 삭제';

  @override
  String get offlineMode => '오프라인 모드';

  @override
  String get searchGenericHint => '검색...';

  @override
  String get delete => '삭제';

  @override
  String get guestUser => '게스트 사용자';

  @override
  String get userFallback => '사용자';

  @override
  String get guestAccountSubtitle => '소셜 계정 연동으로 데이터를 안전하게 보관하세요';

  @override
  String get signedInWithEmail => '이메일로 로그인됨';

  @override
  String get guestDataLossWarning => '게스트 계정은 앱 삭제 시 데이터가 손실될 수 있습니다.';

  @override
  String get logoutGuestWarning =>
      '게스트 계정에서 로그아웃하면 학습 기록이 삭제될 수 있습니다. 계속하시겠습니까?';

  @override
  String get logoutConfirmBody => '정말 로그아웃 하시겠습니까?';

  @override
  String get logoutFailed => '로그아웃 중 오류가 발생했습니다.';

  @override
  String get deleteStudyDataBody =>
      '학습 기록, 즐겨찾기, AI 퀴즈 기록을 삭제합니다. 계정 로그인 정보는 유지됩니다.';

  @override
  String get studyDataDeleted => '학습 데이터가 삭제되었습니다.';

  @override
  String get deleteStudyDataFailed => '데이터 삭제 중 오류가 발생했습니다.';

  @override
  String get deleteAccountBody =>
      '계정과 서버에 저장된 학습 데이터를 삭제합니다. 이 작업은 되돌릴 수 없습니다.';

  @override
  String get accountDeleteRequested => '계정 삭제가 요청되었습니다.';

  @override
  String get deleteAccountUnavailable =>
      '계정 삭제 서버 기능을 확인해주세요. 데이터는 삭제되지 않았습니다.';

  @override
  String get appSubtitle => '일본어 한자와 단어를 이어서 학습하는 앱';

  @override
  String get versionLabel => '버전';

  @override
  String get developerLabel => '개발자';

  @override
  String get serverStoredData => '서버에 저장되는 데이터';

  @override
  String get accountIdentifier => '계정 식별자';

  @override
  String get accountIdentifierBody => '로그인 유지, 기기 간 학습 기록 동기화';

  @override
  String get emailAddress => '이메일 주소';

  @override
  String get emailAddressBody => '소셜 로그인 계정 표시 및 인증';

  @override
  String get learningActivity => '학습 활동';

  @override
  String get learningActivityBody => '학습 기록, 즐겨찾기, 퀴즈 결과 동기화';

  @override
  String get deviceOnlyData => '기기에만 저장되는 데이터';

  @override
  String get learningContentCache => '학습 콘텐츠 캐시';

  @override
  String get learningContentCacheBody => '오프라인 사용을 위한 한자/단어 데이터';

  @override
  String get geminiApiKey => 'Gemini API 키';

  @override
  String get geminiApiKeyBody => '사용자가 입력한 경우 예문/퀴즈 생성에 사용';

  @override
  String get notificationSettings => '알림 설정';

  @override
  String get notificationSettingsBody => '매일 학습 알림 시간과 사용 여부';

  @override
  String get privacyInfo =>
      '광고 추적에는 사용하지 않습니다. 계정 및 학습 데이터 삭제는 설정 > 계정 관리에서 시작할 수 있습니다.';

  @override
  String get selectFlashcardCount => '학습할 카드 개수를 선택하세요';

  @override
  String get enterCount => '개수를 입력해주세요';

  @override
  String get invalidNumber => '올바른 숫자를 입력해주세요';

  @override
  String get minimumOneCount => '최소 1개 이상 선택해주세요';

  @override
  String maxCountAllowed(int count) {
    return '최대 $count개까지 선택 가능합니다';
  }

  @override
  String get directInput => '또는 직접 입력:';

  @override
  String get countUnit => '개';

  @override
  String allWithCount(int count) {
    return '전체 ($count개)';
  }

  @override
  String get start => '시작';

  @override
  String get findKanjiByHandwriting => '손글씨로 한자 찾기';

  @override
  String get writeOneCharacterFirst => '먼저 한 글자를 써주세요.';

  @override
  String get noMatchingKanjiCandidates => '앱 데이터와 일치하는 한자 후보를 찾지 못했습니다.';

  @override
  String get findWordByHandwriting => '손글씨로 단어 찾기';

  @override
  String get writeWordFirst => '먼저 단어를 써주세요.';

  @override
  String get noMatchingWordCandidates => '앱 데이터와 일치하는 단어 후보를 찾지 못했습니다.';

  @override
  String get handwritingModelRequired => '일본어 필기 인식 모델을 먼저 내려받아야 합니다.';

  @override
  String modelStatusFailed(Object error) {
    return '모델 상태를 확인하지 못했습니다: $error';
  }

  @override
  String get modelDownloadFailed => '모델 다운로드에 실패했습니다.';

  @override
  String modelDownloadError(Object error) {
    return '모델 다운로드 중 오류가 발생했습니다: $error';
  }

  @override
  String get noRecognitionResults => '인식 결과가 없습니다. 조금 더 크게 또박또박 써보세요.';

  @override
  String get handwritingModelDownload => '필기 인식 모델 다운로드';

  @override
  String get handwritingModelDownloadBody =>
      '처음 한 번만 다운로드하면 이후에는 바로 사용할 수 있습니다.';

  @override
  String get downloadModel => '모델 다운로드';

  @override
  String get recognize => '인식';

  @override
  String get clear => '지우기';

  @override
  String get recognitionCandidates => '인식 후보';

  @override
  String get aiQuiz => 'AI 퀴즈';

  @override
  String get recentQuizRecords => '최근 퀴즈 기록';

  @override
  String get generatingQuiz => 'AI가 퀴즈를 생성하고 있습니다...';

  @override
  String quizGenerateFailed(Object error) {
    return '퀴즈 생성 실패: $error';
  }

  @override
  String get apiKeyRequired => 'API 키 필요';

  @override
  String get apiKeyRequiredBody =>
      'AI 퀴즈를 사용하려면 Gemini API 키가 필요합니다.\n설정에서 API 키를 입력해주세요.';

  @override
  String get goToSettings => '설정으로 이동';

  @override
  String get jpToMeaningQuizTitle => '일→한';

  @override
  String get meaningToJpQuizTitle => '한→일';

  @override
  String get meaningQuiz => '뜻 맞추기';

  @override
  String get wordQuiz => '단어 맞추기';

  @override
  String get furigana => '후리가나';

  @override
  String get fillBlank => '문장 완성';

  @override
  String correctAnswerCount(int correct, int total) {
    return '$correct/$total 정답';
  }

  @override
  String get wordStudy => '단어 학습';

  @override
  String get kanjiStudy => '한자 학습';

  @override
  String get wordFlashcards => '단어 플래시카드';

  @override
  String get kanjiFlashcards => '한자 플래시카드';

  @override
  String get todayRelative => '오늘';

  @override
  String get yesterdayRelative => '어제';

  @override
  String daysAgo(int count) {
    return '$count일 전';
  }

  @override
  String get initialDataRequiresInternet => '초기 데이터 다운로드를 위해 인터넷 연결이 필요합니다.';

  @override
  String get learningGoalSaved => '학습 목표를 저장했습니다.';

  @override
  String get learningGoalSavedLocalOnly =>
      '학습 목표를 저장했습니다. 서버 동기화는 나중에 다시 시도됩니다.';

  @override
  String get learningGoalSaveFailed => '학습 목표 저장에 실패했습니다.';

  @override
  String get noTodayWords => '오늘 학습할 단어가 없습니다';

  @override
  String get todayGoalSetup => '오늘 학습 목표 설정';

  @override
  String get todayGoalSetupBody =>
      '하루 단어 수와 목표 JLPT를 설정하면 오늘 학습할 단어를 바로 추천해드릴게요.';

  @override
  String get saveGoal => '목표 저장';

  @override
  String get todayWordStudy => '오늘의 단어 학습';

  @override
  String dailyGoalSummary(int level, int count) {
    return 'JLPT N$level 중심으로 $count개';
  }

  @override
  String get progress => '진행도';

  @override
  String get dailyGoalCompleted => '오늘 목표를 완료했습니다.';

  @override
  String remainingWords(int count) {
    return '남은 단어 $count개';
  }

  @override
  String get thisWeek => '이번 주';

  @override
  String get todayStudyCompleted => '오늘 학습 완료';

  @override
  String get todayWords => '오늘 학습할 단어';

  @override
  String otherWordsCount(int count) {
    return '외 $count개 단어';
  }

  @override
  String get startTodayStudy => '오늘 학습 시작';

  @override
  String get review => '복습';

  @override
  String get newWord => '새 단어';

  @override
  String get enoughStudyToday => '오늘은 충분히 학습했어요';

  @override
  String get tomorrowRecommendations => '내일 다시 새로운 단어를 추천해드릴게요.';

  @override
  String get noRecommendations => '추천할 단어를 찾지 못했습니다. 단어 데이터가 준비되면 다시 시도해주세요.';

  @override
  String get dailyWordCount => '하루 단어 수';

  @override
  String get targetJlpt => '목표 JLPT';
}

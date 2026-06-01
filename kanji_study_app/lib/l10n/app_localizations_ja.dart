// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'こんな漢字';

  @override
  String get loginSubtitle => '日本語学習、ちょうどこんな感じ';

  @override
  String get continueWithGoogle => 'Googleで続ける';

  @override
  String get continueWithApple => 'Appleで続ける';

  @override
  String get continueWithKakao => 'カカオで続ける';

  @override
  String get orDivider => 'または';

  @override
  String get startAsGuest => 'ゲストとして始める';

  @override
  String get guestStartInfo => 'ゲストとして始めても、あとでSNSアカウントを連携してデータを安全に保管できます。';

  @override
  String guestLoginFailed(Object error) {
    return 'ゲストログインに失敗しました: $error';
  }

  @override
  String googleLoginFailed(Object error) {
    return 'Googleログインに失敗しました: $error';
  }

  @override
  String appleLoginFailed(Object error) {
    return 'Appleログインに失敗しました: $error';
  }

  @override
  String kakaoLoginFailed(Object error) {
    return 'カカオログインに失敗しました: $error';
  }

  @override
  String get home => 'ホーム';

  @override
  String get kanji => '漢字';

  @override
  String get words => '単語';

  @override
  String get quiz => 'クイズ';

  @override
  String get profile => 'プロフィール';

  @override
  String get settings => '設定';

  @override
  String get language => '言語';

  @override
  String get languageSettings => '言語設定';

  @override
  String get appLanguage => 'アプリの言語';

  @override
  String get kanjiMeaningLanguage => '漢字の意味の言語';

  @override
  String get wordMeaningLanguage => '単語の意味の言語';

  @override
  String get korean => '한국어';

  @override
  String get japanese => '日本語';

  @override
  String get english => 'English';

  @override
  String get account => 'アカウント';

  @override
  String get accountDetails => 'ログイン情報とアカウント設定';

  @override
  String get notifications => '通知';

  @override
  String get notificationDetails => '学習通知と時間設定';

  @override
  String get learningGoal => '学習目標';

  @override
  String get learningGoalDetails => '1日の単語数と目標JLPTを設定';

  @override
  String get aiSettings => 'AI設定';

  @override
  String get aiSettingsDetails => 'Gemini APIキーの管理';

  @override
  String get privacy => 'プライバシー';

  @override
  String get privacyDetails => '収集データと削除案内';

  @override
  String get appInfo => 'アプリ情報';

  @override
  String get appInfoDetails => 'バージョンと開発者情報';

  @override
  String get filter => 'フィルター';

  @override
  String get studyStatus => '学習状況';

  @override
  String get all => 'すべて';

  @override
  String get notStudied => '未学習';

  @override
  String get completed => '学習完了';

  @override
  String get forgotWord => '忘れた単語';

  @override
  String get forgotKanji => '忘れた漢字';

  @override
  String get forgotAction => '忘れた';

  @override
  String get grade => '学年';

  @override
  String get middleSchoolPlus => '中学校+';

  @override
  String get done => '完了';

  @override
  String get cancel => 'キャンセル';

  @override
  String get close => '終了';

  @override
  String get searchWordsHint => '日本語、意味、ふりがなで検索...';

  @override
  String get searchKanjiHint => '漢字、意味、読みで検索...';

  @override
  String searchResultShown(Object value) {
    return '$value の検索結果を表示します';
  }

  @override
  String get noFavoriteWords => 'お気に入りの単語がありません';

  @override
  String get noFavoriteKanji => 'お気に入りの漢字がありません';

  @override
  String get noSearchResults => '検索結果がありません';

  @override
  String get noWordsToStudy => '学習する単語がありません';

  @override
  String get noKanjiToStudy => '学習する漢字がありません';

  @override
  String favoriteSaveFailed(Object error) {
    return 'お気に入りの保存に失敗しました: $error';
  }

  @override
  String get studyCompletedToast => '学習完了を記録しました。';

  @override
  String get studyForgotToast => '忘れた項目を記録しました。';

  @override
  String get recording => '記録中...';

  @override
  String get studyRecords => '学習記録';

  @override
  String get noStudyRecords => '学習記録がありません';

  @override
  String recordSaveFailed(Object error) {
    return '記録の保存に失敗しました: $error';
  }

  @override
  String get flashcardStudy => 'フラッシュカード学習';

  @override
  String get flashcardCompleted => 'すべてのカードを学習しました。';

  @override
  String get studyCompleteTitle => '学習完了！';

  @override
  String get totalCards => '総カード数';

  @override
  String get correctCount => '正解数';

  @override
  String get incorrectCount => '不正解数';

  @override
  String get accuracy => '正答率';

  @override
  String countItems(int count) {
    return '$count枚';
  }

  @override
  String get exitStudy => '学習を終了';

  @override
  String get exitStudyBody => 'フラッシュカード学習を終了しますか？\n進行状況は保存されます。';

  @override
  String get dontKnow => 'わからない';

  @override
  String get know => 'わかった';

  @override
  String get tapToFlip => 'カードをタップして裏返す';

  @override
  String get cardLoadFailed => 'カードを読み込めません';

  @override
  String get showStrokeOrder => '筆順を表示';

  @override
  String get hideStrokeOrder => '筆順を隠す';

  @override
  String get meaning => '意味';

  @override
  String get radical => '部首';

  @override
  String get kunReading => '訓読み';

  @override
  String get onReading => '音読み';

  @override
  String get kanjiCommentary => '漢字の解説';

  @override
  String get examples => '例文';

  @override
  String get generateExamples => '例文を生成';

  @override
  String get generatingExamples => '例文を生成中...';

  @override
  String get sourceAi => 'AI生成';

  @override
  String get sourceUser => 'ユーザー提供';

  @override
  String get sourceManual => '手動入力';

  @override
  String exampleGenerateFailed(Object error) {
    return '例文の生成に失敗しました: $error';
  }

  @override
  String get noMeaning => '意味情報なし';

  @override
  String get apiKeySaved => 'APIキーを保存しました。';

  @override
  String get apiKeyHint => 'APIキーを入力してください';

  @override
  String get saveApiKey => 'APIキーを保存';

  @override
  String get getApiKey => 'APIキーを取得';

  @override
  String get getApiKeyDetails => 'Google AI Studioで無料発行';

  @override
  String get aiStudioOpenFailed =>
      'ブラウザで aistudio.google.com を開いてAPIキーを作成してください。';

  @override
  String get aiInfo => 'Gemini APIを使って例文や学習コンテンツを生成できます。';

  @override
  String get apiKeyPrivacy => 'APIキーは端末に安全に保存され、例文生成時のみ使用されます。';

  @override
  String get studyNotification => '学習通知';

  @override
  String get studyNotificationDetails => '毎日の学習時間をお知らせします';

  @override
  String get notificationPermissionError => '通知権限を確認してください。';

  @override
  String get notificationTime => '通知時間';

  @override
  String get notificationInfo => '通知を使って学習習慣を作りましょう。設定した時間に毎日学習通知を受け取れます。';

  @override
  String get logout => 'ログアウト';

  @override
  String get deleteStudyData => '学習データを削除';

  @override
  String get deleteAccount => 'アカウント削除';

  @override
  String get offlineMode => 'オフラインモード';

  @override
  String get searchGenericHint => '検索...';

  @override
  String get delete => '削除';

  @override
  String get guestUser => 'ゲストユーザー';

  @override
  String get userFallback => 'ユーザー';

  @override
  String get guestAccountSubtitle => 'ソーシャルアカウント連携でデータを安全に保管できます';

  @override
  String get signedInWithEmail => 'メールでログイン中';

  @override
  String get guestDataLossWarning => 'ゲストアカウントはアプリ削除時にデータが失われることがあります。';

  @override
  String get logoutGuestWarning =>
      'ゲストアカウントからログアウトすると学習記録が削除されることがあります。続行しますか？';

  @override
  String get logoutConfirmBody => '本当にログアウトしますか？';

  @override
  String get logoutFailed => 'ログアウト中にエラーが発生しました。';

  @override
  String get deleteStudyDataBody =>
      '学習記録、お気に入り、AIクイズ履歴を削除します。アカウントのログイン情報は保持されます。';

  @override
  String get studyDataDeleted => '学習データを削除しました。';

  @override
  String get deleteStudyDataFailed => 'データ削除中にエラーが発生しました。';

  @override
  String get deleteAccountBody => 'アカウントとサーバーに保存された学習データを削除します。この操作は元に戻せません。';

  @override
  String get accountDeleteRequested => 'アカウント削除をリクエストしました。';

  @override
  String get deleteAccountUnavailable =>
      'アカウント削除のサーバー機能を確認してください。データは削除されていません。';

  @override
  String get appSubtitle => '日本語の漢字と単語をつなげて学習するアプリ';

  @override
  String get versionLabel => 'バージョン';

  @override
  String get developerLabel => '開発者';

  @override
  String get serverStoredData => 'サーバーに保存されるデータ';

  @override
  String get accountIdentifier => 'アカウント識別子';

  @override
  String get accountIdentifierBody => 'ログイン維持、端末間の学習記録同期';

  @override
  String get emailAddress => 'メールアドレス';

  @override
  String get emailAddressBody => 'ソーシャルログインアカウント表示と認証';

  @override
  String get learningActivity => '学習活動';

  @override
  String get learningActivityBody => '学習記録、お気に入り、クイズ結果の同期';

  @override
  String get deviceOnlyData => '端末のみに保存されるデータ';

  @override
  String get learningContentCache => '学習コンテンツキャッシュ';

  @override
  String get learningContentCacheBody => 'オフライン利用のための漢字・単語データ';

  @override
  String get geminiApiKey => 'Gemini APIキー';

  @override
  String get geminiApiKeyBody => '入力した場合、例文・クイズ生成に使用';

  @override
  String get notificationSettings => '通知設定';

  @override
  String get notificationSettingsBody => '毎日の学習通知時間と使用有無';

  @override
  String get privacyInfo =>
      '広告トラッキングには使用しません。アカウントと学習データの削除は 設定 > アカウント から開始できます。';

  @override
  String get selectFlashcardCount => '学習するカード数を選択してください';

  @override
  String get enterCount => '数を入力してください';

  @override
  String get invalidNumber => '有効な数字を入力してください';

  @override
  String get minimumOneCount => '1枚以上を選択してください';

  @override
  String maxCountAllowed(int count) {
    return '最大$count枚まで選択できます';
  }

  @override
  String get directInput => 'または直接入力:';

  @override
  String get countUnit => '枚';

  @override
  String allWithCount(int count) {
    return 'すべて ($count枚)';
  }

  @override
  String get start => '開始';

  @override
  String get findKanjiByHandwriting => '手書きで漢字を探す';

  @override
  String get writeOneCharacterFirst => '先に1文字を書いてください。';

  @override
  String get noMatchingKanjiCandidates => 'アプリデータと一致する漢字候補が見つかりませんでした。';

  @override
  String get findWordByHandwriting => '手書きで単語を探す';

  @override
  String get writeWordFirst => '先に単語を書いてください。';

  @override
  String get noMatchingWordCandidates => 'アプリデータと一致する単語候補が見つかりませんでした。';

  @override
  String get handwritingModelRequired => '日本語手書き認識モデルを先にダウンロードしてください。';

  @override
  String modelStatusFailed(Object error) {
    return 'モデル状態を確認できませんでした: $error';
  }

  @override
  String get modelDownloadFailed => 'モデルのダウンロードに失敗しました。';

  @override
  String modelDownloadError(Object error) {
    return 'モデルのダウンロード中にエラーが発生しました: $error';
  }

  @override
  String get noRecognitionResults => '認識結果がありません。もう少し大きく、はっきり書いてみてください。';

  @override
  String get handwritingModelDownload => '手書き認識モデルをダウンロード';

  @override
  String get handwritingModelDownloadBody => '最初に一度だけダウンロードすれば、その後はすぐに使用できます。';

  @override
  String get downloadModel => 'モデルをダウンロード';

  @override
  String get recognize => '認識';

  @override
  String get clear => '消去';

  @override
  String get recognitionCandidates => '認識候補';

  @override
  String get aiQuiz => 'AIクイズ';

  @override
  String get recentQuizRecords => '最近のクイズ記録';

  @override
  String get generatingQuiz => 'AIがクイズを生成しています...';

  @override
  String quizGenerateFailed(Object error) {
    return 'クイズ生成に失敗しました: $error';
  }

  @override
  String get apiKeyRequired => 'APIキーが必要です';

  @override
  String get apiKeyRequiredBody =>
      'AIクイズを使用するにはGemini APIキーが必要です。\n設定でAPIキーを入力してください。';

  @override
  String get goToSettings => '設定へ移動';

  @override
  String get jpToMeaningQuizTitle => '日→意味';

  @override
  String get meaningToJpQuizTitle => '意味→日';

  @override
  String get meaningQuiz => '意味クイズ';

  @override
  String get wordQuiz => '単語クイズ';

  @override
  String get furigana => 'ふりがな';

  @override
  String get fillBlank => '文を完成';

  @override
  String correctAnswerCount(int correct, int total) {
    return '$correct/$total 正解';
  }

  @override
  String get wordStudy => '単語学習';

  @override
  String get kanjiStudy => '漢字学習';

  @override
  String get wordFlashcards => '単語フラッシュカード';

  @override
  String get kanjiFlashcards => '漢字フラッシュカード';

  @override
  String get todayRelative => '今日';

  @override
  String get yesterdayRelative => '昨日';

  @override
  String daysAgo(int count) {
    return '$count日前';
  }

  @override
  String get initialDataRequiresInternet => '初期データのダウンロードにはインターネット接続が必要です。';

  @override
  String get learningGoalSaved => '学習目標を保存しました。';

  @override
  String get learningGoalSavedLocalOnly => '学習目標を保存しました。サーバー同期は後で再試行されます。';

  @override
  String get learningGoalSaveFailed => '学習目標の保存に失敗しました。';

  @override
  String get noTodayWords => '今日学習する単語がありません';

  @override
  String get todayGoalSetup => '今日の学習目標を設定';

  @override
  String get todayGoalSetupBody => '1日の単語数と目標JLPTを設定すると、今日学習する単語をすぐにおすすめします。';

  @override
  String get saveGoal => '目標を保存';

  @override
  String get todayWordStudy => '今日の単語学習';

  @override
  String dailyGoalSummary(int level, int count) {
    return 'JLPT N$level中心に$count語';
  }

  @override
  String get progress => '進捗';

  @override
  String get dailyGoalCompleted => '今日の目標を完了しました。';

  @override
  String remainingWords(int count) {
    return '残り$count語';
  }

  @override
  String get thisWeek => '今週';

  @override
  String get todayStudyCompleted => '今日の学習完了';

  @override
  String get todayWords => '今日学習する単語';

  @override
  String otherWordsCount(int count) {
    return 'ほか$count語';
  }

  @override
  String get startTodayStudy => '今日の学習を開始';

  @override
  String get review => '復習';

  @override
  String get newWord => '新しい単語';

  @override
  String get enoughStudyToday => '今日は十分に学習しました';

  @override
  String get tomorrowRecommendations => '明日また新しい単語をおすすめします。';

  @override
  String get noRecommendations => 'おすすめする単語が見つかりませんでした。単語データの準備後にもう一度お試しください。';

  @override
  String get dailyWordCount => '1日の単語数';

  @override
  String get targetJlpt => '目標JLPT';
}

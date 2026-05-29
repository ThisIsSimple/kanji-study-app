import 'package:flutter/widgets.dart';

import 'app_localizations.dart';
import 'app_localizations_ko.dart';

extension LocalizationBuildContext on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      AppLocalizationsKo();
}

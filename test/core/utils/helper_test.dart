import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_settings/core/utils/helper.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  group('getScreenTimeoutLabel', () {
    test('maps each supported timeout to its label', () {
      expect(getScreenTimeoutLabel(l10n, 10), l10n.screenOffTenSeconds);
      expect(getScreenTimeoutLabel(l10n, 30), l10n.screenOffThirtySeconds);
      expect(getScreenTimeoutLabel(l10n, 60), l10n.screenOffOneMinute);
      expect(getScreenTimeoutLabel(l10n, 120), l10n.screenOffTwoMinutes);
      expect(getScreenTimeoutLabel(l10n, 300), l10n.screenOffFiveMinutes);
      expect(getScreenTimeoutLabel(l10n, 0), l10n.screenOffNever);
    });

    test('falls back to Never for an unsupported timeout', () {
      expect(getScreenTimeoutLabel(l10n, 45), l10n.screenOffNever);
    });
  });
}

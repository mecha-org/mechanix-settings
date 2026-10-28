import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/display/blocs/display_bloc.dart';
import 'package:mechanix_settings/features/display/data/repositories/display_repository.dart';
import 'package:mechanix_settings/features/display/presentation/screens/display_screen.dart';
import 'package:mechanix_settings/features/display/presentation/screens/screen_off_time_screen.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:widgets/widgets.dart';

class MockDisplayRepository extends Mock implements DisplayRepository {}

void main() {
  late MockDisplayRepository mockRepository;
  late DisplayBloc displayBloc;

  setUp(() {
    mockRepository = MockDisplayRepository();
    when(() => mockRepository.init()).thenAnswer((_) async {});
    when(() => mockRepository.getBrightness()).thenAnswer((_) async => 0.5);
    when(() => mockRepository.getAutoBrightness()).thenAnswer((_) async => true);
    when(() => mockRepository.getScreenTimeout()).thenAnswer((_) async => 30);
    displayBloc = DisplayBloc(mockRepository);
  });

  tearDown(() async {
    await displayBloc.close();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<DisplayBloc>.value(
        value: displayBloc,
        child: const DisplayScreen(),
      ),
    );
  }

  testWidgets('verify tap on label navigates on first tap', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.byType(DisplayScreen));
    final l10n = AppLocalizations.of(context)!;

    await tester.tap(find.text(l10n.screenOffTime));
    await tester.pumpAndSettle();

    expect(find.byType(ScreenOffTimeScreen), findsOneWidget);
  });

  testWidgets('verify tap on timeout value text ("30 seconds") navigates on first tap', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.byType(DisplayScreen));
    final l10n = AppLocalizations.of(context)!;

    await tester.tap(find.text(l10n.screenOffThirtySeconds));
    await tester.pumpAndSettle();

    expect(find.byType(ScreenOffTimeScreen), findsOneWidget);
  });

  testWidgets('verify tap on caret button navigates on first tap', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final caretButton = find.byWidgetPredicate(
      (widget) =>
          widget is MechanixIconButton &&
          widget.icon is ImageIcon &&
          ((widget.icon as ImageIcon).image as AssetImage).assetName ==
              SettingIcons.caretRight,
    );

    await tester.tap(caretButton);
    await tester.pumpAndSettle();

    expect(find.byType(ScreenOffTimeScreen), findsOneWidget);
  });
}

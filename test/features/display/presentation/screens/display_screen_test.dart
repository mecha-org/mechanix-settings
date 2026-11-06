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
    when(
      () => mockRepository.changes(),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockRepository.watchWriteFailed(),
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockRepository.getBrightness()).thenAnswer((_) async => 0.5);
    when(
      () => mockRepository.getAutoBrightness(),
    ).thenAnswer((_) async => true);
    when(() => mockRepository.getScreenTimeout()).thenAnswer((_) async => 30);
    when(() => mockRepository.setBrightness(any())).thenAnswer((_) async {});
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

  testWidgets(
    'verify tap on timeout value text ("30 seconds") navigates on first tap',
    (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(DisplayScreen));
      final l10n = AppLocalizations.of(context)!;

      await tester.tap(find.text(l10n.screenOffThirtySeconds));
      await tester.pumpAndSettle();

      expect(find.byType(ScreenOffTimeScreen), findsOneWidget);
    },
  );

  testWidgets('verify tap on caret button navigates on first tap', (
    tester,
  ) async {
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

  testWidgets(
    'brightness slider displays initial value and percentage',
    (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('50 %'), findsOneWidget);
      final slider = tester.widget<MechanixSlider>(find.byType(MechanixSlider));
      expect(slider.value, equals(0.5));
    },
  );

  testWidgets(
    'brightness slider throttles onChanged updates and persists on onChangeEnd',
    (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final slider = tester.widget<MechanixSlider>(find.byType(MechanixSlider));

      // First change: leading edge triggers setBrightness immediately
      slider.onChanged!(0.6);
      await tester.pump();
      verify(() => mockRepository.setBrightness(0.6)).called(1);

      // Rapid changes within 200ms throttle interval are not sent immediately
      slider.onChanged!(0.7);
      slider.onChanged!(0.8);
      await tester.pump();
      verifyNever(() => mockRepository.setBrightness(0.7));
      verifyNever(() => mockRepository.setBrightness(0.8));

      // Advance by throttle duration: the latest pending value (0.8) is dispatched
      await tester.pump(const Duration(milliseconds: 200));
      verify(() => mockRepository.setBrightness(0.8)).called(1);

      // Ending drag immediately persists final brightness value
      slider.onChangeEnd!(0.95);
      await tester.pump();
      verify(() => mockRepository.setBrightness(0.95)).called(1);

      // Verify no duplicate timer fires later
      await tester.pump(const Duration(milliseconds: 250));
      verifyNever(() => mockRepository.setBrightness(0.95));
    },
  );
}

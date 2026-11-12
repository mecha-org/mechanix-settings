import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_settings/features/display/blocs/display_bloc.dart';
import 'package:mechanix_settings/features/display/blocs/display_event.dart';
import 'package:mechanix_settings/features/display/data/repositories/display_repository.dart';
import 'package:mechanix_settings/features/display/presentation/screens/screen_off_time_screen.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:widgets/widgets.dart';

class MockDisplayRepository extends Mock implements DisplayRepository {}

void main() {
  late MockDisplayRepository mockRepository;
  late DisplayBloc displayBloc;
  final l10n = lookupAppLocalizations(const Locale('en'));

  setUp(() {
    mockRepository = MockDisplayRepository();
    when(() => mockRepository.setScreenTimeout(any())).thenAnswer((_) async {});
    when(() => mockRepository.setBrightness(any())).thenAnswer((_) async {});
  });

  // The bloc is created inside the test zone so its emits run on the
  // FakeAsync clock that pumpAndSettle drives.
  Future<void> pumpScreen(WidgetTester tester) async {
    // Initial state has screenTimeout = 30.
    displayBloc = DisplayBloc(mockRepository);
    addTearDown(displayBloc.close);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<DisplayBloc>.value(
          value: displayBloc,
          child: const ScreenOffTimeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder findRadio(int value) => find.byWidgetPredicate(
    (widget) => widget is MechanixRadio<int> && widget.value == value,
  );

  int? selectedValue(WidgetTester tester) =>
      tester.widget<MechanixRadio<int>>(findRadio(30)).groupValue;

  testWidgets('shows all options in order with the current one selected', (
    tester,
  ) async {
    await pumpScreen(tester);

    final labels = [
      l10n.screenOffTenSeconds,
      l10n.screenOffThirtySeconds,
      l10n.screenOffOneMinute,
      l10n.screenOffTwoMinutes,
      l10n.screenOffFiveMinutes,
      l10n.screenOffNever,
    ];
    for (final label in labels) {
      expect(find.text(label), findsOneWidget);
    }
    final dys = labels.map((l) => tester.getCenter(find.text(l)).dy).toList();
    expect(dys, orderedEquals([...dys]..sort()));

    expect(find.byType(MechanixRadio<int>), findsNWidgets(6));
    expect(selectedValue(tester), 30);
  });

  testWidgets('tapping a row selects that timeout', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text(l10n.screenOffOneMinute));
    await tester.pumpAndSettle();

    verify(() => mockRepository.setScreenTimeout(60)).called(1);
    expect(selectedValue(tester), 60);
  });

  testWidgets('tapping the radio selects that timeout', (tester) async {
    await pumpScreen(tester);

    await tester.tap(findRadio(120));
    await tester.pumpAndSettle();

    verify(() => mockRepository.setScreenTimeout(120)).called(1);
    expect(selectedValue(tester), 120);
  });

  testWidgets('unrelated state changes keep the selection and app bar', (
    tester,
  ) async {
    await pumpScreen(tester);

    displayBloc.add(const SetBrightness(0.8));
    await tester.pumpAndSettle();

    expect(selectedValue(tester), 30);
    expect(find.byType(MechanixAppBar), findsOneWidget);
    expect(find.byType(MechanixRadio<int>), findsNWidgets(6));
  });
}

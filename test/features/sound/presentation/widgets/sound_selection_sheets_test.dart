import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mechanix_settings/features/sound/blocs/sound_bloc.dart';
import 'package:mechanix_settings/features/sound/blocs/sound_event.dart';
import 'package:mechanix_settings/features/sound/blocs/sound_state.dart';
import 'package:mechanix_settings/features/sound/presentation/widgets/sound_selection_sheets.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class MockSoundBloc extends MockBloc<SoundEvent, SoundState>
    implements SoundBloc {}

Widget createTestWidget({required Widget child, required SoundBloc bloc}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: BlocProvider<SoundBloc>.value(
        value: bloc,
        child: child,
      ),
    ),
  );
}

void main() {
  late MockSoundBloc mockSoundBloc;

  setUp(() {
    mockSoundBloc = MockSoundBloc();
  });

  group('OutputDeviceSheet', () {
    testWidgets('renders output devices from state and handles selection', (
      tester,
    ) async {
      when(() => mockSoundBloc.state).thenReturn(
        const SoundState(
          outputDevices: ['Built-in Speaker', 'HDMI Audio'],
          selectedOutputDevice: 'Built-in Speaker',
        ),
      );

      await tester.pumpWidget(
        createTestWidget(
          bloc: mockSoundBloc,
          child: const OutputDeviceSheet(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Built-in Speaker'), findsOneWidget);
      expect(find.text('HDMI Audio'), findsOneWidget);

      await tester.tap(find.text('HDMI Audio'));
      await tester.pump();

      verify(
        () => mockSoundBloc.add(const SetOutputDevice('HDMI Audio')),
      ).called(1);
    });
  });

  group('InputDeviceSheet', () {
    testWidgets('renders input devices from state and handles selection', (
      tester,
    ) async {
      when(() => mockSoundBloc.state).thenReturn(
        const SoundState(
          inputDevices: ['Internal Mic', 'USB Microphone'],
          selectedInputDevice: 'Internal Mic',
        ),
      );

      await tester.pumpWidget(
        createTestWidget(
          bloc: mockSoundBloc,
          child: const InputDeviceSheet(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Internal Mic'), findsOneWidget);
      expect(find.text('USB Microphone'), findsOneWidget);

      await tester.tap(find.text('USB Microphone'));
      await tester.pump();

      verify(
        () => mockSoundBloc.add(const SetInputDevice('USB Microphone')),
      ).called(1);
    });
  });
}

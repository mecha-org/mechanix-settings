import 'dart:async';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_settings/core/exceptions/display_exceptions.dart';
import 'package:mechanix_settings/features/display/data/models/display_enums.dart';
import 'package:mechanix_settings/features/display/data/repositories/display_repository.dart';
import 'package:mechanix_settings/features/display/blocs/display_bloc.dart';
import 'package:mechanix_settings/features/display/blocs/display_event.dart';
import 'package:mechanix_settings/features/display/blocs/display_state.dart';
import 'package:mechanix_settings/generated/settingsapp.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mxconfig_dart/mxconfig.dart';

class MockDisplayRepository extends Mock implements DisplayRepository {}

void main() {
  late DisplayBloc displayBloc;
  late MockDisplayRepository mockRepository;

  setUp(() {
    mockRepository = MockDisplayRepository();
    when(() => mockRepository.changes()).thenAnswer((_) => const Stream.empty());
    when(
      () => mockRepository.watchWriteFailed(),
    ).thenAnswer((_) => const Stream.empty());
    displayBloc = DisplayBloc(mockRepository);
  });

  tearDown(() async {
    await displayBloc.close();
  });

  group('DisplayBloc Initial State', () {
    test('initial state is correct', () {
      expect(displayBloc.state.brightness, equals(0.5));
      expect(displayBloc.state.isAutoBrightness, isTrue);
      expect(displayBloc.state.screenTimeout, equals(30));
      expect(displayBloc.state.status, equals(DisplayStatus.initial));
      expect(displayBloc.state.error, isNull);
    });
  });

  group('DisplayInit', () {
    blocTest<DisplayBloc, DisplayState>(
      'emits status loading and adds LoadDisplaySettings on success',
      build: () {
        when(() => mockRepository.init()).thenAnswer((_) async {});
        when(
          () => mockRepository.changes(),
        ).thenAnswer((_) => const Stream.empty());
        // Mocking getters that will be called in LoadDisplaySettings
        when(() => mockRepository.getBrightness()).thenAnswer((_) async => 0.8);
        when(
          () => mockRepository.getAutoBrightness(),
        ).thenAnswer((_) async => false);
        when(
          () => mockRepository.getScreenTimeout(),
        ).thenAnswer((_) async => 60);
        return displayBloc;
      },
      act: (bloc) => bloc.add(const DisplayInit()),
      expect: () => [
        const DisplayState(status: DisplayStatus.loading),
        const DisplayState(
          status: DisplayStatus.loaded,
          brightness: 0.8,
          isAutoBrightness: false,
          screenTimeout: 60,
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.init()).called(1);
      },
    );

    blocTest<DisplayBloc, DisplayState>(
      'emits loading and error status when repository init throws DisplayInitializationException',
      build: () {
        when(
          () => mockRepository.init(),
        ).thenThrow(const DisplayInitializationException());
        return displayBloc;
      },
      act: (bloc) => bloc.add(const DisplayInit()),
      expect: () => [
        const DisplayState(status: DisplayStatus.loading),
        const DisplayState(
          status: DisplayStatus.error,
          error: DisplayError.initializationFailed,
        ),
      ],
    );

    blocTest<DisplayBloc, DisplayState>(
      'emits loading and error status when repository init throws unexpected Exception',
      build: () {
        when(() => mockRepository.init()).thenThrow(Exception('Unexpected'));
        return displayBloc;
      },
      act: (bloc) => bloc.add(const DisplayInit()),
      expect: () => [
        const DisplayState(status: DisplayStatus.loading),
        const DisplayState(
          status: DisplayStatus.error,
          error: DisplayError.unknown,
        ),
      ],
    );
  });

  group('LoadDisplaySettings', () {
    blocTest<DisplayBloc, DisplayState>(
      'emits loading and loaded with settings on success',
      build: () {
        when(() => mockRepository.getBrightness()).thenAnswer((_) async => 0.4);
        when(
          () => mockRepository.getAutoBrightness(),
        ).thenAnswer((_) async => true);
        when(
          () => mockRepository.getScreenTimeout(),
        ).thenAnswer((_) async => 15);
        return displayBloc;
      },
      act: (bloc) => bloc.add(const LoadDisplaySettings()),
      expect: () => [
        const DisplayState(status: DisplayStatus.loading),
        const DisplayState(
          status: DisplayStatus.loaded,
          brightness: 0.4,
          isAutoBrightness: true,
          screenTimeout: 15,
        ),
      ],
    );

    blocTest<DisplayBloc, DisplayState>(
      'emits loading and error when loading settings throws exception',
      build: () {
        when(
          () => mockRepository.getBrightness(),
        ).thenThrow(Exception('Read failed'));
        return displayBloc;
      },
      act: (bloc) => bloc.add(const LoadDisplaySettings()),
      expect: () => [
        const DisplayState(status: DisplayStatus.loading),
        const DisplayState(
          status: DisplayStatus.error,
          error: DisplayError.unknown,
        ),
      ],
    );
  });

  group('SetBrightness', () {
    blocTest<DisplayBloc, DisplayState>(
      'emits state with updated brightness on success',
      build: () {
        when(() => mockRepository.setBrightness(0.7)).thenAnswer((_) async {});
        return displayBloc;
      },
      act: (bloc) => bloc.add(const SetBrightness(0.7)),
      expect: () => [const DisplayState(brightness: 0.7)],
      verify: (_) {
        verify(() => mockRepository.setBrightness(0.7)).called(1);
      },
    );

    blocTest<DisplayBloc, DisplayState>(
      'emits error with setBrightnessFailed on SetBrightnessException',
      build: () {
        when(
          () => mockRepository.setBrightness(0.7),
        ).thenThrow(const SetBrightnessException());
        return displayBloc;
      },
      act: (bloc) => bloc.add(const SetBrightness(0.7)),
      expect: () => [
        const DisplayState(
          status: DisplayStatus.error,
          error: DisplayError.setBrightnessFailed,
        ),
      ],
    );

    blocTest<DisplayBloc, DisplayState>(
      'emits error with unknown on unexpected Exception',
      build: () {
        when(
          () => mockRepository.setBrightness(0.7),
        ).thenThrow(Exception('Unexpected'));
        return displayBloc;
      },
      act: (bloc) => bloc.add(const SetBrightness(0.7)),
      expect: () => [
        const DisplayState(
          status: DisplayStatus.error,
          error: DisplayError.unknown,
        ),
      ],
    );
  });

  group('SetAutoBrightness', () {
    blocTest<DisplayBloc, DisplayState>(
      'emits state with updated auto-brightness status on success',
      build: () {
        when(
          () => mockRepository.setAutoBrightness(false),
        ).thenAnswer((_) async {});
        return displayBloc;
      },
      act: (bloc) => bloc.add(const SetAutoBrightness(false)),
      expect: () => [const DisplayState(isAutoBrightness: false)],
      verify: (_) {
        verify(() => mockRepository.setAutoBrightness(false)).called(1);
      },
    );

    blocTest<DisplayBloc, DisplayState>(
      'emits error with setAutoBrightnessFailed on SetAutoBrightnessException',
      build: () {
        when(
          () => mockRepository.setAutoBrightness(false),
        ).thenThrow(const SetAutoBrightnessException());
        return displayBloc;
      },
      act: (bloc) => bloc.add(const SetAutoBrightness(false)),
      expect: () => [
        const DisplayState(
          status: DisplayStatus.error,
          error: DisplayError.setAutoBrightnessFailed,
        ),
      ],
    );

    blocTest<DisplayBloc, DisplayState>(
      'emits error with unknown on unexpected Exception',
      build: () {
        when(
          () => mockRepository.setAutoBrightness(false),
        ).thenThrow(Exception('Unexpected'));
        return displayBloc;
      },
      act: (bloc) => bloc.add(const SetAutoBrightness(false)),
      expect: () => [
        const DisplayState(
          status: DisplayStatus.error,
          error: DisplayError.unknown,
        ),
      ],
    );
  });

  group('SetScreenTimeout', () {
    blocTest<DisplayBloc, DisplayState>(
      'emits state with updated screen timeout on success',
      build: () {
        when(
          () => mockRepository.setScreenTimeout(45),
        ).thenAnswer((_) async {});
        return displayBloc;
      },
      act: (bloc) => bloc.add(const SetScreenTimeout(45)),
      expect: () => [const DisplayState(screenTimeout: 45)],
      verify: (_) {
        verify(() => mockRepository.setScreenTimeout(45)).called(1);
      },
    );

    blocTest<DisplayBloc, DisplayState>(
      'emits error with setScreenTimeoutFailed on SetScreenTimeoutException',
      build: () {
        when(
          () => mockRepository.setScreenTimeout(45),
        ).thenThrow(const SetScreenTimeoutException());
        return displayBloc;
      },
      act: (bloc) => bloc.add(const SetScreenTimeout(45)),
      expect: () => [
        const DisplayState(
          status: DisplayStatus.error,
          error: DisplayError.setScreenTimeoutFailed,
        ),
      ],
    );

    blocTest<DisplayBloc, DisplayState>(
      'emits error with unknown on unexpected Exception',
      build: () {
        when(
          () => mockRepository.setScreenTimeout(45),
        ).thenThrow(Exception('Unexpected'));
        return displayBloc;
      },
      act: (bloc) => bloc.add(const SetScreenTimeout(45)),
      expect: () => [
        const DisplayState(
          status: DisplayStatus.error,
          error: DisplayError.unknown,
        ),
      ],
    );
  });

  group('WatchWriteFailed', () {
    const libPath = '/home/batman/Work/mxconfig/target/release/libmxconfig.so';
    late Directory tempDir;
    late Settings settings;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync();
      settings = await Settings.openIn(
        userDir: tempDir.path,
        schemaToml: schema,
        libraryPath: File(libPath).existsSync() ? libPath : null,
      );
    });

    tearDown(() {
      settings.dispose();
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('propagates brightness write failure to the bloc', () async {
      final failureController = StreamController<WriteFailure>();
      addTearDown(failureController.close);

      when(() => mockRepository.init()).thenAnswer((_) async {});
      when(
        () => mockRepository.watchWriteFailed(),
      ).thenAnswer((_) => failureController.stream);
      when(() => mockRepository.getBrightness()).thenAnswer((_) async => 0.5);
      when(
        () => mockRepository.getAutoBrightness(),
      ).thenAnswer((_) async => true);
      when(() => mockRepository.getScreenTimeout()).thenAnswer((_) async => 30);

      displayBloc.add(const DisplayInit());
      await pumpEventQueue();

      final failureFuture = settings.watchWriteFailed().first;
      settings.setInt('display.brightness', 999);
      final failure = await failureFuture;

      failureController.add(failure);
      await pumpEventQueue();

      expect(displayBloc.state.status, equals(DisplayStatus.error));
      expect(displayBloc.state.error, equals(DisplayError.setBrightnessFailed));
      expect(displayBloc.state.brightness, equals(100 / 254));
    });

    test('propagates screen timeout write failure to the bloc', () async {
      final failureController = StreamController<WriteFailure>();
      addTearDown(failureController.close);

      when(() => mockRepository.init()).thenAnswer((_) async {});
      when(
        () => mockRepository.watchWriteFailed(),
      ).thenAnswer((_) => failureController.stream);
      when(() => mockRepository.getBrightness()).thenAnswer((_) async => 0.5);
      when(
        () => mockRepository.getAutoBrightness(),
      ).thenAnswer((_) async => true);
      when(() => mockRepository.getScreenTimeout()).thenAnswer((_) async => 30);

      displayBloc.add(const DisplayInit());
      await pumpEventQueue();

      final failureFuture = settings.watchWriteFailed().first;
      // timeout must be int, sending wrong type causes a write failure with current value
      settings.setBool('display.screen_timeout', true);
      final failure = await failureFuture;

      failureController.add(failure);
      await pumpEventQueue();

      expect(displayBloc.state.status, equals(DisplayStatus.error));
      expect(displayBloc.state.error, equals(DisplayError.setScreenTimeoutFailed));
      expect(displayBloc.state.screenTimeout, equals(30));
    });
  });
}

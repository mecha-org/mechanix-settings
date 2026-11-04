import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_settings/core/exceptions/display_exceptions.dart';
import 'package:mechanix_settings/features/display/data/repositories/display_repository_impl.dart';
import 'package:mechanix_settings/generated/settingsapp.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mxconfig_dart/mxconfig.dart';

class MockSettingsapp extends Mock implements Settingsapp {}

class MockDisplay extends Mock implements Display {}

class MockSettings extends Mock implements Settings {}

void main() {
  late MockSettingsapp mockSettingsapp;
  late MockDisplay mockDisplay;
  late MockSettings mockSettings;
  late DisplayRepositoryImpl repository;

  setUp(() async {
    mockSettingsapp = MockSettingsapp();
    mockDisplay = MockDisplay();
    mockSettings = MockSettings();
    when(() => mockSettingsapp.display).thenReturn(mockDisplay);
    when(() => mockSettingsapp.settings).thenReturn(mockSettings);
    repository = DisplayRepositoryImpl(
      openSettings: () async => mockSettingsapp,
    );
  });

  group('DisplayRepositoryImpl - Initialization', () {
    test('init opens settings once', () async {
      var opens = 0;
      repository = DisplayRepositoryImpl(
        openSettings: () async {
          opens++;
          return mockSettingsapp;
        },
      );

      await repository.init();
      await repository.init();

      expect(opens, equals(1));
    });

    test(
      'init throws DisplayInitializationException when settings fail to open',
      () async {
        repository = DisplayRepositoryImpl(
          openSettings: () async => throw Exception('open failed'),
        );

        expect(
          () => repository.init(),
          throwsA(isA<DisplayInitializationException>()),
        );
      },
    );
  });

  group('DisplayRepositoryImpl - Brightness', () {
    setUp(() async => repository.init());

    test('getBrightness scales the setting to 0.0-1.0', () async {
      when(() => mockDisplay.brightness).thenReturn(127);

      final result = await repository.getBrightness();

      expect(result, equals(127 / 254));
    });

    test('getBrightness throws GetBrightnessException on failure', () async {
      when(() => mockDisplay.brightness).thenThrow(Exception('get failed'));

      expect(
        () => repository.getBrightness(),
        throwsA(isA<GetBrightnessException>()),
      );
    });

    test('setBrightness writes the setting on the 0-254 scale', () async {
      await repository.setBrightness(0.8);

      verify(() => mockDisplay.setBrightness(203)).called(1);
    });

    test('setBrightness clamps out-of-range values', () async {
      await repository.setBrightness(1.5);

      verify(() => mockDisplay.setBrightness(254)).called(1);
    });

    test('setBrightness throws SetBrightnessException on failure', () async {
      when(
        () => mockDisplay.setBrightness(any()),
      ).thenThrow(Exception('set failed'));

      expect(
        () => repository.setBrightness(0.8),
        throwsA(isA<SetBrightnessException>()),
      );
    });
  });

  group('DisplayRepositoryImpl - AutoBrightness', () {
    setUp(() async => repository.init());

    test('getAutoBrightness returns value from settings', () async {
      when(() => mockDisplay.autoBrightness).thenReturn(false);

      final result = await repository.getAutoBrightness();

      expect(result, isFalse);
    });

    test(
      'getAutoBrightness throws GetAutoBrightnessException on failure',
      () async {
        when(() => mockDisplay.autoBrightness).thenThrow(Exception('failed'));

        expect(
          () => repository.getAutoBrightness(),
          throwsA(isA<GetAutoBrightnessException>()),
        );
      },
    );

    test('setAutoBrightness writes the setting', () async {
      await repository.setAutoBrightness(false);

      verify(() => mockDisplay.setAutoBrightness(false)).called(1);
    });

    test(
      'setAutoBrightness throws SetAutoBrightnessException on failure',
      () async {
        when(
          () => mockDisplay.setAutoBrightness(any()),
        ).thenThrow(Exception('set failed'));

        expect(
          () => repository.setAutoBrightness(false),
          throwsA(isA<SetAutoBrightnessException>()),
        );
      },
    );
  });

  group('DisplayRepositoryImpl - ScreenTimeout', () {
    setUp(() async => repository.init());

    test('getScreenTimeout returns value from settings', () async {
      when(() => mockDisplay.screenTimeout).thenReturn(45);

      final result = await repository.getScreenTimeout();

      expect(result, equals(45));
    });

    test(
      'getScreenTimeout throws GetScreenTimeoutException on failure',
      () async {
        when(() => mockDisplay.screenTimeout).thenThrow(Exception('failed'));

        expect(
          () => repository.getScreenTimeout(),
          throwsA(isA<GetScreenTimeoutException>()),
        );
      },
    );

    test('setScreenTimeout writes the setting', () async {
      await repository.setScreenTimeout(60);

      verify(() => mockDisplay.setScreenTimeout(60)).called(1);
    });

    test(
      'setScreenTimeout throws SetScreenTimeoutException on failure',
      () async {
        when(
          () => mockDisplay.setScreenTimeout(any()),
        ).thenThrow(Exception('set failed'));

        expect(
          () => repository.setScreenTimeout(60),
          throwsA(isA<SetScreenTimeoutException>()),
        );
      },
    );

    test('a read racing init waits for the same open', () async {
      var opens = 0;
      final opened = Completer<Settingsapp>();
      repository = DisplayRepositoryImpl(
        openSettings: () {
          opens++;
          return opened.future;
        },
      );
      when(() => mockDisplay.screenTimeout).thenReturn(45);

      final init = repository.init();
      final read = repository.getScreenTimeout();
      opened.complete(mockSettingsapp);

      await init;
      expect(await read, equals(45));
      expect(opens, equals(1));
    });

    test('a failed open is retried on the next call', () async {
      var opens = 0;
      repository = DisplayRepositoryImpl(
        openSettings: () async {
          if (opens++ == 0) throw Exception('open failed');
          return mockSettingsapp;
        },
      );
      when(() => mockDisplay.screenTimeout).thenReturn(45);

      await expectLater(
        repository.getScreenTimeout(),
        throwsA(isA<GetScreenTimeoutException>()),
      );
      expect(await repository.getScreenTimeout(), equals(45));
    });
  });

  group('DisplayRepositoryImpl - Close', () {
    test('close disposes settings', () async {
      await repository.init();

      await repository.close();

      verify(() => mockSettings.dispose()).called(1);
    });

    test('close throws DisplayCloseException on failure', () async {
      when(() => mockSettings.dispose()).thenThrow(Exception('close failed'));
      await repository.init();

      expect(() => repository.close(), throwsA(isA<DisplayCloseException>()));
    });
  });
}

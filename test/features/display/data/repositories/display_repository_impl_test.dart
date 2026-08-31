import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_settings/core/exceptions/display_exceptions.dart';
import 'package:mechanix_settings/features/display/data/repositories/display_repository_impl.dart';
import 'package:mechanix_settings/features/display/data/services/display_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDisplayService extends Mock implements DisplayService {}

void main() {
  late MockDisplayService mockService;
  late DisplayRepositoryImpl repository;

  setUp(() {
    mockService = MockDisplayService();
    repository = DisplayRepositoryImpl(displayService: mockService);
  });

  group('DisplayRepositoryImpl - Initialization', () {
    test('init calls service init and completes successfully', () async {
      when(() => mockService.init()).thenAnswer((_) async {});

      await repository.init();

      verify(() => mockService.init()).called(1);
    });

    test(
      'init throws DisplayInitializationException on service failure',
      () async {
        when(() => mockService.init()).thenThrow(Exception('init failed'));

        expect(
          () => repository.init(),
          throwsA(isA<DisplayInitializationException>()),
        );
      },
    );
  });

  group('DisplayRepositoryImpl - Brightness', () {
    test('getBrightness returns value from service on success', () async {
      when(() => mockService.getBrightness()).thenAnswer((_) async => 0.75);

      final result = await repository.getBrightness();

      expect(result, equals(0.75));
      verify(() => mockService.getBrightness()).called(1);
    });

    test(
      'getBrightness throws GetBrightnessException on service failure',
      () async {
        when(
          () => mockService.getBrightness(),
        ).thenThrow(Exception('get failed'));

        expect(
          () => repository.getBrightness(),
          throwsA(isA<GetBrightnessException>()),
        );
      },
    );

    test('setBrightness throws SetBrightnessException on failure', () async {
      when(
        () => mockService.setBrightness(any()),
      ).thenThrow(Exception('set failed'));

      expect(
        () => repository.setBrightness(0.8),
        throwsA(isA<SetBrightnessException>()),
      );
    });
  });

  group('DisplayRepositoryImpl - AutoBrightness', () {
    test('getAutoBrightness returns value from service on success', () async {
      when(
        () => mockService.getAutoBrightness(),
      ).thenAnswer((_) async => false);

      final result = await repository.getAutoBrightness();

      expect(result, isFalse);
      verify(() => mockService.getAutoBrightness()).called(1);
    });

    test(
      'getAutoBrightness throws GetAutoBrightnessException on service failure',
      () async {
        when(
          () => mockService.getAutoBrightness(),
        ).thenThrow(Exception('get failed'));

        expect(
          () => repository.getAutoBrightness(),
          throwsA(isA<GetAutoBrightnessException>()),
        );
      },
    );

    test(
      'setAutoBrightness throws SetAutoBrightnessException on failure',
      () async {
        when(
          () => mockService.setAutoBrightness(any()),
        ).thenThrow(Exception('set failed'));

        expect(
          () => repository.setAutoBrightness(false),
          throwsA(isA<SetAutoBrightnessException>()),
        );
      },
    );
  });

  group('DisplayRepositoryImpl - ScreenTimeout', () {
    test('getScreenTimeout returns value from service on success', () async {
      when(() => mockService.getScreenTimeout()).thenAnswer((_) async => 45);

      final result = await repository.getScreenTimeout();

      expect(result, equals(45));
      verify(() => mockService.getScreenTimeout()).called(1);
    });
    test(
      'getScreenTimeout throws GetScreenTimeoutException on service failure',
      () async {
        when(
          () => mockService.getScreenTimeout(),
        ).thenThrow(Exception('get failed'));

        expect(
          () => repository.getScreenTimeout(),
          throwsA(isA<GetScreenTimeoutException>()),
        );
      },
    );
    test(
      'setScreenTimeout throws SetScreenTimeoutException on failure',
      () async {
        when(
          () => mockService.setScreenTimeout(any()),
        ).thenThrow(Exception('set failed'));

        expect(
          () => repository.setScreenTimeout(60),
          throwsA(isA<SetScreenTimeoutException>()),
        );
      },
    );
  });

  group('DisplayRepositoryImpl - Close', () {
    test('close calls service close', () async {
      when(() => mockService.close()).thenAnswer((_) async {});

      await repository.close();

      verify(() => mockService.close()).called(1);
    });

    test('close throws DisplayCloseException on failure', () async {
      when(() => mockService.close()).thenThrow(Exception('close failed'));

      expect(() => repository.close(), throwsA(isA<DisplayCloseException>()));
    });
  });
}

import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_settings/features/language/data/models/enums.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mechanix_settings/core/exceptions/language_exceptions.dart';
import 'package:mechanix_settings/features/language/blocs/language_bloc.dart';
import 'package:mechanix_settings/features/language/blocs/language_event.dart';
import 'package:mechanix_settings/features/language/blocs/language_state.dart';
import 'package:mechanix_settings/features/language/data/repositories/language_repository.dart';

class MockLanguageRepository extends Mock implements LanguageRepository {}

void main() {
  late LanguageBloc languageBloc;
  late MockLanguageRepository mockLanguageRepository;
  late StreamController<List<String>> propertiesChangedController;

  setUp(() {
    mockLanguageRepository = MockLanguageRepository();
    propertiesChangedController = StreamController<List<String>>.broadcast();

    when(
      () => mockLanguageRepository.propertiesChangedStream,
    ).thenAnswer((_) => propertiesChangedController.stream);
    when(() => mockLanguageRepository.init()).thenAnswer((_) async {});
    when(() => mockLanguageRepository.close()).thenAnswer((_) async {});

    languageBloc = LanguageBloc(mockLanguageRepository);
  });

  tearDown(() async {
    await languageBloc.close();
    await propertiesChangedController.close();
  });

  group('LanguageBloc Initial State', () {
    test('initial state is correct', () {
      expect(languageBloc.state.status, LanguageStatus.initial);
      expect(languageBloc.state.systemLanguage, 'en_US.UTF-8');
      expect(languageBloc.state.appLocale, const Locale('en', 'US'));
      expect(languageBloc.state.error, isNull);
    });
  });

  group('InitializeLanguageEvent', () {
    blocTest<LanguageBloc, LanguageState>(
      'emits [loading, loaded] with system language and app locale on success',
      build: () {
        when(
          () => mockLanguageRepository.getLanguage(),
        ).thenAnswer((_) async => 'en_GB.UTF-8');
        return languageBloc;
      },
      act: (bloc) => bloc.add(const InitializeLanguage()),
      expect: () => [
        const LanguageState(
          status: LanguageStatus.loading,
          systemLanguage: 'en_US.UTF-8',
          appLocale: Locale('en', 'US'),
          error: null,
        ),
        const LanguageState(
          status: LanguageStatus.loaded,
          systemLanguage: 'en_GB.UTF-8',
          appLocale: Locale('en', 'GB'),
          error: null,
        ),
      ],
      verify: (_) {
        verify(() => mockLanguageRepository.init()).called(1);
        verify(() => mockLanguageRepository.getLanguage()).called(1);
      },
    );

    blocTest<LanguageBloc, LanguageState>(
      'emits [loading, error] with initializationFailed when init fails',
      build: () {
        when(
          () => mockLanguageRepository.init(),
        ).thenThrow(const LanguageInitializationException());
        return languageBloc;
      },
      act: (bloc) => bloc.add(const InitializeLanguage()),
      expect: () => [
        const LanguageState(
          status: LanguageStatus.loading,
          systemLanguage: 'en_US.UTF-8',
          appLocale: Locale('en', 'US'),
          error: null,
        ),
        const LanguageState(
          status: LanguageStatus.error,
          systemLanguage: 'en_US.UTF-8',
          appLocale: Locale('en', 'US'),
          error: LanguageError.initializationFailed,
        ),
      ],
    );
  });

  group('RefreshLanguageEvent', () {
    blocTest<LanguageBloc, LanguageState>(
      'emits [loaded] with refreshed language on success',
      build: () {
        when(
          () => mockLanguageRepository.getLanguage(),
        ).thenAnswer((_) async => 'en_GB.UTF-8');
        return languageBloc;
      },
      act: (bloc) => bloc.add(const RefreshLanguage()),
      expect: () => [
        const LanguageState(
          status: LanguageStatus.loaded,
          systemLanguage: 'en_GB.UTF-8',
          appLocale: Locale('en', 'GB'),
          error: null,
        ),
      ],
    );

    blocTest<LanguageBloc, LanguageState>(
      'emits [error] with unknown when refresh throws',
      build: () {
        when(
          () => mockLanguageRepository.getLanguage(),
        ).thenThrow(const GetLanguageException());
        return languageBloc;
      },
      act: (bloc) => bloc.add(const RefreshLanguage()),
      expect: () => [
        const LanguageState(
          status: LanguageStatus.error,
          systemLanguage: 'en_US.UTF-8',
          appLocale: Locale('en', 'US'),
          error: LanguageError.unknown,
        ),
      ],
    );
  });

  group('SetSystemLanguageEvent', () {
    blocTest<LanguageBloc, LanguageState>(
      'optimistically emits new locale and updates repository',
      build: () {
        when(
          () => mockLanguageRepository.setLanguage(any()),
        ).thenAnswer((_) async {});
        return languageBloc;
      },
      act: (bloc) => bloc.add(const SetSystemLanguage('en_GB.UTF-8')),
      expect: () => [
        const LanguageState(
          status: LanguageStatus.loaded,
          systemLanguage: 'en_GB.UTF-8',
          appLocale: Locale('en', 'GB'),
          error: null,
        ),
      ],
      verify: (_) {
        verify(
          () => mockLanguageRepository.setLanguage('en_GB.UTF-8'),
        ).called(1);
      },
    );

    blocTest<LanguageBloc, LanguageState>(
      'reverts state and emits error if setLanguage fails',
      build: () {
        when(
          () => mockLanguageRepository.setLanguage(any()),
        ).thenThrow(const SetLanguageException());
        return languageBloc;
      },
      act: (bloc) => bloc.add(const SetSystemLanguage('en_GB.UTF-8')),
      expect: () => [
        const LanguageState(
          status: LanguageStatus.loaded,
          systemLanguage: 'en_GB.UTF-8',
          appLocale: Locale('en', 'GB'),
          error: null,
        ),
        const LanguageState(
          status: LanguageStatus.error,
          systemLanguage: 'en_US.UTF-8',
          appLocale: Locale('en', 'US'),
          error: LanguageError.setLanguageFailed,
        ),
      ],
    );
  });
}

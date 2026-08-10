import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_settings/core/exceptions/about_exceptions.dart';
import 'package:mechanix_settings/features/about/data/models/enums.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mechanix_settings/features/about/blocs/about_bloc.dart';
import 'package:mechanix_settings/features/about/blocs/about_event.dart';
import 'package:mechanix_settings/features/about/blocs/about_state.dart';
import 'package:mechanix_settings/features/about/data/models/about_details.dart';
import 'package:mechanix_settings/features/about/data/repositories/about_repository.dart';

class MockAboutRepository extends Mock implements AboutRepository {}

void main() {
  late AboutBloc aboutBloc;
  late MockAboutRepository mockAboutRepository;
  late AboutDetails testDetails;

  setUp(() {
    mockAboutRepository = MockAboutRepository();

    testDetails = const AboutDetails(
      deviceName: 'Comet01',
      hostname: 'comet',
      model: 'Mecha Comet',
      manufacturer: 'Mecha',
      operatingSystem: 'Mecha OS',
      supportUntil: '2030-12-31',
      kernel: 'Linux 6.6.87.1',
      kernelBuild: '#1 SMP',
      firmwareVersion: '1.0.0',
      firmwareVendor: 'Mecha',
      firmwareDate: '2026-08-01',
      serialNumber: '1234 6789',
      machineId: '4d7803045b574ef5a05fbea4b7642d51',
      bootId: '1234567890abcdef1234567890abcdef',
      osWebsite: 'https://example.com',
    );

    aboutBloc = AboutBloc(mockAboutRepository);
  });

  tearDown(() async {
    await aboutBloc.close();
  });

  group('AboutBloc Initial State', () {
    test('initial state is correct', () {
      expect(aboutBloc.state.status, AboutStatus.initial);
      expect(aboutBloc.state.details, isNull);
      expect(aboutBloc.state.error, isNull);
    });
  });

  group('LoadAboutDetails', () {
    blocTest<AboutBloc, AboutState>(
      'emits [loading, success] states with details when loading succeeds',
      build: () {
        when(
          () => mockAboutRepository.getAboutDetails(),
        ).thenAnswer((_) async => testDetails);

        return aboutBloc;
      },
      act: (bloc) => bloc.add(const LoadAboutDetails()),
      expect: () => [
        const AboutState(status: AboutStatus.loading),
        AboutState(status: AboutStatus.success, details: testDetails),
      ],
      verify: (_) {
        verify(() => mockAboutRepository.getAboutDetails()).called(1);
      },
    );

    blocTest<AboutBloc, AboutState>(
      'emits [loading, failure] states with aboutDetailsLoadFailed when loading fails',
      build: () {
        when(
          () => mockAboutRepository.getAboutDetails(),
        ).thenThrow(const GetAboutDetailsException());

        return aboutBloc;
      },
      act: (bloc) => bloc.add(const LoadAboutDetails()),
      expect: () => [
        const AboutState(status: AboutStatus.loading),
        const AboutState(
          status: AboutStatus.failure,
          error: AboutError.aboutDetailsLoadFailed,
        ),
      ],
      verify: (_) {
        verify(() => mockAboutRepository.getAboutDetails()).called(1);
      },
    );

    blocTest<AboutBloc, AboutState>(
      'emits [loading, failure] states with unknown when loading throws unexpected error',
      build: () {
        when(
          () => mockAboutRepository.getAboutDetails(),
        ).thenThrow(Exception('Unexpected error'));

        return aboutBloc;
      },
      act: (bloc) => bloc.add(const LoadAboutDetails()),
      expect: () => [
        const AboutState(status: AboutStatus.loading),
        const AboutState(
          status: AboutStatus.failure,
          error: AboutError.unknown,
        ),
      ],
      verify: (_) {
        verify(() => mockAboutRepository.getAboutDetails()).called(1);
      },
    );
  });

  group('UpdateDeviceName', () {
    blocTest<AboutBloc, AboutState>(
      'emits [loading, success] when updateDeviceName succeeds and loads details',
      build: () {
        when(
          () => mockAboutRepository.updateDeviceName(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockAboutRepository.getAboutDetails(),
        ).thenAnswer((_) async => testDetails);

        return aboutBloc;
      },
      act: (bloc) => bloc.add(const UpdateDeviceName('NewName')),
      expect: () => [
        const AboutState(status: AboutStatus.loading),
        AboutState(status: AboutStatus.success, details: testDetails),
      ],
      verify: (_) {
        verify(() => mockAboutRepository.updateDeviceName('NewName')).called(1);
        verify(() => mockAboutRepository.getAboutDetails()).called(1);
      },
    );

    blocTest<AboutBloc, AboutState>(
      'emits [failure] with deviceNameUpdateFailed when updateDeviceName throws UpdateDeviceNameException',
      build: () {
        when(
          () => mockAboutRepository.updateDeviceName(any()),
        ).thenThrow(const UpdateDeviceNameException());

        return aboutBloc;
      },
      act: (bloc) => bloc.add(const UpdateDeviceName('NewName')),
      expect: () => [
        const AboutState(
          status: AboutStatus.failure,
          error: AboutError.deviceNameUpdateFailed,
        ),
      ],
      verify: (_) {
        verify(() => mockAboutRepository.updateDeviceName('NewName')).called(1);
        verifyNever(() => mockAboutRepository.getAboutDetails());
      },
    );

    blocTest<AboutBloc, AboutState>(
      'emits [failure] with unknown when updateDeviceName throws unexpected error',
      build: () {
        when(
          () => mockAboutRepository.updateDeviceName(any()),
        ).thenThrow(Exception('Unexpected error'));

        return aboutBloc;
      },
      act: (bloc) => bloc.add(const UpdateDeviceName('NewName')),
      expect: () => [
        const AboutState(
          status: AboutStatus.failure,
          error: AboutError.unknown,
        ),
      ],
      verify: (_) {
        verify(() => mockAboutRepository.updateDeviceName('NewName')).called(1);
        verifyNever(() => mockAboutRepository.getAboutDetails());
      },
    );
  });

  group('UpdateHostname', () {
    blocTest<AboutBloc, AboutState>(
      'emits [loading, success] when updateHostname succeeds and loads details',
      build: () {
        when(
          () => mockAboutRepository.updateHostname(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockAboutRepository.getAboutDetails(),
        ).thenAnswer((_) async => testDetails);

        return aboutBloc;
      },
      act: (bloc) => bloc.add(const UpdateHostname('new-hostname')),
      expect: () => [
        const AboutState(status: AboutStatus.loading),
        AboutState(status: AboutStatus.success, details: testDetails),
      ],
      verify: (_) {
        verify(() => mockAboutRepository.updateHostname('new-hostname')).called(1);
        verify(() => mockAboutRepository.getAboutDetails()).called(1);
      },
    );

    blocTest<AboutBloc, AboutState>(
      'emits [failure] with hostnameUpdateFailed when updateHostname throws UpdateHostnameException',
      build: () {
        when(
          () => mockAboutRepository.updateHostname(any()),
        ).thenThrow(const UpdateHostnameException());

        return aboutBloc;
      },
      act: (bloc) => bloc.add(const UpdateHostname('new-hostname')),
      expect: () => [
        const AboutState(
          status: AboutStatus.failure,
          error: AboutError.hostnameUpdateFailed,
        ),
      ],
      verify: (_) {
        verify(() => mockAboutRepository.updateHostname('new-hostname')).called(1);
        verifyNever(() => mockAboutRepository.getAboutDetails());
      },
    );

    blocTest<AboutBloc, AboutState>(
      'emits [failure] with unknown when updateHostname throws unexpected error',
      build: () {
        when(
          () => mockAboutRepository.updateHostname(any()),
        ).thenThrow(Exception('Unexpected error'));

        return aboutBloc;
      },
      act: (bloc) => bloc.add(const UpdateHostname('new-hostname')),
      expect: () => [
        const AboutState(
          status: AboutStatus.failure,
          error: AboutError.unknown,
        ),
      ],
      verify: (_) {
        verify(() => mockAboutRepository.updateHostname('new-hostname')).called(1);
        verifyNever(() => mockAboutRepository.getAboutDetails());
      },
    );
  });
}

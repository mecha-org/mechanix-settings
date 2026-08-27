import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mechanix_settings/core/exceptions/sound_exceptions.dart';
import 'package:mechanix_settings/features/sound/blocs/sound_bloc.dart';
import 'package:mechanix_settings/features/sound/blocs/sound_event.dart';
import 'package:mechanix_settings/features/sound/blocs/sound_state.dart';
import 'package:mechanix_settings/features/sound/data/models/enums.dart';
import 'package:mechanix_settings/features/sound/data/repositories/sound_repository.dart';

class MockSoundRepository extends Mock implements SoundRepository {}

void main() {
  late SoundBloc soundBloc;
  late MockSoundRepository mockSoundRepository;
  late StreamController<SoundChangeType> changeStreamController;

  setUp(() {
    mockSoundRepository = MockSoundRepository();
    changeStreamController = StreamController<SoundChangeType>.broadcast();

    // Default mocks to prevent crashes
    when(() => mockSoundRepository.init()).thenAnswer((_) async {});
    when(
      () => mockSoundRepository.onSoundChanged,
    ).thenAnswer((_) => changeStreamController.stream);
    when(
      () => mockSoundRepository.getOutputVolume(),
    ).thenAnswer((_) async => 0.5);
    when(
      () => mockSoundRepository.getSelectedOutputDevice(),
    ).thenAnswer((_) async => 'Speakers');
    when(
      () => mockSoundRepository.getOutputDevices(),
    ).thenAnswer((_) async => ['Speakers', 'HDMI']);
    when(
      () => mockSoundRepository.getInputVolume(),
    ).thenAnswer((_) async => 0.4);
    when(
      () => mockSoundRepository.getSelectedInputDevice(),
    ).thenAnswer((_) async => 'Mic');
    when(
      () => mockSoundRepository.getInputDevices(),
    ).thenAnswer((_) async => ['Mic', 'USB Mic']);
    when(
      () => mockSoundRepository.getLauncherSoundsEnabled(),
    ).thenAnswer((_) async => true);
    when(
      () => mockSoundRepository.getHapticFeedbackEnabled(),
    ).thenAnswer((_) async => false);
    when(
      () => mockSoundRepository.getSelectedNotificationSound(),
    ).thenAnswer((_) async => 'Default');
    when(
      () => mockSoundRepository.getNotificationSounds(),
    ).thenAnswer((_) async => ['Default', 'None']);
    when(() => mockSoundRepository.close()).thenAnswer((_) async {});

    soundBloc = SoundBloc(soundRepository: mockSoundRepository);
  });

  tearDown(() async {
    await soundBloc.close();
    await changeStreamController.close();
  });

  group('SoundBloc Initial State', () {
    test('initial state has correct default values', () {
      expect(soundBloc.state.status, SoundStatus.initial);
      expect(soundBloc.state.outputVolume, 0.6);
      expect(soundBloc.state.inputVolume, 0.4);
      expect(soundBloc.state.launcherSoundsEnabled, isTrue);
      expect(soundBloc.state.hapticFeedbackEnabled, isTrue);
      expect(soundBloc.state.selectedOutputDevice, isEmpty);
      expect(soundBloc.state.selectedInputDevice, isEmpty);
      expect(soundBloc.state.outputDevices, isEmpty);
      expect(soundBloc.state.inputDevices, isEmpty);
      expect(soundBloc.state.outputDeviceLoading, isFalse);
      expect(soundBloc.state.inputDeviceLoading, isFalse);
      expect(soundBloc.state.error, isNull);
    });
  });

  group('SoundInit Event', () {
    blocTest<SoundBloc, SoundState>(
      'initializes sound repository successfully',
      build: () => soundBloc,
      act: (bloc) => bloc.add(const SoundInit()),
      expect: () => [
        isA<SoundState>().having(
          (s) => s.status,
          'status',
          SoundStatus.loading,
        ),
        isA<SoundState>().having((s) => s.status, 'status', SoundStatus.loaded),
      ],
      verify: (_) {
        verify(() => mockSoundRepository.init()).called(1);
      },
    );

    blocTest<SoundBloc, SoundState>(
      'emits error state when repository init throws SoundInitializationException',
      build: () {
        when(
          () => mockSoundRepository.init(),
        ).thenThrow(const SoundInitializationException());
        return soundBloc;
      },
      act: (bloc) => bloc.add(const SoundInit()),
      expect: () => [
        isA<SoundState>().having(
          (s) => s.status,
          'status',
          SoundStatus.loading,
        ),
        isA<SoundState>()
            .having((s) => s.status, 'status', SoundStatus.error)
            .having((s) => s.error, 'error', SoundError.initializationFailed),
      ],
    );
  });

  group('LoadSoundSettings Event', () {
    blocTest<SoundBloc, SoundState>(
      'loads all sound settings correctly',
      build: () => soundBloc,
      act: (bloc) => bloc.add(const LoadSoundSettings()),
      skip: 9,
      expect: () => [
        isA<SoundState>()
            .having((s) => s.status, 'status', SoundStatus.loaded)
            .having((s) => s.outputVolume, 'outputVolume', 0.5)
            .having(
              (s) => s.selectedOutputDevice,
              'selectedOutputDevice',
              'Speakers',
            )
            .having((s) => s.outputDevices, 'outputDevices', [
              'Speakers',
              'HDMI',
            ])
            .having((s) => s.inputVolume, 'inputVolume', 0.4)
            .having((s) => s.selectedInputDevice, 'selectedInputDevice', 'Mic')
            .having((s) => s.inputDevices, 'inputDevices', ['Mic', 'USB Mic'])
            .having(
              (s) => s.launcherSoundsEnabled,
              'launcherSoundsEnabled',
              true,
            )
            .having(
              (s) => s.hapticFeedbackEnabled,
              'hapticFeedbackEnabled',
              false,
            )
            .having(
              (s) => s.selectedNotificationSound,
              'selectedNotificationSound',
              'Default',
            )
            .having((s) => s.notificationSounds, 'notificationSounds', [
              'Default',
              'None',
            ]),
      ],
    );
  });

  group('SetOutputVolume Event', () {
    blocTest<SoundBloc, SoundState>(
      'sets output volume successfully',
      build: () {
        when(
          () => mockSoundRepository.setOutputVolume(any()),
        ).thenAnswer((_) async {});
        return soundBloc;
      },
      act: (bloc) => bloc.add(const SetOutputVolume(0.7)),
      expect: () => [
        isA<SoundState>().having((s) => s.outputVolume, 'outputVolume', 0.7),
      ],
      verify: (_) {
        verify(() => mockSoundRepository.setOutputVolume(0.7)).called(1);
      },
    );

    blocTest<SoundBloc, SoundState>(
      'emits error state when setOutputVolume throws SetOutputVolumeException',
      build: () {
        when(
          () => mockSoundRepository.setOutputVolume(any()),
        ).thenThrow(const SetOutputVolumeException());
        return soundBloc;
      },
      act: (bloc) => bloc.add(const SetOutputVolume(0.7)),
      expect: () => [
        isA<SoundState>()
            .having((s) => s.status, 'status', SoundStatus.error)
            .having((s) => s.error, 'error', SoundError.setOutputVolumeFailed),
      ],
    );
  });

  group('SetOutputDevice Event', () {
    blocTest<SoundBloc, SoundState>(
      'sets output device successfully',
      build: () {
        when(
          () => mockSoundRepository.setSelectedOutputDevice(any()),
        ).thenAnswer((_) async {});
        return soundBloc;
      },
      act: (bloc) => bloc.add(const SetOutputDevice('HDMI')),
      expect: () => [
        isA<SoundState>().having(
          (s) => s.selectedOutputDevice,
          'selectedOutputDevice',
          'HDMI',
        ),
      ],
      verify: (_) {
        verify(
          () => mockSoundRepository.setSelectedOutputDevice('HDMI'),
        ).called(1);
      },
    );
  });

  group('ToggleLauncherSounds Event', () {
    blocTest<SoundBloc, SoundState>(
      'toggles launcher sounds successfully',
      build: () {
        when(
          () => mockSoundRepository.setLauncherSoundsEnabled(any()),
        ).thenAnswer((_) async {});
        return soundBloc;
      },
      act: (bloc) => bloc.add(const ToggleLauncherSounds(false)),
      expect: () => [
        isA<SoundState>().having(
          (s) => s.launcherSoundsEnabled,
          'launcherSoundsEnabled',
          false,
        ),
      ],
    );
  });

  group('ToggleHapticFeedback Event', () {
    blocTest<SoundBloc, SoundState>(
      'toggles haptic feedback successfully',
      build: () {
        when(
          () => mockSoundRepository.setHapticFeedbackEnabled(any()),
        ).thenAnswer((_) async {});
        return soundBloc;
      },
      act: (bloc) => bloc.add(const ToggleHapticFeedback(true)),
      expect: () => [
        isA<SoundState>().having(
          (s) => s.hapticFeedbackEnabled,
          'hapticFeedbackEnabled',
          true,
        ),
      ],
    );
  });

  group('SetNotificationSound Event', () {
    blocTest<SoundBloc, SoundState>(
      'sets notification sound successfully',
      build: () {
        when(
          () => mockSoundRepository.setSelectedNotificationSound(any()),
        ).thenAnswer((_) async {});
        return soundBloc;
      },
      act: (bloc) => bloc.add(const SetNotificationSound('None')),
      expect: () => [
        isA<SoundState>().having(
          (s) => s.selectedNotificationSound,
          'selectedNotificationSound',
          'None',
        ),
      ],
    );
  });

  group('RefreshOutputDevicesList Event', () {
    blocTest<SoundBloc, SoundState>(
      'refreshes output devices list successfully after delay',
      build: () {
        when(
          () => mockSoundRepository.getOutputDevices(),
        ).thenAnswer((_) async => ['Speakers', 'HDMI', 'Bluetooth']);
        when(
          () => mockSoundRepository.getSelectedOutputDevice(),
        ).thenAnswer((_) async => 'Bluetooth');
        return soundBloc;
      },
      act: (bloc) => bloc.add(const RefreshOutputDevicesList()),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        isA<SoundState>().having(
          (s) => s.outputDeviceLoading,
          'outputDeviceLoading',
          true,
        ),
        isA<SoundState>()
            .having((s) => s.outputDeviceLoading, 'outputDeviceLoading', false)
            .having((s) => s.outputDevices, 'outputDevices', [
              'Speakers',
              'HDMI',
              'Bluetooth',
            ])
            .having(
              (s) => s.selectedOutputDevice,
              'selectedOutputDevice',
              'Bluetooth',
            ),
      ],
    );
  });

  group('RefreshInputDevicesList Event', () {
    blocTest<SoundBloc, SoundState>(
      'refreshes input devices list successfully after delay',
      build: () {
        when(
          () => mockSoundRepository.getInputDevices(),
        ).thenAnswer((_) async => ['Mic', 'USB Mic', 'Bluetooth Mic']);
        when(
          () => mockSoundRepository.getSelectedInputDevice(),
        ).thenAnswer((_) async => 'Bluetooth Mic');
        return soundBloc;
      },
      act: (bloc) => bloc.add(const RefreshInputDevicesList()),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        isA<SoundState>().having(
          (s) => s.inputDeviceLoading,
          'inputDeviceLoading',
          true,
        ),
        isA<SoundState>()
            .having((s) => s.inputDeviceLoading, 'inputDeviceLoading', false)
            .having((s) => s.inputDevices, 'inputDevices', [
              'Mic',
              'USB Mic',
              'Bluetooth Mic',
            ])
            .having(
              (s) => s.selectedInputDevice,
              'selectedInputDevice',
              'Bluetooth Mic',
            ),
      ],
    );
  });

  group('Repository Stream Notifications', () {
    blocTest<SoundBloc, SoundState>(
      'triggers RefreshOutputVolume on outputVolume change event',
      build: () => soundBloc,
      act: (bloc) async {
        bloc.add(const SoundInit());
        await Future.delayed(Duration.zero);
        changeStreamController.add(SoundChangeType.outputVolume);
      },
      skip: 2, // Skip initialization states
      expect: () => [
        isA<SoundState>().having((s) => s.outputVolume, 'outputVolume', 0.5),
      ],
    );

    blocTest<SoundBloc, SoundState>(
      'triggers RefreshOutputDevicesList on outputDevice change event',
      build: () => soundBloc,
      act: (bloc) async {
        bloc.add(const SoundInit());
        await Future.delayed(Duration.zero);
        changeStreamController.add(SoundChangeType.outputDevice);
      },
      wait: const Duration(milliseconds: 600),
      skip: 2, // Skip initialization states
      expect: () => [
        isA<SoundState>().having(
          (s) => s.outputDeviceLoading,
          'outputDeviceLoading',
          true,
        ),
        isA<SoundState>()
            .having((s) => s.outputDeviceLoading, 'outputDeviceLoading', false)
            .having((s) => s.outputDevices, 'outputDevices', [
              'Speakers',
              'HDMI',
            ])
            .having(
              (s) => s.selectedOutputDevice,
              'selectedOutputDevice',
              'Speakers',
            ),
      ],
    );
  });
}

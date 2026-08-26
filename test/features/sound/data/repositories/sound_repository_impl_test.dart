import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_settings/core/exceptions/sound_exceptions.dart';
import 'package:mechanix_settings/features/sound/data/models/enums.dart';
import 'package:mechanix_settings/features/sound/data/repositories/sound_repository_impl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulseaudio/pulseaudio.dart';

class MockPulseAudioClient extends Mock implements PulseAudioClient {}

class MockPulseAudioSink extends Mock implements PulseAudioSink {}

class MockPulseAudioSource extends Mock implements PulseAudioSource {}

class MockPulseAudioServerInfo extends Mock implements PulseAudioServerInfo {}

void main() {
  late SoundRepositoryImpl repository;
  late MockPulseAudioClient mockClient;

  late MockPulseAudioSink mockSink;
  late MockPulseAudioSource mockSource;
  late MockPulseAudioServerInfo mockServerInfo;

  late StreamController<PulseAudioSink> sinkController;
  late StreamController<PulseAudioSource> sourceController;
  late StreamController<int> sinkRemovedController;
  late StreamController<int> sourceRemovedController;
  late StreamController<PulseAudioServerInfo> serverInfoController;

  setUp(() {
    mockClient = MockPulseAudioClient();
    mockSink = MockPulseAudioSink();
    mockSource = MockPulseAudioSource();
    mockServerInfo = MockPulseAudioServerInfo();

    sinkController = StreamController<PulseAudioSink>.broadcast();
    sourceController = StreamController<PulseAudioSource>.broadcast();
    sinkRemovedController = StreamController<int>.broadcast();
    sourceRemovedController = StreamController<int>.broadcast();
    serverInfoController = StreamController<PulseAudioServerInfo>.broadcast();

    // Default stubbing to prevent crashes
    when(() => mockClient.initialize()).thenAnswer((_) async {});

    when(() => mockClient.onSinkChanged).thenAnswer((_) => sinkController.stream);
    when(() => mockClient.onSourceChanged).thenAnswer((_) => sourceController.stream);
    when(() => mockClient.onSinkRemoved).thenAnswer((_) => sinkRemovedController.stream);
    when(() => mockClient.onSourceRemoved).thenAnswer((_) => sourceRemovedController.stream);
    when(() => mockClient.onServerInfoChanged).thenAnswer((_) => serverInfoController.stream);

    when(() => mockSink.name).thenReturn('alsa_output.pci-0000_00_1b.0.analog-stereo');
    when(() => mockSink.volume).thenReturn(0.5);
    when(() => mockSink.description).thenReturn('Built-in Audio Analog Stereo');

    when(() => mockSource.name).thenReturn('alsa_input.pci-0000_00_1b.0.analog-stereo');
    when(() => mockSource.volume).thenReturn(0.4);
    when(() => mockSource.description).thenReturn('Built-in Audio Analog Stereo Input');

    when(() => mockServerInfo.defaultSinkName).thenReturn('alsa_output.pci-0000_00_1b.0.analog-stereo');
    when(() => mockServerInfo.defaultSourceName).thenReturn('alsa_input.pci-0000_00_1b.0.analog-stereo');

    when(() => mockClient.getServerInfo()).thenAnswer((_) async => mockServerInfo);
    when(() => mockClient.getSinkList()).thenAnswer((_) async => [mockSink]);
    when(() => mockClient.getSourceList()).thenAnswer((_) async => [mockSource]);

    repository = SoundRepositoryImpl(client: mockClient);
  });

  tearDown(() async {
    try {
      await repository.close();
    } catch (_) {}
    await sinkController.close();
    await sourceController.close();
    await sinkRemovedController.close();
    await sourceRemovedController.close();
    await serverInfoController.close();
  });

  group('Initialization', () {
    test('init connects to PulseAudio and sets up listeners', () async {
      await repository.init();

      verify(() => mockClient.initialize()).called(1);
      verify(() => mockClient.onSinkChanged).called(1);
    });

    test('init throws SoundInitializationException on failure', () async {
      when(() => mockClient.initialize()).thenThrow(Exception());

      expect(repository.init(), throwsA(isA<SoundInitializationException>()));
    });
  });

  group('Output Volume', () {
    test('getOutputVolume returns correct volume', () async {
      final vol = await repository.getOutputVolume();
      expect(vol, 0.5);
      verify(() => mockClient.getServerInfo()).called(1);
      verify(() => mockClient.getSinkList()).called(1);
    });

    test('getOutputVolume throws GetOutputVolumeException on failure', () async {
      when(() => mockClient.getServerInfo()).thenThrow(Exception());

      expect(
        repository.getOutputVolume(),
        throwsA(isA<GetOutputVolumeException>()),
      );
    });

    test('setOutputVolume sets the volume on PulseAudio Client', () async {
      when(() => mockClient.setSinkVolume(any(), any())).thenAnswer((_) async {});

      await repository.setOutputVolume(0.7);

      verify(
        () => mockClient.setSinkVolume(
          'alsa_output.pci-0000_00_1b.0.analog-stereo',
          0.7,
        ),
      ).called(1);
    });

    test('setOutputVolume throws SetOutputVolumeException on failure', () async {
      when(() => mockClient.setSinkVolume(any(), any())).thenThrow(Exception());

      expect(
        repository.setOutputVolume(0.7),
        throwsA(isA<SetOutputVolumeException>()),
      );
    });
  });

  group('Output Devices', () {
    test('getOutputDevices returns listed devices, excluding monitors', () async {
      final monitorSink = MockPulseAudioSink();
      when(() => monitorSink.name).thenReturn('alsa_output.pci-0000_00_1b.0.analog-stereo.monitor');
      when(() => monitorSink.description).thenReturn('Monitor of Built-in Audio');

      when(() => mockClient.getSinkList()).thenAnswer((_) async => [mockSink, monitorSink]);

      final list = await repository.getOutputDevices();

      expect(list.length, 1);
      expect(list.first, 'Built-in Audio Analog Stereo');
    });

    test('getOutputDevices throws GetOutputDevicesException on failure', () async {
      when(() => mockClient.getSinkList()).thenThrow(Exception());

      expect(
        repository.getOutputDevices(),
        throwsA(isA<GetOutputDevicesException>()),
      );
    });

    test('getSelectedOutputDevice returns default device description', () async {
      final deviceName = await repository.getSelectedOutputDevice();

      expect(deviceName, 'Built-in Audio Analog Stereo');
    });

    test('getSelectedOutputDevice throws GetSelectedOutputDeviceException on failure', () async {
      when(() => mockClient.getServerInfo()).thenThrow(Exception());

      expect(
        repository.getSelectedOutputDevice(),
        throwsA(isA<GetSelectedOutputDeviceException>()),
      );
    });

    test('setSelectedOutputDevice updates default sink', () async {
      when(() => mockClient.setDefaultSink(any())).thenAnswer((_) async {});

      await repository.setSelectedOutputDevice('Built-in Audio Analog Stereo');

      verify(
        () => mockClient.setDefaultSink(
          'alsa_output.pci-0000_00_1b.0.analog-stereo',
        ),
      ).called(1);
    });

    test('setSelectedOutputDevice throws SetSelectedOutputDeviceException on failure', () async {
      when(() => mockClient.setDefaultSink(any())).thenThrow(Exception());

      expect(
        repository.setSelectedOutputDevice('Built-in Audio Analog Stereo'),
        throwsA(isA<SetSelectedOutputDeviceException>()),
      );
    });
  });

  group('Input Volume', () {
    test('getInputVolume returns correct volume', () async {
      final vol = await repository.getInputVolume();
      expect(vol, 0.4);
      verify(() => mockClient.getServerInfo()).called(1);
      verify(() => mockClient.getSourceList()).called(1);
    });

    test('getInputVolume throws GetInputVolumeException on failure', () async {
      when(() => mockClient.getServerInfo()).thenThrow(Exception());

      expect(
        repository.getInputVolume(),
        throwsA(isA<GetInputVolumeException>()),
      );
    });

    test('setInputVolume sets the volume on PulseAudio Client', () async {
      when(() => mockClient.setSourceVolume(any(), any())).thenAnswer((_) async {});

      await repository.setInputVolume(0.6);

      verify(
        () => mockClient.setSourceVolume(
          'alsa_input.pci-0000_00_1b.0.analog-stereo',
          0.6,
        ),
      ).called(1);
    });

    test('setInputVolume throws SetInputVolumeException on failure', () async {
      when(() => mockClient.setSourceVolume(any(), any())).thenThrow(Exception());

      expect(
        repository.setInputVolume(0.6),
        throwsA(isA<SetInputVolumeException>()),
      );
    });
  });

  group('Input Devices', () {
    test('getInputDevices returns listed devices, excluding monitors', () async {
      final monitorSource = MockPulseAudioSource();
      when(() => monitorSource.name).thenReturn('alsa_input.pci-0000_00_1b.0.analog-stereo.monitor');
      when(() => monitorSource.description).thenReturn('Monitor of Input');

      when(() => mockClient.getSourceList()).thenAnswer((_) async => [mockSource, monitorSource]);

      final list = await repository.getInputDevices();

      expect(list.length, 1);
      expect(list.first, 'Built-in Audio Analog Stereo Input');
    });

    test('getInputDevices throws GetInputDevicesException on failure', () async {
      when(() => mockClient.getSourceList()).thenThrow(Exception());

      expect(
        repository.getInputDevices(),
        throwsA(isA<GetInputDevicesException>()),
      );
    });

    test('getSelectedInputDevice returns default device description', () async {
      final deviceName = await repository.getSelectedInputDevice();

      expect(deviceName, 'Built-in Audio Analog Stereo Input');
    });

    test('getSelectedInputDevice throws GetSelectedInputDeviceException on failure', () async {
      when(() => mockClient.getServerInfo()).thenThrow(Exception());

      expect(
        repository.getSelectedInputDevice(),
        throwsA(isA<GetSelectedInputDeviceException>()),
      );
    });

    test('setSelectedInputDevice updates default source', () async {
      when(() => mockClient.setDefaultSource(any())).thenAnswer((_) async {});

      await repository.setSelectedInputDevice('Built-in Audio Analog Stereo Input');

      verify(
        () => mockClient.setDefaultSource(
          'alsa_input.pci-0000_00_1b.0.analog-stereo',
        ),
      ).called(1);
    });

    test('setSelectedInputDevice throws SetSelectedInputDeviceException on failure', () async {
      when(() => mockClient.setDefaultSource(any())).thenThrow(Exception());

      expect(
        repository.setSelectedInputDevice('Built-in Audio Analog Stereo Input'),
        throwsA(isA<SetSelectedInputDeviceException>()),
      );
    });
  });

  group('Sound Settings Preferences', () {
    test('get and set launcher sounds enabled', () async {
      var enabled = await repository.getLauncherSoundsEnabled();
      expect(enabled, isTrue);

      await repository.setLauncherSoundsEnabled(false);
      enabled = await repository.getLauncherSoundsEnabled();
      expect(enabled, isFalse);
    });

    test('get and set haptic feedback enabled', () async {
      var enabled = await repository.getHapticFeedbackEnabled();
      expect(enabled, isTrue);

      await repository.setHapticFeedbackEnabled(false);
      enabled = await repository.getHapticFeedbackEnabled();
      expect(enabled, isFalse);
    });

    test('get notification sounds list', () async {
      final sounds = await repository.getNotificationSounds();
      expect(sounds, contains('Space'));
      expect(sounds.length, greaterThan(1));
    });

    test('get and set selected notification sound', () async {
      var sound = await repository.getSelectedNotificationSound();
      expect(sound, 'Space');

      await repository.setSelectedNotificationSound('Cosmic');
      sound = await repository.getSelectedNotificationSound();
      expect(sound, 'Cosmic');
    });
  });

  group('Stream events', () {
    test('emits correct SoundChangeType on client events', () async {
      await repository.init();

      final events = <SoundChangeType>[];
      final subscription = repository.onSoundChanged.listen(events.add);

      // Trigger sink changed
      sinkController.add(mockSink);
      await Future.delayed(Duration.zero);
      expect(events.last, SoundChangeType.outputVolume);

      // Trigger source changed
      sourceController.add(mockSource);
      await Future.delayed(Duration.zero);
      expect(events.last, SoundChangeType.inputVolume);

      // Trigger sink removed
      sinkRemovedController.add(1);
      await Future.delayed(Duration.zero);
      expect(events.last, SoundChangeType.outputDevice);

      // Trigger source removed
      sourceRemovedController.add(2);
      await Future.delayed(Duration.zero);
      expect(events.last, SoundChangeType.inputDevice);

      // Trigger server info changed
      serverInfoController.add(mockServerInfo);
      await Future.delayed(Duration.zero);
      expect(events.last, SoundChangeType.defaultDevice);

      await subscription.cancel();
    });
  });

  group('Close', () {
    test('cancels subscriptions and resets connected flag successfully', () async {
      await repository.init();
      expect(repository.close(), completes);
    });
  });
}

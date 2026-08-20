abstract class SoundException implements Exception {
  final String message;

  const SoundException(this.message);

  @override
  String toString() => message;
}

class SoundInitializationException extends SoundException {
  const SoundInitializationException([
    super.message = 'Failed to initialize sound service.',
  ]);
}

class GetOutputVolumeException extends SoundException {
  const GetOutputVolumeException([
    super.message = 'Failed to retrieve output volume.',
  ]);
}

class SetOutputVolumeException extends SoundException {
  const SetOutputVolumeException([
    super.message = 'Failed to update output volume.',
  ]);
}

class GetOutputDevicesException extends SoundException {
  const GetOutputDevicesException([
    super.message = 'Failed to retrieve output devices.',
  ]);
}

class GetSelectedOutputDeviceException extends SoundException {
  const GetSelectedOutputDeviceException([
    super.message = 'Failed to retrieve selected output device.',
  ]);
}

class SetSelectedOutputDeviceException extends SoundException {
  const SetSelectedOutputDeviceException([
    super.message = 'Failed to update output device.',
  ]);
}

class GetInputVolumeException extends SoundException {
  const GetInputVolumeException([
    super.message = 'Failed to retrieve input volume.',
  ]);
}

class SetInputVolumeException extends SoundException {
  const SetInputVolumeException([
    super.message = 'Failed to update input volume.',
  ]);
}

class GetInputDevicesException extends SoundException {
  const GetInputDevicesException([
    super.message = 'Failed to retrieve input devices.',
  ]);
}

class GetSelectedInputDeviceException extends SoundException {
  const GetSelectedInputDeviceException([
    super.message = 'Failed to retrieve selected input device.',
  ]);
}

class SetSelectedInputDeviceException extends SoundException {
  const SetSelectedInputDeviceException([
    super.message = 'Failed to update input device.',
  ]);
}

class GetSoundSettingException extends SoundException {
  const GetSoundSettingException([
    super.message = 'Failed to retrieve sound setting.',
  ]);
}

class SetSoundSettingException extends SoundException {
  const SetSoundSettingException([
    super.message = 'Failed to update sound setting.',
  ]);
}

class SoundCloseException extends SoundException {
  const SoundCloseException([
    super.message = 'Failed to close sound service.',
  ]);
}

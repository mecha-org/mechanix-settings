import 'package:mechanix_settings/core/constants/icons.dart';

enum BluetoothDeviceType {
  speaker,
  headphones,
  mobile,
  computer,
  tv,
  car,
  unknown,
}

extension BluetoothDeviceTypeExtension on BluetoothDeviceType {
  String get icon {
    return switch (this) {
      BluetoothDeviceType.car => SettingIcons.car,
      BluetoothDeviceType.mobile => SettingIcons.mobile,
      BluetoothDeviceType.computer => SettingIcons.monitor,
      BluetoothDeviceType.headphones => SettingIcons.headphone,
      BluetoothDeviceType.speaker => SettingIcons.speaker,
      BluetoothDeviceType.tv => SettingIcons.television,
      BluetoothDeviceType.unknown => SettingIcons.devices,
    };
  }
}

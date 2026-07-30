import 'dart:async';
import 'package:dbus/dbus.dart';
import 'package:mechanix_settings/core/exceptions/battery_exceptions.dart';
import 'package:mechanix_settings/core/utils/app_logger.dart';
import 'package:mechanix_settings/features/battery/data/models/battery_info.dart';
import 'package:mechanix_settings/features/battery/data/models/enums.dart';
import 'package:upower/upower.dart';
import 'battery_repository.dart';

class BatteryRepositoryImpl implements BatteryRepository {
  bool _connected = false;
  // final UPowerClient _client = UPowerClient();

  BatteryRepositoryImpl({
    UPowerClient? client,
    DBusClient Function()? dbusClientFactory,
  }) : _client = client ?? UPowerClient(),
       _dbusClientFactory = dbusClientFactory ?? DBusClient.system;

  final UPowerClient _client;
  final DBusClient Function() _dbusClientFactory;

  /// Initializes the UPower client connection.
  ///
  /// Establishes a connection to the UPower service if it has not already
  /// been connected.
  @override
  Future<void> init() async {
    try {
      AppLogger.d("Before battery connect: _connected = $_connected");
      if (!_connected) {
        await _client.connect();
        _connected = true;
      }
      AppLogger.d("After battery connect: _connected = $_connected");
    } catch (e, stack) {
      AppLogger.e(
        "Failed to initialize battery UPower client",
        error: e,
        stack: stack,
      );
      throw const BatteryInitializationException();
    }
  }

  /// Ensures the UPower client is connected before performing operations.
  ///
  /// Reconnects automatically if the existing connection has been lost.
  Future<void> _ensureConnected() async {
    try {
      if (!_connected) {
        await _client.connect();
        _connected = true;
      }
    } catch (e, stack) {
      AppLogger.e(
        "Failed to ensure battery client connection",
        error: e,
        stack: stack,
      );
      throw const BatteryConnectionException();
    }
  }

  /// Retrieves the current battery information.
  ///
  /// Returns the battery percentage, charging state, charging/discharging
  /// time estimates, active power profile, and available power profiles.
  @override
  Future<BatteryInfo> getBatteryInfo() async {
    try {
      await _ensureConnected();
      await Future.delayed(const Duration(milliseconds: 150));

      final batteryMode = await getBatteryModeViaDBus();
      final modes = await getAvailableBatteryModes();

      final device = _client.displayDevice;

      return BatteryInfo(
        batteryPercentage: device.percentage,
        status: device.state,
        mode: batteryMode,
        batteryChargingTime: device.timeToFull,
        batteryRemainingTime: device.timeToEmpty,
        availableBatteryModes: modes,
      );
    } catch (e, stack) {
      AppLogger.e(
        "Failed to retrieve battery information",
        error: e,
        stack: stack,
      );

      throw const GetBatteryInfoException();
    }
  }

  /// Updates the active battery power profile.
  ///
  /// Attempts to use the standard Power Profiles daemon first and falls back
  /// to the UPower PowerProfiles interface if necessary.
  @override
  Future<PowerProfileMode> setBatteryMode(PowerProfileMode mode) async {
    final client = _dbusClientFactory();

    try {
      try {
        final object = DBusRemoteObject(
          client,
          name: 'net.hadess.PowerProfiles',
          path: DBusObjectPath('/net/hadess/PowerProfiles'),
        );

        await object.setProperty(
          'net.hadess.PowerProfiles',
          'ActiveProfile',
          DBusString(mode.value),
        );

        final response = await object.getProperty(
          'net.hadess.PowerProfiles',
          'ActiveProfile',
        );

        var activeProfileVal = response;
        if (activeProfileVal is DBusVariant) {
          activeProfileVal = activeProfileVal.asVariant();
        }

        final newMode = PowerProfileModeExtension.fromValue(
          (activeProfileVal as DBusString).value,
        );

        AppLogger.i('Updated power profile to: ${newMode.value}');
        return newMode;
      } catch (e, stack) {
        AppLogger.e(
          'Failed to set power profile via net.hadess.PowerProfiles. '
          'Trying org.freedesktop.UPower.PowerProfiles...',
          error: e,
          stack: stack,
        );
      }

      final object = DBusRemoteObject(
        client,
        name: 'org.freedesktop.UPower.PowerProfiles',
        path: DBusObjectPath('/org/freedesktop/UPower/PowerProfiles'),
      );

      await object.setProperty(
        'org.freedesktop.UPower.PowerProfiles',
        'ActiveProfile',
        DBusString(mode.value),
      );

      final response = await object.getProperty(
        'org.freedesktop.UPower.PowerProfiles',
        'ActiveProfile',
      );

      var activeProfileVal = response;
      if (activeProfileVal is DBusVariant) {
        activeProfileVal = activeProfileVal.asVariant();
      }

      final newMode = PowerProfileModeExtension.fromValue(
        (activeProfileVal as DBusString).value,
      );

      AppLogger.i('Updated power profile to: ${newMode.value}');
      return newMode;
    } catch (e, stack) {
      AppLogger.e('Failed to set battery mode.', error: e, stack: stack);
      throw const SetBatteryModeException();
    } finally {
      await client.close();
    }
  }

  /// Retrieves the currently active battery power profile.
  ///
  /// Falls back to the legacy UPower PowerProfiles interface if the standard
  /// Power Profiles daemon is unavailable.
  Future<PowerProfileMode> getBatteryModeViaDBus() async {
    final client = _dbusClientFactory();

    try {
      final object = DBusRemoteObject(
        client,
        name: 'net.hadess.PowerProfiles',
        path: DBusObjectPath('/net/hadess/PowerProfiles'),
      );

      final prop = await object.getProperty(
        'net.hadess.PowerProfiles',
        'ActiveProfile',
      );

      var activeProfileVal = prop;
      if (activeProfileVal is DBusVariant) {
        activeProfileVal = activeProfileVal.asVariant();
      }

      if (activeProfileVal is DBusString) {
        return PowerProfileModeExtension.fromValue(activeProfileVal.value);
      }
    } catch (e) {
      try {
        final object = DBusRemoteObject(
          client,
          name: 'org.freedesktop.UPower.PowerProfiles',
          path: DBusObjectPath('/org/freedesktop/UPower/PowerProfiles'),
        );

        final prop = await object.getProperty(
          'org.freedesktop.UPower.PowerProfiles',
          'ActiveProfile',
        );

        var activeProfileVal = prop;
        if (activeProfileVal is DBusVariant) {
          activeProfileVal = activeProfileVal.asVariant();
        }

        if (activeProfileVal is DBusString) {
          return PowerProfileModeExtension.fromValue(activeProfileVal.value);
        }
      } catch (_) {}
    } finally {
      await client.close();
    }

    return PowerProfileMode.balanced;
  }

  /// Retrieves the list of supported battery power profiles.
  ///
  /// Queries the standard Power Profiles daemon first and falls back to the
  /// UPower PowerProfiles interface if needed.
  Future<List<String>> getAvailableBatteryModes() async {
    final client = _dbusClientFactory();
    try {
      // First try standard power profiles daemon service
      final object = DBusRemoteObject(
        client,
        name: 'net.hadess.PowerProfiles',
        path: DBusObjectPath('/net/hadess/PowerProfiles'),
      );
      final prop = await object.getProperty(
        'net.hadess.PowerProfiles',
        'Profiles',
      );
      List<String> modes = [];
      if (prop is DBusArray) {
        for (var element in prop.children) {
          if (element is DBusDict) {
            final value = element.children[const DBusString('Profile')];
            if (value is DBusVariant) {
              final variant = value.asVariant();
              if (variant is DBusString) {
                modes.add(variant.value);
              }
            }
          }
        }
      }
      if (modes.isNotEmpty) return modes;
    } catch (e) {
      // Fallback
      try {
        final object = DBusRemoteObject(
          client,
          name: 'org.freedesktop.UPower.PowerProfiles',
          path: DBusObjectPath('/org/freedesktop/UPower/PowerProfiles'),
        );
        final prop = await object.getProperty(
          'org.freedesktop.UPower.PowerProfiles',
          'Profiles',
        );
        List<String> modes = [];
        if (prop is DBusArray) {
          for (var element in prop.children) {
            if (element is DBusDict) {
              final value = element.children[const DBusString('Profile')];
              if (value is DBusVariant) {
                final variant = value.asVariant();
                if (variant is DBusString) {
                  modes.add(variant.value);
                }
              }
            }
          }
        }
        return modes;
      } catch (_) {}
    } finally {
      await client.close();
    }
    return [];
  }

  /// Returns a stream of battery property change events.
  ///
  /// The stream emits the names of battery properties whenever they are
  /// updated by UPower.
  @override
  Future<Stream<List<String>>?> streamBatteryEvents() async {
    try {
      await _ensureConnected();
      final device = _client.displayDevice;
      return device.propertiesChanged;
    } catch (e, stackTrace) {
      AppLogger.e(
        'Error initializing battery events stream',
        error: e,
        stack: stackTrace,
      );
      return null;
    }
  }

  /// Closes the UPower client connection and releases resources.
  @override
  Future<void> close() async {
    try {
      AppLogger.d("Closing battery repository...");
      _connected = false;
      await _client.close();
    } catch (e, stack) {
      AppLogger.e("Error closing battery client", error: e, stack: stack);
      throw const BatteryCloseException();
    }
  }
}

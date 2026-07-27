import 'dart:async';
import 'package:dbus/dbus.dart';
import 'package:mechanix_settings/core/exceptions/date_time_exceptions.dart';
import 'package:mechanix_settings/core/utils/app_logger.dart';
import 'date_time_repository.dart';
import 'dart:io';

/// Repository implementation that manages system date, time, timezone,
/// NTP settings, and time format using D-Bus and gsettings.
class DateTimeRepositoryImpl implements DateTimeRepository {
  static const _service = 'org.freedesktop.timedate1';
  static const _path = '/org/freedesktop/timedate1';
  static const _interface = 'org.freedesktop.timedate1';
  static const _interactive = false;

  DBusClient? _client;
  DBusRemoteObject? _object;
  bool _initialized = false;

  final DBusClient? _injectClient;
  final DBusRemoteObject? _injectObject;
  final Function? _processRun;

  DateTimeRepositoryImpl({
    DBusClient? client,
    DBusRemoteObject? object,
    Function? processRun,
  }) : _injectClient = client,
       _injectObject = object,
       _processRun = processRun;

  final _propertiesChangedController =
      StreamController<List<String>>.broadcast();
  StreamSubscription? _propertiesSubscription;

  /// Broadcasts the names of D-Bus properties that have changed.
  @override
  Stream<List<String>> get propertiesChangedStream =>
      _propertiesChangedController.stream;

  /// Initializes the D-Bus client and subscribes to timedate property changes.
  @override
  Future<void> init() async {
    if (_initialized) return;
    try {
      _client = _injectClient ?? DBusClient.system();
      _object =
          _injectObject ??
          DBusRemoteObject(
            _client!,
            name: _service,
            path: DBusObjectPath(_path),
          );

      _propertiesSubscription = _object!.propertiesChanged.listen((signal) {
        final changed = signal.changedProperties.keys.toList();
        _propertiesChangedController.add(changed);
      });

      _initialized = true;
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to initialize DateTime D-Bus client: $e',
        stack: stackTrace,
      );

      throw const DateTimeInitializationException();
    }
  }

  /// Returns whether automatic network time (NTP) synchronization is enabled.
  @override
  Future<bool> getNtpEnabled() async {
    final object = await _getObject();

    try {
      final property = await object.getProperty(_interface, 'NTP');
      return (property as DBusBoolean).value;
    } catch (e, stackTrace) {
      AppLogger.e('Failed to get NTP status: $e', stack: stackTrace);
      throw const GetNtpException();
    }
  }

  @override
  Future<void> setNtpEnabled(bool enabled) async {
    final object = await _getObject();

    try {
      await object.callMethod(_interface, 'SetNTP', [
        DBusBoolean(enabled),
        const DBusBoolean(_interactive),
      ]);
      AppLogger.i('SetNTP successfully called: $enabled');
    } catch (e, stackTrace) {
      AppLogger.e('Error calling SetNTP: $e', stack: stackTrace);
      throw const SetNtpException();
    }
  }

  /// Returns the current system timezone.
  @override
  Future<String> getTimezone() async {
    final object = await _getObject();

    try {
      final property = await object.getProperty(_interface, 'Timezone');
      return (property as DBusString).value;
    } catch (e, stackTrace) {
      AppLogger.e('Failed to get timezone: $e', stack: stackTrace);
      throw const GetTimezoneException();
    }
  }

  @override
  Future<void> setTimezone(String timezone) async {
    final object = await _getObject();

    try {
      await object.callMethod(_interface, 'SetTimezone', [
        DBusString(timezone),
        const DBusBoolean(_interactive),
      ]);
      AppLogger.i('SetTimezone successfully called: $timezone');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to set timezone: $e', stack: stackTrace);

      throw const SetTimezoneException();
    }
  }

  /// Sets the system time using microseconds since the Unix epoch.
  @override
  Future<void> setTime(int microsecondsSinceEpoch) async {
    final object = await _getObject();

    try {
      await object.callMethod(_interface, 'SetTime', [
        DBusInt64(microsecondsSinceEpoch),
        const DBusBoolean(false), // relative
        const DBusBoolean(_interactive),
      ]);
      AppLogger.i('SetTime successfully called: $microsecondsSinceEpoch');
    } catch (e, stackTrace) {
      AppLogger.e('Error calling SetTime: $e', stack: stackTrace);
      throw const SetTimeException();
    }
  }

  /// Returns the current system time from systemd-timedated.
  ///
  /// Throws [GetTimeException] if the system time cannot be retrieved.
  @override
  Future<DateTime> getSystemTime() async {
    final object = await _getObject();

    try {
      final property = await object.getProperty(_interface, 'TimeUSec');
      final timeMillis = property.asUint64() ~/ 1000;
      return DateTime.fromMillisecondsSinceEpoch(timeMillis);
    } catch (e, stackTrace) {
      AppLogger.e('Failed to get system time: $e', stack: stackTrace);
      throw const GetTimeException();
    }
  }

  /// Returns the current clock display format from GNOME settings.
  ///
  /// Expected values are '12h' or '24h'.
  @override
  Future<String> getTimeFormat() async {
    try {
      final runFn = _processRun ?? Process.run;
      final result = await runFn('gsettings', [
        'get',
        'org.gnome.desktop.interface',
        'clock-format',
      ]);

      if (result.exitCode != 0) {
        throw Exception(result.stderr.toString());
      }

      return result.stdout.toString().trim().replaceAll("'", "");
    } catch (e, stackTrace) {
      AppLogger.e('Failed to get time format: $e', stack: stackTrace);
      throw const GetTimeFormatException();
    }
  }

  /// Updates the GNOME clock display format.
  ///
  /// Accepted values are '12h' and '24h'.
  @override
  Future<void> setTimeFormat(String format) async {
    try {
      final runFn = _processRun ?? Process.run;
      final result = await runFn('gsettings', [
        'set',
        'org.gnome.desktop.interface',
        'clock-format',
        format,
      ]);

      if (result.exitCode != 0) {
        throw Exception(result.stderr.toString());
      }

      AppLogger.i('Time format set successfully: $format');
    } catch (e, stackTrace) {
      AppLogger.e('Error setting time format: $e', stack: stackTrace);
      throw const SetTimeFormatException();
    }
  }

  /// Releases D-Bus resources, subscriptions, and stream controllers.
  @override
  Future<void> close() async {
    try {
      await _propertiesSubscription?.cancel();
      await _propertiesChangedController.close();
      await _client?.close();
    } catch (e, stackTrace) {
      AppLogger.e('Error closing DateTimeRepository: $e', stack: stackTrace);
    } finally {
      _client = null;
      _object = null;
      _initialized = false;
    }
  }

  Future<DBusRemoteObject> _getObject() async {
    await init();

    if (_object == null) {
      throw const DateTimeInitializationException();
    }

    return _object!;
  }
}

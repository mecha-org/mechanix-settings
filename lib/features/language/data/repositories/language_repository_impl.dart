import 'dart:async';
import 'dart:io';
import 'package:dbus/dbus.dart';
import 'package:mechanix_settings/core/exceptions/language_exceptions.dart';
import 'package:mechanix_settings/core/utils/app_logger.dart';
import 'language_repository.dart';

class LanguageRepositoryImpl implements LanguageRepository {
  static const _service = 'org.freedesktop.Accounts';
  static const _accountsPath = '/org/freedesktop/Accounts';
  static const _accountsInterface = 'org.freedesktop.Accounts';
  static const _userInterface = 'org.freedesktop.Accounts.User';

  DBusClient? _client;
  DBusRemoteObject? _accountsObject;
  DBusRemoteObject? _userObject;
  bool _initialized = false;

  final DBusClient? _injectClient;
  final DBusRemoteObject? _injectAccountsObject;
  final DBusRemoteObject? _injectUserObject;

  LanguageRepositoryImpl({
    DBusClient? client,
    DBusRemoteObject? accountsObject,
    DBusRemoteObject? userObject,
  }) : _injectClient = client,
       _injectAccountsObject = accountsObject,
       _injectUserObject = userObject;

  final _propertiesChangedController =
      StreamController<List<String>>.broadcast();
  StreamSubscription? _propertiesSubscription;

  @override
  Stream<List<String>> get propertiesChangedStream =>
      _propertiesChangedController.stream;

  @override
  Future<void> init() async {
    if (_initialized) return;

    try {
      _client = _injectClient ?? DBusClient.system();
      
      _accountsObject = _injectAccountsObject ??
          DBusRemoteObject(
            _client!,
            name: _service,
            path: DBusObjectPath(_accountsPath),
          );

      if (_injectUserObject != null) {
        _userObject = _injectUserObject;
      } else {
        final username = Platform.environment['USER'] ?? Platform.environment['LOGNAME'] ?? 'root';
        final response = await _accountsObject!.callMethod(
          _accountsInterface,
          'FindUserByName',
          [DBusString(username)],
        );
        if (response.values.isEmpty) {
          throw Exception('User path not found for username: $username');
        }
        final userPath = (response.values.first as DBusObjectPath).value;
        _userObject = DBusRemoteObject(
          _client!,
          name: _service,
          path: DBusObjectPath(userPath),
        );
      }

      _propertiesSubscription = _userObject!.propertiesChanged.listen((signal) {
        final changed = signal.changedProperties.keys.toList();
        _propertiesChangedController.add(changed);
      });

      _initialized = true;
    } catch (e, stackTrace) {
      AppLogger.e('Failed to initialize Language D-Bus client: $e', stack: stackTrace);
      throw const LanguageInitializationException();
    }
  }

  @override
  Future<String> getLanguage() async {
    await _ensureInitialized();
    try {
      final property = await _userObject!.getProperty(_userInterface, 'Language');
      return (property as DBusString).value;
    } catch (e, stackTrace) {
      AppLogger.e('Failed to get language: $e', stack: stackTrace);
      throw const GetLanguageException();
    }
  }

  @override
  Future<void> setLanguage(String language) async {
    await _ensureInitialized();
    try {
      await _userObject!.callMethod(
        _userInterface,
        'SetLanguage',
        [DBusString(language)],
      );
      AppLogger.i('SetLanguage successfully called: $language');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to set language: $e', stack: stackTrace);
      throw const SetLanguageException();
    }
  }

  @override
  Future<void> close() async {
    try {
      await _propertiesSubscription?.cancel();
      await _propertiesChangedController.close();
      await _client?.close();
    } catch (e, stackTrace) {
      AppLogger.e('Error closing LanguageRepository: $e', stack: stackTrace);
    } finally {
      _client = null;
      _accountsObject = null;
      _userObject = null;
      _initialized = false;
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
  }
}

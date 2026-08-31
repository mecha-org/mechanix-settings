import 'dart:async';
import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mechanix_settings/core/exceptions/language_exceptions.dart';
import 'package:mechanix_settings/features/language/data/repositories/language_repository_impl.dart';

class MockDBusClient extends Mock implements DBusClient {}
class MockDBusRemoteObject extends Mock implements DBusRemoteObject {}
class MockDBusPropertiesChangedSignal extends Mock implements DBusPropertiesChangedSignal {}
class MockDBusMethodSuccessResponse extends Mock implements DBusMethodSuccessResponse {}

void main() {
  late LanguageRepositoryImpl repository;
  late MockDBusClient mockClient;
  late MockDBusRemoteObject mockAccountsObject;
  late MockDBusRemoteObject mockUserObject;
  late StreamController<DBusPropertiesChangedSignal> signalController;

  setUpAll(() {
    registerFallbackValue(const DBusString(''));
  });

  setUp(() {
    mockClient = MockDBusClient();
    mockAccountsObject = MockDBusRemoteObject();
    mockUserObject = MockDBusRemoteObject();
    signalController = StreamController<DBusPropertiesChangedSignal>();

    when(() => mockUserObject.propertiesChanged)
        .thenAnswer((_) => signalController.stream);
    when(() => mockClient.close()).thenAnswer((_) async {});

    repository = LanguageRepositoryImpl(
      client: mockClient,
      accountsObject: mockAccountsObject,
      userObject: mockUserObject,
    );
  });

  tearDown(() async {
    await repository.close();
    await signalController.close();
  });

  group('LanguageRepositoryImpl - Initialization & Stream', () {
    test('init subscribes to propertiesChanged and forwards event names', () async {
      await repository.init();

      final events = [];
      final subscription = repository.propertiesChangedStream.listen((event) {
        events.add(event);
      });

      final signal = MockDBusPropertiesChangedSignal();
      when(() => signal.changedProperties)
          .thenReturn({'Language': const DBusString('en_GB.UTF-8')});

      signalController.add(signal);
      await Future.delayed(Duration.zero);

      expect(events, isNotEmpty);
      expect(events.first, contains('Language'));

      await subscription.cancel();
    });

    test('init executes only once on multiple calls', () async {
      await repository.init();
      await repository.init();

      verify(() => mockUserObject.propertiesChanged).called(1);
    });
  });

  group('LanguageRepositoryImpl - Get & Set Language', () {
    test('getLanguage returns language property value', () async {
      when(() => mockUserObject.getProperty('org.freedesktop.Accounts.User', 'Language'))
          .thenAnswer((_) async => const DBusString('en_GB.UTF-8'));

      final lang = await repository.getLanguage();
      expect(lang, equals('en_GB.UTF-8'));
    });

    test('getLanguage throws GetLanguageException on D-Bus failure', () async {
      when(() => mockUserObject.getProperty(any(), any()))
          .thenThrow(Exception('D-Bus error'));

      expect(repository.getLanguage(), throwsA(isA<GetLanguageException>()));
    });

    test('setLanguage calls SetLanguage on D-Bus user object', () async {
      final mockResponse = MockDBusMethodSuccessResponse();
      when(() => mockUserObject.callMethod(any(), any(), any()))
          .thenAnswer((_) async => mockResponse);

      await repository.setLanguage('en_US.UTF-8');

      verify(() => mockUserObject.callMethod(
            'org.freedesktop.Accounts.User',
            'SetLanguage',
            [const DBusString('en_US.UTF-8')],
          )).called(1);
    });

    test('setLanguage throws SetLanguageException on D-Bus failure', () async {
      when(() => mockUserObject.callMethod(any(), any(), any()))
          .thenThrow(Exception('D-Bus failure'));

      expect(repository.setLanguage('en_US.UTF-8'), throwsA(isA<SetLanguageException>()));
    });
  });

  group('LanguageRepositoryImpl - Close', () {
    test('close cancels subscriptions and closes client', () async {
      await repository.init();
      await repository.close();

      verify(() => mockClient.close()).called(1);
    });
  });
}

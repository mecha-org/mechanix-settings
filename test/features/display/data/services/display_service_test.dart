import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_settings/features/display/data/services/display_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDBusClient extends Mock implements DBusClient {}

class MockDBusMethodSuccessResponse extends Mock
    implements DBusMethodSuccessResponse {}

void main() {
  late MockDBusClient mockSystemClient;
  late MockDBusClient mockSessionClient;
  late DisplayService displayService;

  setUpAll(() {
    registerFallbackValue(DBusObjectPath('/org/mechanix/services/Display'));
    registerFallbackValue(const DBusByte(0));
    registerFallbackValue(const DBusString(''));
  });

  setUp(() {
    mockSystemClient = MockDBusClient();
    mockSessionClient = MockDBusClient();
    displayService = DisplayService(
      systemClient: mockSystemClient,
      sessionClient: mockSessionClient,
    );
  });

  group('DisplayService - Brightness', () {
    test('getBrightness returns correct value', () async {
      final mockResponse = MockDBusMethodSuccessResponse();
      when(() => mockResponse.values).thenReturn([const DBusByte(127)]);

      when(() => mockSystemClient.callMethod(
            destination: 'org.mechanix.services.Display',
            path: DBusObjectPath('/org/mechanix/services/Display'),
            interface: 'org.mechanix.services.Display',
            name: 'GetBrightness',
            values: any(named: 'values'),
          )).thenAnswer((_) async => mockResponse);

      final brightness = await displayService.getBrightness();
      expect(brightness, closeTo(127 / 254.0, 0.0001));
    });

    test('setBrightness calls DBus correctly', () async {
      final mockResponse = MockDBusMethodSuccessResponse();
      when(() => mockSystemClient.callMethod(
            destination: 'org.mechanix.services.Display',
            path: DBusObjectPath('/org/mechanix/services/Display'),
            interface: 'org.mechanix.services.Display',
            name: 'SetBrightness',
            values: any(named: 'values'),
          )).thenAnswer((_) async => mockResponse);

      await displayService.setBrightness(0.5);

      verify(() => mockSystemClient.callMethod(
            destination: 'org.mechanix.services.Display',
            path: DBusObjectPath('/org/mechanix/services/Display'),
            interface: 'org.mechanix.services.Display',
            name: 'SetBrightness',
            values: [const DBusByte(127)],
          )).called(1);
    });
  });

  group('DisplayService - AutoBrightness', () {
    test('getAutoBrightness returns true', () async {
      final mockResponse = MockDBusMethodSuccessResponse();
      when(() => mockResponse.returnValues).thenReturn([
        DBusDict(
          DBusSignature('s'),
          DBusSignature('s'),
          {
            const DBusString(
                "org.mechanix.desktop.settings.display.enable_auto_brightness.value"):
                const DBusString('true'),
          },
        )
      ]);

      when(() => mockSessionClient.callMethod(
            destination: 'org.mechanix.services.Display',
            path: DBusObjectPath('/org/mechanix/services/Display'),
            interface: 'org.mechanix.services.Display',
            name: 'GetSetting',
            values: any(named: 'values'),
          )).thenAnswer((_) async => mockResponse);

      final auto = await displayService.getAutoBrightness();
      expect(auto, isTrue);
    });

    test('setAutoBrightness calls DBus correctly', () async {
      final mockResponse = MockDBusMethodSuccessResponse();
      when(() => mockSessionClient.callMethod(
            destination: 'org.mechanix.services.Display',
            path: DBusObjectPath('/org/mechanix/services/Display'),
            interface: 'org.mechanix.services.Display',
            name: 'SetSetting',
            values: any(named: 'values'),
          )).thenAnswer((_) async => mockResponse);

      await displayService.setAutoBrightness(true);

      verify(() => mockSessionClient.callMethod(
            destination: 'org.mechanix.services.Display',
            path: DBusObjectPath('/org/mechanix/services/Display'),
            interface: 'org.mechanix.services.Display',
            name: 'SetSetting',
            values: [
              DBusStruct([
                const DBusString(
                    "org.mechanix.desktop.settings.display.enable_auto_brightness.value"),
                const DBusString('true'),
              ]),
            ],
          )).called(1);
    });
  });

  group('DisplayService - ScreenTimeout', () {
    test('getScreenTimeout returns correct timeout', () async {
      final mockResponse = MockDBusMethodSuccessResponse();
      when(() => mockResponse.returnValues).thenReturn([
        DBusDict(
          DBusSignature('s'),
          DBusSignature('s'),
          {
            const DBusString(
                "org.mechanix.desktop.settings.display.timeout.value"):
                const DBusString('45'),
          },
        )
      ]);

      when(() => mockSessionClient.callMethod(
            destination: 'org.mechanix.services.Display',
            path: DBusObjectPath('/org/mechanix/services/Display'),
            interface: 'org.mechanix.services.Display',
            name: 'GetSetting',
            values: any(named: 'values'),
          )).thenAnswer((_) async => mockResponse);

      final timeout = await displayService.getScreenTimeout();
      expect(timeout, equals(45));
    });

    test('setScreenTimeout calls DBus correctly', () async {
      final mockResponse = MockDBusMethodSuccessResponse();
      when(() => mockSessionClient.callMethod(
            destination: 'org.mechanix.services.Display',
            path: DBusObjectPath('/org/mechanix/services/Display'),
            interface: 'org.mechanix.services.Display',
            name: 'SetSetting',
            values: any(named: 'values'),
          )).thenAnswer((_) async => mockResponse);

      await displayService.setScreenTimeout(60);

      verify(() => mockSessionClient.callMethod(
            destination: 'org.mechanix.services.Display',
            path: DBusObjectPath('/org/mechanix/services/Display'),
            interface: 'org.mechanix.services.Display',
            name: 'SetSetting',
            values: [
              DBusStruct([
                const DBusString(
                    "org.mechanix.desktop.settings.display.timeout.value"),
                const DBusString('60'),
              ]),
            ],
          )).called(1);
    });
  });
}

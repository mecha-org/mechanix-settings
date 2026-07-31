import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:upower/upower.dart';
import 'package:mechanix_settings/features/battery/blocs/battery_bloc.dart';
import 'package:mechanix_settings/features/battery/blocs/battery_event.dart';
import 'package:mechanix_settings/features/battery/blocs/battery_state.dart';
import 'package:mechanix_settings/features/battery/data/repositories/battery_repository.dart';
import 'package:mechanix_settings/features/battery/data/models/battery_info.dart';
import 'package:mechanix_settings/features/battery/data/models/enums.dart';

class MockBatteryRepository extends Mock implements BatteryRepository {}

void main() {
  late BatteryBloc batteryBloc;
  late MockBatteryRepository mockBatteryRepository;
  late PowerProfileMode mockMode;

  setUp(() {
    mockBatteryRepository = MockBatteryRepository();
    mockMode = PowerProfileMode.balanced;

    // Default mocks to prevent crashes
    when(() => mockBatteryRepository.init()).thenAnswer((_) async {});
    when(
      () => mockBatteryRepository.streamBatteryEvents(),
    ).thenAnswer((_) async => const Stream<List<String>>.empty());
    when(() => mockBatteryRepository.getBatteryInfo()).thenAnswer(
      (_) async => BatteryInfo(
        batteryPercentage: 75.0,
        status: UPowerDeviceState.discharging,
        mode: mockMode,
        batteryChargingTime: 0,
        batteryRemainingTime: 7200,
        availableBatteryModes: const ['power-saver', 'balanced', 'performance'],
      ),
    );
    when(() => mockBatteryRepository.close()).thenAnswer((_) async {});

    batteryBloc = BatteryBloc(batteryRepository: mockBatteryRepository);
  });

  tearDown(() {
    batteryBloc.close();
  });

  group('BatteryBloc Initial State', () {
    test('initial state has correct default values', () {
      expect(batteryBloc.state.batteryPercentage, 0.0);
      expect(batteryBloc.state.batteryStatus, UPowerDeviceState.unknown);
    });
  });

  group('BatteryInit Event', () {
    blocTest<BatteryBloc, BatteryState>(
      'initializes repository and battery stream',
      build: () => batteryBloc,
      act: (bloc) => bloc.add(const BatteryInit()),
      expect: () => [
        isA<BatteryState>().having(
          (s) => s.status,
          'status',
          BatteryStatus.loading,
        ),
      ],
      verify: (_) {
        verify(() => mockBatteryRepository.init()).called(1);
        verify(() => mockBatteryRepository.streamBatteryEvents()).called(1);
        verifyNever(() => mockBatteryRepository.getBatteryInfo());
      },
    );
  });
  group('ToggleBatterySaver Event', () {
    blocTest<BatteryBloc, BatteryState>(
      'toggles battery saver to true and sets power-saver mode',
      build: () {
        when(
          () =>
              mockBatteryRepository.setBatteryMode(PowerProfileMode.powerSaver),
        ).thenAnswer((_) async {
          mockMode = PowerProfileMode.powerSaver;
          return PowerProfileMode.powerSaver;
        });
        return batteryBloc;
      },
      act: (bloc) => bloc.add(const ToggleBatterySaver(true)),
      expect: () => [
        isA<BatteryState>()
            .having(
              (s) => s.performanceMode == PowerProfileMode.powerSaver,
              'isBatterySaverOn',
              true,
            )
            .having(
              (s) => s.performanceMode,
              'performanceMode',
              PowerProfileMode.powerSaver,
            ),
        isA<BatteryState>()
            .having((s) => s.batteryPercentage, 'batteryPercentage', 75.0)
            .having(
              (s) => s.performanceMode == PowerProfileMode.powerSaver,
              'isBatterySaverOn',
              true,
            )
            .having(
              (s) => s.performanceMode,
              'performanceMode',
              PowerProfileMode.powerSaver,
            ),
      ],
      verify: (_) {
        verify(
          () =>
              mockBatteryRepository.setBatteryMode(PowerProfileMode.powerSaver),
        ).called(1);
        verify(() => mockBatteryRepository.getBatteryInfo()).called(1);
      },
    );

    blocTest<BatteryBloc, BatteryState>(
      'toggles battery saver to false and sets balanced mode',
      build: () {
        when(
          () => mockBatteryRepository.setBatteryMode(PowerProfileMode.balanced),
        ).thenAnswer((_) async {
          mockMode = PowerProfileMode.balanced;
          return PowerProfileMode.balanced;
        });
        return batteryBloc;
      },
      act: (bloc) => bloc.add(const ToggleBatterySaver(false)),
      expect: () => [
        isA<BatteryState>()
            .having(
              (s) => s.performanceMode == PowerProfileMode.powerSaver,
              'isBatterySaverOn',
              false,
            )
            .having(
              (s) => s.performanceMode,
              'performanceMode',
              PowerProfileMode.balanced,
            ),
        isA<BatteryState>()
            .having((s) => s.batteryPercentage, 'batteryPercentage', 75.0)
            .having(
              (s) => s.performanceMode == PowerProfileMode.powerSaver,
              'isBatterySaverOn',
              false,
            )
            .having(
              (s) => s.performanceMode,
              'performanceMode',
              PowerProfileMode.balanced,
            ),
      ],
      verify: (_) {
        verify(
          () => mockBatteryRepository.setBatteryMode(PowerProfileMode.balanced),
        ).called(1);
        verify(() => mockBatteryRepository.getBatteryInfo()).called(1);
      },
    );
  });
}

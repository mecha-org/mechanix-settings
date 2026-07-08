import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/features/bluetooth/data/repositories/bluetooth_repository.dart';
import 'package:mechanix_settings/features/bluetooth/blocs/bluetooth_event.dart';
import 'package:mechanix_settings/features/bluetooth/blocs/bluetooth_state.dart';

import '../../../core/utils/app_logger.dart';

export 'bluetooth_event.dart';
export 'bluetooth_state.dart';

class BluetoothBloc extends Bloc<BluetoothEvent, BluetoothState> {
  final BluetoothRepository _repository;
  Timer? _scanTimer;

  BluetoothBloc(this._repository) : super(const BluetoothState()) {
    on<LoadBluetooth>(_onLoadBluetooth);
    on<ToggleBluetoothPower>(_onToggleBluetoothPower);
    on<ScanBluetoothDevices>(_onScanBluetoothDevices);
    on<ConnectToDeviceEvent>(_onConnectToDevice);
    on<DisconnectFromDeviceEvent>(_onDisconnectFromDevice);
    on<ForgetDeviceEvent>(_onForgetDevice);
    on<ShowPairingInputEvent>(_onShowPairingInput);
    on<ShowPairingCodeEvent>(_onShowPairingCode);
    on<CancelPairingEvent>(_onCancelPairing);
    on<CompletePairingEvent>(_onCompletePairing);
    on<RenameLocalDeviceEvent>(_onRenameLocalDevice);
  }

  Future<void> _onLoadBluetooth(
    LoadBluetooth event,
    Emitter<BluetoothState> emit,
  ) async {
    try {
      final paired = await _repository.getPairedDevices();
      final discovered = await _repository.getDiscoveredDevices();
      final localDeviceName = await _repository.getLocalDeviceName();

      String? connectedName;
      for (var d in paired) {
        if (d.isConnected) connectedName = d.name;
      }

      emit(
        state.copyWith(
          pairedDevices: paired,
          discoveredDevices: discovered,
          connectedDeviceName: connectedName,
          localDeviceName: localDeviceName,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.e('Failed to load bluetooth devices: $e', stack: stackTrace);
    }
  }

  Future<void> _onToggleBluetoothPower(
    ToggleBluetoothPower event,
    Emitter<BluetoothState> emit,
  ) async {
    try {
      _scanTimer?.cancel();

      if (event.isEnabled) {
        emit(
          state.copyWith(
            isBluetoothOn: true,
            isScanning: true,
            connectingDeviceName: null,
            pairingRequestDevice: null,
            pairingCodeDisplayDevice: null,
          ),
        );

        final paired = await _repository.getPairedDevices();
        final discovered = await _repository.getDiscoveredDevices();

        add(const ScanBluetoothDevices());

        emit(
          state.copyWith(pairedDevices: paired, discoveredDevices: discovered),
        );
      } else {
        await _repository.disconnectAll();

        final paired = await _repository.getPairedDevices();
        final discovered = await _repository.getDiscoveredDevices();

        emit(
          state.copyWith(
            isBluetoothOn: false,
            isScanning: false,
            connectingDeviceName: null,
            connectedDeviceName: null,
            pairingRequestDevice: null,
            pairingCodeDisplayDevice: null,
            pairedDevices: paired,
            discoveredDevices: discovered,
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.e('Failed to toggle bluetooth: $e', stack: stackTrace);
    }
  }

  Future<void> _onScanBluetoothDevices(
    ScanBluetoothDevices event,
    Emitter<BluetoothState> emit,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 1500));

      if (state.isBluetoothOn) {
        emit(state.copyWith(isScanning: false));
      }
    } catch (e, stackTrace) {
      AppLogger.e('Failed to scan bluetooth devices: $e', stack: stackTrace);
    }
  }

  Future<void> _onConnectToDevice(
    ConnectToDeviceEvent event,
    Emitter<BluetoothState> emit,
  ) async {
    try {
      final isAlreadyConnected = state.pairedDevices.any(
        (d) => d.name == event.device.name && d.isConnected,
      );
      if (isAlreadyConnected) {
        return;
      }

      // Trigger pairing simulation sheets if the device is not paired
      if (!event.device.isSaved) {
        if (event.device.name == 'iPhone 15 Pro') {
          add(ShowPairingInputEvent(event.device));
          return;
        } else if (event.device.name == 'JBL Charge 5') {
          add(ShowPairingCodeEvent(event.device));
          return;
        }
      }

      // Direct connect if already paired or other devices
      add(CompletePairingEvent(event.device));
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to connect to bluetooth device: $e',
        stack: stackTrace,
      );
    }
  }

  Future<void> _onShowPairingInput(
    ShowPairingInputEvent event,
    Emitter<BluetoothState> emit,
  ) async {
    try {
      emit(state.copyWith(pairingRequestDevice: event.device));
    } catch (e, stackTrace) {
      AppLogger.e('Failed to show pairing input: $e', stack: stackTrace);
    }
  }

  Future<void> _onShowPairingCode(
    ShowPairingCodeEvent event,
    Emitter<BluetoothState> emit,
  ) async {
    try {
      emit(state.copyWith(pairingCodeDisplayDevice: event.device));
    } catch (e, stackTrace) {
      AppLogger.e('Failed to show pairing code: $e', stack: stackTrace);
    }
  }

  Future<void> _onCancelPairing(
    CancelPairingEvent event,
    Emitter<BluetoothState> emit,
  ) async {
    try {
      emit(
        state.copyWith(
          pairingRequestDevice: null,
          pairingCodeDisplayDevice: null,
          connectingDeviceName: null,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.e('Failed to cancel pairing: $e', stack: stackTrace);
    }
  }

  Future<void> _onCompletePairing(
    CompletePairingEvent event,
    Emitter<BluetoothState> emit,
  ) async {
    try {
      final updatedPaired = state.pairedDevices.map((d) {
        return d.copyWith(isConnecting: d.name == event.device.name);
      }).toList();
      final updatedDiscovered = state.discoveredDevices.map((d) {
        return d.copyWith(isConnecting: d.name == event.device.name);
      }).toList();

      emit(
        state.copyWith(
          connectingDeviceName: event.device.name,
          pairingRequestDevice: null,
          pairingCodeDisplayDevice: null,
          pairedDevices: updatedPaired,
          discoveredDevices: updatedDiscovered,
        ),
      );

      await _repository.connectToDevice(event.device.name);

      if (state.isBluetoothOn) {
        final paired = await _repository.getPairedDevices();
        final discovered = await _repository.getDiscoveredDevices();

        emit(
          state.copyWith(
            pairedDevices: paired,
            discoveredDevices: discovered,
            connectingDeviceName: null,
            connectedDeviceName: event.device.name,
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.e('Failed to complete pairing: $e', stack: stackTrace);

      emit(state.copyWith(connectingDeviceName: null));
    }
  }

  Future<void> _onDisconnectFromDevice(
    DisconnectFromDeviceEvent event,
    Emitter<BluetoothState> emit,
  ) async {
    try {
      await _repository.disconnectFromDevice(event.device.name);

      if (state.isBluetoothOn) {
        final paired = await _repository.getPairedDevices();
        final discovered = await _repository.getDiscoveredDevices();

        emit(
          state.copyWith(
            pairedDevices: paired,
            discoveredDevices: discovered,
            connectedDeviceName: state.connectedDeviceName == event.device.name
                ? null
                : state.connectedDeviceName,
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to disconnect bluetooth device: $e',
        stack: stackTrace,
      );
    }
  }

  Future<void> _onForgetDevice(
    ForgetDeviceEvent event,
    Emitter<BluetoothState> emit,
  ) async {
    try {
      await _repository.forgetDevice(event.device.name);

      if (state.isBluetoothOn) {
        final paired = await _repository.getPairedDevices();
        final discovered = await _repository.getDiscoveredDevices();

        emit(
          state.copyWith(
            pairedDevices: paired,
            discoveredDevices: discovered,
            connectedDeviceName: state.connectedDeviceName == event.device.name
                ? null
                : state.connectedDeviceName,
            connectingDeviceName:
                state.connectingDeviceName == event.device.name
                ? null
                : state.connectingDeviceName,
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.e('Failed to forget bluetooth device: $e', stack: stackTrace);
    }
  }

  Future<void> _onRenameLocalDevice(
    RenameLocalDeviceEvent event,
    Emitter<BluetoothState> emit,
  ) async {
    try {
      await _repository.updateLocalDeviceName(event.name);
      emit(state.copyWith(localDeviceName: event.name));
    } catch (e, stackTrace) {
      AppLogger.e('Failed to rename bluetooth device: $e', stack: stackTrace);
    }
  }

  @override
  Future<void> close() {
    _scanTimer?.cancel();
    return super.close();
  }
}

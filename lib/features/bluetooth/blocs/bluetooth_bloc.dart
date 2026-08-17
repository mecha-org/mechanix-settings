import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/features/bluetooth/data/repositories/bluetooth_repository.dart';
import 'package:mechanix_settings/features/bluetooth/blocs/bluetooth_event.dart';
import 'package:mechanix_settings/features/bluetooth/blocs/bluetooth_state.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/bluetooth_device.dart';

import '../../../core/utils/app_logger.dart';

export 'bluetooth_event.dart';
export 'bluetooth_state.dart';

class BluetoothBloc extends Bloc<BluetoothEvent, BluetoothState> {
  final BluetoothRepository _repository;

  // Real-time BlueZ streams.
  StreamSubscription? _powerSub;
  StreamSubscription? _scanningSub;
  StreamSubscription? _discoverableSub;
  StreamSubscription<List<BluetoothDevice>>? _devicesSub;

  BluetoothBloc(this._repository) : super(const BluetoothState()) {
    // User actions.
    on<LoadBluetooth>(_onLoadBluetooth);
    on<ToggleBluetoothPower>(_onToggleBluetoothPower);
    on<ToggleBluetoothDiscoverable>(_onToggleBluetoothDiscoverable);
    on<ScanBluetoothDevices>(_onScanBluetoothDevices);
    on<ConnectToDeviceEvent>(_onConnectToDevice);
    on<DisconnectFromDeviceEvent>(_onDisconnectFromDevice);
    on<ForgetDeviceEvent>(_onForgetDevice);
    on<CancelPairingEvent>(_onCancelPairing);
    on<CompletePairingEvent>(_onCompletePairing);
    on<RenameLocalDeviceEvent>(_onRenameLocalDevice);

    // Internal events from repository streams.
    on<BluetoothPowerChanged>(_onPowerChanged);
    on<BluetoothScanningChanged>(_onScanningChanged);
    on<BluetoothDiscoverableChanged>(_onDiscoverableChanged);
    on<BluetoothDevicesUpdated>(_onDevicesChanged);
    on<StopBluetoothDiscovery>(_onStopBluetoothDiscovery);
  }

  /// Initializes Bluetooth and listens for BlueZ state changes.
  ///
  /// Loads:
  /// - Bluetooth power state
  /// - Local adapter name
  /// - Previously paired devices
  /// - Starts discovery when Bluetooth is enabled
  Future<void> _onLoadBluetooth(
    LoadBluetooth event,
    Emitter<BluetoothState> emit,
  ) async {
    try {
      await _repository.init();

      // Cancel old subscriptions first
      await _powerSub?.cancel();
      await _scanningSub?.cancel();
      await _discoverableSub?.cancel();
      await _devicesSub?.cancel();

      // Listen for adapter power changes.
      _powerSub = _repository.powerStream.listen((isOn) {
        if (!isClosed) {
          add(BluetoothPowerChanged(isOn));
        }
      });

      // Listen for discovery start/stop changes.
      _scanningSub = _repository.scanningStream.listen((isScanning) {
        if (!isClosed) {
          add(BluetoothScanningChanged(isScanning));
        }
      });

      // Listen for adapter discoverable changes.
      _discoverableSub = _repository.discoverableStream.listen((
        isDiscoverable,
      ) {
        if (!isClosed) {
          add(BluetoothDiscoverableChanged(isDiscoverable));
        }
      });

      // Listen for paired and discovered device updates.
      _devicesSub = _repository.devicesStream.listen((devices) {
        if (!isClosed) {
          add(BluetoothDevicesUpdated(devices));
        }
      });

      final isPowered = await _repository.isBluetoothEnabled();
      final localDeviceName = await _repository.getLocalDeviceName();
      final isDiscoverable = isPowered
          ? await _repository.isDiscoverable()
          : false;

      final pairedDevices = isPowered
          ? await _repository.getPairedDevices()
          : <BluetoothDevice>[];

      emit(
        state.copyWith(
          isBluetoothOn: isPowered,
          localDeviceName: localDeviceName,
          isDiscoverable: isDiscoverable,
          pairedDevices: pairedDevices,
        ),
      );

      if (isPowered) {
        await _repository.startDiscovery();
      }
    } catch (e, stackTrace) {
      AppLogger.e('Failed to load bluetooth devices: $e', stack: stackTrace);
    }
  }

  Future<void> _onToggleBluetoothPower(
    ToggleBluetoothPower event,
    Emitter<BluetoothState> emit,
  ) async {
    try {
      await _repository.togglePower(event.isEnabled);
    } catch (e, stackTrace) {
      AppLogger.e('Failed to toggle bluetooth: $e', stack: stackTrace);
    }
  }

  Future<void> _onToggleBluetoothDiscoverable(
    ToggleBluetoothDiscoverable event,
    Emitter<BluetoothState> emit,
  ) async {
    try {
      await _repository.setDiscoverable(event.isDiscoverable);
    } catch (e, stackTrace) {
      AppLogger.e('Failed to toggle discoverable: $e', stack: stackTrace);
    }
  }

  Future<void> _onScanBluetoothDevices(
    ScanBluetoothDevices event,
    Emitter<BluetoothState> emit,
  ) async {
    try {
      if (!state.isBluetoothOn) {
        return;
      }

      await _repository.startDiscovery();
    } catch (e, stackTrace) {
      AppLogger.e('Failed to start bluetooth discovery: $e', stack: stackTrace);
    }
  }

  /// Handles device connection request.
  ///
  /// For unpaired devices:
  /// 1. Start pairing
  /// 2. Wait for pairing completion
  /// 3. Trigger connection
  ///
  /// The connectingDevices set is used to display the loader in UI.
  Future<void> _onConnectToDevice(
    ConnectToDeviceEvent event,
    Emitter<BluetoothState> emit,
  ) async {
    final macAddress = event.device.macAddress;

    try {
      if (state.connectingDevices.contains(macAddress)) {
        return;
      }

      final isAlreadyConnected = state.pairedDevices.any(
        (device) => device.macAddress == macAddress && device.isConnected,
      );

      if (isAlreadyConnected) {
        return;
      }

      final updatedConnecting = {...state.connectingDevices, macAddress};

      emit(state.copyWith(connectingDevices: updatedConnecting, error: null));

      if (!event.device.isSaved) {
        await _repository.pairDevice(macAddress);
      }

      add(CompletePairingEvent(event.device));
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to connect to bluetooth device: $e',
        stack: stackTrace,
      );

      final updatedConnecting = {...state.connectingDevices}
        ..remove(macAddress);

      emit(
        state.copyWith(
          connectingDevices: updatedConnecting,
          error: BluetoothFailure(
            type: BluetoothErrorType.pairingFailed,
            message: e.toString(),
            data: {'deviceName': event.device.name},
          ),
        ),
      );
    }
  }

  Future<void> _onCancelPairing(
    CancelPairingEvent event,
    Emitter<BluetoothState> emit,
  ) async {
    final updatedConnecting = {...state.connectingDevices}
      ..remove(event.device.macAddress);

    emit(state.copyWith(connectingDevices: updatedConnecting));
  }

  /// Completes the connection after pairing.
  ///
  /// BlueZ will later emit device property changes through
  /// devicesStream, which updates the final connected state.
  Future<void> _onCompletePairing(
    CompletePairingEvent event,
    Emitter<BluetoothState> emit,
  ) async {
    try {
      await _repository.connectToDevice(event.device.macAddress);
    } catch (e, stackTrace) {
      AppLogger.e('Failed to complete pairing: $e', stack: stackTrace);

      final updatedConnecting = {...state.connectingDevices}
        ..remove(event.device.macAddress);

      emit(
        state.copyWith(
          connectingDevices: updatedConnecting,
          error: BluetoothFailure(
            type: BluetoothErrorType.connectionFailed,
            message: e.toString(),
            data: {'deviceName': event.device.name},
          ),
        ),
      );
    }
  }

  Future<void> _onDisconnectFromDevice(
    DisconnectFromDeviceEvent event,
    Emitter<BluetoothState> emit,
  ) async {
    try {
      await _repository.disconnectFromDevice(event.device.macAddress);
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
      await _repository.forgetDevice(event.device.macAddress);
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

  // Updates Bluetooth power state.
  //
  // When Bluetooth is disabled:
  // - Stops the scanning state.
  // - Clears discoverable state and device lists.
  //
  // When Bluetooth is enabled again:
  // - Refreshes the paired devices.
  // - Automatically restarts Bluetooth discovery.
  Future<void> _onPowerChanged(
    BluetoothPowerChanged event,
    Emitter emit,
  ) async {
    emit(state.copyWith(isBluetoothOn: event.isOn));

    if (!event.isOn) {
      emit(
        state.copyWith(
          isScanning: false,
          isDiscoverable: false,
          pairedDevices: [],
          discoveredDevices: [],
          connectingDevices: {},
          connectedDeviceName: null,
        ),
      );

      return;
    }

    // Bluetooth has been powered on again.
    try {
      final pairedDevices = await _repository.getPairedDevices();

      emit(state.copyWith(isBluetoothOn: true, pairedDevices: pairedDevices));

      await _repository.startDiscovery();
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to restart Bluetooth discovery after power on: $e',
        stack: stackTrace,
      );
    }
  }

  void _onDiscoverableChanged(
    BluetoothDiscoverableChanged event,
    Emitter<BluetoothState> emit,
  ) {
    emit(state.copyWith(isDiscoverable: event.isDiscoverable));
  }

  // Updates scanning indicator shown in the UI.
  void _onScanningChanged(
    BluetoothScanningChanged event,
    Emitter<BluetoothState> emit,
  ) {
    emit(state.copyWith(isScanning: event.isScanning));
  }

  /// Handles device list updates received from BlueZ.
  ///
  /// Separates devices into:
  /// - Paired devices
  /// - Discovered devices
  ///
  /// Removes loading state once BlueZ reports the device as connected.
  void _onDevicesChanged(
    BluetoothDevicesUpdated event,
    Emitter<BluetoothState> emit,
  ) {
    final paired = event.devices.where((device) => device.isSaved).map((
      device,
    ) {
      final connected = device.isConnected;

      return device.copyWith(
        isConnecting:
            state.connectingDevices.contains(device.macAddress) && !connected,
      );
    }).toList();

    final discovered = event.devices.where((device) => !device.isSaved).map((
      device,
    ) {
      return device.copyWith(
        isConnecting: state.connectingDevices.contains(device.macAddress),
      );
    }).toList();

    final connectedMacs = paired
        .where((device) => device.isConnected)
        .map((device) => device.macAddress)
        .toSet();

    final updatedConnecting = {...state.connectingDevices}
      ..removeWhere(connectedMacs.contains);

    String? connectedName;

    for (final device in paired) {
      if (device.isConnected) {
        connectedName = device.name;
        break;
      }
    }

    emit(
      state.copyWith(
        pairedDevices: paired,
        discoveredDevices: discovered,
        connectedDeviceName: connectedName,
        connectingDevices: updatedConnecting,
      ),
    );
  }

  Future<void> _onStopBluetoothDiscovery(
    StopBluetoothDiscovery event,
    Emitter<BluetoothState> emit,
  ) async {
    try {
      await _repository.stopDiscovery();
    } catch (e, stackTrace) {
      AppLogger.e('Failed to stop bluetooth discovery: $e', stack: stackTrace);
    }
  }

  /// Releases stream subscriptions, timers, and Bluetooth resources.
  @override
  Future<void> close() async {
    await _powerSub?.cancel();
    await _scanningSub?.cancel();
    await _discoverableSub?.cancel();
    await _devicesSub?.cancel();

    await _repository.close();

    return super.close();
  }
}

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/utils/app_logger.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_event.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_state.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/data/repositories/wireless_repository.dart';
import 'package:nm/nm.dart';

export 'wireless_event.dart';
export 'wireless_state.dart';

/// BLoC responsible for managing the Wi-Fi connectivity state, network scanning,
/// and profile configurations (IP, DNS settings) in the application.
class WirelessBloc extends Bloc<WirelessEvent, WirelessState> {
  final WirelessRepository wirelessRepository;

  // Subscriptions to track NetworkManager status changes reactively.
  StreamSubscription? _wifiEventsSub;
  StreamSubscription? _deviceEventsSub;
  StreamSubscription? _wirelessEventsSub;

  bool _reloadScheduled = false;
  bool _isLoading = false;
  Timer? _refreshTimer;
  Timer? _scanTimer;
  bool _connectionInProgress = false;
  DateTime? _connectionStartTime;

  WirelessBloc({required this.wirelessRepository})
    : super(const WirelessState()) {
    on<InitWifi>(_onInit);
    on<LoadWireless>(_onLoadWireless);
    on<ToggleWirelessPower>(_onToggleWirelessPower);
    on<ScanNetworks>(_onScanNetworks);
    on<ConnectToNetworkEvent>(_onConnectToNetwork);
    on<AddNetworkEvent>(_onAddNetwork);
    on<UpdateNetworkSettingsEvent>(_onUpdateNetworkSettings);
    on<UpdateIPSettingsEvent>(_onUpdateIPSettings);
    on<UpdateDNSSettingsEvent>(_onUpdateDNSSettings);
    on<ForgetNetworkEvent>(_onForgetNetwork);
  }

  /// Initial setup: listens to D-Bus events and triggers an initial loading of networks.
  Future<void> _onInit(InitWifi event, Emitter<WirelessState> emit) async {
    try {
      await wirelessRepository.init().then((_) {
        final enabled = wirelessRepository.isWirelessEnabled();
        emit(state.copyWith(isWirelessOn: enabled));
      });
      await _subscribeToStreams();
      add(const LoadWireless());
      await wirelessRepository.requestScan();
      _startPeriodicScan();
    } catch (e, stack) {
      AppLogger.e('Failed to initialize Wi-Fi: $e', stack: stack);
    }
  }

  /// Subscribes to D-Bus event streams for reactive UI updates when settings,
  /// connectivity, or available access points change.
  Future<void> _subscribeToStreams() async {
    await _unsubscribeFromStreams();

    try {
      final wifiEventsStream = wirelessRepository.getWifiEventsStream();
      final deviceEventsStream = wirelessRepository.getDeviceEventsStream();
      final wirelessEventsStream = wirelessRepository
          .getWirelessDeviceEventsStream();

      // Listen to global NetworkManager client property changes
      _wifiEventsSub = wifiEventsStream.listen((events) async {
        if (events.contains('State') ||
            events.contains('Connectivity') ||
            events.contains('ActiveConnections') ||
            events.contains('WirelessEnabled') ||
            events.contains('WirelessHardwareEnabled')) {
          await _scheduleWirelessRefresh();
        }
      });

      // Listen to specific Wi-Fi device property changes (e.g., state transitions)
      _deviceEventsSub = deviceEventsStream.listen((events) async {
        await _scheduleWirelessRefresh();
      });

      // Listen to Wi-Fi wireless capabilities changes (e.g., scanned access points list)
      _wirelessEventsSub = wirelessEventsStream.listen((events) async {
        if (events.contains('AccessPoints') ||
            events.contains('ActiveAccessPoint')) {
          await _scheduleWirelessRefresh();
        }
      });
    } catch (e, stack) {
      AppLogger.e('Failed to subscribe to wireless streams: $e', stack: stack);
    }
  }

  /// Reloads the wireless network lists from NetworkManager, ensuring that we
  /// ignore intermediate states to prevent interference (e.g. dismissing password dialogs).
  Future<void> _scheduleWirelessRefresh() async {
    _refreshTimer?.cancel();

    _refreshTimer = Timer(const Duration(milliseconds: 250), () async {
      try {
        if (isClosed) return;

        final deviceState = wirelessRepository.getWifiDeviceState();

        final elapsed = _connectionStartTime != null
            ? DateTime.now().difference(_connectionStartTime!)
            : Duration.zero;
        final bool isTransientStart =
            _connectionInProgress && elapsed.inSeconds < 3;

        // Ignore transient states while authentication is happening or connection is just starting.
        if (isTransientStart ||
            (_connectionInProgress &&
                const {
                  NetworkManagerDeviceState.needAuth,
                  NetworkManagerDeviceState.prepare,
                  NetworkManagerDeviceState.config,
                  NetworkManagerDeviceState.ipConfig,
                  NetworkManagerDeviceState.ipCheck,
                  NetworkManagerDeviceState.secondaries,
                }.contains(deviceState))) {
          return;
        }

        if (_connectionInProgress &&
            !isTransientStart &&
            const {
              NetworkManagerDeviceState.activated,
              NetworkManagerDeviceState.failed,
              NetworkManagerDeviceState.disconnected,
            }.contains(deviceState)) {
          _connectionInProgress = false;
        }

        add(const LoadWireless(requestScan: false));
      } catch (e, stackTrace) {
        AppLogger.e('Failed to refresh wireless state: $e', stack: stackTrace);
      }
    });
  }

  /// Cleans up active stream subscriptions to prevent resource leaks.
  Future<void> _unsubscribeFromStreams() async {
    try {
      await _wifiEventsSub?.cancel();
      _wifiEventsSub = null;

      await _deviceEventsSub?.cancel();
      _deviceEventsSub = null;

      await _wirelessEventsSub?.cancel();
      _wirelessEventsSub = null;
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to unsubscribe from wireless streams: $e',
        stack: stackTrace,
      );
    }
  }

  /// Reloads saved and available networks, identifies the currently connected network,
  /// and updates connection status.
  Future<void> _onLoadWireless(
    LoadWireless event,
    Emitter<WirelessState> emit,
  ) async {
    if (_isLoading) {
      _reloadScheduled = true;
      return;
    }
    _isLoading = true;
    _reloadScheduled = false;

    try {
      final isEnabled = wirelessRepository.isWirelessEnabled();
      if (!isEnabled) {
        emit(
          state.copyWith(
            isWirelessOn: false,
            isScanning: false,
            savedNetworks: [],
            myNetworks: [],
            availableNetworks: [],
            connectedNetworkName: null,
            connectingNetworkName: null,
          ),
        );
        return;
      }

      if (_wifiEventsSub == null) {
        await _subscribeToStreams();
      }

      final savedNetworks = await wirelessRepository.getSavedNetworks();
      final myNetworks = await wirelessRepository.getMyNetworks();

      final deviceState = wirelessRepository.getWifiDeviceState();

      // Request a Wi-Fi scan only when explicitly needed and the device is not
      // in the middle of establishing a connection.
      final shouldScan =
          event.requestScan &&
          !_connectionInProgress &&
          deviceState != NetworkManagerDeviceState.prepare &&
          deviceState != NetworkManagerDeviceState.config &&
          deviceState != NetworkManagerDeviceState.needAuth &&
          deviceState != NetworkManagerDeviceState.ipConfig &&
          deviceState != NetworkManagerDeviceState.ipCheck;

      final availNets = await wirelessRepository.getAvailableNetworks(
        requestScan: shouldScan,
        savedNetworks: savedNetworks,
      );

      String? connectedName;

      for (final network in myNetworks) {
        if (network.isConnected) {
          connectedName = network.name;
        }
      }

      for (final network in availNets) {
        if (network.isConnected) {
          connectedName = network.name;
        }
      }

      String? connectingName = state.connectingNetworkName;
      WirelessFailure? failure = state.error;

      // Clear the pending connection on success, or report an error if the
      // connection attempt failed or was terminated.
      if (connectingName != null) {
        if (deviceState == NetworkManagerDeviceState.activated &&
            connectedName == connectingName) {
          connectingName = null;
          failure = null;
        } else if (deviceState == NetworkManagerDeviceState.failed ||
            deviceState == NetworkManagerDeviceState.disconnected ||
            deviceState == NetworkManagerDeviceState.deactivating) {
          failure = WirelessFailure(
            type: WirelessErrorType.connectionFailed,
            message: 'Failed to connect to $connectingName',
            data: {'networkName': connectingName},
          );
          connectingName = null;
        }
      }

      final newState = state.copyWith(
        isWirelessOn: true,
        savedNetworks: savedNetworks,
        myNetworks: myNetworks,
        availableNetworks: availNets,
        connectedNetworkName: connectedName,
        connectingNetworkName: connectingName,
        error: failure,
      );

      if (newState != state) {
        emit(newState);
      }
    } catch (e, stackTrace) {
      AppLogger.e('Failed to load wireless networks: $e', stack: stackTrace);
    } finally {
      _isLoading = false;
      if (!isClosed && _reloadScheduled) {
        _reloadScheduled = false;
        add(const LoadWireless(requestScan: false));
      }
    }
  }

  /// Toggles the hardware/software Wi-Fi power state via NetworkManager.
  Future<void> _onToggleWirelessPower(
    ToggleWirelessPower event,
    Emitter<WirelessState> emit,
  ) async {
    try {
      if (event.isEnabled) {
        emit(
          state.copyWith(
            isWirelessOn: true,
            isScanning: true,
            connectingNetworkName: null,
          ),
        );
        await wirelessRepository.setWifiEnabled(true);

        await _subscribeToStreams();
        // add(const LoadWireless(requestScan: true));
        add(const ScanNetworks());
        _startPeriodicScan();
      } else {
        _stopPeriodicScan();
        await wirelessRepository.setWifiEnabled(false);
        await _unsubscribeFromStreams();
        emit(
          state.copyWith(
            isWirelessOn: false,
            isScanning: false,
            connectingNetworkName: null,
            connectedNetworkName: null,
            savedNetworks: [],
            myNetworks: [],
            availableNetworks: [],
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.e('Failed to toggle wireless: $e', stack: stackTrace);
    }
  }

  /// Manages network scanning state timeout.
  Future<void> _onScanNetworks(
    ScanNetworks event,
    Emitter<WirelessState> emit,
  ) async {
    try {
      if (!state.isWirelessOn) return;

      emit(state.copyWith(isScanning: true));
      await wirelessRepository.requestScan();

      await Future.delayed(const Duration(seconds: 2));

      if (!isClosed && state.isWirelessOn) {
        emit(state.copyWith(isScanning: false));
      }
    } catch (e, stackTrace) {
      AppLogger.e('Failed to scan wireless networks: $e', stack: stackTrace);
      if (!isClosed) {
        emit(state.copyWith(isScanning: false));
      }
    }
  }

  /// Initiates a connection request to the designated Wi-Fi network.
  Future<void> _onConnectToNetwork(
    ConnectToNetworkEvent event,
    Emitter<WirelessState> emit,
  ) async {
    try {
      _connectionInProgress = true;
      _connectionStartTime = DateTime.now();
      emit(state.copyWith(connectingNetworkName: event.name, error: null));

      await wirelessRepository.connectToNetwork(
        event.name,
        event.password,
        enterpriseConfig: event.enterpriseConfig,
      );
    } catch (e, stackTrace) {
      _connectionInProgress = false;
      _connectionStartTime = null;
      emit(
        state.copyWith(
          connectingNetworkName: null,
          error: WirelessFailure(
            type: WirelessErrorType.connectionFailed,
            message: e.toString(),
            data: {'networkName': event.name},
          ),
        ),
      );
      AppLogger.e("Failed to connect", stack: stackTrace);
    }
  }

  /// Adds a new network profile to NetworkManager connection settings.
  Future<void> _onAddNetwork(
    AddNetworkEvent event,
    Emitter<WirelessState> emit,
  ) async {
    try {
      _connectionInProgress = true;
      _connectionStartTime = DateTime.now();
      emit(state.copyWith(connectingNetworkName: event.name, error: null));

      await wirelessRepository.addNetwork(
        event.name,
        event.security,
        event.enterpriseConfig,
      );

      final savedNetworks = await wirelessRepository.getSavedNetworks();
      final myNetworks = await wirelessRepository.getMyNetworks(
        savedNetworks: savedNetworks,
      );
      final availableNetworks = await wirelessRepository.getAvailableNetworks(
        savedNetworks: savedNetworks,
      );

      emit(
        state.copyWith(
          savedNetworks: savedNetworks,
          myNetworks: myNetworks,
          availableNetworks: availableNetworks,
        ),
      );
    } catch (e, stackTrace) {
      _connectionInProgress = false;
      _connectionStartTime = null;
      emit(
        state.copyWith(
          connectingNetworkName: null,
          error: WirelessFailure(
            type: WirelessErrorType.addNetworkFailed,
            message: e.toString(),
            data: {'networkName': event.name},
          ),
        ),
      );
      AppLogger.e('Failed to add network: $e', stack: stackTrace);
    }
  }

  /// Updates connection parameters (e.g. autoconnect / low data mode).
  Future<void> _onUpdateNetworkSettings(
    UpdateNetworkSettingsEvent event,
    Emitter<WirelessState> emit,
  ) async {
    try {
      await wirelessRepository.updateNetwork(event.network);
      final savedNetworks = await wirelessRepository.getSavedNetworks();
      final myNetworks = await wirelessRepository.getMyNetworks(
        savedNetworks: savedNetworks,
      );
      final availableNetworks = await wirelessRepository.getAvailableNetworks(
        savedNetworks: savedNetworks,
      );

      emit(
        state.copyWith(
          savedNetworks: savedNetworks,
          myNetworks: myNetworks,
          availableNetworks: availableNetworks,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.e('Failed to update network settings: $e', stack: stackTrace);
    }
  }

  /// Updates connection static/dynamic IP Address settings.
  Future<void> _onUpdateIPSettings(
    UpdateIPSettingsEvent event,
    Emitter<WirelessState> emit,
  ) async {
    try {
      await wirelessRepository.updateIPSettings(
        event.network,
        event.ipConfigType,
        event.ipAddress,
        event.subnetMask,
        event.router,
      );

      final savedNetworks = await wirelessRepository.getSavedNetworks();
      final myNetworks = await wirelessRepository.getMyNetworks(
        savedNetworks: savedNetworks,
      );
      final availableNetworks = await wirelessRepository.getAvailableNetworks(
        savedNetworks: savedNetworks,
      );

      emit(
        state.copyWith(
          savedNetworks: savedNetworks,
          myNetworks: myNetworks,
          availableNetworks: availableNetworks,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.e('Failed to update IP settings: $e', stack: stackTrace);
    }
  }

  /// Updates connection DNS configuration.
  Future<void> _onUpdateDNSSettings(
    UpdateDNSSettingsEvent event,
    Emitter<WirelessState> emit,
  ) async {
    try {
      await wirelessRepository.updateDNSSettings(
        event.network,
        event.dnsConfigType,
        event.dnsServers,
        event.dnsSearchDomains,
      );

      final savedNetworks = await wirelessRepository.getSavedNetworks();
      final myNetworks = await wirelessRepository.getMyNetworks(
        savedNetworks: savedNetworks,
      );
      final availableNetworks = await wirelessRepository.getAvailableNetworks(
        savedNetworks: savedNetworks,
      );

      emit(
        state.copyWith(
          savedNetworks: savedNetworks,
          myNetworks: myNetworks,
          availableNetworks: availableNetworks,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.e('Failed to update DNS settings: $e', stack: stackTrace);
    }
  }

  /// Deletes a saved network profile from NetworkManager connection settings.
  Future<void> _onForgetNetwork(
    ForgetNetworkEvent event,
    Emitter<WirelessState> emit,
  ) async {
    try {
      await wirelessRepository.forgetNetwork(event.network);
      final savedNetworks = await wirelessRepository.getSavedNetworks();
      final myNetworks = await wirelessRepository.getMyNetworks(
        savedNetworks: savedNetworks,
      );
      final availableNetworks = await wirelessRepository.getAvailableNetworks(
        savedNetworks: savedNetworks,
      );

      emit(
        state.copyWith(
          savedNetworks: savedNetworks,
          myNetworks: myNetworks,
          availableNetworks: availableNetworks,
          connectedNetworkName: state.connectedNetworkName == event.network.name
              ? null
              : state.connectedNetworkName,
          connectingNetworkName:
              state.connectingNetworkName == event.network.name
              ? null
              : state.connectingNetworkName,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.e('Failed to forget network: $e', stack: stackTrace);
    }
  }

  /// Starts periodic Wi-Fi scanning every 10 seconds.
  void _startPeriodicScan() {
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (isClosed) return;
      if (!wirelessRepository.isWirelessEnabled()) return;

      add(const ScanNetworks());
    });
  }

  /// Stops periodic Wi-Fi scanning.
  void _stopPeriodicScan() {
    _scanTimer?.cancel();
    _scanTimer = null;
  }

  @override
  Future<void> close() async {
    try {
      _refreshTimer?.cancel();
      _stopPeriodicScan();

      await _unsubscribeFromStreams();
    } catch (e, stackTrace) {
      AppLogger.e('Failed to close WirelessBloc: $e', stack: stackTrace);
    } finally {
      await super.close();
    }
  }
}

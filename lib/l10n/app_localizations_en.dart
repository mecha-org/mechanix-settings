// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get wireless => 'Wireless';

  @override
  String get cellularData => 'Cellular data (LTE)';

  @override
  String get bluetooth => 'Bluetooth';

  @override
  String get display => 'Display';

  @override
  String get sound => 'Sound';

  @override
  String get system => 'System';

  @override
  String get timeAndDate => 'Time & Date';

  @override
  String get language => 'Language';

  @override
  String get battery => 'Battery';

  @override
  String get about => 'About';

  @override
  String get addWireless => 'Add wireless';

  @override
  String get manageWireless => 'Manage wireless';

  @override
  String get onToggle => 'ON';

  @override
  String get offToggle => 'OFF';

  @override
  String get myNetworks => 'My networks';

  @override
  String get avaialableNetworks => 'Available networks';

  @override
  String joinNetwork(String networkName) {
    return 'Join $networkName';
  }

  @override
  String get hintName => 'Name';

  @override
  String get aboutNetwork => 'About the network';

  @override
  String get privateWirelessAddress => 'Private Wireless address';

  @override
  String get wirelessAddress => 'Wireless address';

  @override
  String get autoJoin => 'Auto join';

  @override
  String get password => 'Password';

  @override
  String get lowDataMode => 'Low Data mode';

  @override
  String get ipv4Address => 'IPv4 Address';

  @override
  String get configureIp => 'Configure IP';

  @override
  String get dns => 'DNS';

  @override
  String get configureDns => 'Configure DNS';

  @override
  String get automatic => 'Automatic';

  @override
  String get automaticDhcp => 'Automatic (DHCP)';

  @override
  String get manual => 'Manual';

  @override
  String get manualIp => 'Manual IP';

  @override
  String get none => 'None';

  @override
  String get staticTitle => 'Static';

  @override
  String get staticOption => 'Static';

  @override
  String get rotating => 'Rotating';

  @override
  String get ipAddressLabel => 'IP Address';

  @override
  String get ipAddressSettingsLabel => 'IP Settings';

  @override
  String get subnetMaskLabel => 'Subnet Mask';

  @override
  String get gatewayLabel => 'Gateway';

  @override
  String get routerLabel => 'Router';

  @override
  String get dnsServerLabel => 'DNS Server';

  @override
  String get serversLabel => 'Servers';

  @override
  String get off => 'Off';

  @override
  String get enterPassword => 'Enter password';

  @override
  String get eapMethod => 'Authentication';

  @override
  String get phase2Authentication => 'Inner authentication';

  @override
  String get identity => 'Identity';

  @override
  String get certificate => 'Certificate';

  @override
  String get caCertificate => 'CA certificate';

  @override
  String get caCertificatePassword => 'CA certificate password';

  @override
  String get noCaCertificate => 'No CA certificate is required';

  @override
  String get userCertificate => 'User certificate';

  @override
  String get userCertificatePassword => 'User certificate password';

  @override
  String get privateKey => 'User private key';

  @override
  String get privateKeyPassword => 'User key password';

  @override
  String get selectFromFile => 'Select from file';

  @override
  String get networkName => 'Network name';

  @override
  String get security => 'Security';

  @override
  String get wep => 'WEP';

  @override
  String get wpaPersonal => 'WPA Personal';

  @override
  String get wpa2Personal => 'WPA & WPA2 Personal';

  @override
  String get wpa3Personal => 'WPA3 Personal';

  @override
  String get wpaEnterprise => 'WPA & WPA2 Enterprise';

  @override
  String get leap => 'LEAP';

  @override
  String get enhancedOpen => 'Enhanced Open';

  @override
  String get peap => 'PEAP';

  @override
  String get tls => 'TLS';

  @override
  String get ttls => 'TTLS';

  @override
  String get pwd => 'PWD';

  @override
  String get version0 => 'Version 0';

  @override
  String get version1 => 'Version 1';

  @override
  String get pap => 'PAP';

  @override
  String get chap => 'CHAP';

  @override
  String get mschap => 'MSCHAP';

  @override
  String get mschapv2 => 'MSCHAPv2';

  @override
  String get mschapv2NoEap => 'MSCHAPv2 (No EAP)';

  @override
  String get md5 => 'MD5';

  @override
  String get gtc => 'GTC';

  @override
  String get peapVersion => 'PEAP Version';

  @override
  String get anonymousIdentity => 'Anonymous Identity';

  @override
  String get domain => 'Domain';

  @override
  String get fixed => 'Fixed';

  @override
  String get randomized => 'Randomized';

  @override
  String get connect => 'Connect';

  @override
  String get forget => 'Forget';

  @override
  String get noSavedNetwork => 'No saved networks';

  @override
  String get dnsServers => 'DNS Servers';

  @override
  String get searchDomains => 'Search Domains';

  @override
  String get addServer => 'Add Server';

  @override
  String get addDomainsHintText => 'domain.com';

  @override
  String get invalidIpAddress => 'Enter a valid IPv4 address.';

  @override
  String get unspecifiedIpAddress => '0.0.0.0 is not a valid host IP address.';

  @override
  String get loopbackIpAddress =>
      'Loopback addresses (127.x.x.x) cannot be used.';

  @override
  String get multicastIpAddress =>
      'Multicast addresses cannot be assigned to a host.';

  @override
  String get invalidSubnetMask => 'Enter a valid subnet mask.';

  @override
  String get invalidSubnetPrefix => 'Enter a valid subnet prefix.';

  @override
  String get invalidSubnetPrefixRange =>
      'Subnet prefix must be between 1 and 30.';

  @override
  String get networkAddressNotAllowed =>
      'The IP address cannot be the network address.';

  @override
  String get broadcastAddressNotAllowed =>
      'The IP address cannot be the broadcast address.';

  @override
  String get invalidGateway => 'Enter a valid gateway address.';

  @override
  String get gatewayDifferentSubnet =>
      'The gateway must be in the same subnet as the IP address.';

  @override
  String get gatewaySameAsIp =>
      'The gateway cannot be the same as the IP address.';

  @override
  String get myDevices => 'My devices';

  @override
  String get otherDevices => 'Other devices';

  @override
  String get deviceName => 'Device name';

  @override
  String get deviceType => 'Device type';

  @override
  String get deviceStatus => 'Device status';

  @override
  String get connected => 'Connected';

  @override
  String get notConnected => 'Not connected';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get forgetDevice => 'Forget Device';

  @override
  String get connectionRequest => 'Connection request';

  @override
  String get enterCodeToConnect => 'Enter code to connect to';

  @override
  String get connectionCode => 'Connection code';

  @override
  String get mobileType => 'Mobile';

  @override
  String get speakerType => 'Speaker';

  @override
  String get unknownType => 'Unknown';

  @override
  String get car => 'Car';

  @override
  String get headphones => 'Headphones';

  @override
  String get computer => 'Computer';

  @override
  String get tv => 'TV';

  @override
  String get cancel => 'Cancel';

  @override
  String get pair => 'Pair';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get networkNameRequired => 'Network name is required';

  @override
  String get identityRequired => 'Identity is required';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get domainRequired => 'Domain is required';

  @override
  String get caCertificateRequired => 'CA certificate is required';

  @override
  String get userCertificateRequired => 'User certificate is required';

  @override
  String get privateKeyRequired => 'Private key is required';

  @override
  String get invalidDomain => 'Enter a valid domain name';

  @override
  String get connectionFailed => 'Failed to connect to network';

  @override
  String connectionFailedWithNetwork(String networkName) {
    return 'Failed to connect to $networkName';
  }

  @override
  String get addNetworkFailed => 'Failed to add network';

  @override
  String addNetworkFailedWithNetwork(String networkName) {
    return 'Failed to add network $networkName';
  }

  @override
  String get discoverable => 'Discoverable';

  @override
  String get bluetoothConnectionFailed =>
      'Failed to connect to Bluetooth device';

  @override
  String bluetoothConnectionFailedWithName(String deviceName) {
    return 'Failed to connect to $deviceName';
  }

  @override
  String get bluetoothPairingFailed => 'Failed to pair with Bluetooth device';

  @override
  String bluetoothPairingFailedWithName(String deviceName) {
    return 'Failed to pair with $deviceName';
  }

  @override
  String get deviceNameLimit => 'Device name cannot exceed 30 characters';

  @override
  String get unknownError => 'An unknown error occurred';
}

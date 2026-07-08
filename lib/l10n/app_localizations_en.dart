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
  String get limitIpAddressTracking => 'Limit IP Address Tracking';

  @override
  String get ipv4Address => 'IPv4 Address';

  @override
  String get configureIp => 'Configure IP';

  @override
  String get dns => 'DNS';

  @override
  String get configureDns => 'Configure DNS';

  @override
  String get httpProxy => 'HTTP Proxy';

  @override
  String get configureProxy => 'Configure Proxy';

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
  String get security => 'Security';

  @override
  String get securityNone => 'None';

  @override
  String get securityWpa2Wpa3 => 'WPA2 / WPA3';

  @override
  String get securityWpa3 => 'WPA3';

  @override
  String get securityWpa => 'WPA';

  @override
  String get securityWpa2Enterprise => 'WPA2 Enterprise';

  @override
  String get securityWep => 'WEP';

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
  String get proxyUrl => 'URL';

  @override
  String get proxyEnterUrl => 'Enter url';

  @override
  String get proxyServer => 'Server';

  @override
  String get proxyEnterServer => 'Enter server';

  @override
  String get proxyPort => 'Port';

  @override
  String get proxyEnterPort => 'Enter port';

  @override
  String get proxyAuthentication => 'Authentication';

  @override
  String get proxyUsername => 'Username';

  @override
  String get proxyPassword => 'Password';

  @override
  String get dnsServers => 'DNS Servers';

  @override
  String get searchDomains => 'Search Domains';

  @override
  String get addServer => 'Add Server';

  @override
  String get addDomainsHintText => 'domain.com';

  @override
  String get autoTime => 'Auto time';

  @override
  String get timezone => 'Timezone';

  @override
  String get setTime => 'Set time';

  @override
  String get setDate => 'Set date';

  @override
  String get timeFormat => 'Time Format';

  @override
  String get dateFormat => 'Date Format';

  @override
  String get format12Hour => '12 hour clock';

  @override
  String get format24Hour => '24 hour clock';

  @override
  String get timezoneGmt => 'GMT (UTC 0)';

  @override
  String get timezoneIst => 'IST (UTC +5:30)';

  @override
  String get timezoneHst => 'HST (UTC -10)';

  @override
  String get timezoneAkst => 'AKST (UTC -9)';

  @override
  String get timezonePst => 'PST (UTC -8)';

  @override
  String get timezoneMst => 'MST (UTC -7)';

  @override
  String get timezoneCstMinus6 => 'CST (UTC -6)';

  @override
  String get timezoneEst => 'EST (UTC -5)';

  @override
  String get timezoneAst => 'AST (UTC -4)';

  @override
  String get timezoneBrt => 'BRT (UTC -3)';

  @override
  String get timezoneCet => 'CET (UTC +1)';

  @override
  String get timezoneEet => 'EET (UTC +2)';

  @override
  String get timezoneGst => 'GST (UTC +4)';

  @override
  String get timezoneIct => 'ICT (UTC +7)';

  @override
  String get timezoneCstPlus8 => 'CST (UTC +8)';

  @override
  String get timezoneJst => 'JST (UTC +9)';

  @override
  String get timezoneAest => 'AEST (UTC +10)';

  @override
  String get timezoneNzst => 'NZST (UTC +12)';

  @override
  String get dateFormatDmy => 'dd/MM/yyyy';

  @override
  String get dateFormatMdy => 'MM/dd/yy';

  @override
  String get dateFormatYmd => 'yyyy-MM-dd';

  @override
  String get dateFormatDmyShort => 'dd MMM yyyy';

  @override
  String get dateFormatDmyLong => 'dd MMMM yyyy';

  @override
  String get am => 'AM';

  @override
  String get pm => 'PM';
}

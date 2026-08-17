import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @wireless.
  ///
  /// In en, this message translates to:
  /// **'Wireless'**
  String get wireless;

  /// No description provided for @cellularData.
  ///
  /// In en, this message translates to:
  /// **'Cellular data (LTE)'**
  String get cellularData;

  /// No description provided for @bluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth'**
  String get bluetooth;

  /// No description provided for @display.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get display;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @timeAndDate.
  ///
  /// In en, this message translates to:
  /// **'Time & Date'**
  String get timeAndDate;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @battery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get battery;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @addWireless.
  ///
  /// In en, this message translates to:
  /// **'Add wireless'**
  String get addWireless;

  /// No description provided for @manageWireless.
  ///
  /// In en, this message translates to:
  /// **'Manage wireless'**
  String get manageWireless;

  /// No description provided for @onToggle.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get onToggle;

  /// No description provided for @offToggle.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get offToggle;

  /// No description provided for @myNetworks.
  ///
  /// In en, this message translates to:
  /// **'My networks'**
  String get myNetworks;

  /// No description provided for @avaialableNetworks.
  ///
  /// In en, this message translates to:
  /// **'Available networks'**
  String get avaialableNetworks;

  /// No description provided for @joinNetwork.
  ///
  /// In en, this message translates to:
  /// **'Join {networkName}'**
  String joinNetwork(String networkName);

  /// No description provided for @hintName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get hintName;

  /// No description provided for @aboutNetwork.
  ///
  /// In en, this message translates to:
  /// **'About the network'**
  String get aboutNetwork;

  /// No description provided for @privateWirelessAddress.
  ///
  /// In en, this message translates to:
  /// **'Private Wireless address'**
  String get privateWirelessAddress;

  /// No description provided for @wirelessAddress.
  ///
  /// In en, this message translates to:
  /// **'Wireless address'**
  String get wirelessAddress;

  /// No description provided for @signalStrength.
  ///
  /// In en, this message translates to:
  /// **'Signal strength'**
  String get signalStrength;

  /// Wi-Fi signal strength as a percentage
  ///
  /// In en, this message translates to:
  /// **'{strength}%'**
  String wifiSignalStrength(int strength);

  /// Wi-Fi signal strength percentage with dBm
  ///
  /// In en, this message translates to:
  /// **'{strength}% ({dbm} dBm)'**
  String wifiSignalStrengthWithDbm(int strength, int dbm);

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// Wi-Fi link speed
  ///
  /// In en, this message translates to:
  /// **'{speed} Mb/s'**
  String wifiSpeed(int speed);

  /// No description provided for @wifiSpeedWithBand.
  ///
  /// In en, this message translates to:
  /// **'{speed} Mb/s ({band})'**
  String wifiSpeedWithBand(int speed, String band);

  /// Wi-Fi frequency displayed in GHz
  ///
  /// In en, this message translates to:
  /// **'{frequency} GHz'**
  String wifiFrequencyGHz(String frequency);

  /// Wi-Fi frequency displayed in MHz
  ///
  /// In en, this message translates to:
  /// **'{frequency} MHz'**
  String wifiFrequencyMHz(int frequency);

  /// No description provided for @autoJoin.
  ///
  /// In en, this message translates to:
  /// **'Auto join'**
  String get autoJoin;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @lowDataMode.
  ///
  /// In en, this message translates to:
  /// **'Low Data mode'**
  String get lowDataMode;

  /// No description provided for @ipv4Address.
  ///
  /// In en, this message translates to:
  /// **'IPv4 Address'**
  String get ipv4Address;

  /// No description provided for @configureIp.
  ///
  /// In en, this message translates to:
  /// **'Configure IP'**
  String get configureIp;

  /// No description provided for @dns.
  ///
  /// In en, this message translates to:
  /// **'DNS'**
  String get dns;

  /// No description provided for @configureDns.
  ///
  /// In en, this message translates to:
  /// **'Configure DNS'**
  String get configureDns;

  /// No description provided for @automatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get automatic;

  /// No description provided for @automaticDhcp.
  ///
  /// In en, this message translates to:
  /// **'Automatic (DHCP)'**
  String get automaticDhcp;

  /// No description provided for @manual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manual;

  /// No description provided for @manualIp.
  ///
  /// In en, this message translates to:
  /// **'Manual IP'**
  String get manualIp;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @staticTitle.
  ///
  /// In en, this message translates to:
  /// **'Static'**
  String get staticTitle;

  /// No description provided for @staticOption.
  ///
  /// In en, this message translates to:
  /// **'Static'**
  String get staticOption;

  /// No description provided for @rotating.
  ///
  /// In en, this message translates to:
  /// **'Rotating'**
  String get rotating;

  /// No description provided for @ipAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'IP Address'**
  String get ipAddressLabel;

  /// No description provided for @ipAddressSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'IP Settings'**
  String get ipAddressSettingsLabel;

  /// No description provided for @subnetMaskLabel.
  ///
  /// In en, this message translates to:
  /// **'Subnet Mask'**
  String get subnetMaskLabel;

  /// No description provided for @gatewayLabel.
  ///
  /// In en, this message translates to:
  /// **'Gateway'**
  String get gatewayLabel;

  /// No description provided for @routerLabel.
  ///
  /// In en, this message translates to:
  /// **'Router'**
  String get routerLabel;

  /// No description provided for @dnsServerLabel.
  ///
  /// In en, this message translates to:
  /// **'DNS Server'**
  String get dnsServerLabel;

  /// No description provided for @serversLabel.
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get serversLabel;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPassword;

  /// No description provided for @eapMethod.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get eapMethod;

  /// No description provided for @phase2Authentication.
  ///
  /// In en, this message translates to:
  /// **'Inner authentication'**
  String get phase2Authentication;

  /// No description provided for @identity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get identity;

  /// No description provided for @certificate.
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get certificate;

  /// No description provided for @caCertificate.
  ///
  /// In en, this message translates to:
  /// **'CA certificate'**
  String get caCertificate;

  /// No description provided for @caCertificatePassword.
  ///
  /// In en, this message translates to:
  /// **'CA certificate password'**
  String get caCertificatePassword;

  /// No description provided for @noCaCertificate.
  ///
  /// In en, this message translates to:
  /// **'No CA certificate is required'**
  String get noCaCertificate;

  /// No description provided for @userCertificate.
  ///
  /// In en, this message translates to:
  /// **'User certificate'**
  String get userCertificate;

  /// No description provided for @userCertificatePassword.
  ///
  /// In en, this message translates to:
  /// **'User certificate password'**
  String get userCertificatePassword;

  /// No description provided for @privateKey.
  ///
  /// In en, this message translates to:
  /// **'User private key'**
  String get privateKey;

  /// No description provided for @privateKeyPassword.
  ///
  /// In en, this message translates to:
  /// **'User key password'**
  String get privateKeyPassword;

  /// No description provided for @selectFromFile.
  ///
  /// In en, this message translates to:
  /// **'Select from file'**
  String get selectFromFile;

  /// No description provided for @networkName.
  ///
  /// In en, this message translates to:
  /// **'Network name'**
  String get networkName;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @wep.
  ///
  /// In en, this message translates to:
  /// **'WEP'**
  String get wep;

  /// No description provided for @wpaPersonal.
  ///
  /// In en, this message translates to:
  /// **'WPA Personal'**
  String get wpaPersonal;

  /// No description provided for @wpa2Personal.
  ///
  /// In en, this message translates to:
  /// **'WPA & WPA2 Personal'**
  String get wpa2Personal;

  /// No description provided for @wpa3Personal.
  ///
  /// In en, this message translates to:
  /// **'WPA3 Personal'**
  String get wpa3Personal;

  /// No description provided for @wpaEnterprise.
  ///
  /// In en, this message translates to:
  /// **'WPA & WPA2 Enterprise'**
  String get wpaEnterprise;

  /// No description provided for @leap.
  ///
  /// In en, this message translates to:
  /// **'LEAP'**
  String get leap;

  /// No description provided for @enhancedOpen.
  ///
  /// In en, this message translates to:
  /// **'Enhanced Open'**
  String get enhancedOpen;

  /// No description provided for @peap.
  ///
  /// In en, this message translates to:
  /// **'PEAP'**
  String get peap;

  /// No description provided for @tls.
  ///
  /// In en, this message translates to:
  /// **'TLS'**
  String get tls;

  /// No description provided for @ttls.
  ///
  /// In en, this message translates to:
  /// **'TTLS'**
  String get ttls;

  /// No description provided for @pwd.
  ///
  /// In en, this message translates to:
  /// **'PWD'**
  String get pwd;

  /// No description provided for @version0.
  ///
  /// In en, this message translates to:
  /// **'Version 0'**
  String get version0;

  /// No description provided for @version1.
  ///
  /// In en, this message translates to:
  /// **'Version 1'**
  String get version1;

  /// No description provided for @pap.
  ///
  /// In en, this message translates to:
  /// **'PAP'**
  String get pap;

  /// No description provided for @chap.
  ///
  /// In en, this message translates to:
  /// **'CHAP'**
  String get chap;

  /// No description provided for @mschap.
  ///
  /// In en, this message translates to:
  /// **'MSCHAP'**
  String get mschap;

  /// No description provided for @mschapv2.
  ///
  /// In en, this message translates to:
  /// **'MSCHAPv2'**
  String get mschapv2;

  /// No description provided for @mschapv2NoEap.
  ///
  /// In en, this message translates to:
  /// **'MSCHAPv2 (No EAP)'**
  String get mschapv2NoEap;

  /// No description provided for @md5.
  ///
  /// In en, this message translates to:
  /// **'MD5'**
  String get md5;

  /// No description provided for @gtc.
  ///
  /// In en, this message translates to:
  /// **'GTC'**
  String get gtc;

  /// No description provided for @peapVersion.
  ///
  /// In en, this message translates to:
  /// **'PEAP Version'**
  String get peapVersion;

  /// No description provided for @anonymousIdentity.
  ///
  /// In en, this message translates to:
  /// **'Anonymous Identity'**
  String get anonymousIdentity;

  /// No description provided for @domain.
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get domain;

  /// No description provided for @fixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get fixed;

  /// No description provided for @randomized.
  ///
  /// In en, this message translates to:
  /// **'Randomized'**
  String get randomized;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @forget.
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get forget;

  /// No description provided for @noSavedNetwork.
  ///
  /// In en, this message translates to:
  /// **'No saved networks'**
  String get noSavedNetwork;

  /// No description provided for @dnsServers.
  ///
  /// In en, this message translates to:
  /// **'DNS Servers'**
  String get dnsServers;

  /// No description provided for @searchDomains.
  ///
  /// In en, this message translates to:
  /// **'Search Domains'**
  String get searchDomains;

  /// No description provided for @addServer.
  ///
  /// In en, this message translates to:
  /// **'Add Server'**
  String get addServer;

  /// No description provided for @addDomainsHintText.
  ///
  /// In en, this message translates to:
  /// **'domain.com'**
  String get addDomainsHintText;

  /// Shown when the IP address format is invalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid IPv4 address.'**
  String get invalidIpAddress;

  /// No description provided for @unspecifiedIpAddress.
  ///
  /// In en, this message translates to:
  /// **'0.0.0.0 is not a valid host IP address.'**
  String get unspecifiedIpAddress;

  /// No description provided for @loopbackIpAddress.
  ///
  /// In en, this message translates to:
  /// **'Loopback addresses (127.x.x.x) cannot be used.'**
  String get loopbackIpAddress;

  /// No description provided for @multicastIpAddress.
  ///
  /// In en, this message translates to:
  /// **'Multicast addresses cannot be assigned to a host.'**
  String get multicastIpAddress;

  /// Shown when the subnet mask format is invalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid subnet mask.'**
  String get invalidSubnetMask;

  /// Shown when the subnet prefix cannot be parsed.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid subnet prefix.'**
  String get invalidSubnetPrefix;

  /// Shown when the subnet prefix is outside the supported range.
  ///
  /// In en, this message translates to:
  /// **'Subnet prefix must be between 1 and 30.'**
  String get invalidSubnetPrefixRange;

  /// Shown when the entered IP address is the network address.
  ///
  /// In en, this message translates to:
  /// **'The IP address cannot be the network address.'**
  String get networkAddressNotAllowed;

  /// Shown when the entered IP address is the broadcast address.
  ///
  /// In en, this message translates to:
  /// **'The IP address cannot be the broadcast address.'**
  String get broadcastAddressNotAllowed;

  /// Shown when the gateway format is invalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid gateway address.'**
  String get invalidGateway;

  /// Shown when the gateway is outside the subnet.
  ///
  /// In en, this message translates to:
  /// **'The gateway must be in the same subnet as the IP address.'**
  String get gatewayDifferentSubnet;

  /// Shown when the gateway equals the IP address.
  ///
  /// In en, this message translates to:
  /// **'The gateway cannot be the same as the IP address.'**
  String get gatewaySameAsIp;

  /// No description provided for @myDevices.
  ///
  /// In en, this message translates to:
  /// **'My devices'**
  String get myDevices;

  /// No description provided for @otherDevices.
  ///
  /// In en, this message translates to:
  /// **'Other devices'**
  String get otherDevices;

  /// No description provided for @deviceName.
  ///
  /// In en, this message translates to:
  /// **'Device name'**
  String get deviceName;

  /// No description provided for @deviceType.
  ///
  /// In en, this message translates to:
  /// **'Device type'**
  String get deviceType;

  /// No description provided for @deviceStatus.
  ///
  /// In en, this message translates to:
  /// **'Device status'**
  String get deviceStatus;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @forgetDevice.
  ///
  /// In en, this message translates to:
  /// **'Forget Device'**
  String get forgetDevice;

  /// No description provided for @connectionRequest.
  ///
  /// In en, this message translates to:
  /// **'Connection request'**
  String get connectionRequest;

  /// No description provided for @enterCodeToConnect.
  ///
  /// In en, this message translates to:
  /// **'Enter code to connect to'**
  String get enterCodeToConnect;

  /// No description provided for @connectionCode.
  ///
  /// In en, this message translates to:
  /// **'Connection code'**
  String get connectionCode;

  /// No description provided for @mobileType.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get mobileType;

  /// No description provided for @speakerType.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get speakerType;

  /// No description provided for @unknownType.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownType;

  /// No description provided for @car.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get car;

  /// No description provided for @headphones.
  ///
  /// In en, this message translates to:
  /// **'Headphones'**
  String get headphones;

  /// No description provided for @computer.
  ///
  /// In en, this message translates to:
  /// **'Computer'**
  String get computer;

  /// No description provided for @tv.
  ///
  /// In en, this message translates to:
  /// **'TV'**
  String get tv;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @pair.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get pair;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @networkNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Network name is required'**
  String get networkNameRequired;

  /// No description provided for @identityRequired.
  ///
  /// In en, this message translates to:
  /// **'Identity is required'**
  String get identityRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @domainRequired.
  ///
  /// In en, this message translates to:
  /// **'Domain is required'**
  String get domainRequired;

  /// No description provided for @caCertificateRequired.
  ///
  /// In en, this message translates to:
  /// **'CA certificate is required'**
  String get caCertificateRequired;

  /// No description provided for @userCertificateRequired.
  ///
  /// In en, this message translates to:
  /// **'User certificate is required'**
  String get userCertificateRequired;

  /// No description provided for @privateKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'Private key is required'**
  String get privateKeyRequired;

  /// No description provided for @invalidDomain.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid domain name'**
  String get invalidDomain;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to network'**
  String get connectionFailed;

  /// No description provided for @connectionFailedWithNetwork.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to {networkName}'**
  String connectionFailedWithNetwork(String networkName);

  /// No description provided for @addNetworkFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add network'**
  String get addNetworkFailed;

  /// No description provided for @addNetworkFailedWithNetwork.
  ///
  /// In en, this message translates to:
  /// **'Failed to add network {networkName}'**
  String addNetworkFailedWithNetwork(String networkName);

  /// No description provided for @discoverable.
  ///
  /// In en, this message translates to:
  /// **'Discoverable'**
  String get discoverable;

  /// No description provided for @bluetoothConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to Bluetooth device'**
  String get bluetoothConnectionFailed;

  /// No description provided for @bluetoothConnectionFailedWithName.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to {deviceName}'**
  String bluetoothConnectionFailedWithName(String deviceName);

  /// No description provided for @bluetoothPairingFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to pair with Bluetooth device'**
  String get bluetoothPairingFailed;

  /// No description provided for @bluetoothPairingFailedWithName.
  ///
  /// In en, this message translates to:
  /// **'Failed to pair with {deviceName}'**
  String bluetoothPairingFailedWithName(String deviceName);

  /// No description provided for @deviceNameLimit.
  ///
  /// In en, this message translates to:
  /// **'Device name cannot exceed 30 characters'**
  String get deviceNameLimit;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred'**
  String get unknownError;

  /// No description provided for @autoTime.
  ///
  /// In en, this message translates to:
  /// **'Auto time'**
  String get autoTime;

  /// No description provided for @timezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get timezone;

  /// No description provided for @setTime.
  ///
  /// In en, this message translates to:
  /// **'Set time'**
  String get setTime;

  /// No description provided for @setDate.
  ///
  /// In en, this message translates to:
  /// **'Set date'**
  String get setDate;

  /// No description provided for @timeFormat.
  ///
  /// In en, this message translates to:
  /// **'Time Format'**
  String get timeFormat;

  /// No description provided for @dateFormat.
  ///
  /// In en, this message translates to:
  /// **'Date Format'**
  String get dateFormat;

  /// No description provided for @format12Hour.
  ///
  /// In en, this message translates to:
  /// **'12 hour clock'**
  String get format12Hour;

  /// No description provided for @format24Hour.
  ///
  /// In en, this message translates to:
  /// **'24 hour clock'**
  String get format24Hour;

  /// No description provided for @timezoneGmt.
  ///
  /// In en, this message translates to:
  /// **'GMT (UTC 0)'**
  String get timezoneGmt;

  /// No description provided for @timezoneIst.
  ///
  /// In en, this message translates to:
  /// **'Kolkata (IST, UTC+5:30)'**
  String get timezoneIst;

  /// No description provided for @timezoneHst.
  ///
  /// In en, this message translates to:
  /// **'Honolulu (HST, UTC-10:00)'**
  String get timezoneHst;

  /// No description provided for @timezoneAkdt.
  ///
  /// In en, this message translates to:
  /// **'Anchorage (AKDT, UTC-08:00)'**
  String get timezoneAkdt;

  /// No description provided for @timezonePdt.
  ///
  /// In en, this message translates to:
  /// **'Los Angeles (PDT, UTC-07:00)'**
  String get timezonePdt;

  /// No description provided for @timezoneMdt.
  ///
  /// In en, this message translates to:
  /// **'Denever (MDT, UTC-06:00)'**
  String get timezoneMdt;

  /// No description provided for @timezoneCdt.
  ///
  /// In en, this message translates to:
  /// **'Chicago (CDT, UTC-05:00)'**
  String get timezoneCdt;

  /// No description provided for @timezoneEdt.
  ///
  /// In en, this message translates to:
  /// **'New York (EDT, UTC-04:00)'**
  String get timezoneEdt;

  /// No description provided for @timezoneAdt.
  ///
  /// In en, this message translates to:
  /// **'Halifax (ADT, UTC-03:00)'**
  String get timezoneAdt;

  /// No description provided for @timezoneBrt.
  ///
  /// In en, this message translates to:
  /// **'Sao Paulo (BRT, UTC-03:00)'**
  String get timezoneBrt;

  /// No description provided for @timezoneCest.
  ///
  /// In en, this message translates to:
  /// **'Paris (CEST, UTC+02:00)'**
  String get timezoneCest;

  /// No description provided for @timezoneEest.
  ///
  /// In en, this message translates to:
  /// **'Helsinki (EEST, UTC+03:00)'**
  String get timezoneEest;

  /// No description provided for @timezoneGst.
  ///
  /// In en, this message translates to:
  /// **'Dubai (GST, UTC+04:00)'**
  String get timezoneGst;

  /// No description provided for @timezoneIct.
  ///
  /// In en, this message translates to:
  /// **'Bangkok (ICT, UTC+07:00)'**
  String get timezoneIct;

  /// No description provided for @timezoneCst.
  ///
  /// In en, this message translates to:
  /// **'Shanghai (CST, UTC+08:00)'**
  String get timezoneCst;

  /// No description provided for @timezoneJst.
  ///
  /// In en, this message translates to:
  /// **'Tokyo (JST, UTC+09:00)'**
  String get timezoneJst;

  /// No description provided for @timezoneAest.
  ///
  /// In en, this message translates to:
  /// **'Sydney (AEST, UTC+10:00)'**
  String get timezoneAest;

  /// No description provided for @timezoneNzst.
  ///
  /// In en, this message translates to:
  /// **'Auckland, (NZST, UTC+12:00)'**
  String get timezoneNzst;

  /// No description provided for @dateFormatDmy.
  ///
  /// In en, this message translates to:
  /// **'dd/MM/yyyy'**
  String get dateFormatDmy;

  /// No description provided for @dateFormatMdy.
  ///
  /// In en, this message translates to:
  /// **'MM/dd/yy'**
  String get dateFormatMdy;

  /// No description provided for @dateFormatYmd.
  ///
  /// In en, this message translates to:
  /// **'yyyy-MM-dd'**
  String get dateFormatYmd;

  /// No description provided for @dateFormatDmyShort.
  ///
  /// In en, this message translates to:
  /// **'dd MMM yyyy'**
  String get dateFormatDmyShort;

  /// No description provided for @dateFormatDmyLong.
  ///
  /// In en, this message translates to:
  /// **'dd MMMM yyyy'**
  String get dateFormatDmyLong;

  /// Ante meridiem time indicator
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get am;

  /// Post meridiem time indicator
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get pm;

  /// Shown when the date and time service could not be initialized.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize date and time settings.'**
  String get failedToInitializeDateTime;

  /// Shown when updating the system time fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to update time.'**
  String get failedToUpdateTime;

  /// Shown when the current system time zone cannot be retrieved.
  ///
  /// In en, this message translates to:
  /// **'Failed to get time zone.'**
  String get failedToGetTimezone;

  /// Shown when updating the system time zone fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to update time zone.'**
  String get failedToUpdateTimezone;

  /// Shown when enabling or disabling automatic network time fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to update automatic time.'**
  String get failedToUpdateAutomaticTime;

  /// Shown when updating the clock format (12-hour/24-hour) fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to update time format.'**
  String get failedToUpdateTimeFormat;

  /// Shown when the automatic time (NTP) status could not be retrieved.
  ///
  /// In en, this message translates to:
  /// **'Failed to get automatic time status.'**
  String get failedToGetAutomaticTime;

  /// Shown when the current system time could not be retrieved.
  ///
  /// In en, this message translates to:
  /// **'Failed to get system time.'**
  String get failedToGetSystemTime;

  /// Shown when the current time format could not be retrieved.
  ///
  /// In en, this message translates to:
  /// **'Failed to get time format.'**
  String get failedToGetTimeFormat;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get somethingWentWrong;

  /// No description provided for @batterySaver.
  ///
  /// In en, this message translates to:
  /// **'Battery saver'**
  String get batterySaver;

  /// No description provided for @usage.
  ///
  /// In en, this message translates to:
  /// **'USAGE'**
  String get usage;

  /// No description provided for @untilFull.
  ///
  /// In en, this message translates to:
  /// **'until full'**
  String get untilFull;

  /// No description provided for @left.
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get left;

  /// No description provided for @batteryStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get batteryStatus;

  /// No description provided for @charging.
  ///
  /// In en, this message translates to:
  /// **'Charging'**
  String get charging;

  /// No description provided for @discharging.
  ///
  /// In en, this message translates to:
  /// **'Discharging'**
  String get discharging;

  /// No description provided for @fullCharged.
  ///
  /// In en, this message translates to:
  /// **'Fully charged'**
  String get fullCharged;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get empty;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @pendingCharge.
  ///
  /// In en, this message translates to:
  /// **'Pending charge'**
  String get pendingCharge;

  /// No description provided for @pendingDischarge.
  ///
  /// In en, this message translates to:
  /// **'Pending discharge'**
  String get pendingDischarge;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// Battery percentage display
  ///
  /// In en, this message translates to:
  /// **'{percentage}%'**
  String batteryPercentage(int percentage);

  /// No description provided for @batteryHours.
  ///
  /// In en, this message translates to:
  /// **'{count}h'**
  String batteryHours(int count);

  /// No description provided for @batteryMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count}m'**
  String batteryMinutes(int count);

  /// No description provided for @batteryTimeRemaining.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String batteryTimeRemaining(String time);

  /// No description provided for @batteryTimeUntilFull.
  ///
  /// In en, this message translates to:
  /// **'{time} until full'**
  String batteryTimeUntilFull(String time);

  /// Error message shown when the battery service fails to initialize.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize battery service.'**
  String get failedToInitializeBattery;

  /// Error message shown when battery information cannot be retrieved.
  ///
  /// In en, this message translates to:
  /// **'Failed to get battery information.'**
  String get failedToGetBatteryInfo;

  /// Error message shown when changing the battery power mode fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to update battery mode.'**
  String get failedToUpdateBatteryMode;

  /// Error message shown when the current battery power mode cannot be retrieved.
  ///
  /// In en, this message translates to:
  /// **'Failed to get battery mode.'**
  String get failedToGetBatteryMode;

  /// Error message shown when the list of supported battery power modes cannot be retrieved.
  ///
  /// In en, this message translates to:
  /// **'Failed to get available battery modes.'**
  String get failedToGetAvailableBatteryModes;

  /// Error message shown when listening for battery state changes cannot be initialized.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize battery event listener.'**
  String get failedToInitializeBatteryEvents;

  /// No description provided for @id.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get id;

  /// No description provided for @osVersion.
  ///
  /// In en, this message translates to:
  /// **'OS Version'**
  String get osVersion;

  /// No description provided for @build.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get build;

  /// No description provided for @serialNumber.
  ///
  /// In en, this message translates to:
  /// **'Serial number'**
  String get serialNumber;

  /// No description provided for @wirelessMac.
  ///
  /// In en, this message translates to:
  /// **'Wireless MAC'**
  String get wirelessMac;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @hostname.
  ///
  /// In en, this message translates to:
  /// **'Hostname'**
  String get hostname;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @manufacturer.
  ///
  /// In en, this message translates to:
  /// **'Manufacturer'**
  String get manufacturer;

  /// No description provided for @operatingSystem.
  ///
  /// In en, this message translates to:
  /// **'Operating system'**
  String get operatingSystem;

  /// No description provided for @supportUntil.
  ///
  /// In en, this message translates to:
  /// **'Support until'**
  String get supportUntil;

  /// No description provided for @kernel.
  ///
  /// In en, this message translates to:
  /// **'Kernel'**
  String get kernel;

  /// No description provided for @kernelBuild.
  ///
  /// In en, this message translates to:
  /// **'Kernel build'**
  String get kernelBuild;

  /// No description provided for @firmwareVersion.
  ///
  /// In en, this message translates to:
  /// **'Firmware version'**
  String get firmwareVersion;

  /// No description provided for @firmwareVendor.
  ///
  /// In en, this message translates to:
  /// **'Firmware vendor'**
  String get firmwareVendor;

  /// No description provided for @firmwareDate.
  ///
  /// In en, this message translates to:
  /// **'Firmware date'**
  String get firmwareDate;

  /// No description provided for @machineId.
  ///
  /// In en, this message translates to:
  /// **'Machine ID'**
  String get machineId;

  /// No description provided for @bootId.
  ///
  /// In en, this message translates to:
  /// **'Boot ID'**
  String get bootId;

  /// No description provided for @osWebsite.
  ///
  /// In en, this message translates to:
  /// **'OS website'**
  String get osWebsite;

  /// No description provided for @deviceNameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Device name cannot be empty'**
  String get deviceNameCannotBeEmpty;

  /// No description provided for @deviceNameMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Device name must be less than 64 characters'**
  String get deviceNameMaxLength;

  /// No description provided for @hostnameMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Hostname must be less than 64 characters'**
  String get hostnameMaxLength;

  /// No description provided for @hostnameDotError.
  ///
  /// In en, this message translates to:
  /// **'Hostname parts cannot start or end with a dot'**
  String get hostnameDotError;

  /// No description provided for @invalidHostname.
  ///
  /// In en, this message translates to:
  /// **'Invalid hostname'**
  String get invalidHostname;

  /// No description provided for @hostnameHyphenError.
  ///
  /// In en, this message translates to:
  /// **'Hostname parts cannot start or end with a hyphen'**
  String get hostnameHyphenError;

  /// No description provided for @hostnameCharactersError.
  ///
  /// In en, this message translates to:
  /// **'Only letters, numbers and hyphens are allowed'**
  String get hostnameCharactersError;

  /// No description provided for @failedToGetAboutDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to retrieve system information.'**
  String get failedToGetAboutDetails;

  /// No description provided for @failedToUpdateDeviceName.
  ///
  /// In en, this message translates to:
  /// **'Failed to update device name.'**
  String get failedToUpdateDeviceName;

  /// No description provided for @failedToUpdateHostname.
  ///
  /// In en, this message translates to:
  /// **'Failed to update hostname.'**
  String get failedToUpdateHostname;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

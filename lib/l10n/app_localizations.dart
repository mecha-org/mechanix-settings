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

  /// No description provided for @limitIpAddressTracking.
  ///
  /// In en, this message translates to:
  /// **'Limit IP Address Tracking'**
  String get limitIpAddressTracking;

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

  /// No description provided for @httpProxy.
  ///
  /// In en, this message translates to:
  /// **'HTTP Proxy'**
  String get httpProxy;

  /// No description provided for @configureProxy.
  ///
  /// In en, this message translates to:
  /// **'Configure Proxy'**
  String get configureProxy;

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

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @securityNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get securityNone;

  /// No description provided for @securityWpa2Wpa3.
  ///
  /// In en, this message translates to:
  /// **'WPA2 / WPA3'**
  String get securityWpa2Wpa3;

  /// No description provided for @securityWpa3.
  ///
  /// In en, this message translates to:
  /// **'WPA3'**
  String get securityWpa3;

  /// No description provided for @securityWpa.
  ///
  /// In en, this message translates to:
  /// **'WPA'**
  String get securityWpa;

  /// No description provided for @securityWpa2Enterprise.
  ///
  /// In en, this message translates to:
  /// **'WPA2 Enterprise'**
  String get securityWpa2Enterprise;

  /// No description provided for @securityWep.
  ///
  /// In en, this message translates to:
  /// **'WEP'**
  String get securityWep;

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

  /// No description provided for @proxyUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get proxyUrl;

  /// No description provided for @proxyEnterUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter url'**
  String get proxyEnterUrl;

  /// No description provided for @proxyServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get proxyServer;

  /// No description provided for @proxyEnterServer.
  ///
  /// In en, this message translates to:
  /// **'Enter server'**
  String get proxyEnterServer;

  /// No description provided for @proxyPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get proxyPort;

  /// No description provided for @proxyEnterPort.
  ///
  /// In en, this message translates to:
  /// **'Enter port'**
  String get proxyEnterPort;

  /// No description provided for @proxyAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get proxyAuthentication;

  /// No description provided for @proxyUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get proxyUsername;

  /// No description provided for @proxyPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get proxyPassword;

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

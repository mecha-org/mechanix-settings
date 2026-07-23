import 'dart:convert';

import 'package:dbus/dbus.dart';
import 'package:mechanix_settings/features/wireless/data/models/enterprise_config.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';

class EnterpriseConnectionBuilder {
  const EnterpriseConnectionBuilder._();

  static Map<String, DBusValue> build8021xSettings(EnterpriseConfig config) {
    final settings = <String, DBusValue>{
      'eap': DBusArray(DBusSignature.string, [
        DBusString(config.method.nmValue),
      ]),
    };

    if (config.identity.isNotEmpty) {
      settings['identity'] = DBusString(config.identity);
    }

    if (config.anonymousIdentity.isNotEmpty) {
      settings['anonymous-identity'] = DBusString(config.anonymousIdentity);
    }

    switch (config.method) {
      case EnterpriseEapMethod.peap:
        _configurePeap(settings, config);
        break;

      case EnterpriseEapMethod.ttls:
        _configureTtls(settings, config);
        break;

      case EnterpriseEapMethod.tls:
        _configureTls(settings, config);
        break;

      case EnterpriseEapMethod.leap:
        _configureLeap(settings, config);
        break;

      case EnterpriseEapMethod.pwd:
        _configurePwd(settings, config);
        break;
    }

    return settings;
  }

  static void _configurePeap(
    Map<String, DBusValue> settings,
    EnterpriseConfig config,
  ) {
    _applyPassword(settings, config);

    final peapVersion = config.peapVersion.nmValue;

    if (peapVersion != null) {
      settings['phase1-peapver'] = DBusString(peapVersion);
    }
    if (config.phase2 != null) {
      settings['phase2-auth'] = DBusString(config.phase2!.nmValue);
    }

    _applyCaCertificate(settings, config);
  }

  static void _configureTtls(
    Map<String, DBusValue> settings,
    EnterpriseConfig config,
  ) {
    _applyPassword(settings, config);

    if (config.phase2 != null) {
      settings['phase2-auth'] = DBusString(config.phase2!.nmValue);
    }

    _applyCaCertificate(settings, config);
  }

  static void _configureTls(
    Map<String, DBusValue> settings,
    EnterpriseConfig config,
  ) {
    _applyCaCertificate(settings, config);

    final userCertPath = config.userCertificate.path;
    if (userCertPath != null && userCertPath.isNotEmpty) {
      settings['client-cert'] = _buildFilePathValue(userCertPath);
    }

    final privateKeyPath = config.privateKey.path;
    if (privateKeyPath != null && privateKeyPath.isNotEmpty) {
      settings['private-key'] = _buildFilePathValue(privateKeyPath);
    }

    if (config.privateKeyPassword.isNotEmpty) {
      settings['private-key-password'] = DBusString(config.privateKeyPassword);
    } else {
      settings['private-key-password-flags'] = const DBusUint32(1);
    }

    if (config.domain.isNotEmpty) {
      settings['domain-suffix-match'] = DBusString(config.domain);
    }
  }

  static void _configureLeap(
    Map<String, DBusValue> settings,
    EnterpriseConfig config,
  ) {
    _applyPassword(settings, config);
  }

  static void _configurePwd(
    Map<String, DBusValue> settings,
    EnterpriseConfig config,
  ) {
    _applyPassword(settings, config);
  }

  static void _applyPassword(
    Map<String, DBusValue> settings,
    EnterpriseConfig config,
  ) {
    if (config.password.isNotEmpty) {
      settings['password'] = DBusString(config.password);
    } else {
      settings['password-flags'] = const DBusUint32(1);
    }
  }

  static void _applyCaCertificate(
    Map<String, DBusValue> settings,
    EnterpriseConfig config,
  ) {
    final caCertPath = config.caCertificate.path;
    if (caCertPath != null && caCertPath.isNotEmpty) {
      settings['ca-cert'] = _buildFilePathValue(caCertPath);
    }

    if (config.caCertificatePassword.isNotEmpty) {
      settings['ca-cert-password'] = DBusString(config.caCertificatePassword);
    }

    if (!config.requireCaCertificate) {
      settings['system-ca-certs'] = const DBusBoolean(true);
    }
  }

  static DBusArray _buildFilePathValue(String path) {
    return DBusArray(DBusSignature.byte, [
      ...utf8.encode('file://$path').map(DBusByte.new),
      const DBusByte(0),
    ]);
  }
}

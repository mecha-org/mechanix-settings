import 'package:mechanix_settings/features/wireless/data/models/enterprise_certificate_selection.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';

class EnterpriseConfig {
  static const Object _unset = Object();

  final EnterpriseEapMethod method;

  /// Used by PEAP only
  final PeapVersion peapVersion;

  /// Used by PEAP/TTLS
  final EnterprisePhase2Auth? phase2;

  /// NetworkManager identity
  final String identity;

  final String anonymousIdentity;

  final String password;

  final String domain;

  final CertificateSelection caCertificate;
  final String caCertificatePassword;

  final CertificateSelection userCertificate;
  final String userCertificatePassword;

  final CertificateSelection privateKey;
  final String privateKeyPassword;

  final bool requireCaCertificate;

  const EnterpriseConfig({
    this.method = EnterpriseEapMethod.peap,
    this.peapVersion = PeapVersion.automatic,
    this.phase2 = EnterprisePhase2Auth.mschapv2,
    this.identity = '',
    this.anonymousIdentity = '',
    this.password = '',
    this.domain = '',
    this.caCertificate = const CertificateSelection.none(),
    this.caCertificatePassword = '',
    this.userCertificate = const CertificateSelection.none(),
    this.userCertificatePassword = '',
    this.privateKey = const CertificateSelection.none(),
    this.privateKeyPassword = '',
    this.requireCaCertificate = true,
  });

  EnterpriseConfig copyWith({
    EnterpriseEapMethod? method,
    PeapVersion? peapVersion,
    Object? phase2 = _unset,
    String? identity,
    String? anonymousIdentity,
    String? password,
    String? domain,
    CertificateSelection? caCertificate,
    String? caCertificatePassword,
    CertificateSelection? userCertificate,
    String? userCertificatePassword,
    CertificateSelection? privateKey,
    String? privateKeyPassword,
    bool? requireCaCertificate,
  }) {
    return EnterpriseConfig(
      method: method ?? this.method,
      peapVersion: peapVersion ?? this.peapVersion,

      phase2: identical(phase2, _unset)
          ? this.phase2
          : phase2 as EnterprisePhase2Auth?,
      identity: identity ?? this.identity,
      anonymousIdentity: anonymousIdentity ?? this.anonymousIdentity,
      password: password ?? this.password,
      domain: domain ?? this.domain,
      caCertificate: caCertificate ?? this.caCertificate,
      caCertificatePassword:
          caCertificatePassword ?? this.caCertificatePassword,
      userCertificate: userCertificate ?? this.userCertificate,
      userCertificatePassword:
          userCertificatePassword ?? this.userCertificatePassword,
      privateKey: privateKey ?? this.privateKey,
      privateKeyPassword: privateKeyPassword ?? this.privateKeyPassword,
      requireCaCertificate: requireCaCertificate ?? this.requireCaCertificate,
    );
  }

  // Helper getters
  bool get supportsPeapVersion => method == EnterpriseEapMethod.peap;

  bool get supportsPhase2 => method.supportedPhase2.isNotEmpty;

  bool get requiresAnonymousIdentity =>
      method == EnterpriseEapMethod.peap || method == EnterpriseEapMethod.ttls;

  bool get requiresCaCertificate =>
      method == EnterpriseEapMethod.peap ||
      method == EnterpriseEapMethod.ttls ||
      method == EnterpriseEapMethod.tls;

  bool get requiresUserCertificate => method == EnterpriseEapMethod.tls;

  bool get requiresPrivateKey => method == EnterpriseEapMethod.tls;

  bool get requiresDomain => method == EnterpriseEapMethod.tls;
}

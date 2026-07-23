import 'package:mechanix_settings/features/wireless/data/models/enterprise_config.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class EnterpriseValidation {
  const EnterpriseValidation._();

  static bool isValidDomain(String domain) {
    final domainRegExp = RegExp(r'^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$');
    return domainRegExp.hasMatch(domain.trim());
  }

  static void validateEnterpriseConfig({
    required EnterpriseConfig config,
    required Map<String, String> errors,
    required AppLocalizations l10n,
  }) {
    switch (config.method) {
      case EnterpriseEapMethod.peap:
      case EnterpriseEapMethod.ttls:
        if (config.identity.trim().isEmpty) {
          errors['identity'] = l10n.identityRequired;
        }

        if (config.password.trim().isEmpty) {
          errors['password'] = l10n.passwordRequired;
        }

        if (config.domain.trim().isNotEmpty && !isValidDomain(config.domain)) {
          errors['domain'] = l10n.invalidDomain;
        }

        if (config.requireCaCertificate) {
          if (config.caCertificate.type == CertificateType.none ||
              (config.caCertificate.type == CertificateType.file &&
                  (config.caCertificate.path?.trim().isEmpty ?? true))) {
            errors['caCertificate'] = l10n.caCertificateRequired;
          }
        }
        break;

      case EnterpriseEapMethod.tls:
        if (config.identity.trim().isEmpty) {
          errors['identity'] = l10n.identityRequired;
        }

        if (config.domain.trim().isEmpty) {
          errors['domain'] = l10n.domainRequired;
        } else if (!isValidDomain(config.domain)) {
          errors['domain'] = l10n.invalidDomain;
        }

        if (config.requireCaCertificate) {
          if (config.caCertificate.type == CertificateType.none ||
              (config.caCertificate.type == CertificateType.file &&
                  (config.caCertificate.path?.trim().isEmpty ?? true))) {
            errors['caCertificate'] = l10n.caCertificateRequired;
          }
        }

        if (config.userCertificate.type == CertificateType.none ||
            (config.userCertificate.type == CertificateType.file &&
                (config.userCertificate.path?.trim().isEmpty ?? true))) {
          errors['userCertificate'] = l10n.userCertificateRequired;
        }

        if (config.privateKey.type == CertificateType.none ||
            (config.privateKey.type == CertificateType.file &&
                (config.privateKey.path?.trim().isEmpty ?? true))) {
          errors['privateKey'] = l10n.privateKeyRequired;
        }

        break;

      case EnterpriseEapMethod.pwd:
      case EnterpriseEapMethod.leap:
        if (config.identity.trim().isEmpty) {
          errors['identity'] = l10n.identityRequired;
        }

        if (config.password.trim().isEmpty) {
          errors['password'] = l10n.passwordRequired;
        }

        break;
    }
  }
}

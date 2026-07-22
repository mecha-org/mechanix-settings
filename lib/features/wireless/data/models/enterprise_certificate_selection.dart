import 'package:mechanix_settings/features/wireless/data/models/enums.dart';

class CertificateSelection {
  final CertificateType type;
  final String? path;

  const CertificateSelection({required this.type, this.path});

  const CertificateSelection.none() : type = CertificateType.none, path = null;

  const CertificateSelection.file(String this.path)
    : type = CertificateType.file;
}

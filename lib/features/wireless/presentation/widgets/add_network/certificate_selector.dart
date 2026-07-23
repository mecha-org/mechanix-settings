import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/features/wireless/data/models/enterprise_certificate_selection.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/add_network/enterprise_row.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class CertificateSelector extends StatelessWidget {
  final String title;
  final CertificateSelection? value;
  final bool allowNone;
  final ValueChanged<CertificateSelection>? onChanged;
  final bool enabled;
  final String? errorText;

  const CertificateSelector({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.allowNone = false,
    this.enabled = true,
    this.errorText,
  });

  CertificateType? _currentValue() {
    if (allowNone) {
      return value?.type ?? CertificateType.none;
    }

    return value?.type == CertificateType.file ? CertificateType.file : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EnterpriseRow(
          label: title,
          child: Opacity(
            opacity: enabled ? 1.0 : 0.5,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.backgroundVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CertificateType>(
                  value: _currentValue(),
                  isExpanded: true,

                  items: [
                    if (allowNone)
                      DropdownMenuItem(
                        value: CertificateType.none,
                        child: Text(l10n.none),
                      ),

                    DropdownMenuItem(
                      value: CertificateType.file,
                      child: Text(l10n.selectFromFile),
                    ),
                  ],

                  onChanged: enabled
                      ? (type) {
                          if (type == null || onChanged == null) return;

                          switch (type) {
                            case CertificateType.none:
                              onChanged!(const CertificateSelection.none());
                              break;

                            case CertificateType.file:
                              onChanged!(const CertificateSelection.file(''));
                              break;
                          }
                        }
                      : null,
                ),
              ),
            ),
          ),
        ),

        if (enabled &&
            value?.type == CertificateType.file &&
            value?.path != null &&
            value!.path!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 186, top: 8),
            child: Text(
              value!.path!,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 186, top: 4),
            child: Text(
              errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
      ],
    );
  }
}

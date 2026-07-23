import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/features/wireless/data/models/enterprise_config.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/add_network/enterprise_row.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/add_network/leap_section.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/add_network/peap_section.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/add_network/pwd_section.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/add_network/tls_section.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/add_network/ttls_section.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class EnterpriseSection extends StatelessWidget {
  final EnterpriseConfig config;
  final ValueChanged<EnterpriseConfig> onChanged;
  final Map<String, String>? errors;

  const EnterpriseSection({
    super.key,
    required this.config,
    required this.onChanged,
    this.errors,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EnterpriseRow(
          label: l10n.eapMethod,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<EnterpriseEapMethod>(
                value: config.method,
                isExpanded: true,
                items: EnterpriseEapMethod.values
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.label(l10n)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;

                  onChanged(
                    config.copyWith(
                      method: value,
                      phase2: value.supportedPhase2.isNotEmpty
                          ? value.supportedPhase2.first
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        switch (config.method) {
          EnterpriseEapMethod.peap => PeapSection(
            config: config,
            onChanged: onChanged,
            errors: errors,
          ),

          EnterpriseEapMethod.ttls => TtlsSection(
            config: config,
            onChanged: onChanged,
            errors: errors,
          ),

          EnterpriseEapMethod.tls => TlsSection(
            config: config,
            onChanged: onChanged,
            errors: errors,
          ),

          EnterpriseEapMethod.pwd => PwdSection(
            config: config,
            onChanged: onChanged,
            errors: errors,
          ),

          EnterpriseEapMethod.leap => LeapSection(
            config: config,
            onChanged: onChanged,
            errors: errors,
          ),
        },
      ],
    );
  }
}

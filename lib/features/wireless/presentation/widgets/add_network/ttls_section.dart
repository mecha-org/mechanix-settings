import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/core/widgets/custom_text_field.dart';
import 'package:mechanix_settings/features/wireless/data/models/enterprise_config.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/add_network/certificate_selector.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/add_network/enterprise_row.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class TtlsSection extends StatefulWidget {
  final EnterpriseConfig config;
  final ValueChanged<EnterpriseConfig> onChanged;
  final Map<String, String>? errors;

  const TtlsSection({
    super.key,
    required this.config,
    required this.onChanged,
    this.errors,
  });

  @override
  State<TtlsSection> createState() => _TtlsSectionState();
}

class _TtlsSectionState extends State<TtlsSection> {
  bool _obscurePassword = true;
  bool _obscureCaCertificatePassword = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final config = widget.config;
    final onChanged = widget.onChanged;

    final bool noCaCertificate = !config.requireCaCertificate;

    return Column(
      children: [
        EnterpriseRow(
          label: l10n.anonymousIdentity,
          child: CustomTextField(
            initialValue: config.anonymousIdentity,
            hintText: '',
            onChanged: (value) {
              onChanged(config.copyWith(anonymousIdentity: value));
            },
            controller: null,
          ),
        ),

        const SizedBox(height: 12),

        EnterpriseRow(
          label: l10n.domain,
          child: CustomTextField(
            initialValue: config.domain,
            hintText: '',
            errorText: widget.errors?['domain'],
            onChanged: (value) {
              onChanged(config.copyWith(domain: value));
            },
          ),
        ),

        const SizedBox(height: 12),

        CertificateSelector(
          title: l10n.caCertificate,
          value: config.caCertificate,
          allowNone: true,
          enabled: !noCaCertificate,
          errorText: widget.errors?['caCertificate'],
          onChanged: (value) {
            if (noCaCertificate) return;

            onChanged(config.copyWith(caCertificate: value));
          },
        ),

        const SizedBox(height: 12),

        EnterpriseRow(
          label: l10n.caCertificatePassword,
          child: CustomTextField(
            initialValue: config.caCertificatePassword,
            hintText: '',
            obscureText: _obscureCaCertificatePassword,
            enabled: !noCaCertificate,

            suffixIcon: IconButton(
              icon: Icon(
                _obscureCaCertificatePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: noCaCertificate
                  ? null
                  : () {
                      setState(() {
                        _obscureCaCertificatePassword =
                            !_obscureCaCertificatePassword;
                      });
                    },
            ),

            onChanged: noCaCertificate
                ? null
                : (value) {
                    onChanged(config.copyWith(caCertificatePassword: value));
                  },
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            SizedBox(
              width: 200,
              child: Text(
                l10n.noCaCertificate,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),

            Checkbox(
              value: noCaCertificate,
              activeColor: AppColors.onSurface,
              onChanged: (value) {
                onChanged(
                  config.copyWith(requireCaCertificate: !(value ?? false)),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 12),

        EnterpriseRow(
          label: l10n.phase2Authentication,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<EnterprisePhase2Auth>(
                value: config.phase2,
                isExpanded: true,
                items: config.method.supportedPhase2
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.label(l10n)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  onChanged(config.copyWith(phase2: value));
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        EnterpriseRow(
          label: l10n.identity,
          child: CustomTextField(
            initialValue: config.identity,
            hintText: '',
            errorText: widget.errors?['identity'],
            onChanged: (value) {
              onChanged(config.copyWith(identity: value));
            },
          ),
        ),

        const SizedBox(height: 12),

        EnterpriseRow(
          label: l10n.password,
          child: CustomTextField(
            initialValue: config.password,
            hintText: '',
            obscureText: _obscurePassword,
            errorText: widget.errors?['password'],

            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),

            onChanged: (value) {
              onChanged(config.copyWith(password: value));
            },
          ),
        ),
      ],
    );
  }
}

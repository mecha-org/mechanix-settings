import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/core/widgets/custom_text_field.dart';
import 'package:mechanix_settings/features/wireless/data/models/enterprise_config.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/add_network/certificate_selector.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/add_network/enterprise_row.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class TlsSection extends StatefulWidget {
  final EnterpriseConfig config;
  final ValueChanged<EnterpriseConfig> onChanged;
  final Map<String, String>? errors;

  const TlsSection({
    super.key,
    required this.config,
    required this.onChanged,
    this.errors,
  });

  @override
  State<TlsSection> createState() => _TlsSectionState();
}

class _TlsSectionState extends State<TlsSection> {
  bool _obscurePrivateKeyPassword = true;
  bool _obscureCaCertificatePassword = true;
  bool _obscureUserCertificatePassword = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final config = widget.config;
    final onChanged = widget.onChanged;

    final bool noCaCertificate = !config.requireCaCertificate;

    return Column(
      children: [
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

            onChanged: !noCaCertificate
                ? (value) {
                    onChanged(config.copyWith(caCertificatePassword: value));
                  }
                : null,
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

        CertificateSelector(
          title: l10n.userCertificate,
          value: config.userCertificate,
          allowNone: true,
          errorText: widget.errors?['userCertificate'],
          onChanged: (value) {
            onChanged(config.copyWith(userCertificate: value));
          },
        ),

        const SizedBox(height: 12),

        EnterpriseRow(
          label: l10n.userCertificatePassword,
          child: CustomTextField(
            initialValue: config.userCertificatePassword,
            hintText: '',
            obscureText: _obscureUserCertificatePassword,

            suffixIcon: IconButton(
              icon: Icon(
                _obscureUserCertificatePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscureUserCertificatePassword =
                      !_obscureUserCertificatePassword;
                });
              },
            ),

            onChanged: (value) {
              onChanged(config.copyWith(userCertificatePassword: value));
            },
          ),
        ),

        const SizedBox(height: 12),

        CertificateSelector(
          title: l10n.privateKey,
          value: config.privateKey,
          allowNone: true,
          errorText: widget.errors?['privateKey'],
          onChanged: (value) {
            onChanged(config.copyWith(privateKey: value));
          },
        ),

        const SizedBox(height: 12),

        EnterpriseRow(
          label: l10n.privateKeyPassword,
          child: CustomTextField(
            initialValue: config.privateKeyPassword,
            hintText: '',
            obscureText: _obscurePrivateKeyPassword,

            suffixIcon: IconButton(
              icon: Icon(
                _obscurePrivateKeyPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscurePrivateKeyPassword = !_obscurePrivateKeyPassword;
                });
              },
            ),

            onChanged: (value) {
              onChanged(config.copyWith(privateKeyPassword: value));
            },
          ),
        ),
      ],
    );
  }
}

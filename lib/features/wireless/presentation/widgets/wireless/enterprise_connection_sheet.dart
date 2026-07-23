import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/core/widgets/custom_button.dart';
import 'package:mechanix_settings/core/widgets/custom_divider.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/widgets/custom_text_field.dart';
import 'package:mechanix_settings/features/wireless/data/models/enterprise_config.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';
import 'package:mechanix_settings/features/wireless/data/utils/enterprise_validations.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/add_network/enterprise_row.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/add_network/enterprise_section.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class EnterpriseConnectionBottomSheet extends StatefulWidget {
  final String networkName;
  final WirelessSecurity security;
  final EnterpriseEapMethod? eapMethod;

  const EnterpriseConnectionBottomSheet({
    super.key,
    required this.networkName,
    required this.security,
    this.eapMethod,
  });

  @override
  State<EnterpriseConnectionBottomSheet> createState() =>
      _EnterpriseConnectionBottomSheetState();
}

class _EnterpriseConnectionBottomSheetState
    extends State<EnterpriseConnectionBottomSheet> {
  late EnterpriseConfig _enterpriseConfig;

  final _identityController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    final method = widget.security == WirelessSecurity.leap
        ? EnterpriseEapMethod.leap
        : (widget.eapMethod ?? EnterpriseEapMethod.peap);

    _enterpriseConfig = EnterpriseConfig(method: method);
  }

  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final errors = <String, String>{};
    final l10n = AppLocalizations.of(context)!;

    if (widget.security == WirelessSecurity.leap) {
      final identity = _identityController.text.trim();
      final password = _passwordController.text.trim();
      if (identity.isEmpty) {
        errors['identity'] = l10n.identityRequired;
      }
      if (password.isEmpty) {
        errors['password'] = l10n.passwordRequired;
      }
    } else {
      EnterpriseValidation.validateEnterpriseConfig(
        config: _enterpriseConfig,
        errors: errors,
        l10n: l10n,
      );
    }

    setState(() {
      _errors = errors;
    });

    return errors.isEmpty;
  }

  void _connect() {
    if (!_validate()) {
      return;
    }
    if (widget.security == WirelessSecurity.leap) {
      final identity = _identityController.text.trim();
      final password = _passwordController.text.trim();
      Navigator.pop(
        context,
        _enterpriseConfig.copyWith(identity: identity, password: password),
      );
    } else {
      Navigator.pop(context, _enterpriseConfig);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(color: AppColors.backgroundVariantDark),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.joinNetwork(widget.networkName),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  CustomIconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const CustomDivider(verticalPadding: 12),

              if (widget.security == WirelessSecurity.leap) ...[
                EnterpriseRow(
                  label: l10n.identity,
                  child: CustomTextField(
                    controller: _identityController,
                    hintText: '',
                    errorText: _errors['identity'],
                    onChanged: (value) {
                      if (_errors.containsKey('identity')) {
                        setState(() {
                          _errors.remove('identity');
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                EnterpriseRow(
                  label: l10n.password,
                  child: CustomTextField(
                    controller: _passwordController,
                    hintText: '',
                    obscureText: _obscurePassword,
                    errorText: _errors['password'],
                    onChanged: (value) {
                      if (_errors.containsKey('password')) {
                        setState(() {
                          _errors.remove('password');
                        });
                      }
                    },
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
                  ),
                ),
              ] else ...[
                // Since EAP method is already known, we display the EnterpriseSection.
                // It is pre-initialized with the known eapMethod, so it shows the fields
                // for that specific EAP method directly, while still allowing adjustment if needed.
                EnterpriseSection(
                  config: _enterpriseConfig,
                  errors: _errors,
                  onChanged: (config) {
                    setState(() {
                      _enterpriseConfig = config;
                      _errors.clear();
                    });
                  },
                ),
              ],

              const SizedBox(height: 24),
              const CustomDivider(verticalPadding: 0),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      label: AppLocalizations.of(context)!.cancel,
                      backgroundColor: AppColors.onSurfaceVariantDark,
                      textColor: AppColors.onSurface,
                      borderRadius: 0,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: CustomButton(
                      label: AppLocalizations.of(context)!.connect,
                      backgroundColor: AppColors.onSurface,
                      textColor: AppColors.surface,
                      borderRadius: 0,
                      onPressed: _connect,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<EnterpriseConfig?> showEnterpriseConnectionBottomSheet(
  BuildContext context,
  WifiNetwork network,
) {
  return showModalBottomSheet<EnterpriseConfig>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (_) => EnterpriseConnectionBottomSheet(
      networkName: network.name,
      security: network.security,
      eapMethod: network.eapMethod,
    ),
  );
}

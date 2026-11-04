import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/data/utils/wifi_password_validator.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/add_network/security_selector.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

class AddNetworkBody extends StatefulWidget {
  const AddNetworkBody({super.key});

  @override
  State<AddNetworkBody> createState() => AddNetworkBodyState();
}

class AddNetworkBodyState extends State<AddNetworkBody> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  WirelessSecurity _security = WirelessSecurity.none;
  Map<String, String> _errors = {};

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final errors = <String, String>{};
    final l10n = AppLocalizations.of(context)!;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      errors['name'] = l10n.networkNameRequired;
    }

    if (_security.requiresPassword) {
      final password = _passwordController.text;
      final error = WifiPasswordValidator.getErrorMessage(
        password,
        _security,
        l10n,
      );
      if (error != null) {
        errors['password'] = error;
      }
    }

    setState(() {
      _errors = errors;
    });

    return errors.isEmpty;
  }

  Future<bool> connect() async {
    if (!_validate()) {
      return false;
    }

    final name = _nameController.text.trim();
    final password = _security.requiresPassword
        ? _passwordController.text
        : null;

    context.read<WirelessBloc>().add(
      AddNetworkEvent(name, _security, password: password),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MechanixTextField.outlined(
              controller: _nameController,
              errorText: _errors['name'],
              decoration: InputDecoration(
                hintText: l10n.networkName,
                hintStyle: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                if (_errors.containsKey('name')) {
                  setState(() {
                    _errors.remove('name');
                  });
                }
              },
            ),

            const SizedBox(height: 12),

            SecuritySelector(
              security: _security,
              onChanged: (value) {
                setState(() {
                  _security = value;
                  _errors.clear();
                });
              },
            ),

            if (_security.requiresPassword) ...[
              const SizedBox(height: 12),

              MechanixTextField.outlined(
                controller: _passwordController,
                errorText: _errors['password'],
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: l10n.password,
                  hintStyle: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) {
                  if (_errors.containsKey('password')) {
                    setState(() {
                      _errors.remove('password');
                    });
                  }
                },
                suffixIcon: MechanixIconButton.standard(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

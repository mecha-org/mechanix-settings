import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/data/models/typed_sheet_results.dart';
import 'package:mechanix_settings/features/wireless/data/utils/wifi_password_validator.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

class WirelessPasswordBottomSheet extends StatefulWidget {
  final String networkName;
  final String? security;
  final WirelessSecurity? securityType;
  final bool initialAutoConnect;

  const WirelessPasswordBottomSheet({
    super.key,
    required this.networkName,
    this.security,
    this.securityType,
    this.initialAutoConnect = true,
  });

  static Future<WirelessPasswordResult?> show({
    required BuildContext context,
    required String networkName,
    String? security,
    WirelessSecurity? securityType,
    bool initialAutoConnect = true,
  }) {
    return MechanixBottomSheet.showModal<WirelessPasswordResult>(
      context: context,
      showDragHandle: true,
      builder: (_) => WirelessPasswordBottomSheet(
        networkName: networkName,
        security: security,
        securityType: securityType,
        initialAutoConnect: initialAutoConnect,
      ),
    );
  }

  @override
  State<WirelessPasswordBottomSheet> createState() =>
      _WirelessPasswordBottomSheetState();
}

class _WirelessPasswordBottomSheetState
    extends State<WirelessPasswordBottomSheet> {
  final _controller = TextEditingController();
  bool _obscurePassword = true;
  late bool _connectAutomatically;

  @override
  void initState() {
    super.initState();
    _connectAutomatically = widget.initialAutoConnect;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _connect() {
    final password = _controller.text;
    if (!WifiPasswordValidator.isValid(password, widget.securityType)) {
      return;
    }
    Navigator.of(context).pop(
      WirelessPasswordResult(
        password: password,
        connectAutomatically: _connectAutomatically,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  MechanixIconButton.standard(
                    icon: ImageIcon(
                      const AssetImage(SettingIcons.back),
                      color: theme.colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.networkName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _controller,
                    builder: (context, value, _) {
                      final isValid = WifiPasswordValidator.isValid(
                        value.text,
                        widget.securityType,
                      );
                      return MechanixIconButton.standard(
                        icon: ImageIcon(
                          const AssetImage(SettingIcons.check),
                          color: isValid
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.38,
                                ),
                        ),
                        onPressed: isValid ? _connect : null,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            /// Password input field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34),
              child: MechanixTextField(
                controller: _controller,
                autofocus: true,
                obscureText: _obscurePassword,
                obscuringCharacter: '*',
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (WifiPasswordValidator.isValid(
                    _controller.text,
                    widget.securityType,
                  )) {
                    _connect();
                  }
                },
                decoration: InputDecoration(
                  filled: false,
                  fillColor: Colors.transparent,
                  hintText: l10n.enterPassword,
                  hintStyle: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                suffixIcon: MechanixIconButton.standard(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            /// Security row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.security,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSecondaryFixed,
                    ),
                  ),
                  Text(
                    widget.security ?? '-',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSecondaryFixed,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// Connect automatically checkbox
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: MechanixCheckbox.labeled(
                value: _connectAutomatically,
                onChanged: (val) {
                  setState(() {
                    _connectAutomatically = val ?? false;
                  });
                },
                labelText: l10n.connectAutomatically,
                labelStyle: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSecondaryFixed,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

Future<WirelessPasswordResult?> showPasswordBottomSheet(
  BuildContext context,
  String networkName, {
  String? security,
  WirelessSecurity? securityType,
  bool initialAutoConnect = true,
}) {
  return WirelessPasswordBottomSheet.show(
    context: context,
    networkName: networkName,
    security: security,
    securityType: securityType,
    initialAutoConnect: initialAutoConnect,
  );
}

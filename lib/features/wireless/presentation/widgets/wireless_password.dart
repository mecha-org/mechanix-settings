import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/core/widgets/custom_divider.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/widgets/custom_text_field.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class WirelessPasswordBottomSheet extends StatefulWidget {
  final String networkName;

  const WirelessPasswordBottomSheet({super.key, required this.networkName});

  @override
  State<WirelessPasswordBottomSheet> createState() =>
      _WirelessPasswordBottomSheetState();
}

class _WirelessPasswordBottomSheetState
    extends State<WirelessPasswordBottomSheet> {
  final _controller = TextEditingController();

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _connect() {
    final password = _controller.text.trim();

    if (password.isEmpty) {
      return;
    }

    Navigator.pop(context, password);
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
      decoration: const BoxDecoration(color: AppColors.backgroundVariantDark),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

          /// Password
          CustomTextField(
            controller: _controller,
            hintText: l10n.enterPassword,
            obscureText: _obscurePassword,
            obscuringCharacter: '*',
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _connect(),
            prefixIcon: const Icon(
              Icons.lock_outline,
              size: 24,
              color: AppColors.onSurfaceVariantDark,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),

          const SizedBox(height: 16),

          const CustomDivider(verticalPadding: 0),

          const SizedBox(height: 16),

          Row(
            children: [
              Text(l10n.security, style: Theme.of(context).textTheme.bodyLarge),
              const Spacer(),
              Text(
                l10n.wpa2Personal,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<String?> showPasswordBottomSheet(
  BuildContext context,
  String networkName,
) {
  return showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (_) => WirelessPasswordBottomSheet(networkName: networkName),
  );
}

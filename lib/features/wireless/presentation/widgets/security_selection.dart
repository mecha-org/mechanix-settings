import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/widgets/breadcrumbs.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class SecuritySelectionScreen extends StatefulWidget {
  final WirelessSecurity selected;

  const SecuritySelectionScreen({super.key, required this.selected});

  @override
  State<SecuritySelectionScreen> createState() =>
      _SecuritySelectionScreenState();
}

class _SecuritySelectionScreenState extends State<SecuritySelectionScreen> {
  late WirelessSecurity _selected;
  final ScrollController _breadcrumbController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  void dispose() {
    _breadcrumbController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: AppBreadcrumbs(
          scrollController: _breadcrumbController,
          items: [
            BreadcrumbItem(
              label: l10n.addWireless,
              onTap: () => Navigator.pop(context),
            ),
            BreadcrumbItem(label: l10n.security),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: RadioGroup<WirelessSecurity>(
        groupValue: _selected,
        onChanged: (WirelessSecurity? value) {
          if (value == null) return;

          setState(() {
            _selected = value;
          });
        },
        child: ListView(
          children: WirelessSecurity.values.map((security) {
            return RadioListTile<WirelessSecurity>(
              minTileHeight: 60,
              value: security,
              activeColor: AppColors.onSurface,
              title: Text(
                security.label(AppLocalizations.of(context)!),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }).toList(),
        ),
      ),
      bottomNavigationBar: BottomBar(
        leading: CustomIconButton.asset(
          assetPath: SettingIcons.back,
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        trailing: [
          CustomIconButton.asset(
            assetPath: SettingIcons.check,
            onPressed: () {
              Navigator.pop(context, _selected);
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/widgets/breadcrumbs.dart';
import 'package:mechanix_settings/core/widgets/custom_divider.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class BluetoothAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ScrollController breadcrumbController;
  final String? deviceName;

  const BluetoothAppBar({
    super.key,
    required this.breadcrumbController,
    this.deviceName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final List<BreadcrumbItem> items = [
      BreadcrumbItem(
        label: l10n.settings,
        onTap: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
      BreadcrumbItem(
        label: l10n.bluetooth,
        onTap: deviceName != null
            ? () {
                Navigator.of(context).pop();
              }
            : null,
      ),
    ];

    if (deviceName != null) {
      items.add(BreadcrumbItem(label: deviceName!));
    }

    return AppBar(
      scrolledUnderElevation: 0,
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      title: AppBreadcrumbs(
        scrollController: breadcrumbController,
        items: items,
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: CustomDivider(verticalPadding: 0),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}

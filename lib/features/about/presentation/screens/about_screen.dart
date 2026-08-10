import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/core/utils/helper.dart';
import 'package:mechanix_settings/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_settings/core/widgets/breadcrumbs.dart';
import 'package:mechanix_settings/core/widgets/custom_divider.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/features/about/blocs/about_bloc.dart';
import 'package:mechanix_settings/features/about/blocs/about_event.dart';
import 'package:mechanix_settings/features/about/blocs/about_state.dart';
import 'package:mechanix_settings/features/about/data/models/enums.dart';
import 'package:mechanix_settings/features/about/data/utils/about_validators.dart';
import 'package:mechanix_settings/features/about/presentation/widgets/about_tile.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final ScrollController _breadcrumbController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<AboutBloc>().add(const LoadAboutDetails());
  }

  @override
  void dispose() {
    _breadcrumbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<AboutBloc, AboutState>(
      listenWhen: (previous, current) =>
          previous.error != current.error && current.error != null,
      listener: (context, state) {
        if (state.error == null) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              getAboutErrorMessage(AppLocalizations.of(context)!, state.error!),
            ),
          ),
        );
      },
      child: BlocBuilder<AboutBloc, AboutState>(
        builder: (context, state) {
          if (state.status == AboutStatus.loading ||
              state.status == AboutStatus.initial) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppColors.onSurface),
              ),
            );
          }

          final details = state.details;

          if (details == null) {
            return Scaffold(
              body: Center(
                child: Text(
                  l10n.somethingWentWrong,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(
              scrolledUnderElevation: 0,
              elevation: 0,
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              title: AppBreadcrumbs(
                scrollController: _breadcrumbController,
                items: [
                  BreadcrumbItem(
                    label: l10n.settings,
                    onTap: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                  BreadcrumbItem(label: l10n.about),
                ],
              ),
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: CustomDivider(verticalPadding: 0),
              ),
            ),
            body: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false,
                dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Device information
                    AboutTile(
                      title: l10n.deviceName,
                      value: details.deviceName,
                      editable: true,
                      validator: (value) =>
                          AboutValidators.validateDeviceName(value, l10n),
                      onSave: (value) {
                        context.read<AboutBloc>().add(UpdateDeviceName(value));
                      },
                    ),
                    AboutTile(
                      title: l10n.hostname,
                      value: details.hostname,
                      editable: true,
                      validator: (value) =>
                          AboutValidators.validateHostname(value, l10n),
                      onSave: (value) {
                        context.read<AboutBloc>().add(UpdateHostname(value));
                      },
                    ),
                    AboutTile(title: l10n.model, value: details.model),
                    AboutTile(
                      title: l10n.manufacturer,
                      value: details.manufacturer,
                    ),

                    const CustomDivider(verticalPadding: 0),

                    // Operating system
                    AboutTile(
                      title: l10n.operatingSystem,
                      value: details.operatingSystem,
                    ),
                    if (details.supportUntil.isNotEmpty)
                      AboutTile(
                        title: l10n.supportUntil,
                        value: details.supportUntil,
                      ),
                    AboutTile(title: l10n.kernel, value: details.kernel),
                    AboutTile(
                      title: l10n.kernelBuild,
                      value: details.kernelBuild,
                    ),

                    const CustomDivider(verticalPadding: 0),

                    // Firmware
                    AboutTile(
                      title: l10n.firmwareVersion,
                      value: details.firmwareVersion,
                    ),
                    AboutTile(
                      title: l10n.firmwareVendor,
                      value: details.firmwareVendor,
                    ),
                    AboutTile(
                      title: l10n.firmwareDate,
                      value: details.firmwareDate,
                    ),

                    const CustomDivider(verticalPadding: 0),

                    // Device identification
                    if (details.serialNumber != null &&
                        details.serialNumber!.isNotEmpty)
                      AboutTile(
                        title: l10n.serialNumber,
                        value: details.serialNumber!,
                        copyable: true,
                      ),
                    AboutTile(
                      title: l10n.machineId,
                      value: details.machineId,
                      copyable: true,
                    ),
                    AboutTile(
                      title: l10n.bootId,
                      value: details.bootId,
                      copyable: true,
                    ),

                    const CustomDivider(verticalPadding: 0),

                    // OS website
                    if (details.osWebsite.isNotEmpty)
                      AboutTile(
                        title: l10n.osWebsite,
                        value: details.osWebsite,
                        copyable: true,
                      ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: BottomBar(
              leading: CustomIconButton.asset(
                assetPath: SettingIcons.back,
                enabled: true,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          );
        },
      ),
    );
  }
}

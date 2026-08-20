import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_settings/core/widgets/custom_divider.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/widgets/breadcrumbs.dart';
import 'package:mechanix_settings/core/widgets/check_box/circular_checkbox.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/core/widgets/custom_loader.dart';
import 'package:mechanix_settings/features/sound/blocs/sound_bloc.dart';
import 'package:mechanix_settings/features/sound/blocs/sound_event.dart';
import 'package:mechanix_settings/features/sound/blocs/sound_state.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class OutputDeviceScreen extends StatefulWidget {
  const OutputDeviceScreen({super.key});

  @override
  State<OutputDeviceScreen> createState() => _OutputDeviceScreenState();
}

class _OutputDeviceScreenState extends State<OutputDeviceScreen> {
  final ScrollController _breadcrumbController = ScrollController();

  @override
  void dispose() {
    _breadcrumbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

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
            BreadcrumbItem(
              label: l10n.sound,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            BreadcrumbItem(label: l10n.outputDevice),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: CustomDivider(verticalPadding: 0),
        ),
      ),
      body: BlocBuilder<SoundBloc, SoundState>(
        builder: (context, state) {
          debugPrint(
            "OutputDeviceScreen: outputDeviceLoading = ${state.outputDeviceLoading}",
          );
          if (state.outputDeviceLoading) {
            return ListView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 16,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const CustomLoader(),
                      const SizedBox(width: 16),
                      Text(
                        "",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              scrollbars: false,
              dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
            ),
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.outputDevices.length,
              itemBuilder: (context, index) {
                final device = state.outputDevices[index];
                final isSelected = device == state.selectedOutputDevice;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () {
                      context.read<SoundBloc>().add(SetOutputDevice(device));
                    },
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 64),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.volume_up,
                              color: AppColors.onSurfaceVariant,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                device,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                            const SizedBox(width: 12),
                            CustomCircleCheckbox(
                              isChecked: isSelected,
                              onTap: () {
                                context.read<SoundBloc>().add(
                                  SetOutputDevice(device),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<SoundBloc, SoundState>(
        builder: (context, state) {
          return BottomBar(
            leading: CustomIconButton.asset(
              assetPath: SettingIcons.back,
              enabled: true,
              onPressed: () => Navigator.pop(context),
            ),
            trailing: [
              CustomIconButton.asset(
                assetPath: SettingIcons.refresh,
                enabled: !state.outputDeviceLoading,
                onPressed: () {
                  context.read<SoundBloc>().add(
                    const RefreshOutputDevicesList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

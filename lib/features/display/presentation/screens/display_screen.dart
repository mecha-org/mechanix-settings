import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/core/utils/helper.dart';
import 'package:mechanix_settings/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/widgets/custom_divider.dart';
import 'package:mechanix_settings/core/widgets/custom_toggle.dart';
import 'package:mechanix_settings/core/widgets/breadcrumbs.dart';
import 'package:mechanix_settings/core/widgets/custom_slider.dart';
import 'package:mechanix_settings/core/widgets/section_list/section_item.dart';
import 'package:mechanix_settings/core/widgets/section_list/section_list.dart';
import 'package:mechanix_settings/features/display/blocs/display_bloc.dart';
import 'package:mechanix_settings/features/display/blocs/display_event.dart';
import 'package:mechanix_settings/features/display/blocs/display_state.dart';
import 'package:mechanix_settings/features/display/data/models/display_enums.dart';
import 'package:mechanix_settings/features/display/presentation/screens/screen_off_time_screen.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class DisplayScreen extends StatefulWidget {
  const DisplayScreen({super.key});

  @override
  State<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen> {
  final ScrollController _breadcrumbController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Dispatch DisplayInit to fetch the initial values
    context.read<DisplayBloc>().add(const DisplayInit());
  }

  @override
  void dispose() {
    _breadcrumbController.dispose();
    super.dispose();
  }

  String _formatScreenTimeout(int seconds, AppLocalizations l10n) {
    switch (seconds) {
      case 10:
        return l10n.screenOffTenSeconds;
      case 30:
        return l10n.screenOffThirtySeconds;
      case 60:
        return l10n.screenOffOneMinute;
      case 120:
        return l10n.screenOffTwoMinutes;
      case 300:
        return l10n.screenOffFiveMinutes;
      default:
        return l10n.screenOffNever;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocListener<DisplayBloc, DisplayState>(
      listener: (context, state) {
        if (state.status == DisplayStatus.error && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(getDisplayErrorMessage(l10n, state.error!)),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      child: BlocBuilder<DisplayBloc, DisplayState>(
        builder: (context, state) {
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
                  BreadcrumbItem(label: l10n.display),
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
                    // Brightness slider block
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.brightness,
                                style: theme.textTheme.bodyLarge,
                              ),
                              Text(
                                "${(state.brightness * 100).round()} %",
                                style: theme.textTheme.bodyLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          CustomSlider(
                            value: state.brightness,
                            onChanged: (val) {
                              context.read<DisplayBloc>().add(
                                SetBrightness(val),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const CustomDivider(verticalPadding: 0),

                    // Auto brightness switch row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.autoBrightness,
                            style: theme.textTheme.bodyLarge,
                          ),
                          CustomToggle(
                            value: state.isAutoBrightness,
                            onChanged: (val) {
                              context.read<DisplayBloc>().add(
                                SetAutoBrightness(val),
                              );
                            },
                            l10n: l10n,
                          ),
                        ],
                      ),
                    ),
                    const CustomDivider(verticalPadding: 0),

                    // Screen off time list item
                    SectionList(
                      items: [
                        SectionItem(
                          title: l10n.screenOffTime,
                          titleStyle: theme.textTheme.bodyLarge!.copyWith(
                            color: AppColors.onSurface,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatScreenTimeout(state.screenTimeout, l10n),
                                style: theme.textTheme.bodyLarge!.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_right,
                                size: 24,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ],
                          ),
                          onTap: () {
                            final bloc = context.read<DisplayBloc>();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: bloc,
                                  child: const ScreenOffTimeScreen(),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
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

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/core/utils/helper.dart';
import 'package:mechanix_settings/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/widgets/custom_divider.dart';
import 'package:mechanix_settings/core/widgets/breadcrumbs.dart';
import 'package:mechanix_settings/core/widgets/check_box/circular_checkbox.dart';
import 'package:mechanix_settings/features/language/blocs/language_bloc.dart';
import 'package:mechanix_settings/features/language/blocs/language_event.dart';
import 'package:mechanix_settings/features/language/blocs/language_state.dart';
import 'package:mechanix_settings/features/language/data/models/enums.dart';
import 'package:mechanix_settings/features/language/data/models/language_options.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final ScrollController _breadcrumbController = ScrollController();

  @override
  void dispose() {
    _breadcrumbController.dispose();
    super.dispose();
  }

  bool _isOptionSelected(String systemLanguage, String optionCode) {
    final optionPrefix = optionCode.split('.').first;
    final systemPrefix = systemLanguage.split('.').first;
    return optionPrefix == systemPrefix;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final options = getLanguageOptions(l10n);

    return BlocListener<LanguageBloc, LanguageState>(
      listener: (context, state) {
        if (state.status == LanguageStatus.error && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(getLanguageErrorMessage(l10n, state.error!)),
            ),
          );
        }
      },
      child: BlocBuilder<LanguageBloc, LanguageState>(
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
                  BreadcrumbItem(label: l10n.language),
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
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = _isOptionSelected(
                    state.systemLanguage,
                    option.code,
                  );

                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          context.read<LanguageBloc>().add(
                            SetSystemLanguage(option.code),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          child: Row(
                            children: [
                              CustomCircleCheckbox(
                                isChecked: isSelected,
                                onTap: () {
                                  context.read<LanguageBloc>().add(
                                    SetSystemLanguage(option.code),
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  option.label,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: isSelected
                                        ? AppColors.onSurface
                                        : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
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

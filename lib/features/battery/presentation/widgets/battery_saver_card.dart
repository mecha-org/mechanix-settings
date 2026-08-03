import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/core/widgets/custom_toggle.dart';
import 'package:mechanix_settings/features/battery/blocs/battery_bloc.dart';
import 'package:mechanix_settings/features/battery/blocs/battery_state.dart';
import 'package:mechanix_settings/features/battery/blocs/battery_event.dart';
import 'package:mechanix_settings/features/battery/data/models/enums.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class BatterySaverCard extends StatelessWidget {
  const BatterySaverCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocSelector<BatteryBloc, BatteryState, PowerProfileMode?>(
      selector: (state) => state.performanceMode,
      builder: (context, performanceMode) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundVariantDark,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.batterySaver,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurface,
                  fontSize: 18,
                ),
              ),
              CustomToggle(
                value: performanceMode == PowerProfileMode.powerSaver,
                onChanged: (value) {
                  context.read<BatteryBloc>().add(ToggleBatterySaver(value));
                },
                l10n: l10n,
              ),
            ],
          ),
        );
      },
    );
  }
}

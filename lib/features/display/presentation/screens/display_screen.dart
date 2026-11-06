import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/core/utils/helper.dart';
import 'package:mechanix_settings/features/display/blocs/display_bloc.dart';
import 'package:mechanix_settings/features/display/blocs/display_event.dart';
import 'package:mechanix_settings/features/display/blocs/display_state.dart';
import 'package:mechanix_settings/features/display/data/models/display_enums.dart';
import 'package:mechanix_settings/features/display/presentation/screens/screen_off_time_screen.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

class DisplayScreen extends StatelessWidget {
  const DisplayScreen({super.key});

  void _navigateToScreenOffTime(BuildContext context) {
    final bloc = context.read<DisplayBloc>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            BlocProvider.value(value: bloc, child: const ScreenOffTimeScreen()),
      ),
    );
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
      child: Scaffold(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        appBar: MechanixAppBar.small(
          primary: false,
          leading: MechanixIconButton.standard(
            size: IconButtonSize.small,
            icon: ImageIcon(
              const AssetImage(SettingIcons.back),
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          titleSpacing: 0,
          leadingWidth: 48,
          title: Text(
            l10n.displaySettings.toUpperCase(),
            style: theme.textTheme.headlineSmall!.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          backgroundColor: Colors.transparent,
        ),
        body: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            scrollbars: false,
            dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
          ),
          child: SingleChildScrollView(
            child: Column(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brightness
                MechanixListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 24,
                  ),
                  leadingWidgets: [
                    ImageIcon(
                      const AssetImage(SettingIcons.sunIcon),
                      color: theme.colorScheme.onSurface,
                      size: 19,
                    ),
                  ],
                  gap: 12,
                  labelText: l10n.brightness,
                  trailingWidgets: const [_BrightnessValue()],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _BrightnessSlider(),
                ),

                // Auto brightness
                MechanixListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 24,
                  ),
                  height: 76,
                  labelText: l10n.autoBrightness,
                  trailingWidgets: const [_AutoBrightnessSwitch()],
                ),

                // Screen off time
                MechanixListTile(
                  key: const ValueKey('screen_off_time_tile'),
                  contentPadding: const EdgeInsets.only(
                    left: 24,
                    right: 8,
                    top: 4,
                    bottom: 4,
                  ),
                  height: 60,
                  labelText: l10n.screenOffTime,
                  onTap: () => _navigateToScreenOffTime(context),
                  trailingWidgets: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _navigateToScreenOffTime(context),
                      child: const _ScreenTimeoutValue(),
                    ),
                    MechanixIconButton.standard(
                      type: IconButtonType.rounded,
                      icon: ImageIcon(
                        const AssetImage(SettingIcons.caretRight),
                        color: theme.colorScheme.onSurface,
                        size: 20,
                      ),
                      onPressed: () => _navigateToScreenOffTime(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Live brightness percentage; rebuilds only when brightness changes.
class _BrightnessValue extends StatelessWidget {
  const _BrightnessValue();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocSelector<DisplayBloc, DisplayState, int>(
      selector: (state) => (state.brightness * 100).round(),
      builder: (context, percent) {
        return Text(
          "$percent %",
          style: theme.textTheme.titleMedium!.copyWith(
            color: theme.colorScheme.onPrimary,
            fontFamily: MechanixFontFamily.geistMono,
          ),
        );
      },
    );
  }
}

class _BrightnessSlider extends StatefulWidget {
  const _BrightnessSlider();

  @override
  State<_BrightnessSlider> createState() => _BrightnessSliderState();
}

class _BrightnessSliderState extends State<_BrightnessSlider> {
  static const _throttleDuration = Duration(milliseconds: 200);

  Timer? _throttleTimer;
  double? _pendingBrightness;
  double? _dragValue;
  double? _lastDispatchedBrightness;
  bool _isDragging = false;

  @override
  void dispose() {
    _throttleTimer?.cancel();
    super.dispose();
  }

  void _onChanged(BuildContext context, double val) {
    _isDragging = true;
    _dragValue = val;
    _pendingBrightness = val;
    if (_throttleTimer == null || !_throttleTimer!.isActive) {
      _dispatchBrightness(context, val);
      _startThrottleTimer(context);
    }
  }

  void _dispatchBrightness(BuildContext context, double val) {
    _lastDispatchedBrightness = val;
    context.read<DisplayBloc>().add(SetBrightness(val));
  }

  void _startThrottleTimer(BuildContext context) {
    _throttleTimer = Timer(_throttleDuration, () {
      if (!mounted) return;
      if (_pendingBrightness != null) {
        final valToSet = _pendingBrightness!;
        _pendingBrightness = null;
        if (valToSet != _lastDispatchedBrightness) {
          _dispatchBrightness(context, valToSet);
        }
        _startThrottleTimer(context);
      }
    });
  }

  void _onChangeStart(double val) {
    _isDragging = true;
    _dragValue = val;
  }

  void _onChangeEnd(BuildContext context, double val) {
    _throttleTimer?.cancel();
    _pendingBrightness = null;
    _isDragging = false;
    _dragValue = null;
    _dispatchBrightness(context, val);
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<DisplayBloc, DisplayState, double>(
      selector: (state) => state.brightness,
      builder: (context, brightness) {
        final displayValue = (_isDragging && _dragValue != null)
            ? _dragValue!
            : brightness;

        return MechanixSlider(
          value: displayValue.clamp(0.0, 1.0),
          min: 0,
          max: 1,
          size: MechanixSliderSize.medium,
          showValueLabel: false,
          onChangeStart: _onChangeStart,
          onChanged: (val) => _onChanged(context, val),
          onChangeEnd: (val) => _onChangeEnd(context, val),
        );
      },
    );
  }
}

class _AutoBrightnessSwitch extends StatelessWidget {
  const _AutoBrightnessSwitch();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocSelector<DisplayBloc, DisplayState, bool>(
      selector: (state) => state.isAutoBrightness,
      builder: (context, isAutoBrightness) {
        return MechanixSwitch(
          value: isAutoBrightness,
          labelOn: l10n.onToggle,
          labelOff: l10n.offToggle,
          onChanged: (val) {
            context.read<DisplayBloc>().add(SetAutoBrightness(val));
          },
        );
      },
    );
  }
}

class _ScreenTimeoutValue extends StatelessWidget {
  const _ScreenTimeoutValue();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocSelector<DisplayBloc, DisplayState, int>(
      selector: (state) => state.screenTimeout,
      builder: (context, screenTimeout) {
        return Text(
          getScreenTimeoutLabel(l10n, screenTimeout),
          style: theme.textTheme.titleLarge!.copyWith(
            color: theme.colorScheme.onPrimaryFixed,
          ),
        );
      },
    );
  }
}

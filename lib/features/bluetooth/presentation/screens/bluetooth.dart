import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/bluetooth/blocs/bluetooth_bloc.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/widgets/bluetooth/bluetooth_body.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/widgets/bluetooth/bluetooth_app_bar.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  final ScrollController _breadcrumbController = ScrollController();

  @override
  void dispose() {
    _breadcrumbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BluetoothBloc, BluetoothState>(
      builder: (context, state) {
        return Scaffold(
          appBar: BluetoothAppBar(breadcrumbController: _breadcrumbController),
          body: const BluetoothBody(),
          bottomNavigationBar: BottomBar(
            leading: CustomIconButton.asset(
              assetPath: SettingIcons.back,
              enabled: true,
              onPressed: () => Navigator.pop(context),
            ),
            trailing: state.isBluetoothOn
                ? [
                    CustomIconButton.asset(
                      assetPath: SettingIcons.refresh,
                      enabled: true,
                      onPressed: () {
                        context.read<BluetoothBloc>().add(
                          const ToggleBluetoothPower(true),
                        );
                      },
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }
}

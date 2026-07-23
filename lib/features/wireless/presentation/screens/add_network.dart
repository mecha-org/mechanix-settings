import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/add_network/add_network_appbar.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/add_network/add_network_body.dart';

class AddNetworkPage extends StatelessWidget {
  AddNetworkPage({super.key});

  final _formKey = GlobalKey<AddNetworkBodyState>();
  final _breadcrumbController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AddNetworkAppBar(breadcrumbController: _breadcrumbController),
      body: AddNetworkBody(key: _formKey),
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
            onPressed: () async {
              final success = await _formKey.currentState?.connect();

              if (success == true && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}

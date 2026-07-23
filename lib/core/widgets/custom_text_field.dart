import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? initialValue;

  final String hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final TextInputAction textInputAction;
  final TextInputType keyboardType;
  final bool obscureText;
  final String obscuringCharacter;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;

  const CustomTextField({
    super.key,
    this.controller,
    this.initialValue,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.focusNode,
    this.nextFocusNode,
    this.textInputAction = TextInputAction.next,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.obscuringCharacter = '•',
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
  }) : assert(
         controller != null || initialValue != null,
         'Either controller or initialValue must be provided',
       );

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late final TextEditingController _controller;
  late final bool _isInternalController;

  @override
  void initState() {
    super.initState();

    if (widget.controller != null) {
      _controller = widget.controller!;
      _isInternalController = false;
    } else {
      _controller = TextEditingController(text: widget.initialValue ?? '');
      _isInternalController = true;
    }
  }

  @override
  void dispose() {
    if (_isInternalController) {
      _controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: widget.enabled
                ? AppColors.backgroundVariant
                : AppColors.backgroundVariantDark,
            borderRadius: BorderRadius.circular(8),
            border: widget.errorText != null
                ? Border.all(
                    color: Theme.of(context).colorScheme.error,
                    width: 1.5,
                  )
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),

          child: TextField(
            controller: _controller,
            focusNode: widget.focusNode,
            enabled: widget.enabled,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            obscureText: widget.obscureText,
            obscuringCharacter: widget.obscuringCharacter,
            textAlignVertical: TextAlignVertical.center,
            style: Theme.of(context).textTheme.bodyLarge,

            onChanged: widget.onChanged,

            onSubmitted: (value) {
              if (widget.nextFocusNode != null) {
                FocusScope.of(context).requestFocus(widget.nextFocusNode);
              }

              widget.onSubmitted?.call(value);
            },

            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: widget.hintText,
              hintStyle: Theme.of(context).textTheme.displaySmall,

              prefixIcon: widget.prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 8, left: 8, top: 8),
                      child: widget.prefixIcon,
                    )
                  : null,

              suffixIcon: widget.suffixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 8, left: 8, top: 8),
                      child: widget.suffixIcon,
                    )
                  : null,
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ],
      ],
    );
  }
}

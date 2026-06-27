import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final int maxLines;

  const CustomTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 1,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _hidePassword = true;

  @override
  Widget build(BuildContext context) {
    final isPassword = widget.obscureText;

    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      onChanged: widget.onChanged,
      enabled: widget.enabled,
      maxLines: isPassword ? 1 : widget.maxLines,
      obscureText: isPassword ? _hidePassword : false,

      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
      ),

      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,

        prefixIcon: widget.icon != null
            ? Icon(
                widget.icon,
                color: AppColors.primary,
              )
            : null,

        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _hidePassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: AppColors.primary,
                ),
                onPressed: () {
                  setState(() {
                    _hidePassword = !_hidePassword;
                  });
                },
              )
            : null,
      ),
    );
  }
}
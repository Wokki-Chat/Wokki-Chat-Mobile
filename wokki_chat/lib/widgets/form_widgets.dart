import 'package:flutter/material.dart';

class FieldLabel extends StatelessWidget {
  final String label;
  final dynamic colors;
  const FieldLabel({super.key, required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: colors.textA20,
        letterSpacing: 0.2,
      ),
    );
  }
}

class InputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool enabled;
  final bool obscureText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final dynamic colors;
  final ValueChanged<String>? onSubmitted;

  const InputField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.prefixIcon,
    required this.colors,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    this.obscureText = false,
    this.suffixIcon,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      enabled: enabled,
      obscureText: obscureText,
      onSubmitted: onSubmitted,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        color: colors.textA0,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          color: colors.textA50,
        ),
        prefixIcon: Icon(prefixIcon, size: 20, color: colors.textA40),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: colors.inputBgDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.inputBorderBgDarkest),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: colors.inputBorderBgDarkest, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.primaryA0, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  final String message;
  final dynamic colors;
  const ErrorBanner({super.key, required this.message, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: colors.dangerA0.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.dangerA0.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: colors.dangerA10),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: colors.dangerA10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
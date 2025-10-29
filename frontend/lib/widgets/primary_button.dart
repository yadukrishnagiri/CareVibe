import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final Widget? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final child = isLoading
        ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
          )
        : (icon ?? const SizedBox.shrink());

    final buttonLabel = Text(isLoading ? 'Please wait…' : label);

    if (icon == null && !isLoading) {
      return ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 54),
          alignment: Alignment.center,
        ),
        child: buttonLabel,
      );
    }

    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: child,
      label: buttonLabel,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 54),
        alignment: Alignment.center,
      ),
    );
  }
}


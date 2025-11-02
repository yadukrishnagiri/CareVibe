import 'package:flutter/material.dart';

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
  });

  final VoidCallback? onPressed;
  final String label;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return DecoratedBox(
      decoration: BoxDecoration(boxShadow: [BoxShadow(color: primary.withOpacity(0.12), blurRadius: 14, offset: const Offset(0, 8))]),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon ?? const SizedBox.shrink(),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 54),
          side: BorderSide(color: primary, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          foregroundColor: primary,
          overlayColor: primary.withOpacity(0.08),
        ),
      ),
    );
  }
}


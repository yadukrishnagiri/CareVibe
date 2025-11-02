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

    final buttonLabel = Text(isLoading ? 'Please wait…' : label, style: const TextStyle(color: Colors.white));

    if (icon == null && !isLoading) {
      return DecoratedBox(
        decoration: BoxDecoration(boxShadow: [
          BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10))
        ]),
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 54),
            alignment: Alignment.center,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            overlayColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
          ),
          child: buttonLabel,
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10))
      ]),
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: child,
        label: buttonLabel,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 54),
          alignment: Alignment.center,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          overlayColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        ),
      ),
    );
  }
}


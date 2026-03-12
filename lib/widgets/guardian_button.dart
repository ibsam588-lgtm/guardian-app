import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GuardianButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final bool outline;
  final Color? color;
  final IconData? icon;

  const GuardianButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.outline = false,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppTheme.primaryBlue;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: outline
          ? OutlinedButton(
              onPressed: loading ? null : onTap,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: bg),
                foregroundColor: bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(label),
            )
          : ElevatedButton(
              onPressed: loading ? null : onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: bg,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(label),
            ),
    );
  }
}

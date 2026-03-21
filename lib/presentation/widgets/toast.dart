import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum ToastType { success, error, info, warning }

void showToast(BuildContext context, String message, ToastType type) {
  final colors = {
    ToastType.success: (AppColors.success, AppColors.successSurface),
    ToastType.error: (AppColors.error, AppColors.errorSurface),
    ToastType.info: (AppColors.info, const Color(0xFFEFF6FF)),
    ToastType.warning: (AppColors.warning, const Color(0xFFFFFBEB)),
  };

  final icons = {
    ToastType.success: Icons.check_circle_rounded,
    ToastType.error: Icons.cancel_rounded,
    ToastType.info: Icons.info_rounded,
    ToastType.warning: Icons.warning_rounded,
  };

  final (color, bg) = colors[type]!;
  final icon = icons[type]!;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: bg,
        duration: const Duration(seconds: 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}

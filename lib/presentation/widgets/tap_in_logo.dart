import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class TapInLogo extends StatelessWidget {
  final bool large;

  const TapInLogo({super.key, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'TAP-In',
          style: GoogleFonts.inter(
            fontSize: large ? 42 : 26,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: -2,
            color: AppColors.primary,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'KASIR DIGITAL',
          style: GoogleFonts.inter(
            fontSize: large ? 11 : 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
            color: AppColors.textTertiary,
            height: 1,
          ),
        ),
      ],
    );
  }
}

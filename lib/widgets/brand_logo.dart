import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The mark plus "eBarangay Mo" wordmark. Switches to the reversed
/// version automatically in dark mode.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.height = 48});

  final double height;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SvgPicture.asset(
      dark
          ? 'assets/logos/ebarangay-lockup-dark.svg'
          : 'assets/logos/ebarangay-lockup.svg',
      height: height,
      semanticsLabel: 'eBarangay Mo',
    );
  }
}

/// The mark alone: use it for anything under 120px wide.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SvgPicture.asset(
      dark
          ? 'assets/logos/ebarangay-mark-reversed.svg'
          : 'assets/logos/ebarangay-mark.svg',
      width: size,
      height: size,
      semanticsLabel: 'eBarangay Mo',
    );
  }
}

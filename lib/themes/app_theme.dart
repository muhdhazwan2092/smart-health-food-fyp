import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Brand tokens
// ---------------------------------------------------------------------------
// Palette inspired by fresh produce: deep basil green (trust, "healthy"),
// a warm turmeric-gold accent (energy, appetite), and a soft oat-cream
// background instead of stark white or the usual dark/near-black theme.
class AppColors {
  static const Color primary = Color(0xFF1F4D36); // deep basil green
  static const Color primaryDark = Color(0xFF12301F); // shadowed basil
  static const Color primaryLight = Color(0xFF3D7A5D); // fresh sage
  static const Color accent = Color(0xFFF2A93B); // turmeric gold
  static const Color accentSoft = Color(0xFFFCE2B8); // pale mango
  static const Color bg = Color(0xFFF6F2E7); // warm oat cream
  static const Color ink = Color(0xFF16241C); // near-black basil for text
  static const Color inkSoft = Color(0xFF5B6B62); // muted body text
}

// Signature shape: a "clipped tag corner" — every card, button and bubble in
// this app shares one noticeably sharper corner (bottom-left), echoing the
// torn corner of a nutrition label / produce tag. Keep the radius small on
// the sharp corner and generous everywhere else.
BorderRadius tagRadius({double r = 26, double sharp = 8}) => BorderRadius.only(
      topLeft: Radius.circular(r),
      topRight: Radius.circular(r),
      bottomRight: Radius.circular(r),
      bottomLeft: Radius.circular(sharp),
    );

// Global dark-mode toggle, shared across every screen.
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.system);

void toggleGlobalDarkMode() {
  themeModeNotifier.value = themeModeNotifier.value == ThemeMode.dark
      ? ThemeMode.light
      : ThemeMode.dark;
}

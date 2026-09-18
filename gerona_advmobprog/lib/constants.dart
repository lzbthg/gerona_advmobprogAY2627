import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

var host = dotenv.env['HOST'];

// LAB_ACT4 ENHANCEMENT (Brand Match):
// NUBD Exchange brand colors, sampled from the nubdexchange_logo.png crest
// (royal blue + gold), used to style the Splash, Sign In, and Profile
// screens so they match the school's branding.
class AppColors {
  static const Color navy = Color(0xFF1B2A78);
  static const Color navyDark = Color(0xFF121D57);
  static const Color gold = Color(0xFFFFC72C);
  static const Color logoutRed = Color(0xFFF1574C);
  static const Color lightBg = Color(0xFFF4F5FA);
}

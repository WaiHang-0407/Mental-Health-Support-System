import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData materialTheme = ThemeData(
    textTheme: GoogleFonts.montserratTextTheme().apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    primarySwatch: Colors.deepPurple,
    scaffoldBackgroundColor: Colors.transparent,

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0, // remove shadow
      titleTextStyle: GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
}

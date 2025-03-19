import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:memofante/discovered_words/pages/discovered_words.dart';
import 'package:google_fonts/google_fonts.dart';

class RootWidget extends StatelessWidget {
  const RootWidget({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color.fromARGB(255, 255, 106, 0);
    return MaterialApp(
      title: 'Memofante',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: primaryColor,
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color.fromARGB(255, 255, 182, 148),
          foregroundColor: Colors.black
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const DiscoveredWords(),
      debugShowCheckedModeBanner: false,
    );
  }
}

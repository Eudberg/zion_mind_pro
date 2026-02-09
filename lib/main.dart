import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'screens/tela_inicial.dart';
import 'controllers/estudo_controller.dart';
import 'controllers/trilha_controller.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EstudoController()),
        ChangeNotifierProvider(create: (_) => TrilhaController()),
      ],
      child: const ZionMindPro(),
    ),
  );
}

class ZionMindPro extends StatelessWidget {
  const ZionMindPro({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZionMindPro',
      debugShowCheckedModeBanner: false,

      // TEMA (100% preservado)
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF6366F1),

        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF2DD4BF),
          surface: Color(0xFF1E293B),
          error: Color(0xFFF43F5E),
        ),

        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),

      home: const TelaInicial(),
    );
  }
}

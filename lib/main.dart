import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/tela_inicial.dart';

void main() {
  runApp(ZionMindPro());
}

class ZionMindPro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZionMindPro',
      debugShowCheckedModeBanner: false,

      // CONFIGURAÇÃO DO TEMA DARK/MODERNO
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF0F172A), // Midnight Indigo (Fundo)
        primaryColor: Color(0xFF6366F1), // Indigo Vívido
        // Cores do esquema (Isso aqui já pinta os Cards automaticamente)
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF2DD4BF), // Electric Teal
          surface: Color(0xFF1E293B), // Cor dos Cards e Superfícies
          error: Color(0xFFF43F5E), // Sunset Orange
        ),

        // Configuração de Fontes
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
        ),

        // Estilo dos Botões
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF6366F1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),

      home: TelaInicial(), // Sua tela inicial
    );
  }
}

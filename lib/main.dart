import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/tela_inicial.dart';
import 'controllers/trilha_controller.dart';
import 'controllers/estudo_controller.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // Provedor do controlador antigo
        ChangeNotifierProvider(create: (_) => EstudoController()),

        // Provedor central da Trilha Estratégica (Lógica)
        ChangeNotifierProvider(create: (_) => TrilhaController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zion Mind Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
        primaryColor: const Color(0xFF1E293B), // Slate 800
        colorScheme: const ColorScheme.dark(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
          surface: Color(0xFF1E293B), // Background dos cards
        ),
        useMaterial3: true,
      ),
      // Apontando corretamente para a classe de interface (UI)
      home: const TelaInicial(),
    );
  }
}

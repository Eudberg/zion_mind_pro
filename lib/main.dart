import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/tela_inicial.dart';
import 'controllers/trilha_controller.dart';
import 'controllers/estudo_controller.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EstudoController()),
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
      title: 'Iterum',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.midnightBlueEmerald,
      home: const TelaInicial(),
    );
  }
}

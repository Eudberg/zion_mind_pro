import 'package:flutter/material.dart';
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
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: TelaInicial(), // Aqui chamamos a sua tela
    );
  }
}

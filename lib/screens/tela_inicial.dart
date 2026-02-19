import 'package:flutter/material.dart';

import 'tela_inicio.dart';
import 'tela_trilha.dart';
import 'tela_revisoes.dart';
import 'tela_estatisticas.dart';
import 'tela_configuracoes.dart';

// NOVO:
import '../widgets/iterum_title.dart';

// CORREÇÃO: A classe agora se chama TelaInicial para não conflitar com o TrilhaController
class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  int _selectedIndex = 0;

  // Lista das telas principais que serão exibidas em cada aba
  final List<Widget> _telas = [
    const TelaInicio(), // Índice 0: Dashboard
    const TelaTrilha(), // Índice 1: Lista de tarefas organizada em blocos de 25
    const TelaRevisoes(), // Índice 2: Calendário de revisões agendadas
    const TelaEstatisticas(), // Índice 3: Métricas de desempenho e tempo
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
title: Image.asset(
          'assets/branding/iterum_logo.png',
          height: 28,
          fit: BoxFit.contain,
        ),
        actions: [
          // Botão de Engrenagem para acessar Importação e Configurações
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configurações e Importação',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TelaConfiguracoes(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      // O IndexedStack preserva o estado (scroll, etc) de cada aba ao alternar
      body: IndexedStack(index: _selectedIndex, children: _telas),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType
            .fixed, // Garante que os rótulos sempre apareçam
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.home_outlined),
            ),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.list_alt),
            ),
            label: 'Trilha',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.loop),
            ),
            label: 'Revisões',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.bar_chart),
            ),
            label: 'Métricas',
          ),
        ],
      ),
    );
  }
}

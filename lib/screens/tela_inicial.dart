import 'package:flutter/material.dart';
import 'tela_trilha.dart';
import 'tela_revisoes.dart';
import 'tela_estatisticas.dart';
import 'tela_configuracoes.dart';

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
    const TelaTrilha(), // Índice 0: Lista de tarefas organizada em blocos de 25
    const TelaRevisoes(), // Índice 1: Calendário de revisões agendadas
    const TelaEstatisticas(), // Índice 2: Métricas de desempenho e tempo
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
        backgroundColor: const Color(0xFF1E293B), // Slate 800
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Zion Mind Pro',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          // Botão de Engrenagem para acessar Importação e Configurações
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
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
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: Colors.blue[400],
        unselectedItemColor: Colors.grey[500],
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

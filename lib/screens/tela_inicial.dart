import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/sessao_estudo.dart';
import '../widgets/modal_cadastro.dart';
import 'tela_cronometro.dart';
import 'tela_questoes.dart';
import 'tela_estatisticas.dart';
import 'package:flutter/material.dart';

class TelaInicial extends StatelessWidget {
  const TelaInicial({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // dark blue/gray
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text(
          'Dashboard de Estudos',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _ResumoGeral(),
            SizedBox(height: 16),
            _ProgressoGeral(),
            SizedBox(height: 16),
            _Disciplinas(),
          ],
        ),
      ),
    );
  }
}

class _ResumoGeral extends StatelessWidget {
  const _ResumoGeral();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _CardResumo(
          titulo: 'Horas estudadas',
          valor: '42h',
          icone: Icons.schedule,
        ),
        SizedBox(width: 12),
        _CardResumo(
          titulo: 'Dias ativos',
          valor: '18',
          icone: Icons.calendar_today,
        ),
      ],
    );
  }
}

class _CardResumo extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;

  const _CardResumo({
    required this.titulo,
    required this.valor,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: Colors.blueAccent),
            const SizedBox(height: 12),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(titulo, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _ProgressoGeral extends StatelessWidget {
  const _ProgressoGeral();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progresso Geral',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.65,
              minHeight: 10,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.greenAccent,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '65% do planejamento concluído',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _Disciplinas extends StatelessWidget {
  const _Disciplinas();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Disciplinas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        _item('Direito Constitucional', 0.8),
        _item('Português', 0.6),
        _item('Raciocínio Lógico', 0.4),
      ],
    );
  }

  Widget _item(String nome, double progresso) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nome,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.blueAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

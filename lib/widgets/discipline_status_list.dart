//discipline_status_list//
import 'package:flutter/material.dart';

class DisciplineStatusList extends StatelessWidget {
  const DisciplineStatusList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Disciplinas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        _item('Direito Constitucional', 'Em revisão', Colors.amber),
        _item('Administrativo', 'Atrasado', Colors.purple),
        _item('Português', 'Em dia', Colors.green),
        _item('Informática', 'Negligenciado', Colors.redAccent),
      ],
    );
  }

  Widget _item(String nome, String status, Color cor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(nome, style: const TextStyle(color: Colors.white)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(status, style: TextStyle(color: cor, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

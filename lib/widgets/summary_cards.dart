//summary_cards//

import 'package:flutter/material.dart';
import 'info_card.dart';

class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        InfoCard(
          titulo: 'Tempo estudado',
          valor: '2h30',
          subtitulo: '+1h hoje',
          icone: Icons.timer,
          cor: Colors.blue,
        ),
        InfoCard(
          titulo: 'Sessões',
          valor: '4',
          subtitulo: 'Hoje',
          icone: Icons.menu_book,
          cor: Colors.purple,
        ),
        InfoCard(
          titulo: 'Revisões',
          valor: '3',
          subtitulo: 'Pendentes',
          icone: Icons.refresh,
          cor: Colors.orange,
        ),
        InfoCard(
          titulo: 'Erros',
          valor: '56%',
          subtitulo: 'Último simulado',
          icone: Icons.close,
          cor: Colors.redAccent,
        ),
      ],
    );
  }
}

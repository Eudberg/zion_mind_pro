import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import '../database/db_helper.dart';
import '../models/sessao_estudo.dart';
import '../models/questao.dart';

class TelaEstatisticas extends StatefulWidget {
  @override
  _TelaEstatisticasState createState() => _TelaEstatisticasState();
}

class _TelaEstatisticasState extends State<TelaEstatisticas> {
  // Variáveis para guardar os totais
  int _totalMinutos = 0;
  int _totalQuestoes = 0; // CORRIGIDO: Sem acento (era _totalQuestões)
  double _mediaAcertos = 0.0;
  Map<DateTime, int> _datasetHeatmap = {};
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  void _carregarDados() async {
    final sessoes = await DbHelper.instance.listarSessoes();
    final questoes = await DbHelper.instance.listarQuestoes();

    // 1. Calcula Total de Tempo
    int minutos = 0;
    Map<DateTime, int> heatmap = {};

    for (var s in sessoes) {
      minutos += s.minutos;

      // Normaliza a data (remove hora) para o Heatmap somar o dia todo
      final dataLimpa = DateTime(s.data.year, s.data.month, s.data.day);
      heatmap[dataLimpa] = (heatmap[dataLimpa] ?? 0) + s.minutos;
    }

    // 2. Calcula Desempenho em Questões
    int totalQ = 0;
    int totalA = 0;
    for (var q in questoes) {
      totalQ += q.qtdFeitas;
      totalA += q.qtdAcertos;
    }
    double media = totalQ > 0 ? (totalA / totalQ) * 100 : 0.0;

    // Atualiza a tela
    if (mounted) {
      setState(() {
        _totalMinutos = minutos;
        _datasetHeatmap = heatmap;
        _totalQuestoes = totalQ; // CORRIGIDO: Sem acento
        _mediaAcertos = media;
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard de Comando'),
        backgroundColor: Colors.transparent,
      ),
      body: _carregando
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. O MAPA DE CALOR (CONSTÂNCIA)
                  Text(
                    "Constância (Minutos)",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: HeatMap(
                        datasets: _datasetHeatmap,
                        colorMode: ColorMode.opacity,
                        showText: false,
                        scrollable: true,
                        colorsets: {
                          1: Colors.indigo.shade100,
                          30: Colors.indigo.shade300,
                          60: Colors
                              .indigo
                              .shade500, // Meta: 1h por dia fica escurinho
                          120: Colors.greenAccent, // 2h ou mais fica verde
                        },
                        onClick: (value) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Dia produtivo: $value mins'),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 30),

                  // 2. OS INDICADORES (KPIs)
                  Text(
                    "Indicadores Gerais",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      _buildKPI(
                        "Horas",
                        (_totalMinutos / 60).toStringAsFixed(1),
                        Icons.timer,
                        Colors.blue,
                      ),
                      SizedBox(width: 10),
                      _buildKPI(
                        "Questões",
                        _totalQuestoes.toString(),
                        Icons.quiz,
                        Colors.orange,
                      ), // CORRIGIDO
                    ],
                  ),
                  SizedBox(height: 10),
                  _buildKPI(
                    "Precisão Global",
                    "${_mediaAcertos.toStringAsFixed(1)}%",
                    Icons.gps_fixed,
                    _getCorDesempenho(_mediaAcertos),
                    fullWidth: true,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildKPI(
    String titulo,
    String valor,
    IconData icone,
    Color cor, {
    bool fullWidth = false,
  }) {
    return Expanded(
      flex: fullWidth ? 0 : 1,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: cor, size: 30),
            SizedBox(height: 10),
            Text(
              valor,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(titulo, style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Color _getCorDesempenho(double media) {
    if (media >= 80) return Colors.greenAccent;
    if (media >= 60) return Colors.amber;
    return Colors.redAccent;
  }
}

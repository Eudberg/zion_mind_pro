import 'dart:async';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../services/cronometro_service.dart';
import '../database/db_helper.dart';
import '../models/sessao_estudo.dart';

class TelaCronometro extends StatefulWidget {
  @override
  _TelaCronometroState createState() => _TelaCronometroState();
}

class _TelaCronometroState extends State<TelaCronometro> {
  final CronometroService _service = CronometroService();
  final TextEditingController _materiaController = TextEditingController();

  Timer? _timer;
  Duration _tempoAtual = Duration.zero;
  bool _estaRodando = false;

  @override
  void initState() {
    super.initState();
    _sincronizarTempo();
    // Atualiza a tela a cada segundo
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_estaRodando) _sincronizarTempo();
    });
  }

  void _sincronizarTempo() async {
    final tempo = await _service.getTempoAtual();
    final rodando = await _service.estaRodando();
    setState(() {
      _tempoAtual = tempo;
      _estaRodando = rodando;
    });
  }

  void _toggleCronometro() async {
    if (_estaRodando) {
      await _service.pausar();
    } else {
      await _service.iniciar();
    }
    _sincronizarTempo();
  }

  void _salvarSessao() async {
    if (_materiaController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Digite uma matéria!')));
      return;
    }

    await _service.pausar(); // Garante que parou
    final minutos = _tempoAtual.inMinutes;

    if (minutos > 0) {
      final sessao = SessaoEstudo(
        materia: _materiaController.text,
        data: DateTime.now(),
        minutos: minutos,
      );
      await DbHelper.instance.inserirSessao(sessao);

      // Limpa tudo
      await _service.resetar();
      _materiaController.clear();
      setState(() {
        _tempoAtual = Duration.zero;
        _estaRodando = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Estudo salvo com sucesso!')));
      Navigator.pop(context, true); // Volta para a home atualizando
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Estude pelo menos 1 minuto!')));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatarTempo(Duration d) {
    String doisDigitos(int n) => n.toString().padLeft(2, "0");
    String horas = doisDigitos(d.inHours);
    String minutos = doisDigitos(d.inMinutes.remainder(60));
    String segundos = doisDigitos(d.inSeconds.remainder(60));
    return "$horas:$minutos:$segundos";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modo Foco'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              // O GRÁFICO CIRCULAR
              CircularPercentIndicator(
                radius: 120.0,
                lineWidth: 15.0,
                percent:
                    (_tempoAtual.inSeconds % 60) / 60, // Animação dos segundos
                center: Text(
                  _formatarTempo(_tempoAtual),
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                progressColor: Theme.of(
                  context,
                ).colorScheme.secondary, // Electric Teal
                backgroundColor: Theme.of(context).colorScheme.surface,
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
                animateFromLastPercent: true,
              ),
              SizedBox(height: 40),

              // INPUT DA MATÉRIA
              TextField(
                controller: _materiaController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Qual o foco de hoje? (Ex: RLM)',
                  labelStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 40),

              // BOTÕES DE AÇÃO
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botão PLAY / PAUSE
                  FloatingActionButton.large(
                    onPressed: _toggleCronometro,
                    backgroundColor: _estaRodando
                        ? Colors.orange
                        : Theme.of(context).primaryColor,
                    child: Icon(
                      _estaRodando ? Icons.pause : Icons.play_arrow,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 20),
                  // Botão STOP (SALVAR)
                  if (_tempoAtual.inSeconds > 0)
                    FloatingActionButton(
                      onPressed: _salvarSessao,
                      backgroundColor: Colors.redAccent,
                      child: Icon(Icons.stop, color: Colors.white),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

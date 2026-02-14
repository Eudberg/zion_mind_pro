import 'dart:async';
import 'package:flutter/material.dart';
import '../models/disciplina.dart';
import '../models/tarefa_trilha.dart';

class EstudoController extends ChangeNotifier {
  Disciplina? disciplinaAtiva;
  int? _tarefaAtivaId;
  Timer? _timer;
  int segundosSessao = 0;

  bool get estudando => _timer != null;
  int? get tarefaAtivaId => _tarefaAtivaId;

  void iniciarSessao(Disciplina disciplina, {int? tarefaId}) {
    disciplinaAtiva = disciplina;
     _tarefaAtivaId = tarefaId;
    segundosSessao = 0;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      segundosSessao++;
      notifyListeners();
    });

    notifyListeners();
  }

  void iniciarSessaoTarefa(TarefaTrilha tarefa) {
    iniciarSessao(
      Disciplina(
        nome: tarefa.disciplina,
        minutosEstudados: tarefa.chEfetivaMin ?? 0,
      ),
      tarefaId: tarefa.id,
    );
  }

void pausarOuRetomar() {
    if (disciplinaAtiva == null) return;

    if (_timer != null) {
      // Pausar
      _timer?.cancel();
      _timer = null;
    } else {
      // Retomar
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        segundosSessao++;
        notifyListeners();
      });
    }

    notifyListeners();
  }

  int finalizarSessaoEmMinutos() {
    _timer?.cancel();
    _timer = null;
     final minutosBrutos = (segundosSessao / 60).round();
    final minutos = minutosBrutos == 0 && segundosSessao > 0
        ? 1
        : minutosBrutos;

    if (disciplinaAtiva != null) {
      disciplinaAtiva!.minutosEstudados += minutos;
    }

    disciplinaAtiva = null;
    _tarefaAtivaId = null;
    segundosSessao = 0;
    notifyListeners();
    return minutos;
  }

  void finalizarSessao() {
    finalizarSessaoEmMinutos();
  }
}

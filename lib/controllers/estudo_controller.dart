import 'dart:async';
import 'package:flutter/material.dart';
import '../models/disciplina.dart';
import '../models/tarefa_trilha.dart';


class EstudoController extends ChangeNotifier {
  Disciplina? disciplinaAtiva;
  int? _tarefaAtivaId;
  int? _tarefaAtivaOrdemGlobal;
  String? _tarefaAtivaDisciplina;
  String? _tarefaAtivaAssunto;
  Timer? _timer;
  int segundosSessao = 0;

  int _segundosAcumulados = 0;
  DateTime? _inicioContagem;

  bool get estudando => _timer != null;
  int? get tarefaAtivaId => _tarefaAtivaId;
  int? get tarefaAtivaOrdemGlobal => _tarefaAtivaOrdemGlobal;
  String? get tarefaAtivaDisciplina => _tarefaAtivaDisciplina;
  String? get tarefaAtivaAssunto => _tarefaAtivaAssunto;

  void iniciarSessao(Disciplina disciplina, {int? tarefaId}) {
    disciplinaAtiva = disciplina;
    _tarefaAtivaId = tarefaId;
    _tarefaAtivaOrdemGlobal = null;
    _tarefaAtivaDisciplina = null;
    _tarefaAtivaAssunto = null;
    segundosSessao = 0;
    _segundosAcumulados = 0;
    _inicioContagem = DateTime.now();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final inicio = _inicioContagem;
      if (inicio != null) {
        segundosSessao =
            _segundosAcumulados + DateTime.now().difference(inicio).inSeconds;
      }
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
    _tarefaAtivaOrdemGlobal = tarefa.ordemGlobal;
    _tarefaAtivaDisciplina = tarefa.disciplina;
    _tarefaAtivaAssunto = tarefa.assunto;
    notifyListeners();
  }

void pausarOuRetomar() {
    if (disciplinaAtiva == null) return;

    if (_timer != null) {
      final inicio = _inicioContagem;
      if (inicio != null) {
        _segundosAcumulados += DateTime.now().difference(inicio).inSeconds;
      }
      segundosSessao = _segundosAcumulados;
      _inicioContagem = null;
      _timer?.cancel();
      _timer = null;
    } else {
      _inicioContagem = DateTime.now();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        final inicio = _inicioContagem;
        if (inicio != null) {
          segundosSessao =
              _segundosAcumulados + DateTime.now().difference(inicio).inSeconds;
        }
        notifyListeners();
      });
    }

    notifyListeners();  
    }

  int finalizarSessaoEmMinutos() {
    final tinhaSessao = disciplinaAtiva != null;

    int elapsedMs = _segundosAcumulados * 1000;
    final inicio = _inicioContagem;
    if (inicio != null) {
      elapsedMs += DateTime.now().difference(inicio).inMilliseconds;
    } 
    _timer?.cancel();
    _timer = null;
    int minutos = 0;
    if (elapsedMs > 0) {
      // Regras: qualquer estudo >0s conta ao menos 1 minuto.
      minutos = (elapsedMs / 60000).round();
      if (minutos == 0) minutos = 1;
    }
    if (tinhaSessao && disciplinaAtiva != null) {
      disciplinaAtiva!.minutosEstudados += minutos;
    }
    disciplinaAtiva = null;
    _tarefaAtivaId = null;
    _tarefaAtivaOrdemGlobal = null;
    _tarefaAtivaDisciplina = null;
    _tarefaAtivaAssunto = null;
    segundosSessao = 0;
    _segundosAcumulados = 0;
    _inicioContagem = null;
    notifyListeners();

    return minutos;
  }
  

  void finalizarSessao() {
    finalizarSessaoEmMinutos();
  }
}

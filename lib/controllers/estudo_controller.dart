import 'dart:async';
import 'package:flutter/material.dart';
import '../models/disciplina.dart';

class EstudoController extends ChangeNotifier {
  Disciplina? disciplinaAtiva;
  Timer? _timer;
  int segundosSessao = 0;

  bool get estudando => _timer != null;

  void iniciarSessao(Disciplina disciplina) {
    disciplinaAtiva = disciplina;
    segundosSessao = 0;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      segundosSessao++;
      notifyListeners();
    });

    notifyListeners();
  }

  void pausarOuRetomar() {
    if (_timer == null) return;
    // Pause = cancela timer; Retomar = reinicia timer
    // (vamos simplificar: se estiver rodando, pausa; se não, retoma)
  }

  void finalizarSessao() {
    _timer?.cancel();
    _timer = null;

    if (disciplinaAtiva != null) {
      // Converte segundos em minutos (arredonda pra cima se passou de 30s)
      final minutos = (segundosSessao / 60).round();
      disciplinaAtiva!.minutosEstudados += minutos == 0 && segundosSessao > 0
          ? 1
          : minutos;
    }

    disciplinaAtiva = null;
    segundosSessao = 0;
    notifyListeners();
  }
}

import 'package:shared_preferences/shared_preferences.dart';

class CronometroService {
  static const String _keyInicio = 'inicio_timestamp';
  static const String _keyAcumulado = 'tempo_acumulado';
  static const String _keyRodando = 'esta_rodando';

  // Inicia (ou retoma) a contagem
  Future<void> iniciar() async {
    final prefs = await SharedPreferences.getInstance();
    // Salva o momento exato de AGORA
    await prefs.setInt(_keyInicio, DateTime.now().millisecondsSinceEpoch);
    await prefs.setBool(_keyRodando, true);
  }

  // Pausa e salva o que já passou
  Future<void> pausar() async {
    final prefs = await SharedPreferences.getInstance();
    final inicio = prefs.getInt(_keyInicio) ?? 0;
    final acumuladoAnterior = prefs.getInt(_keyAcumulado) ?? 0;

    // Calcula quanto tempo passou desde o início até agora
    final agora = DateTime.now().millisecondsSinceEpoch;
    final diferenca = agora - inicio;

    // Guarda no "banco"
    await prefs.setInt(_keyAcumulado, acumuladoAnterior + diferenca);
    await prefs.setBool(_keyRodando, false);
  }

  // Reseta tudo (Stop)
  Future<void> resetar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyInicio);
    await prefs.remove(_keyAcumulado);
    await prefs.remove(_keyRodando);
  }

  // A mágica: Calcula o tempo total para mostrar na tela
  Future<Duration> getTempoAtual() async {
    final prefs = await SharedPreferences.getInstance();
    final acumulado = prefs.getInt(_keyAcumulado) ?? 0;
    final estaRodando = prefs.getBool(_keyRodando) ?? false;

    if (estaRodando) {
      final inicio = prefs.getInt(_keyInicio) ?? 0;
      final agora = DateTime.now().millisecondsSinceEpoch;
      return Duration(milliseconds: acumulado + (agora - inicio));
    } else {
      return Duration(milliseconds: acumulado);
    }
  }

  Future<bool> estaRodando() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRodando) ?? false;
  }
}

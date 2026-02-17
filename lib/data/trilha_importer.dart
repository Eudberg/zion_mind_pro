import 'dart:convert';
import 'package:csv/csv.dart';
import '../models/tarefa_trilha.dart';

class TrilhaImporter {
  Future<List<TarefaTrilha>> importarBytes(List<int> bytes) async {
    String conteudo;
    try {
      conteudo = utf8.decode(bytes);
    } catch (_) {
      conteudo = latin1.decode(bytes);
    }

    // Observação: alguns CSVs vêm com \r\n. O conversor normalmente lida,
    // mas vamos manter eol '\n' como você já fez.
    final linhas = const CsvToListConverter(
      fieldDelimiter: ',',
      eol: '\n',
      shouldParseNumbers: false, // mantém strings; a gente parseia manualmente
    ).convert(conteudo);

    final tarefas = <TarefaTrilha>[];

    for (var i = 0; i < linhas.length; i++) {
      final linha = linhas[i];
      if (linha.isEmpty) continue;

      // Precisamos pelo menos até a coluna 7 (TAREFAS/instruções).
      if (linha.length < 8) continue;

      final col0 = _cell(
        linha,
        0,
      ).toUpperCase(); // TRILHA (cabeçalho ou "Trilha 0")
      final col2 = _cell(
        linha,
        2,
      ).toUpperCase(); // TAREFA (cabeçalho) ou número
      final col3 = _cell(
        linha,
        3,
      ).toUpperCase(); // DISCIPLINA (cabeçalho) ou conteúdo

      // ✅ Cabeçalho: não use contains, senão mata "Trilha 0".
      final isHeader =
          (col0.trim() == 'TRILHA') ||
          (col2.trim() == 'TAREFA') ||
          (col3.trim() == 'DISCIPLINA');
      if (isHeader) continue;

      // Ignorar linhas de "DESCANSO" (se existirem)
      if (col0.trim() == 'DESCANSO') continue;

      final numTarefaRaw = _cell(linha, 2).trim(); // TAREFA
      final disciplinaRaw = _cell(linha, 3).trim(); // DISCIPLINA
      final chRaw = _cell(linha, 4).trim(); // CH (planejada) ex: 1:00
      final chEfetivaRaw = _cell(linha, 5).trim(); // CH (EFETIVA) ex: 0:30
      final instrucoes = _cell(linha, 7).trim(); // TAREFAS (instruções)

      // Linha sem número e sem disciplina: ignora
      if (numTarefaRaw.isEmpty && disciplinaRaw.isEmpty) continue;

      final ordem = int.tryParse(numTarefaRaw);
      if (ordem == null || ordem <= 0) {
        // Se não tem número válido, ignora (pra manter trilha por faixa de 25 correta)
        continue;
      }

      final disciplina = disciplinaRaw.isEmpty
          ? 'GERAL'
          : disciplinaRaw.toUpperCase();

      // Opção 1: assunto curto e padronizado
      final assunto = '$disciplina — #$ordem';

      // CH planejada/efetiva
      final chPlanejadaMin = _parseDuracaoParaMinutos(chRaw) ?? 60;
      final chEfetivaMin = _parseDuracaoParaMinutos(chEfetivaRaw) ?? 0;

      // Cálculo da trilha por blocos de 25
      final trilhaIndex = (ordem - 1) ~/ 25;
      final trilhaNome = 'Trilha $trilhaIndex';

      final tarefa = TarefaTrilha(
        id: null,
        ordemGlobal: ordem,
        disciplina: disciplina,
        assunto: assunto,
        descricao: instrucoes, // ✅ instruções do que fazer
        duracaoMinutos: chPlanejadaMin, // se você usa esse campo, alinha com CH
        chPlanejadaMin: chPlanejadaMin,
        concluida: false,
        trilha: trilhaNome,
        tarefaCodigo: numTarefaRaw,
        chEfetivaMin: chEfetivaMin,
        // Se seu model tiver esses campos e você quiser importar:
        // fonteQuestoes, questoes, acertos, dataConclusao etc. podem ser mapeados depois.
      );

      tarefas.add(tarefa);
    }

    return tarefas;
  }

  String _cell(List<dynamic> row, int index) {
    if (index < 0 || index >= row.length) return '';
    final v = row[index];
    if (v == null) return '';
    return v.toString();
  }

  /// Aceita:
  /// - "1:00" -> 60
  /// - "0:30" -> 30
  /// - "90"   -> 90
  /// - ""     -> null
  int? _parseDuracaoParaMinutos(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;

    // Formato H:MM
    if (s.contains(':')) {
      final parts = s.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0].trim()) ?? 0;
        final m = int.tryParse(parts[1].trim()) ?? 0;
        return (h * 60) + m;
      }
    }

    // Formato numérico simples
    return int.tryParse(s);
  }
}

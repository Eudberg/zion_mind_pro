import 'dart:convert';
import 'dart:typed_data';

import '../models/tarefa_trilha.dart';

class TrilhaImporter {
  /// Importa um CSV (bytes) e devolve tarefas prontas para inserir no banco.
  ///
  /// Regras:
  /// - Ordem global: 1..N (sequencial).
  /// - trilha 0 => tarefas 1..25; trilha 1 => 26..50; etc.
  /// - tarefaCodigo é a posição dentro da trilha (1..25).
  /// - Data vem do CSV (estável), não “hoje”.
  Future<List<TarefaTrilha>> importarBytes(Uint8List bytes) async {
    final raw = _decodeSmart(bytes);
    final rows = _parseCsv(raw);

    if (rows.isEmpty) return [];

    // Primeira linha é header
    final header = rows.first.map((e) => e.trim()).toList();
    final headerNorm = header.map(_normKey).toList();

    String cell(List<String> row, List<String> aliases) {
      for (final a in aliases) {
        final idx = headerNorm.indexOf(_normKey(a));
        if (idx >= 0 && idx < row.length) return row[idx].trim();
      }
      return '';
    }

    int? toInt(String s) {
      final t = s.trim();
      if (t.isEmpty) return null;
      return int.tryParse(t.replaceAll(RegExp(r'[^0-9\-]'), ''));
    }

    DateTime? toDate(String s) {
      final t = s.trim();
      if (t.isEmpty) return null;

      // tenta dd/MM/yyyy
      final m = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(t);
      if (m != null) {
        final d = int.parse(m.group(1)!);
        final mo = int.parse(m.group(2)!);
        final y = int.parse(m.group(3)!);
        return DateTime(y, mo, d);
      }

      // tenta ISO
      return DateTime.tryParse(t);
    }

    int toMinFromCH(String s) {
      final t = s.trim();
      if (t.isEmpty) return 0;

      // aceita "60", "1h", "1h00", "1:00", "90min"
      final onlyNum = int.tryParse(t.replaceAll(RegExp(r'[^0-9]'), ''));
      if (onlyNum != null && !t.contains('h') && !t.contains(':')) {
        return onlyNum;
      }

      final hm = RegExp(r'(\d+)\s*h\s*(\d+)?').firstMatch(t.toLowerCase());
      if (hm != null) {
        final h = int.parse(hm.group(1)!);
        final m = int.tryParse(hm.group(2) ?? '0') ?? 0;
        return (h * 60) + m;
      }

      final col = RegExp(r'^(\d+):(\d+)$').firstMatch(t);
      if (col != null) {
        final h = int.parse(col.group(1)!);
        final m = int.parse(col.group(2)!);
        return (h * 60) + m;
      }

      return onlyNum ?? 0;
    }

    final tasks = <TarefaTrilha>[];

    // A partir da 2ª linha
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;
      if (row.every((e) => e.trim().isEmpty)) continue;

      // DISCIPLINA
      final disciplina = cell(row, [
        'DISCIPLINA',
        'DISCIPLÍNA',
        'MATÉRIA',
        'MATERIA',
      ]).trim();

      // DESCRIÇÃO: sua planilha usa "TAREFAS" como descrição
      final descricao = cell(row, [
        'TAREFAS',
        'DESCRICAO',
        'DESCRIÇÃO',
        'DESCRICAO DA TAREFA',
        'DESCRIÇÃO DA TAREFA',
        'ATIVIDADE',
      ]).trim();

      // Data estável do CSV
      final dataPlanejada = toDate(
        cell(row, ['DATA', 'DATA PLANEJADA', 'DATA_PLANEJADA']),
      );

      // CH
      final chMin = toMinFromCH(
        cell(row, [
          'CH',
          'CARGA HORARIA',
          'CARGA HORÁRIA',
          'CH PLANEJADA',
          'CH_PLANEJADA',
        ]),
      );

      // Ordem global: se o CSV tiver, respeita; se não, usa sequência.
      final ordemCsv = toInt(
        cell(row, ['ORDEM_GLOBAL', 'ORDEM GLOBAL', 'ORDEM', 'N', 'NUM']),
      );
      final ordemGlobal =
          ordemCsv ?? i; // i já começa em 1 na primeira linha de dados

      // trilha e posição 1..25
      final trilhaNum = (ordemGlobal - 1) ~/ 25;
      final posNaTrilha = ((ordemGlobal - 1) % 25) + 1;

      // especiais
      final isDescanso = _isDescanso(disciplina, descricao);
      final isLimparErros = _isLimparErros(disciplina, descricao);

      tasks.add(
        TarefaTrilha(
          trilha: 'TRILHA $trilhaNum',
          ordemGlobal: ordemGlobal,
          tarefaCodigo: posNaTrilha.toString(), // 1..25
          disciplina: disciplina,
          descricao: descricao.isEmpty ? '' : descricao,
          dataPlanejada: dataPlanejada,
          chPlanejadaMin: chMin == 0 ? null : chMin,
          concluida: false,
        ),
      );
    }

    // GARANTE sequencial global (1..N), mesmo que CSV venha bagunçado
    tasks.sort((a, b) => (a.ordemGlobal ?? 0).compareTo(b.ordemGlobal ?? 0));

    for (var idx = 0; idx < tasks.length; idx++) {
      final og = idx + 1;
      final trilhaNum = (og - 1) ~/ 25;
      final posNaTrilha = ((og - 1) % 25) + 1;

      tasks[idx] = tasks[idx].copyWith(
        ordemGlobal: og,
        trilha: 'TRILHA $trilhaNum',
        tarefaCodigo: posNaTrilha.toString(),
      );
    }

    return tasks;
  }

  // ---------- helpers CSV ----------

  String _decodeSmart(Uint8List bytes) {
    // tenta UTF-8, senão latin1
    try {
      final s = utf8.decode(bytes);
      return s;
    } catch (_) {
      return latin1.decode(bytes);
    }
  }

  List<List<String>> _parseCsv(String s) {
    final t = s.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // detecta separador
    final comma = ','.allMatches(t).length;
    final semi = ';'.allMatches(t).length;
    final sep = semi > comma ? ';' : ',';

    final lines = t.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final out = <List<String>>[];

    for (final line in lines) {
      out.add(_splitCsvLine(line, sep));
    }
    return out;
  }

  List<String> _splitCsvLine(String line, String sep) {
    final res = <String>[];
    final sb = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final c = line[i];

      if (c == '"') {
        // "" => "
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          sb.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }

      if (!inQuotes && c == sep) {
        res.add(sb.toString());
        sb.clear();
        continue;
      }

      sb.write(c);
    }

    res.add(sb.toString());
    return res;
  }

  String _normKey(String s) {
    final t = s
        .replaceAll('\uFEFF', '') // BOM
        .trim()
        .toUpperCase();

    // remove acentos básicos
    return t
        .replaceAll('Á', 'A')
        .replaceAll('À', 'A')
        .replaceAll('Â', 'A')
        .replaceAll('Ã', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Ê', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ô', 'O')
        .replaceAll('Õ', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('Ç', 'C')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _isDescanso(String disciplina, String descricao) {
    final a = _normKey(disciplina);
    final b = _normKey(descricao);
    return a.contains('DESCANS') || b.contains('DESCANS');
  }

  bool _isLimparErros(String disciplina, String descricao) {
    final a = _normKey(disciplina);
    final b = _normKey(descricao);
    return a.contains('LIMPE OS ERROS') ||
        b.contains('LIMPE OS ERROS') ||
        a.contains('LIMPAR ERROS') ||
        b.contains('LIMPAR ERROS');
  }

  /// Você disse: "Raciocínio-lógico / RLM / Raciocínio Lógico" = mesma coisa.
  String _normalizaDisciplinaUser(String s) {
    final n = _normKey(s).replaceAll(RegExp(r'[^A-Z0-9 ]'), '');
    if (n == 'RLM' ||
        n.contains('RACIOCINIO LOGICO') ||
        n.contains('RACIOCINIOLOGICO')) {
      return 'Raciocínio Lógico';
    }
    return s.trim();
  }
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

import '../models/tarefa_trilha.dart';

class TrilhaImporter {
  TrilhaImporter();

  /// Método principal (o controller usa este).
  Future<List<TarefaTrilha>> importarBytes(Uint8List bytes) async {
    final content = _decodeBytes(bytes);
    return importarTexto(content);
  }

  /// Alias (caso você tenha chamado diferente em algum lugar).
  Future<List<TarefaTrilha>> importarCsvBytes(Uint8List bytes) =>
      importarBytes(bytes);

  /// Também deixo esse alias por segurança.
  Future<List<TarefaTrilha>> importarArquivoBytes(Uint8List bytes) =>
      importarBytes(bytes);

  /// Importa a partir de texto CSV.
  Future<List<TarefaTrilha>> importarTexto(String csvText) async {
    // Detecta delimitador: ";" (muito comum em CSV do Excel BR) ou ","
    final delimiter = csvText.contains(';') ? ';' : ',';

    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      fieldDelimiter: ';',
      eol: '\n',
    ).convert(csvText.replaceAll('\r\n', '\n'));

    // Se não era ';', refaz com ','
    final parsed = (delimiter == ';')
        ? rows
        : const CsvToListConverter(
            shouldParseNumbers: false,
            fieldDelimiter: ',',
            eol: '\n',
          ).convert(csvText.replaceAll('\r\n', '\n'));

    if (parsed.isEmpty) return [];

    // Cabeçalho
    final header = parsed.first
        .map((e) => (e ?? '').toString().trim())
        .toList();
    final col = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      final key = _norm(header[i]);
      if (key.isNotEmpty) col[key] = i;
    }

    String cell(List row, String key) {
      final idx = col[_norm(key)];
      if (idx == null || idx < 0 || idx >= row.length) return '';
      return (row[idx] ?? '').toString().trim();
    }

    // Dados
    final dataRows = parsed.skip(1).toList();
    final tarefas = <TarefaTrilha>[];

    int ordem = 0; // ordem global SEQUENCIAL 1..N

    for (final row in dataRows) {
      // Linhas vazias
      final disciplinaRaw = cell(row, 'DISCIPLINA');
      final descRaw = cell(row, 'TAREFAS');
      final chRaw = cell(row, 'CH');
      final dataRaw = cell(row, 'DATA');

      if (disciplinaRaw.isEmpty &&
          descRaw.isEmpty &&
          chRaw.isEmpty &&
          dataRaw.isEmpty) {
        continue;
      }

      ordem += 1; // SEMPRE sequencial

      final disciplina = _cleanDisciplina(disciplinaRaw);
      final descricao = descRaw.trim();

      final chMin = _parseMinutes(chRaw);
      final dataPlanejada = _parseDatePt(dataRaw);

      // posição dentro da trilha (1..25)
      final posNaTrilha = ((ordem - 1) % 25) + 1;

      // trilha (0..)
      final trilhaIndex = (ordem - 1) ~/ 25;
      final trilha = 'TRILHA $trilhaIndex';

      // Guarda o valor original "TAREFA" se existir (só pra auditoria)
      final tarefaOriginal = cell(row, 'TAREFA'); // pode vir vazio
      final jsonExtra = <String, dynamic>{};
      if (tarefaOriginal.isNotEmpty)
        jsonExtra['tarefa_original'] = tarefaOriginal;
      if (cell(row, 'CODIGO').isNotEmpty)
        jsonExtra['codigo'] = cell(row, 'CODIGO');

      tarefas.add(
        TarefaTrilha(
          trilha: trilha,
          ordemGlobal: ordem,
          tarefaCodigo: posNaTrilha.toString(), // 1..25
          disciplina: disciplina.isEmpty ? null : disciplina,
          descricao: descricao.isEmpty ? null : descricao,
          dataPlanejada: dataPlanejada,
          chPlanejadaMin: chMin,
          // Campos preenchidos depois pelo app
          chEfetivaMin: null,
          questoes: null,
          acertos: null,
          desempenho: null,
          concluida: false,
          jsonExtra: jsonExtra.isEmpty ? null : json.encode(jsonExtra),
        ),
      );
    }

    return tarefas;
  }

  String _decodeBytes(Uint8List bytes) {
    // tenta UTF-8; se falhar, latin1 (excel BR é comum)
    try {
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return latin1.decode(bytes, allowMalformed: true);
    }
  }

  String _norm(String s) => s.trim().toUpperCase();

  String _cleanDisciplina(String s) {
    final t = s.trim();
    if (t.isEmpty) return '';
    // Normalização leve (você disse que RLM/Raciocínio-lógico tanto faz)
    final up = t.toUpperCase();
    if (up == 'RLM' || up == 'RACIOCINIO-LOGICO' || up == 'RACIOCÍNIO-LÓGICO') {
      return 'RACIOCÍNIO LÓGICO';
    }
    if (up == 'RACIOCINIO LOGICO') return 'RACIOCÍNIO LÓGICO';
    return t;
  }

  DateTime? _parseDatePt(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;

    // dd/MM/yyyy
    final m = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(t);
    if (m != null) {
      final dd = int.tryParse(m.group(1)!) ?? 1;
      final mm = int.tryParse(m.group(2)!) ?? 1;
      final yy = int.tryParse(m.group(3)!) ?? 2000;
      return DateTime(yy, mm, dd);
    }

    // fallback ISO
    return DateTime.tryParse(t);
  }

  int? _parseMinutes(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;

    // "1:00" ou "01:30"
    final hm = RegExp(r'^(\d{1,2})\s*:\s*(\d{1,2})$').firstMatch(t);
    if (hm != null) {
      final h = int.tryParse(hm.group(1)!) ?? 0;
      final m = int.tryParse(hm.group(2)!) ?? 0;
      return (h * 60) + m;
    }

    // "60", "60min", "150 min"
    final n = RegExp(r'(\d+)').firstMatch(t)?.group(1);
    if (n == null) return null;
    return int.tryParse(n);
  }
}

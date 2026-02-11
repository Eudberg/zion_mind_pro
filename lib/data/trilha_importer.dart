import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

import '../database/tarefas_trilha_dao.dart';
import '../models/tarefa_trilha.dart';

class TrilhaImporter {
  final TarefasTrilhaDao _tarefasDao;

  TrilhaImporter(this._tarefasDao);

  /// Importa um CSV em bytes e grava em lote no DB.
  Future<List<TarefaTrilha>> importarBytes(
    Uint8List bytes, {
    bool limparAntes = true,
  }) async {
    final csvText = _decodeCsvBytes(bytes);
    return importarCsv(csvText, limparAntes: limparAntes);
  }

  /// Importa um CSV (formato da sua planilha) e grava em lote no DB.
  /// Regras importantes:
  /// - Ordem global sempre vira 1..N (sequencial, sem buracos)
  /// - Trilha = (ordemGlobal-1) ~/ 25  (TRILHA 0, 1, 2...)
  /// - tarefa_codigo = posição dentro da trilha (1..25)
  Future<List<TarefaTrilha>> importarCsv(
    String csvText, {
    bool limparAntes = true,
  }) async {
    final rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(csvText);

    if (rows.isEmpty) return <TarefaTrilha>[];

    final header = rows.first.map((e) => e.toString().trim()).toList();
    final idx = <String, int>{};
    for (int i = 0; i < header.length; i++) {
      idx[_norm(header[i])] = i;
    }

    final tarefas = <TarefaTrilha>[];
    int seq = 1;

    for (int r = 1; r < rows.length; r++) {
      final row = rows[r].map((e) => e?.toString() ?? '').toList();

      // Ignora linhas vazias
      if (row.join('').trim().isEmpty) continue;

      final tarefaNum = _parseInt(_value(idx, row, 'TAREFA')) ?? seq++;
      final data = _parseDate(_value(idx, row, 'DATA'));
      final disciplina = _normalizarNomeDisciplina(
        _value(idx, row, 'DISCIPLINA') ?? 'SEM DISCIPLINA',
      );

      final descricao = _value(idx, row, 'TAREFAS') ?? '';
      final chPlanejada = _parseMinutos(_value(idx, row, 'CH'));
      final chEfetiva = _parseMinutos(_value(idx, row, 'CH_EFETIVA'));

      final questoes = _parseInt(_value(idx, row, 'TOT_QUEST_FEITAS'));
      final acertos = _parseInt(_value(idx, row, 'TOT_ACERTOS'));
      final desempenhoRaw = _parseDouble(_value(idx, row, 'DESEMPENHO'));
      final desempenho = _normalizeDesempenho(
        desempenhoRaw,
        questoes: questoes,
        acertos: acertos,
      );

      // Por enquanto: trilha e tarefaCodigo serão recalculados no “refeeder” 1..N
      final hashLinha = '$tarefaNum|$disciplina|$descricao'.hashCode.toString();

      tarefas.add(
        TarefaTrilha(
          trilha: null,
          dataPlanejada: data,
          tarefaCodigo: null,
          ordemGlobal: tarefaNum,
          disciplina: disciplina,
          descricao: descricao,
          chPlanejadaMin: chPlanejada,
          chEfetivaMin: chEfetiva,
          questoes: questoes,
          acertos: acertos,
          desempenho: desempenho,
          hashLinha: hashLinha,
          concluida: false,
        ),
      );
    }

    if (tarefas.isEmpty) return <TarefaTrilha>[];

    // Ordena por ordem_global e (depois) força uma sequência 1..N.
    // Motivo: o CSV pode vir com números faltando, duplicados ou fora de ordem.
    tarefas.sort((a, b) => (a.ordemGlobal ?? 0).compareTo(b.ordemGlobal ?? 0));

    final normalizadas = <TarefaTrilha>[];
    for (int i = 0; i < tarefas.length; i++) {
      final og = i + 1; // 1..N SEMPRE
      final trilhaIndex = (og - 1) ~/ 25; // 0..n
      final posNaTrilha = ((og - 1) % 25) + 1; // 1..25

      final t = tarefas[i];

      // Hash agora fica estável com a nova ordem
      final hashLinha = '$og|${t.disciplina ?? ''}|${t.descricao ?? ''}'
          .hashCode
          .toString();

      normalizadas.add(
        t.copyWith(
          ordemGlobal: og,
          trilha: 'TRILHA $trilhaIndex',
          tarefaCodigo: '$posNaTrilha',
          hashLinha: hashLinha,
        ),
      );
    }

    // Substitui tudo: “controle completo”
    if (limparAntes) {
      await _tarefasDao.limparTudo();
    }
    await _tarefasDao.inserirEmLote(normalizadas);
    return _tarefasDao.listarTodas();
  }

  // ---------------- Helpers ----------------

  String _norm(String s) {
    return s
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll('ç', 'c')
        .replaceAll('ã', 'a')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u');
  }

  String _decodeCsvBytes(Uint8List bytes) {
    final semBom = _removeUtf8Bom(bytes);
    try {
      return utf8.decode(semBom);
    } on FormatException {
      return latin1.decode(semBom);
    }
  }

  Uint8List _removeUtf8Bom(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return bytes.sublist(3);
    }
    return bytes;
  }

  String? _value(Map<String, int> idx, List<String> row, String col) {
    final key = _norm(col);
    final i = idx[key];
    if (i == null) return null;
    if (i < 0 || i >= row.length) return null;
    final v = row[i];
    return v.trim().isEmpty ? null : v.trim();
  }

  int? _parseInt(String? v) {
    if (v == null) return null;
    final s = v.replaceAll(RegExp(r'[^0-9-]'), '').trim();
    return s.isEmpty ? null : int.tryParse(s);
  }

  double? _parseDouble(String? v) {
    if (v == null) return null;
    final s = v.replaceAll('%', '').replaceAll(',', '.').trim();
    return s.isEmpty ? null : double.tryParse(s);
  }

  DateTime? _parseDate(String? v) {
    if (v == null) return null;
    final s = v.trim();
    if (s.isEmpty) return null;

    final m = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{2,4})$').firstMatch(s);
    if (m != null) {
      final d = int.parse(m.group(1)!);
      final mo = int.parse(m.group(2)!);
      var y = int.parse(m.group(3)!);
      if (y < 100) y += 2000;
      return DateTime(y, mo, d);
    }

    return DateTime.tryParse(s);
  }

  int? _parseMinutos(String? v) {
    if (v == null) return null;
    final s = v.trim();
    if (s.isEmpty) return null;

    final hm = RegExp(r'^(\d+):(\d{1,2})$').firstMatch(s);
    if (hm != null) {
      final h = int.parse(hm.group(1)!);
      final m = int.parse(hm.group(2)!);
      return h * 60 + m;
    }

    return int.tryParse(s);
  }

  double? _normalizeDesempenho(double? d, {int? questoes, int? acertos}) {
    if (d == null) {
      if (questoes != null && questoes > 0 && acertos != null) {
        return (acertos / questoes).clamp(0.0, 1.0);
      }
      return null;
    }
    if (d > 1.0) {
      if (d <= 100.0) return (d / 100.0).clamp(0.0, 1.0);
      return 1.0;
    }
    return d.clamp(0.0, 1.0);
  }

  String _normalizarNomeDisciplina(String s) {
    final n = _norm(s).replaceAll('_', '');
    if (n == 'rlm' || n.contains('raciociniologico')) {
      return 'Raciocínio Lógico';
    }
    return s.trim();
  }
}

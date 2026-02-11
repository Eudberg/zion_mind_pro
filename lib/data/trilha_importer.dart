import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

import '../database/plano_diario_dao.dart';
import '../database/revisoes_dao.dart';
import '../database/tarefas_trilha_dao.dart';
import '../models/tarefa_trilha.dart';

class TrilhaImporter {
  final TarefasTrilhaDao _tarefasDao;
  final RevisoesDao _revisoesDao;
  final PlanoDiarioDao _planoDao;

  TrilhaImporter({
    TarefasTrilhaDao? tarefasDao,
    RevisoesDao? revisoesDao,
    PlanoDiarioDao? planoDao,
  }) : _tarefasDao = tarefasDao ?? TarefasTrilhaDao(),
       _revisoesDao = revisoesDao ?? RevisoesDao(),
       _planoDao = planoDao ?? PlanoDiarioDao();

  Future<List<TarefaTrilha>> importarBytes(
    Uint8List bytes, {
    bool limparAntes = true,
  }) async {
    final conteudo = _decode(bytes);
    final delimiter = _detectDelimiter(conteudo);

    final rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(conteudo, fieldDelimiter: delimiter);

    if (rows.isEmpty) return [];

    final headerRowIndex = _findHeaderRow(rows);
    if (headerRowIndex < 0) {
      throw Exception(
        'Nao encontrei o cabecalho do CSV (DISCIPLINA / TAREFA / TAREFAS / CH).',
      );
    }

    final header = rows[headerRowIndex]
        .map((e) => e?.toString() ?? '')
        .toList();
    final headerIndex = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      headerIndex[_norm(header[i])] = i;
    }

    if (limparAntes) {
      await _planoDao.limparTudo();
      await _revisoesDao.limparTudo();
      await _tarefasDao.limparTudo();
    }

    int seq = 0;
    final tarefas = <TarefaTrilha>[];

    for (var r = headerRowIndex + 1; r < rows.length; r++) {
      final row = rows[r];
      if (_rowEmpty(row)) continue;

      String? v(String key) => _value(headerIndex, row, key);

      final trilhaCsv = v('trilha');
      final dataPlanejada = _parseDate(v('data'));
      final tarefaNum = _parseInt(v('tarefa')); // número global (se vier)
      final disciplinaRaw = (v('disciplina') ?? '').trim();

      // descrição longa geralmente vem em "TAREFAS"
      final descricao = (v('tarefas') ?? v('descricao') ?? '').trim();

      final chPlanejadaMin = _parseMinutos(v('ch'));
      final chEfetivaMin = _parseMinutos(v('ch_efetiva'));

      final questoes =
          _parseInt(v('tot_quest_feitas')) ?? _parseInt(v('questoes'));
      final acertos = _parseInt(v('tot_acertos')) ?? _parseInt(v('acertos'));

      final desempenhoCsv = _parseDouble(v('desempenho'));

      // ignora “linhas de separador”
      final pareceSeparador =
          (tarefaNum == null && disciplinaRaw.isEmpty && descricao.isEmpty);
      if (pareceSeparador) continue;

      // ordem global: usa a coluna se for válida, senão sequencial
      final ordemGlobal = (tarefaNum != null && tarefaNum > 0)
          ? tarefaNum
          : (++seq);

      final trilhaIndex = (ordemGlobal - 1) ~/ 25;
      final posNaTrilha = ((ordemGlobal - 1) % 25) + 1;

      final disciplina = _normalizarNomeDisciplina(disciplinaRaw);

      final desempenho = _normalizeDesempenho(
        desempenhoCsv,
        questoes: questoes,
        acertos: acertos,
      );

      final extras = <String, dynamic>{};
      if (trilhaCsv != null && trilhaCsv.trim().isNotEmpty) {
        extras['trilha_csv'] = trilhaCsv.trim();
      }

      tarefas.add(
        TarefaTrilha(
          trilha: 'TRILHA $trilhaIndex',
          dataPlanejada: dataPlanejada,
          tarefaCodigo: '$posNaTrilha',
          ordemGlobal: ordemGlobal,
          disciplina: disciplina.isEmpty ? null : disciplina,
          descricao: descricao.isEmpty ? null : descricao,
          chPlanejadaMin: chPlanejadaMin,
          chEfetivaMin: chEfetivaMin ?? 0,
          questoes: questoes,
          acertos: acertos,
          fonteQuestoes: null,
          desempenho: desempenho,
          rev7d: null,
          rev30d: null,
          rev60d: null,
          jsonExtra: extras.isEmpty ? null : jsonEncode(extras),
          hashLinha: '$ordemGlobal|$disciplina|$descricao'.hashCode.toString(),
          concluida: false,
        ),
      );
    }

    // garante ordenação global
    tarefas.sort((a, b) => (a.ordemGlobal ?? 0).compareTo(b.ordemGlobal ?? 0));

    // se você usou tarefaNum, pode ter “buracos” — isso não quebra.
    // se quiser forçar 1..N sempre, comente a linha acima e use seq.

    final ids = await _tarefasDao.inserirEmLote(tarefas);

    final out = <TarefaTrilha>[];
    for (var i = 0; i < tarefas.length; i++) {
      out.add(tarefas[i].copyWith(id: ids[i]));
    }
    return out;
  }

  // ---------------- helpers ----------------

  String _decode(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return latin1.decode(bytes);
    }
  }

  String _detectDelimiter(String content) {
    final sample = content.split('\n').take(5).join('\n');
    final semi = ';'.allMatches(sample).length;
    final comma = ','.allMatches(sample).length;
    return semi >= comma ? ';' : ',';
  }

  int _findHeaderRow(List<List<dynamic>> rows) {
    for (var i = 0; i < rows.length && i < 80; i++) {
      final s = rows[i]
          .map((e) => (e?.toString() ?? '').toLowerCase())
          .join('|');
      if (s.contains('disciplina') &&
          s.contains('tarefa') &&
          (s.contains('ch') || s.contains('c/h'))) {
        return i;
      }
    }
    return -1;
  }

  bool _rowEmpty(List row) {
    return row.every((e) => (e?.toString().trim() ?? '').isEmpty);
  }

  String _norm(String input) {
    var s = input.trim().toLowerCase();
    s = s
        .replaceAll(RegExp(r'[áàãâä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòõôö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ç', 'c');
    s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    s = s.replaceAll(RegExp(r'_+'), '_');
    return s.replaceAll(RegExp(r'^_|_$'), '');
  }

  String? _value(Map<String, int> idx, List row, String key) {
    final k = _norm(key);
    final i = idx[k];
    if (i == null || i >= row.length) return null;
    final v = row[i]?.toString();
    return v?.trim().isEmpty == true ? null : v?.trim();
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

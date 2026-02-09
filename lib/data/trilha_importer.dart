import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

import '../database/plano_diario_dao.dart';
import '../database/revisoes_dao.dart';
import '../database/tarefas_trilha_dao.dart';
import '../models/revisao.dart';
import '../models/tarefa_trilha.dart';

class TrilhaImporter {
  final TarefasTrilhaDao _tarefasDao;
  final RevisoesDao _revisoesDao;
  final PlanoDiarioDao _planoDao;

  TrilhaImporter({
    TarefasTrilhaDao? tarefasDao,
    RevisoesDao? revisoesDao,
    PlanoDiarioDao? planoDao,
  })  : _tarefasDao = tarefasDao ?? TarefasTrilhaDao(),
        _revisoesDao = revisoesDao ?? RevisoesDao(),
        _planoDao = planoDao ?? PlanoDiarioDao();

  Future<List<TarefaTrilha>> importarBytes(
    Uint8List bytes, {
    bool limparAntes = true,
  }) async {
    final conteudo = _decode(bytes);
    final delimiter = _detectDelimiter(conteudo);
    final rows = CsvToListConverter(
      fieldDelimiter: delimiter,
      shouldParseNumbers: false,
    ).convert(conteudo);

    final headerIndex = _findHeaderIndex(rows);
    if (headerIndex < 0) {
      throw Exception('Cabecalho nao encontrado no CSV.');
    }

    final headerRow = rows[headerIndex];
    final headerMap = _buildHeaderMap(headerRow);
    final rawHeaders = headerRow.map((e) => e?.toString() ?? '').toList();

    final tarefas = <TarefaTrilha>[];
    String? trilhaAtual;

    for (var i = headerIndex + 1; i < rows.length; i++) {
      final row = rows[i];
      if (_isRowEmpty(row)) continue;

      final rawTrilha = _valueByKey(row, headerMap, 'trilha');
      if (rawTrilha != null && rawTrilha.trim().isNotEmpty) {
        trilhaAtual = rawTrilha.trim();
      }

      final trilha = (rawTrilha != null && rawTrilha.trim().isNotEmpty)
          ? rawTrilha.trim()
          : trilhaAtual;

      final dataPlanejada =
          _parseDate(_valueByKey(row, headerMap, 'data_planejada'));

      final tarefaCodigo = _valueByKey(row, headerMap, 'tarefa_codigo');
      final disciplina = _valueByKey(row, headerMap, 'disciplina');
      final descricao = _valueByKey(row, headerMap, 'descricao');
      final chPlanejada =
          _parseMinutos(_valueByKey(row, headerMap, 'ch_planejada_min'));
      final chEfetiva =
          _parseMinutos(_valueByKey(row, headerMap, 'ch_efetiva_min'));
      final questoes = _parseInt(_valueByKey(row, headerMap, 'questoes'));
      final acertos = _parseInt(_valueByKey(row, headerMap, 'acertos'));
      final desempenho =
          _parseDouble(_valueByKey(row, headerMap, 'desempenho'));

      final rev24h = _parseDate(_valueByKey(row, headerMap, 'rev_24h'));
      final rev7d = _parseDate(_valueByKey(row, headerMap, 'rev_7d'));
      final rev15d = _parseDate(_valueByKey(row, headerMap, 'rev_15d'));
      final rev30d = _parseDate(_valueByKey(row, headerMap, 'rev_30d'));
      final rev60d = _parseDate(_valueByKey(row, headerMap, 'rev_60d'));

      final extras = _extractExtras(
        row,
        rawHeaders,
        headerMap.values.toSet(),
      );

      final computedRev24h = rev24h ??
          (dataPlanejada != null
              ? dataPlanejada.add(const Duration(days: 1))
              : null);
      final computedRev7d = rev7d ??
          (dataPlanejada != null
              ? dataPlanejada.add(const Duration(days: 7))
              : null);
      final computedRev15d = rev15d ??
          (dataPlanejada != null
              ? dataPlanejada.add(const Duration(days: 15))
              : null);
      final computedRev30d = rev30d ??
          (dataPlanejada != null
              ? dataPlanejada.add(const Duration(days: 30))
              : null);
      final computedRev60d = rev60d ??
          (dataPlanejada != null
              ? dataPlanejada.add(const Duration(days: 60))
              : null);

      final tarefa = TarefaTrilha(
        trilha: trilha,
        dataPlanejada: dataPlanejada,
        tarefaCodigo: tarefaCodigo,
        disciplina: disciplina,
        descricao: descricao,
        chPlanejadaMin: chPlanejada,
        chEfetivaMin: chEfetiva,
        questoes: questoes,
        acertos: acertos,
        desempenho: desempenho,
        rev24h: computedRev24h,
        rev7d: computedRev7d,
        rev15d: computedRev15d,
        rev30d: computedRev30d,
        rev60d: computedRev60d,
        jsonExtra: extras.isEmpty ? null : jsonEncode(extras),
        hashLinha: _hashRow(row),
      );

      tarefas.add(tarefa);
    }

    if (limparAntes) {
      await _planoDao.limparTudo();
      await _revisoesDao.limparTudo();
      await _tarefasDao.limparTudo();
    }

    final ids = await _tarefasDao.inserirEmLote(tarefas);
    final tarefasComId = <TarefaTrilha>[];
    final revisoes = <Revisao>[];

    for (var i = 0; i < tarefas.length; i++) {
      final tarefa = tarefas[i].copyWith(id: ids[i]);
      tarefasComId.add(tarefa);

      if (tarefa.dataPlanejada != null) {
        revisoes.addAll(_gerarRevisoes(tarefa));
      }
    }

    if (revisoes.isNotEmpty) {
      await _revisoesDao.inserirEmLote(revisoes);
    }

    return tarefasComId;
  }

  List<Revisao> _gerarRevisoes(TarefaTrilha tarefa) {
    final base = tarefa.dataPlanejada;
    if (base == null) return [];

    final revisoes = <Revisao>[];
    final id = tarefa.id;
    if (id == null) return revisoes;

    revisoes.add(
      Revisao(
        tarefaId: id,
        tipo: '7d',
        dataPrevista: tarefa.rev7d ?? base.add(const Duration(days: 7)),
        status: 'pendente',
      ),
    );
    revisoes.add(
      Revisao(
        tarefaId: id,
        tipo: '30d',
        dataPrevista: tarefa.rev30d ?? base.add(const Duration(days: 30)),
        status: 'pendente',
      ),
    );
    revisoes.add(
      Revisao(
        tarefaId: id,
        tipo: '60d',
        dataPrevista: tarefa.rev60d ?? base.add(const Duration(days: 60)),
        status: 'pendente',
      ),
    );

    return revisoes;
  }

  String _decode(Uint8List bytes) {
    try {
      return const Utf8Decoder(allowMalformed: true).convert(bytes);
    } catch (_) {
      return latin1.decode(bytes);
    }
  }

  String _detectDelimiter(String text) {
    final lines = text.split(RegExp(r'\r?\n'));
    final sample = lines.take(5).join('\n');
    final commas = _countChar(sample, ',');
    final semicolons = _countChar(sample, ';');
    return semicolons > commas ? ';' : ',';
  }

  int _countChar(String text, String char) {
    var count = 0;
    for (var i = 0; i < text.length; i++) {
      if (text[i] == char) count++;
    }
    return count;
  }

  int _findHeaderIndex(List<List<dynamic>> rows) {
    var bestIndex = -1;
    var bestScore = 0;
    final limit = rows.length < 10 ? rows.length : 10;

    for (var i = 0; i < limit; i++) {
      final row = rows[i];
      var score = 0;
      for (final cell in row) {
        final header = cell?.toString() ?? '';
        if (_mapHeader(header) != null) score++;
      }
      if (score > bestScore) {
        bestScore = score;
        bestIndex = i;
      }
    }

    return bestScore >= 2 ? bestIndex : -1;
  }

  Map<String, int> _buildHeaderMap(List<dynamic> headerRow) {
    final map = <String, int>{};
    for (var i = 0; i < headerRow.length; i++) {
      final raw = headerRow[i]?.toString() ?? '';
      final key = _mapHeader(raw);
      if (key != null && !map.containsKey(key)) {
        map[key] = i;
      }
    }
    return map;
  }

  String? _mapHeader(String header) {
    final h = _normalize(header);

    if (h.contains('rev') && h.contains('24')) return 'rev_24h';
    if (h.contains('rev') && h.contains('7')) return 'rev_7d';
    if (h.contains('rev') && h.contains('15')) return 'rev_15d';
    if (h.contains('rev') && h.contains('30')) return 'rev_30d';
    if (h.contains('rev') && h.contains('60')) return 'rev_60d';

    if (h.contains('trilha')) return 'trilha';
    if (h.contains('data')) return 'data_planejada';

    if (h.contains('codigo') ||
        (h.contains('cod') && h.contains('tarefa')) ||
        h == 'cod') {
      return 'tarefa_codigo';
    }

    if (h.contains('disciplina') || h.contains('materia')) {
      return 'disciplina';
    }

    if (h.contains('descricao') || h.contains('assunto')) {
      return 'descricao';
    }

    if (h.contains('ch') || h.contains('carga')) {
      if (h.contains('planej') || h.contains('previst') || h.contains('plan')) {
        return 'ch_planejada_min';
      }
      if (h.contains('efet') || h.contains('real')) {
        return 'ch_efetiva_min';
      }
    }

    if (h.contains('quest')) return 'questoes';
    if (h.contains('acert')) return 'acertos';

    if (h.contains('desempenho') ||
        h.contains('aproveitamento') ||
        h.contains('percent') ||
        h.contains('%')) {
      return 'desempenho';
    }

    return null;
  }

  String _normalize(String input) {
    var s = input.trim().toLowerCase();
    s = s
        .replaceAll(RegExp(r'[áàãâä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòõôö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll(RegExp(r'ç'), 'c');
    s = s.replaceAll(RegExp(r'[^a-z0-9%]+'), ' ');
    return s.trim();
  }

  String? _valueByKey(
    List<dynamic> row,
    Map<String, int> headerMap,
    String key,
  ) {
    final idx = headerMap[key];
    if (idx == null || idx >= row.length) return null;
    final value = row[idx];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  bool _isRowEmpty(List<dynamic> row) {
    for (final cell in row) {
      if (cell != null && cell.toString().trim().isNotEmpty) return false;
    }
    return true;
  }

  Map<String, dynamic> _extractExtras(
    List<dynamic> row,
    List<String> rawHeaders,
    Set<int> usedIndexes,
  ) {
    final extras = <String, dynamic>{};
    for (var i = 0; i < row.length && i < rawHeaders.length; i++) {
      if (usedIndexes.contains(i)) continue;
      final header = rawHeaders[i].trim();
      if (header.isEmpty) continue;
      final value = row[i];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isEmpty) continue;
      extras[header] = text;
    }
    return extras;
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final raw = value.trim();

    final numeric = double.tryParse(raw.replaceAll(',', '.'));
    if (numeric != null && numeric > 1000) {
      final base = DateTime(1899, 12, 30);
      return base.add(Duration(days: numeric.round()));
    }

    if (raw.contains('/')) {
      final parts = raw.split('/');
      if (parts.length >= 2) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = parts.length >= 3
            ? int.tryParse(parts[2])
            : DateTime.now().year;
        if (day != null && month != null && year != null) {
          return DateTime(year, month, day);
        }
      }
    }

    return DateTime.tryParse(raw);
  }

  int? _parseMinutos(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final raw = value.trim();

    if (raw.contains(':')) {
      final parts = raw.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        return (h * 60) + m;
      }
    }

    final normalized = raw.replaceAll(',', '.');
    final number = double.tryParse(normalized);
    if (number == null) return null;
    if (raw.contains('.') || raw.contains(',')) {
      return (number * 60).round();
    }
    return number.round();
  }

  int? _parseInt(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return int.tryParse(value.replaceAll(RegExp(r'[^0-9-]'), ''));
  }

  double? _parseDouble(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.replaceAll(',', '.').replaceAll('%', '');
    final number = double.tryParse(normalized);
    if (number == null) return null;
    if (number > 1 && number <= 100) {
      return number / 100;
    }
    return number;
  }

  String _hashRow(List<dynamic> row) {
    final buffer = StringBuffer();
    for (final cell in row) {
      buffer.write(cell?.toString().trim() ?? '');
      buffer.write('|');
    }
    return _fnv1a64(buffer.toString());
  }

  String _fnv1a64(String input) {
    const fnvPrime = 1099511628211;
    var hash = 1469598103934665603;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * fnvPrime) & 0xFFFFFFFFFFFFFFFF;
    }
    final unsigned = hash.toUnsigned(64);
    return unsigned.toRadixString(16).padLeft(16, '0');
  }
}

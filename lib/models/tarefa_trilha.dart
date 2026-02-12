class TarefaTrilha {
  final int? id;
  final String? trilha;
  final DateTime? dataPlanejada;

  /// posição dentro da trilha (1..25)
  final String? tarefaCodigo;

  /// número global (1..N)
  final int? ordemGlobal;

  final String? disciplina;
  final String? descricao;

  final int? chPlanejadaMin;
  final int? chEfetivaMin;

  final int? questoes;
  final int? acertos;

  /// 'pdf' | 'sistema' | null
  final String? fonteQuestoes;

  /// 0.0..1.0
  final double? desempenho;

  final DateTime? rev7d;
  final DateTime? rev30d;
  final DateTime? rev60d;

  final String? jsonExtra;
  final String? hashLinha;

  final bool concluida;

  // --- O CAMPO QUE FALTAVA ---
  final String? dataConclusao;

  const TarefaTrilha({
    this.id,
    this.trilha,
    this.dataPlanejada,
    this.tarefaCodigo,
    this.ordemGlobal,
    this.disciplina,
    this.descricao,
    this.chPlanejadaMin,
    this.chEfetivaMin,
    this.questoes,
    this.acertos,
    this.fonteQuestoes,
    this.desempenho,
    this.rev7d,
    this.rev30d,
    this.rev60d,
    this.jsonExtra,
    this.hashLinha,
    this.concluida = false,
    this.dataConclusao, // Adicionado ao construtor
  });

  // Regras especiais
  bool get isDescanso {
    final d = (disciplina ?? '').toLowerCase();
    final x = (descricao ?? '').toLowerCase();
    return d.contains('descanso') || x.contains('descanso');
  }

  bool get isLimparErros {
    final d = (disciplina ?? '').toLowerCase();
    final x = (descricao ?? '').toLowerCase();
    return d.contains('limpar erros') ||
        x.contains('limpar erros') ||
        x.contains('limpe os erros');
  }

  double? get desempenhoCalculado {
    if (questoes != null && questoes! > 0 && acertos != null) {
      return (acertos! / questoes!).clamp(0.0, 1.0);
    }
    if (desempenho == null) return null;
    return desempenho!.clamp(0.0, 1.0);
  }

  TarefaTrilha copyWith({
    int? id,
    String? trilha,
    DateTime? dataPlanejada,
    String? tarefaCodigo,
    int? ordemGlobal,
    String? disciplina,
    String? descricao,
    int? chPlanejadaMin,
    int? chEfetivaMin,
    int? questoes,
    int? acertos,
    String? fonteQuestoes,
    double? desempenho,
    DateTime? rev7d,
    DateTime? rev30d,
    DateTime? rev60d,
    String? jsonExtra,
    String? hashLinha,
    bool? concluida,
    String? dataConclusao, // Adicionado ao copyWith
  }) {
    return TarefaTrilha(
      id: id ?? this.id,
      trilha: trilha ?? this.trilha,
      dataPlanejada: dataPlanejada ?? this.dataPlanejada,
      tarefaCodigo: tarefaCodigo ?? this.tarefaCodigo,
      ordemGlobal: ordemGlobal ?? this.ordemGlobal,
      disciplina: disciplina ?? this.disciplina,
      descricao: descricao ?? this.descricao,
      chPlanejadaMin: chPlanejadaMin ?? this.chPlanejadaMin,
      chEfetivaMin: chEfetivaMin ?? this.chEfetivaMin,
      questoes: questoes ?? this.questoes,
      acertos: acertos ?? this.acertos,
      fonteQuestoes: fonteQuestoes ?? this.fonteQuestoes,
      desempenho: desempenho ?? this.desempenho,
      rev7d: rev7d ?? this.rev7d,
      rev30d: rev30d ?? this.rev30d,
      rev60d: rev60d ?? this.rev60d,
      jsonExtra: jsonExtra ?? this.jsonExtra,
      hashLinha: hashLinha ?? this.hashLinha,
      concluida: concluida ?? this.concluida,
      dataConclusao: dataConclusao ?? this.dataConclusao,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trilha': trilha,
      'data_planejada': dataPlanejada?.toIso8601String(),
      'tarefa_codigo': tarefaCodigo,
      'ordem_global': ordemGlobal,
      'disciplina': disciplina,
      'descricao': descricao,
      'ch_planejada_min': chPlanejadaMin,
      'ch_efetiva_min': chEfetivaMin,
      'questoes': questoes,
      'acertos': acertos,
      'fonte_questoes': fonteQuestoes,
      'desempenho': desempenho,
      'rev_7d': rev7d?.toIso8601String(),
      'rev_30d': rev30d?.toIso8601String(),
      'rev_60d': rev60d?.toIso8601String(),
      'json_extra': jsonExtra,
      'hash_linha': hashLinha,
      'concluida': concluida ? 1 : 0,
      'data_conclusao': dataConclusao, // Adicionado ao Mapa do Banco
    };
  }

  factory TarefaTrilha.fromMap(Map<String, dynamic> map) {
    return TarefaTrilha(
      id: map['id'] as int?,
      trilha: map['trilha'] as String?,
      dataPlanejada: _parseDate(map['data_planejada']),
      tarefaCodigo: map['tarefa_codigo'] as String?,
      ordemGlobal: map['ordem_global'] as int?,
      disciplina: map['disciplina'] as String?,
      descricao: map['descricao'] as String?,
      chPlanejadaMin: map['ch_planejada_min'] as int?,
      chEfetivaMin: map['ch_efetiva_min'] as int?,
      questoes: map['questoes'] as int?,
      acertos: map['acertos'] as int?,
      fonteQuestoes: map['fonte_questoes'] as String?,
      desempenho: _parseDouble(map['desempenho']),
      rev7d: _parseDate(map['rev_7d']),
      rev30d: _parseDate(map['rev_30d']),
      rev60d: _parseDate(map['rev_60d']),
      jsonExtra: map['json_extra'] as String?,
      hashLinha: map['hash_linha'] as String?,
      concluida: (map['concluida'] as int? ?? 0) == 1,
      dataConclusao: map['data_conclusao'] as String?, // Recuperado do Banco
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.'));
  }
}

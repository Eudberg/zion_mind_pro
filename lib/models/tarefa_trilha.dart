class TarefaTrilha {
  final int? id;
  final String? trilha;
  final DateTime? dataPlanejada;
  final String? tarefaCodigo;
  final String? disciplina;
  final String? descricao;
  final int? chPlanejadaMin;
  final int? chEfetivaMin;
  final int? questoes;
  final int? acertos;
  final double? desempenho;
  final DateTime? rev24h;
  final DateTime? rev7d;
  final DateTime? rev15d;
  final DateTime? rev30d;
  final DateTime? rev60d;
  final String? jsonExtra;
  final String? hashLinha;

  TarefaTrilha({
    this.id,
    this.trilha,
    this.dataPlanejada,
    this.tarefaCodigo,
    this.disciplina,
    this.descricao,
    this.chPlanejadaMin,
    this.chEfetivaMin,
    this.questoes,
    this.acertos,
    this.desempenho,
    this.rev24h,
    this.rev7d,
    this.rev15d,
    this.rev30d,
    this.rev60d,
    this.jsonExtra,
    this.hashLinha,
  });

  TarefaTrilha copyWith({
    int? id,
    String? trilha,
    DateTime? dataPlanejada,
    String? tarefaCodigo,
    String? disciplina,
    String? descricao,
    int? chPlanejadaMin,
    int? chEfetivaMin,
    int? questoes,
    int? acertos,
    double? desempenho,
    DateTime? rev24h,
    DateTime? rev7d,
    DateTime? rev15d,
    DateTime? rev30d,
    DateTime? rev60d,
    String? jsonExtra,
    String? hashLinha,
  }) {
    return TarefaTrilha(
      id: id ?? this.id,
      trilha: trilha ?? this.trilha,
      dataPlanejada: dataPlanejada ?? this.dataPlanejada,
      tarefaCodigo: tarefaCodigo ?? this.tarefaCodigo,
      disciplina: disciplina ?? this.disciplina,
      descricao: descricao ?? this.descricao,
      chPlanejadaMin: chPlanejadaMin ?? this.chPlanejadaMin,
      chEfetivaMin: chEfetivaMin ?? this.chEfetivaMin,
      questoes: questoes ?? this.questoes,
      acertos: acertos ?? this.acertos,
      desempenho: desempenho ?? this.desempenho,
      rev24h: rev24h ?? this.rev24h,
      rev7d: rev7d ?? this.rev7d,
      rev15d: rev15d ?? this.rev15d,
      rev30d: rev30d ?? this.rev30d,
      rev60d: rev60d ?? this.rev60d,
      jsonExtra: jsonExtra ?? this.jsonExtra,
      hashLinha: hashLinha ?? this.hashLinha,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trilha': trilha,
      'data_planejada': dataPlanejada?.toIso8601String(),
      'tarefa_codigo': tarefaCodigo,
      'disciplina': disciplina,
      'descricao': descricao,
      'ch_planejada_min': chPlanejadaMin,
      'ch_efetiva_min': chEfetivaMin,
      'questoes': questoes,
      'acertos': acertos,
      'desempenho': desempenho,
      'rev_24h': rev24h?.toIso8601String(),
      'rev_7d': rev7d?.toIso8601String(),
      'rev_15d': rev15d?.toIso8601String(),
      'rev_30d': rev30d?.toIso8601String(),
      'rev_60d': rev60d?.toIso8601String(),
      'json_extra': jsonExtra,
      'hash_linha': hashLinha,
    };
  }

  factory TarefaTrilha.fromMap(Map<String, dynamic> map) {
    return TarefaTrilha(
      id: map['id'] as int?,
      trilha: map['trilha'] as String?,
      dataPlanejada: _parseDate(map['data_planejada']),
      tarefaCodigo: map['tarefa_codigo'] as String?,
      disciplina: map['disciplina'] as String?,
      descricao: map['descricao'] as String?,
      chPlanejadaMin: map['ch_planejada_min'] as int?,
      chEfetivaMin: map['ch_efetiva_min'] as int?,
      questoes: map['questoes'] as int?,
      acertos: map['acertos'] as int?,
      desempenho: _parseDouble(map['desempenho']),
      rev24h: _parseDate(map['rev_24h']),
      rev7d: _parseDate(map['rev_7d']),
      rev15d: _parseDate(map['rev_15d']),
      rev30d: _parseDate(map['rev_30d']),
      rev60d: _parseDate(map['rev_60d']),
      jsonExtra: map['json_extra'] as String?,
      hashLinha: map['hash_linha'] as String?,
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

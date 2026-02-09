class SessaoEstudo {
  final int? id;
  final int? tarefaId;
  final DateTime? inicio;
  final DateTime? fim;
  final int? minutos;
  final int? questoes;
  final int? acertos;

  // Campos legado (tabela sessoes)
  final String? materia;
  final DateTime? data;

  SessaoEstudo({
    this.id,
    this.tarefaId,
    this.inicio,
    this.fim,
    this.minutos,
    this.questoes,
    this.acertos,
    this.materia,
    this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tarefa_id': tarefaId,
      'inicio': inicio?.toIso8601String(),
      'fim': fim?.toIso8601String(),
      'minutos': minutos,
      'questoes': questoes,
      'acertos': acertos,
    };
  }

  factory SessaoEstudo.fromMap(Map<String, dynamic> map) {
    return SessaoEstudo(
      id: map['id'] as int?,
      tarefaId: map['tarefa_id'] as int?,
      inicio: _parseDate(map['inicio']),
      fim: _parseDate(map['fim']),
      minutos: map['minutos'] as int?,
      questoes: map['questoes'] as int?,
      acertos: map['acertos'] as int?,
    );
  }

  Map<String, dynamic> toLegacyMap() {
    return {
      'id': id,
      'materia': materia,
      'data': data?.toIso8601String(),
      'minutos': minutos,
    };
  }

  factory SessaoEstudo.fromLegacyMap(Map<String, dynamic> map) {
    return SessaoEstudo(
      id: map['id'] as int?,
      materia: map['materia'] as String?,
      data: _parseDate(map['data']),
      minutos: map['minutos'] as int?,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class TarefaTrilha {
  final int? id; // ID opcional para novos registros (importação)
  final int ordemGlobal;
  final String disciplina;
  final String assunto;
  final int duracaoMinutos;
  final int chPlanejadaMin;
  bool concluida;

  // Campos Legados Restaurados
  final String? descricao;
  final String? fonteQuestoes;
  final int? questoes;
  final int? acertos;
  final String? trilha;
  final String? tarefaCodigo;
  final int? chEfetivaMin;

  // Novos campos (7-30-60)
  int estagioRevisao;
  DateTime? dataConclusao;
  DateTime? dataProximaRevisao;

  TarefaTrilha({
    this.id, // Opcional
    required this.ordemGlobal,
    required this.disciplina,
    required this.assunto,
    required this.duracaoMinutos,
    required this.chPlanejadaMin,
    this.concluida = false,

    this.descricao,
    this.fonteQuestoes,
    this.questoes,
    this.acertos,
    this.trilha,
    this.tarefaCodigo,
    this.chEfetivaMin,

    this.estagioRevisao = 0,
    this.dataConclusao,
    this.dataProximaRevisao,
  });

  TarefaTrilha copyWith({
    int? id,
    int? ordemGlobal,
    String? disciplina,
    String? assunto,
    int? duracaoMinutos,
    int? chPlanejadaMin,
    bool? concluida,
    String? descricao,
    String? fonteQuestoes,
    int? questoes,
    int? acertos,
    String? trilha,
    String? tarefaCodigo,
    int? chEfetivaMin,
    int? estagioRevisao,
    DateTime? dataConclusao,
    DateTime? dataProximaRevisao,
  }) {
    return TarefaTrilha(
      id: id ?? this.id,
      ordemGlobal: ordemGlobal ?? this.ordemGlobal,
      disciplina: disciplina ?? this.disciplina,
      assunto: assunto ?? this.assunto,
      duracaoMinutos: duracaoMinutos ?? this.duracaoMinutos,
      chPlanejadaMin: chPlanejadaMin ?? this.chPlanejadaMin,
      concluida: concluida ?? this.concluida,
      descricao: descricao ?? this.descricao,
      fonteQuestoes: fonteQuestoes ?? this.fonteQuestoes,
      questoes: questoes ?? this.questoes,
      acertos: acertos ?? this.acertos,
      trilha: trilha ?? this.trilha,
      tarefaCodigo: tarefaCodigo ?? this.tarefaCodigo,
      chEfetivaMin: chEfetivaMin ?? this.chEfetivaMin,
      estagioRevisao: estagioRevisao ?? this.estagioRevisao,
      dataConclusao: dataConclusao ?? this.dataConclusao,
      dataProximaRevisao: dataProximaRevisao ?? this.dataProximaRevisao,
    );
  }

  double get desempenhoCalculado {
    if (questoes == null || questoes == 0) return 0.0;
    return (acertos ?? 0) / questoes!;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ordemGlobal': ordemGlobal,
      'disciplina': disciplina,
      'assunto': assunto,
      'duracaoMinutos': duracaoMinutos,
      'chPlanejadaMin': chPlanejadaMin,
      'concluida': concluida ? 1 : 0,
      'descricao': descricao,
      'fonteQuestoes': fonteQuestoes,
      'questoes': questoes,
      'acertos': acertos,
      'trilha': trilha,
      'tarefaCodigo': tarefaCodigo,
      'chEfetivaMin': chEfetivaMin,
      'estagioRevisao': estagioRevisao,
      'dataConclusao': dataConclusao?.toIso8601String(),
      'dataProximaRevisao': dataProximaRevisao?.toIso8601String(),
    };
  }

  factory TarefaTrilha.fromMap(Map<String, dynamic> map) {
    return TarefaTrilha(
      id: map['id'],
      ordemGlobal: map['ordemGlobal'] ?? 0,
      disciplina: map['disciplina'] ?? '',
      assunto: map['assunto'] ?? '',
      duracaoMinutos: map['duracaoMinutos'] ?? 0,
      chPlanejadaMin: map['chPlanejadaMin'] ?? 0,
      concluida: map['concluida'] == 1,
      descricao: map['descricao'],
      fonteQuestoes: map['fonteQuestoes'],
      questoes: map['questoes'],
      acertos: map['acertos'],
      trilha: map['trilha'],
      tarefaCodigo: map['tarefaCodigo'],
      chEfetivaMin: map['chEfetivaMin'],
      estagioRevisao: map['estagioRevisao'] ?? 0,
      dataConclusao: map['dataConclusao'] != null
          ? DateTime.parse(map['dataConclusao'])
          : null,
      dataProximaRevisao: map['dataProximaRevisao'] != null
          ? DateTime.parse(map['dataProximaRevisao'])
          : null,
    );
  }
}

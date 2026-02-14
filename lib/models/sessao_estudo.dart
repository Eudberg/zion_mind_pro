class SessaoEstudo {
  final int? id;
  final int tarefaId;
  final String disciplina;
  final DateTime dataInicio;
  final int duracaoMinutos;
  final int questoesFeitas;
  final int questoesAcertadas;

  SessaoEstudo({
    this.id,
    required this.tarefaId,
    required this.disciplina,
    required this.dataInicio,
    required this.duracaoMinutos,
    required this.questoesFeitas,
    required this.questoesAcertadas,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tarefaId': tarefaId,
      'disciplina': disciplina,
      'dataInicio': dataInicio.toIso8601String(),
      'duracaoMinutos': duracaoMinutos,
      'questoesFeitas': questoesFeitas,
      'questoesAcertadas': questoesAcertadas,
    };
  }

  factory SessaoEstudo.fromMap(Map<String, dynamic> map) {
    return SessaoEstudo(
      id: map['id'],
      tarefaId: map['tarefaId'],
      disciplina: map['disciplina'],
      dataInicio: DateTime.parse(map['dataInicio']),
      duracaoMinutos: map['duracaoMinutos'],
      questoesFeitas: map['questoesFeitas'],
      questoesAcertadas: map['questoesAcertadas'],
    );
  }
}

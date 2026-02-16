class Questao {
  final int? id;

  /// Mantemos o nome "materia" no app (pra não quebrar telas e lógica),
  /// mas no banco NOVO essa informação vai na coluna "disciplina".
  final String materia;

  final String assunto;
  final DateTime data;

  /// Mantemos nomes camelCase no app,
  /// mas no banco NOVO vira "quantidade" e "acertos".
  final int qtdFeitas;
  final int qtdAcertos;

  Questao({
    this.id,
    required this.materia,
    required this.assunto,
    required this.data,
    required this.qtdFeitas,
    required this.qtdAcertos,
  });

  double get desempenho {
    if (qtdFeitas == 0) return 0.0;
    return (qtdAcertos / qtdFeitas) * 100;
  }

  /// ✅ GRAVA no esquema NOVO (compatível com seu DbHelper atual)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'disciplina': materia, // <- era 'materia' no legado
      'assunto': assunto,
      'data': data.toIso8601String(),
      'quantidade': qtdFeitas, // <- era 'qtd_feitas' no legado
      'acertos': qtdAcertos, // <- era 'qtd_acertos' no legado
    };
  }

  /// ✅ LÊ tanto do esquema NOVO quanto do LEGADO
  factory Questao.fromMap(Map<String, dynamic> map) {
    int asInt(dynamic v) => v == null ? 0 : (v as num).toInt();

    final String materiaLida = (map['disciplina'] ?? map['materia'] ?? '')
        .toString();

    final String assuntoLido = (map['assunto'] ?? '').toString();

    final String dataStr = (map['data'] ?? DateTime.now().toIso8601String())
        .toString();

    return Questao(
      id: map['id'] == null ? null : (map['id'] as num).toInt(),
      materia: materiaLida,
      assunto: assuntoLido,
      data: DateTime.parse(dataStr),
      qtdFeitas: asInt(map['quantidade'] ?? map['qtd_feitas']),
      qtdAcertos: asInt(map['acertos'] ?? map['qtd_acertos']),
    );
  }
}

class Assunto {
  final int? id;
  final int materiaId;
  final String nome;
  final String nomeNormalizado;
  final String origem;
  final DateTime createdAt;

  Assunto({
    this.id,
    required this.materiaId,
    required this.nome,
    required this.nomeNormalizado,
    required this.origem,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'materiaId': materiaId,
      'nome': nome,
      'nomeNormalizado': nomeNormalizado,
      'origem': origem,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Assunto.fromMap(Map<String, dynamic> map) {
    return Assunto(
      id: map['id'] as int?,
      materiaId: map['materiaId'] as int? ?? 0,
      nome: map['nome'] as String? ?? '',
      nomeNormalizado: map['nomeNormalizado'] as String? ?? '',
      origem: map['origem'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

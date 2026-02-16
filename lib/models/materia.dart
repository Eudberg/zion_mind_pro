class Materia {
  final int? id;
  final String nome;
  final String nomeNormalizado;
  final String origem;
  final DateTime createdAt;

  Materia({
    this.id,
    required this.nome,
    required this.nomeNormalizado,
    required this.origem,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'nomeNormalizado': nomeNormalizado,
      'origem': origem,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Materia.fromMap(Map<String, dynamic> map) {
    return Materia(
      id: map['id'] as int?,
      nome: map['nome'] as String? ?? '',
      nomeNormalizado: map['nomeNormalizado'] as String? ?? '',
      origem: map['origem'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

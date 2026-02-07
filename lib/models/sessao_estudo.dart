class SessaoEstudo {
  final int? id;
  final String materia; // Mudamos de subject para materia
  final DateTime data; // Mudamos de date para data
  final int minutos;

  SessaoEstudo({
    this.id,
    required this.materia,
    required this.data,
    required this.minutos,
  });

  // Converte para Map (para o banco)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'materia': materia,
      'data': data.toIso8601String(),
      'minutos': minutos,
    };
  }

  // Converte de Map para Objeto (para ler do banco)
  factory SessaoEstudo.fromMap(Map<String, dynamic> map) {
    return SessaoEstudo(
      id: map['id'],
      materia: map['materia'],
      data: DateTime.parse(map['data']),
      minutos: map['minutos'],
    );
  }
}

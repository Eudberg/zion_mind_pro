class Questao {
  final int? id;
  final String materia;
  final String assunto;
  final DateTime data;
  final int qtdFeitas; // Variável em CamelCase
  final int qtdAcertos; // Variável em CamelCase

  Questao({
    this.id,
    required this.materia,
    required this.assunto,
    required this.data,
    required this.qtdFeitas,
    required this.qtdAcertos,
  });

  // Calcula o desempenho automaticamente (ex: 85.0)
  double get desempenho {
    if (qtdFeitas == 0) return 0.0;
    return (qtdAcertos / qtdFeitas) * 100;
  }

  // Envia para o Banco (usa chaves snake_case)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'materia': materia,
      'assunto': assunto,
      'data': data.toIso8601String(),
      'qtd_feitas': qtdFeitas, // Nome da variável
      'qtd_acertos': qtdAcertos, // Nome da variável
    };
  }

  // Traz do Banco (converte snake_case para CamelCase)
  factory Questao.fromMap(Map<String, dynamic> map) {
    return Questao(
      id: map['id'],
      materia: map['materia'],
      assunto: map['assunto'] ?? '',
      data: DateTime.parse(map['data']),
      // CORREÇÃO AQUI: O lado esquerdo é a Classe, o lado direito é o Banco
      qtdFeitas: map['qtd_feitas'],
      qtdAcertos: map['qtd_acertos'],
    );
  }
}

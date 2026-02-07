class StudySession {
  final int? id;
  final String subject; // Ex: Direito Tributário
  final DateTime date;
  final int minutes; // Tempo estudado

  StudySession({
    this.id,
    required this.subject,
    required this.date,
    required this.minutes,
  });

  // Converte para Map (para salvar no banco de dados)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'date': date.toIso8601String(),
      'minutes': minutes,
    };
  }
}

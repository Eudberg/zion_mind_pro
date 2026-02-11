class Disciplina {
  final String nome;

  // modo “tarefas”
  final int? totalTarefas;
  final int? tarefasConcluidas;

  // modo “horas” (legado)
  final int cargaHorariaTotal;
  int minutosEstudados;

  Disciplina({
    required this.nome,
    this.totalTarefas,
    this.tarefasConcluidas,
    this.cargaHorariaTotal = 0,
    this.minutosEstudados = 0,
  });

  factory Disciplina.fromTarefas({
    required String nome,
    required int totalTarefas,
    required int tarefasConcluidas,
  }) {
    return Disciplina(
      nome: nome,
      totalTarefas: totalTarefas,
      tarefasConcluidas: tarefasConcluidas,
      cargaHorariaTotal: 0,
      minutosEstudados: 0,
    );
  }

  double get horasEstudadas => minutosEstudados / 60;

  double get progresso {
    if (totalTarefas != null && totalTarefas! > 0) {
      return ((tarefasConcluidas ?? 0) / totalTarefas!).clamp(0.0, 1.0);
    }
    final totalMinutos = cargaHorariaTotal * 60;
    if (totalMinutos == 0) return 0;
    return (minutosEstudados / totalMinutos).clamp(0.0, 1.0);
  }
}

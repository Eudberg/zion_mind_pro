class Disciplina {
  final String nome;
  final int cargaHorariaTotal;
  int minutosEstudados;

  Disciplina({
    required this.nome,
    required this.cargaHorariaTotal,
    this.minutosEstudados = 0,
  });

  // Horas estudadas (exibidas no app)
  double get horasEstudadas => minutosEstudados / 60;

  // Progresso entre 0 e 1
  double get progresso {
    final totalMinutos = cargaHorariaTotal * 60;
    if (totalMinutos == 0) return 0;
    return (minutosEstudados / totalMinutos).clamp(0, 1);
  }
}

class Revisao {
  final int? id;
  final int? tarefaId;
  final String? tipo;
  final DateTime? dataPrevista;
  final String? status;

  Revisao({this.id, this.tarefaId, this.tipo, this.dataPrevista, this.status});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tarefa_id': tarefaId,
      'tipo': tipo,
      'data_prevista': dataPrevista?.toIso8601String(),
      'status': status,
    };
  }

  factory Revisao.fromMap(Map<String, dynamic> map) {
    return Revisao(
      id: map['id'] as int?,
      tarefaId: map['tarefa_id'] as int?,
      tipo: map['tipo'] as String?,
      dataPrevista: _parseDate(map['data_prevista']),
      status: map['status'] as String?,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

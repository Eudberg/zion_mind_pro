class PlanoItem {
  final int? id;
  final DateTime? data;
  final int? tarefaId;
  final String? tipo;
  final int? minutosSugeridos;
  final String? status;

  PlanoItem({
    this.id,
    this.data,
    this.tarefaId,
    this.tipo,
    this.minutosSugeridos,
    this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': data?.toIso8601String(),
      'tarefa_id': tarefaId,
      'tipo': tipo,
      'minutos_sugeridos': minutosSugeridos,
      'status': status,
    };
  }

  factory PlanoItem.fromMap(Map<String, dynamic> map) {
    return PlanoItem(
      id: map['id'] as int?,
      data: _parseDate(map['data']),
      tarefaId: map['tarefa_id'] as int?,
      tipo: map['tipo'] as String?,
      minutosSugeridos: map['minutos_sugeridos'] as int?,
      status: map['status'] as String?,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

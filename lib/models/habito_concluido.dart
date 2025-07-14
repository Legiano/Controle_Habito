
class HabitoConcluido {
  String? id;
  String habitoId;
  String nome;
  DateTime dataConclusao;

  HabitoConcluido({
    this.id,
    required this.habitoId,
    required this.nome,
    required this.dataConclusao,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'habitoId': habitoId,
      'nome': nome,
      'dataConclusao': dataConclusao.toIso8601String(),
    };

    if (id != null && id!.isNotEmpty) {
      data['_id'] = id;
    }
    return data;
  }

  factory HabitoConcluido.fromJson(Map<String, dynamic> json) {
    return HabitoConcluido(
      id: json['_id'] as String?,
      habitoId: json['habitoId'] as String,
      nome: json['nome'] as String,
      dataConclusao: DateTime.parse(json['dataConclusao'] as String),
    );
  }
}

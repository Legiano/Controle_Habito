class Habito {
  String? id;
  String nome;
  bool seg;
  bool ter;
  bool qua;
  bool qui;
  bool sex;
  bool sab;
  bool dom;
  final DateTime? dataCriacao;

  Habito({
    this.id,
    required this.nome,
    required this.seg,
    required this.ter,
    required this.qua,
    required this.qui,
    required this.sex,
    required this.sab,
    required this.dom,
    this.dataCriacao,
  });

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    "nome": nome,
    "seg": seg,
    "ter": ter,
    "qua": qua,
    "qui": qui,
    "sex": sex,
    "sab": sab,
    "dom": dom,
  };
  factory Habito.fromJson(Map<String, dynamic> json) => Habito(
  id: json['_id'] as String?,
  nome: json['nome'] ?? '',
  seg: json['seg'] ?? false,
  ter: json['ter'] ?? false,
  qua: json['qua'] ?? false,
  qui: json['qui'] ?? false,
  sex: json['sex'] ?? false,
  sab: json['sab'] ?? false,
  dom: json['dom'] ?? false,
  dataCriacao: json['dataCriacao'] != null
      ? DateTime.parse(json['dataCriacao'])
      : null,
);

}

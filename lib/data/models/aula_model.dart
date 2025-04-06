class Aula {
  final int? idAula;
  final int idUc;
  final int idTurma;
  final DateTime data;
  final String horario;
  final String status;

  Aula({
    this.idAula,
    required this.idUc,
    required this.idTurma,
    required this.data,
    required this.horario,
    required this.status,
  });

  factory Aula.fromMap(Map<String, dynamic> map) {
    return Aula(
      idAula: map['idAula'] as int?,
      idUc: map['idUc'] as int,
      idTurma: map['idTurma'] as int,
      data: DateTime.parse(map['data'] as String),
      horario: map['horario'] as String,
      status: map['status'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idAula': idAula,
      'idUc': idUc,
      'idTurma': idTurma,
      'data': data.toIso8601String(),
      'horario': horario,
      'status': status,
    };
  }
}

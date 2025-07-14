import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/habito.dart';
import '../models/habito_concluido.dart';

class ApiService {
  final String baseUrl = 'http://192.168.3.24:8080';
  //final String baseUrl = 'http://10.5.32.207:8080';

Future<List<Habito>> buscarTodosHabitos() async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/habito'));
    if (response.statusCode == 200) {
      print('Resposta JSON: ${response.body}'); // <<<< Aqui
      List<dynamic> body = json.decode(response.body);
      return body.map((dynamic item) => Habito.fromJson(item)).toList();
    } else {
      print('Erro ao buscar hábitos: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    print('Exceção ao buscar hábitos: $e');
    return [];
  }
}

Future<String?> salvarHabito(Habito habito) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/habito'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(habito.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['success'] == true && data.containsKey('id')) {
        return data['id'];
      } else if (data['success'] == true && data.containsKey('_id')) {
        return data['_id'];
      } else {
        print('Resposta inesperada ao salvar hábito: ${response.body}');
        return null;
      }
    } else {
      print('Erro ao salvar hábito: ${response.statusCode} - ${response.body}');
      return null;
    }
  } catch (e) {
    print('Exceção ao salvar hábito: $e');
    return null;
  }
}


Future<bool> editarHabito(Habito habito) async {
  if (habito.id == null || habito.id!.isEmpty) {
    print('Erro: ID do hábito é necessário para edição.');
    return false;
  }
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/habito'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(habito.toJson()),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonBody = json.decode(response.body);
      if (jsonBody['success'] == true) {
        return true;
      } else {
        print('Falha no backend ao editar hábito: ${response.body}');
        return false;
      }
    } else {
      print('Erro ao editar hábito: ${response.statusCode} - ${response.body}');
      return false;
    }
  } catch (e) {
    print('Exceção ao editar hábito: $e');
    return false;
  }
}

  Future<bool> excluirHabito(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/habito/id/$id'));
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Erro ao excluir hábito: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exceção ao excluir hábito: $e');
      return false;
    }
  }

  Future<List<HabitoConcluido>> buscarHistoricoPorData(DateTime date) async {
    final int ano = date.year;
    final int mes = date.month;
    final int dia = date.day;

    try {
      final response = await http.get(Uri.parse('$baseUrl/concluido/$ano/$mes/$dia'));

      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((dynamic item) => HabitoConcluido.fromJson(item)).toList();
      } else {
        print('Erro ao buscar histórico por data: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exceção ao buscar histórico por data: $e');
      return [];
    }
  }

  Future<List<HabitoConcluido>> buscarHistoricoCompleto() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/concluido'));
      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((dynamic item) => HabitoConcluido.fromJson(item)).toList();
      } else {
        print('Erro ao buscar histórico completo: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exceção ao buscar histórico completo: $e');
      return [];
    }
  }

  Future<String?> salvarHabitoConcluido(HabitoConcluido habitoConcluido) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/concluido'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(habitoConcluido.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        return responseBody['_id'];
      } else {
        print('Erro ao salvar hábito concluído: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exceção ao salvar hábito concluído: $e');
      return null;
    }
  }

  Future<bool> excluirHabitoConcluido(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/concluido/$id'));
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Erro ao excluir hábito concluído: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exceção ao excluir hábito concluído: $e');
      return false;
    }
  }

  Future<List<Habito>> buscarHabitosPorDiaDaSemana(int dia) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/habito/diaDaSemana/$dia'));
      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((item) => Habito.fromJson(item)).toList();
      } else {
        print('Erro ao buscar hábitos do dia: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exceção ao buscar hábitos por dia da semana: $e');
      return [];
    }
  }

  Future<List<HabitoConcluido>> buscarHistoricoMes() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/concluido/nesteMes'));
      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((dynamic item) => HabitoConcluido.fromJson(item)).toList();
      } else {
        print('Erro ao buscar histórico mensal: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exceção ao buscar histórico mensal: $e');
      return [];
    }
  }

  Future<List<HabitoConcluido>> buscarHistoricoAno() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/concluido/nesteAno'));
      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((dynamic item) => HabitoConcluido.fromJson(item)).toList();
      } else {
        print('Erro ao buscar histórico anual: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exceção ao buscar histórico anual: $e');
      return [];
    }
  }

  Future<List<HabitoConcluido>> buscarHistoricoSemana() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/concluido/nestaSemana'));
      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((dynamic item) => HabitoConcluido.fromJson(item)).toList();
      } else {
        print('Erro ao buscar histórico da semana: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exceção ao buscar histórico da semana: $e');
      return [];
    }
  }
}

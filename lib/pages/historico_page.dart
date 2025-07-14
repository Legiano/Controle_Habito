import 'package:flutter/material.dart';
import '../models/habito_concluido.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({Key? key}) : super(key: key);

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  final ApiService api = ApiService();

  List<HabitoConcluido> concluidos = [];
  bool carregando = false;
  String? erroMensagem;

  @override
  void initState() {
    super.initState();
    carregarConcluidos();
  }

  Future<void> carregarConcluidos() async {
    setState(() {
      carregando = true;
      erroMensagem = null;
    });

    try {
      final lista = await api.buscarHistoricoCompleto();
      if (!mounted) return;
      setState(() {
        concluidos = lista;
        carregando = false;
      });
    } catch (e) {
      setState(() {
        erroMensagem = 'Erro ao carregar histórico: $e';
        carregando = false;
      });
    }
  }

  Future<void> excluirHabitoConcluido(HabitoConcluido habito) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Hábito Concluído'),
        content: Text('Deseja excluir "${habito.nome}" do histórico?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final sucesso = await api.excluirHabitoConcluido(habito.id!);
      if (sucesso) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hábito removido do histórico.')),
          );
          await carregarConcluidos();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao excluir hábito.')),
          );
        }
      }
    }
  }

  String formatarData(DateTime? data) {
    if (data == null) return '';
    return DateFormat('dd/MM/yyyy HH:mm').format(data.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Hábitos Concluídos 📅')),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : erroMensagem != null
              ? Center(child: Text(erroMensagem!))
              : concluidos.isEmpty
                  ? const Center(child: Text('Nenhum hábito concluído ainda.'))
                  : RefreshIndicator(
                      onRefresh: carregarConcluidos,
                      child: ListView.builder(
                        itemCount: concluidos.length,
                        itemBuilder: (context, index) {
                          final habito = concluidos[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(habito.nome),
                              subtitle: Text('Concluído em: ${formatarData(habito.dataConclusao)}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => excluirHabitoConcluido(habito),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/habito.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';

class TodosHabitosPage extends StatefulWidget {
  const TodosHabitosPage({super.key});

  @override
  State<TodosHabitosPage> createState() => _TodosHabitosPageState();
}

class _TodosHabitosPageState extends State<TodosHabitosPage> {
  final ApiService api = ApiService();
  final NotificationService notificationService = NotificationService();

  List<Habito> habitos = [];
  bool carregando = false;
  String? erroMensagem;

  @override
  void initState() {
    super.initState();
    carregarHabitos();
  }

  Future<void> carregarHabitos() async {
    setState(() {
      carregando = true;
      erroMensagem = null;
    });

    try {
      final lista = await api.buscarTodosHabitos();
      if (!mounted) return;
      setState(() {
        habitos = lista;
        carregando = false;
      });
    } catch (e) {
      setState(() {
        erroMensagem = 'Erro ao carregar hábitos: $e';
        carregando = false;
      });
    }
  }

  Future<void> excluirHabito(Habito habito) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Excluir hábito'),
            content: Text(
              'Deseja realmente excluir o hábito "${habito.nome}"?',
            ),
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
      final sucesso = await api.excluirHabito(habito.id!);
      if (sucesso) {
        await notificationService.cancelarNotificacoesDoHabito(habito.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hábito "${habito.nome}" excluído')),
          );
        }
        await carregarHabitos();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao excluir hábito')),
          );
        }
      }
    }
  }

  String formatarDias(Habito h) {
    final dias = <String>[];
    if (h.seg) dias.add('Seg');
    if (h.ter) dias.add('Ter');
    if (h.qua) dias.add('Qua');
    if (h.qui) dias.add('Qui');
    if (h.sex) dias.add('Sex');
    if (h.sab) dias.add('Sab');
    if (h.dom) dias.add('Dom');
    return dias.length == 7 ? 'Todos os dias' : dias.join(', ');
  }

  String formatarData(DateTime? data) {
    if (data == null) return '';
    return DateFormat('dd/MM/yyyy').format(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todos os Hábitos 🎯')),
      body:
          carregando
              ? const Center(child: CircularProgressIndicator())
              : erroMensagem != null
              ? Center(child: Text(erroMensagem!))
              : habitos.isEmpty
              ? const Center(child: Text('Nenhum hábito cadastrado.🤔'))
              : ListView.builder(
                itemCount: habitos.length,
                itemBuilder: (context, index) {
                  final h = habitos[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ' ${h.nome}',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(' Dia: ${formatarDias(h)}'),
                          const SizedBox(height: 4),
                          Text(' Criado em: ${formatarData(h.dataCriacao)}'),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () => excluirHabito(h),
                              icon: const Icon(Icons.delete),
                              label: const Text('Excluir'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

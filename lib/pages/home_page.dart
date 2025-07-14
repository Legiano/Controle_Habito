import 'package:flutter/material.dart';
import '../models/habito.dart';
import '../models/habito_concluido.dart';
import '../services/api_service.dart';
import 'cadastro_page.dart';
import '../services/notification_service.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService api = ApiService();
  final NotificationService notificationService = NotificationService();

  List<Habito> habitos = [];
  List<HabitoConcluido> concluidosHoje = [];
  bool carregando = false;
  String? erroMensagem;
  int diaSelecionado = DateTime.now().weekday - 1; // 0 = Segunda

  final diasDaSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  DateTime getDataDoDiaSelecionado() {
    final hoje = DateTime.now();
    final diferenca = hoje.weekday - 1 - diaSelecionado;
    return hoje.subtract(Duration(days: diferenca));
  }

  Future<void> carregarDados() async {
    setState(() {
      carregando = true;
      erroMensagem = null;
    });

    try {
      final habitosDia = await api.buscarHabitosPorDiaDaSemana(diaSelecionado);
      final dataSelecionada = getDataDoDiaSelecionado();
      final concluidos = await api.buscarHistoricoPorData(dataSelecionada);

      if (!mounted) return;
      setState(() {
        habitos = habitosDia;
        concluidosHoje = concluidos;
        carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        erroMensagem = 'Erro ao carregar dados: $e';
        carregando = false;
      });
    }
  }

  bool estaConcluido(String habitoId) {
    return concluidosHoje.any((c) => c.habitoId == habitoId);
  }

  Future<void> alternarConclusao(Habito habito) async {
    final concluido = estaConcluido(habito.id!);
    final dataSelecionada = getDataDoDiaSelecionado();

    print(
      'alternarConclusao chamado para hábito: ${habito.nome} (ID: ${habito.id})',
    );
    print('Estado atual: ${concluido ? 'Concluído' : 'Não concluído'}');
    print('Data selecionada para conclusão: $dataSelecionada');

    try {
      if (concluido) {
        HabitoConcluido? habitoConcluido;

        try {
          habitoConcluido = concluidosHoje.firstWhere(
            (c) => c.habitoId == habito.id,
          );
        } catch (e) {
          habitoConcluido = null;
        }

        if (habitoConcluido == null) {
          print('Erro: hábito concluído não encontrado para exclusão!');
          return;
        }

        print('Excluindo hábito concluído com ID: ${habitoConcluido.id}');
        await api.excluirHabitoConcluido(habitoConcluido.id!);

        print('Reagendando notificações do hábito');
        await notificationService
            .agendarNotificacoesParaHabito(habito.id!, habito.nome, {
              'seg': habito.seg,
              'ter': habito.ter,
              'qua': habito.qua,
              'qui': habito.qui,
              'sex': habito.sex,
              'sab': habito.sab,
              'dom': habito.dom,
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hábito "${habito.nome}" desmarcado com sucesso!'),
            ),
          );
        }
      } else {
        print('Salvando novo hábito concluído');
        await api.salvarHabitoConcluido(
          HabitoConcluido(
            habitoId: habito.id!,
            nome: habito.nome,
            dataConclusao: dataSelecionada,
          ),
        );

        print('Cancelando notificações do hábito');
        await notificationService.cancelarNotificacoesDoHabito(habito.id!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Hábito "${habito.nome}" concluído com sucesso! 🚀',
              ),
            ),
          );
        }
      }

      print('Atualizando dados após alteração');
      await carregarDados();
    } catch (e) {
      print('Erro ao alternar conclusão do hábito: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar o hábito: $e')),
        );
      }
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
        if (mounted) mostrarMensagem('Hábito "${habito.nome}" excluído');
        await carregarDados();
      } else {
        if (mounted) mostrarMensagem('Erro ao excluir hábito');
      }
    }
  }

  void abrirCadastro([Habito? habito]) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CadastroPage(habito: habito)),
    );

    if (resultado == true) {
      await carregarDados();
      if (mounted) mostrarMensagem('Hábito salvo com sucesso! 🚀');
    }
  }

  void mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Widget buildListaHabitos() {
    return ListView.builder(
      itemCount: habitos.length,
      itemBuilder: (context, index) {
        final habito = habitos[index];
        final concluido = estaConcluido(habito.id!);

        return CheckboxListTile(
          title: Text(habito.nome),
          value: concluido,
          onChanged: (_) => alternarConclusao(habito),
          secondary: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => abrirCadastro(habito),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => excluirHabito(habito),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Hábitos'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: DropdownButton<int>(
              value: diaSelecionado,
              isDense: true,
              underline: const SizedBox(),
              onChanged: (novoDia) {
                if (novoDia != null) {
                  setState(() => diaSelecionado = novoDia);
                  carregarDados();
                }
              },
              items: List.generate(7, (index) {
                return DropdownMenuItem(
                  value: index,
                  child: Text(diasDaSemana[index]),
                );
              }),
            ),
          ),
        ],
      ),
      body:
          carregando
              ? const Center(child: CircularProgressIndicator())
              : erroMensagem != null
              ? Center(child: Text(erroMensagem!))
              : habitos.isEmpty
              ? const Center(
                child: Text(
                  'Nenhum hábito cadastrado para o dia selecionado. 🤔',
                ),
              )
              : buildListaHabitos(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => abrirCadastro(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

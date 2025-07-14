import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/habito.dart';
import '../services/notification_service.dart';

class CadastroPage extends StatefulWidget {
  final Habito? habito;

  const CadastroPage({super.key, this.habito});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  bool _salvando = false;

  final ApiService api = ApiService();
  final NotificationService notificationService = NotificationService();

  Map<String, bool> diasSelecionados = {
    'seg': false,
    'ter': false,
    'qua': false,
    'qui': false,
    'sex': false,
    'sab': false,
    'dom': false,
  };

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.habito?.nome ?? '');

    if (widget.habito != null) {
      diasSelecionados = {
        'seg': widget.habito!.seg,
        'ter': widget.habito!.ter,
        'qua': widget.habito!.qua,
        'qui': widget.habito!.qui,
        'sex': widget.habito!.sex,
        'sab': widget.habito!.sab,
        'dom': widget.habito!.dom,
      };
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> salvar() async {
    if (_salvando || !_formKey.currentState!.validate()) return;

    if (!diasSelecionados.containsValue(true)) {
      mostrarMensagem('Selecione pelo menos um dia para o hábito');
      return;
    }

    setState(() => _salvando = true);

    final habito = Habito(
      id: widget.habito?.id,
      nome: _nomeController.text.trim(),
      seg: diasSelecionados['seg']!,
      ter: diasSelecionados['ter']!,
      qua: diasSelecionados['qua']!,
      qui: diasSelecionados['qui']!,
      sex: diasSelecionados['sex']!,
      sab: diasSelecionados['sab']!,
      dom: diasSelecionados['dom']!,
    );

    bool sucesso = false;
    String? habitoId = habito.id;

    try {
      if (widget.habito != null && habitoId != null) {
        sucesso = await api.editarHabito(habito);
      } else {
        habitoId = await api.salvarHabito(habito);
        sucesso = habitoId != null;
      }
    } catch (e) {
      sucesso = false;
      mostrarMensagem('Erro ao salvar hábito: $e');
    }

    if (!mounted) return;
    setState(() => _salvando = false);

    if (sucesso && habitoId != null) {
      // Cancelar notificações antigas (se for edição)
      if (widget.habito != null) {
        await notificationService.cancelarNotificacoesDoHabito(habitoId);
      }

      // Agendar notificações novas
      await notificationService.agendarNotificacoesParaHabito(
        habitoId,
        habito.nome,
        diasSelecionados,
      );

      Navigator.of(context).pop(true);
    } else {
      mostrarMensagem('Erro ao salvar hábito');
    }
  }

  void mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  String _mapDiaToTexto(String dia) {
    const mapa = {
      'seg': 'Segunda',
      'ter': 'Terça',
      'qua': 'Quarta',
      'qui': 'Quinta',
      'sex': 'Sexta',
      'sab': 'Sábado',
      'dom': 'Domingo',
    };
    return mapa[dia] ?? dia;
  }

  @override
  Widget build(BuildContext context) {
    final isEditando = widget.habito != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditando ? 'Editar Hábito' : 'Novo Hábito')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome do Hábito'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Informe o nome do hábito'
                        : null,
              ),
              const SizedBox(height: 20),
              Text(
                'Dias da Semana:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: diasSelecionados.keys.map((dia) {
                  return FilterChip(
                    label: Text(_mapDiaToTexto(dia)),
                    selected: diasSelecionados[dia]!,
                    onSelected: (selected) {
                      setState(() {
                        diasSelecionados[dia] = selected;
                      });
                    },
                  );
                }).toList(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _salvando ? null : salvar,
                  child: _salvando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(isEditando ? 'Atualizar' : 'Salvar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

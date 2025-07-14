import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/habito_concluido.dart';

class ProgressoPage extends StatefulWidget {
  const ProgressoPage({super.key});

  @override
  State<ProgressoPage> createState() => _ProgressoPageState();
}

class _ProgressoPageState extends State<ProgressoPage>
    with SingleTickerProviderStateMixin {
  final ApiService api = ApiService();
  List<HabitoConcluido> dados = [];
  late TabController _tabController;

  final List<String> periodos = ['semana', 'mes', 'ano'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: periodos.length, vsync: this);

    _tabController.addListener(() {
      if (_tabController.index != _tabController.previousIndex) {
        carregarDados();
      }
    });

    carregarDados();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get periodoAtual => periodos[_tabController.index];

  Future<void> carregarDados() async {
    List<HabitoConcluido> resposta = [];

    if (periodoAtual == 'semana') {
      resposta = await api.buscarHistoricoSemana();
    } else if (periodoAtual == 'mes') {
      resposta = await api.buscarHistoricoMes();
    } else if (periodoAtual == 'ano') {
      resposta = await api.buscarHistoricoAno();
    }

    if (!mounted) return;

    setState(() {
      dados = resposta;
    });
  }

  List<BarChartGroupData> gerarDadosGrafico() {
    Map<String, int> contagem = {};

    for (var item in dados) {
      final data = item.dataConclusao;
      String chave;

      if (periodoAtual == 'semana') {
        const diasSemana = {
          1: 'Seg',
          2: 'Ter',
          3: 'Qua',
          4: 'Qui',
          5: 'Sex',
          6: 'Sab',
          7: 'Dom',
        };
        chave = diasSemana[data.weekday]!;
      } else if (periodoAtual == 'mes') {
        chave = data.day.toString().padLeft(2, '0');
      } else {
        chave = data.month.toString().padLeft(2, '0');
      }

      contagem[chave] = (contagem[chave] ?? 0) + 1;
    }

    List<String> chavesOrdenadas;
    if (periodoAtual == 'semana') {
      chavesOrdenadas = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];
    } else if (periodoAtual == 'mes') {
      chavesOrdenadas = List.generate(
        31,
        (i) => (i + 1).toString().padLeft(2, '0'),
      );
    } else {
      chavesOrdenadas = List.generate(
        12,
        (i) => (i + 1).toString().padLeft(2, '0'),
      );
    }

    return chavesOrdenadas.asMap().entries.map((entry) {
      final index = entry.key;
      final key = entry.value;
      final value = contagem[key] ?? 0;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(toY: value.toDouble(), color: Colors.blue, width: 18),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dadosGrafico = gerarDadosGrafico();

    List<String> labels;
    if (periodoAtual == 'semana') {
      labels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];
    } else if (periodoAtual == 'mes') {
      labels = List.generate(31, (i) => (i + 1).toString());
    } else {
      labels = [
        'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
        'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
      ];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progresso'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Semanal'),
            Tab(text: 'Mensal'),
            Tab(text: 'Anual'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: dadosGrafico.every((g) => g.barRods.first.toY == 0)
            ? const Center(
                child: Text('Nenhum dado disponível para este período.🤔'),
              )
            : BarChart(
                BarChartData(
                  barGroups: dadosGrafico,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 == 0) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index < 0 || index >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              labels[index],
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.blueAccent,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${labels[group.x.toInt()]}\n${rod.toY.toInt()} hábitos concluídos',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

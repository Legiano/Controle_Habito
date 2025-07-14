import 'package:controle_habitos/pages/historico_page.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'progresso_page.dart';
import 'todos_habitos_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _paginaAtual = 0;

  final List<Widget> _paginas = [
    const HomePage(),
    const TodosHabitosPage(),
    const ProgressoPage(),
    HistoricoPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _paginas[_paginaAtual],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _paginaAtual,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        onTap: (index) {
          setState(() {
            _paginaAtual = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Hábitos',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.checklist), label: 'Todos'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Progresso',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Histórico',
          ),
        ],
      ),
    );
  }
}

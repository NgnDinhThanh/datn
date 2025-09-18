import 'package:flutter/material.dart';
import 'quizz_screen.dart';
import 'classes_screen.dart';
import 'students_screen.dart';
import 'my_account_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 3; // My Account mặc định
  final List<Widget> _screens = const [
    QuizzesScreen(),
    ClassesScreen(),
    StudentsScreen(),
    MyAccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.check_box), label: 'Quizzes'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Classes'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Students'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'My Account'),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
} 
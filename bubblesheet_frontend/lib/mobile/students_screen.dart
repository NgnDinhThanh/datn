import 'package:bubblesheet_frontend/mobile/student_detail_screen.dart';
import 'package:bubblesheet_frontend/mobile/student_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student_model.dart';
import '../providers/student_provider.dart';
import '../services/api_service.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({Key? key}) : super(key: key);

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  String _search = '';
  String _sortKey = 'Last Name';
  final List<String> _sortOptions = ['First Name', 'Last Name', 'ID'];

  @override
  void initState() {
    super.initState();
    ApiService.setContext(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentProvider>(context, listen: false).fetchStudents(context);
    });
  }

  List<Student> _filterAndSort(List<Student> students) {
    List<Student> filtered = students;
    // Search
    if (_search.isNotEmpty) {
      filtered = filtered.where((s) =>
        s.firstName.toLowerCase().contains(_search.toLowerCase()) ||
        s.lastName.toLowerCase().contains(_search.toLowerCase()) ||
        s.studentId.toLowerCase().contains(_search.toLowerCase())
      ).toList();
    }
    // Sort
    switch (_sortKey) {
      case 'First Name':
        filtered.sort((a, b) => a.firstName.compareTo(b.firstName));
        break;
      case 'Last Name':
        filtered.sort((a, b) => a.lastName.compareTo(b.lastName));
        break;
      case 'ID':
        filtered.sort((a, b) => a.studentId.compareTo(b.studentId));
        break;
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        centerTitle: true,
      ),
      body: Consumer<StudentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text('Error: \\${provider.error}', style: TextStyle(color: Colors.red)));
          }
          final students = _filterAndSort(provider.students);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    DropdownButton<String>(
                      value: _sortKey,
                      items: _sortOptions.map((e) => DropdownMenuItem(value: e, child: Text('Sort\n$e'))).toList(),
                      onChanged: (v) => setState(() => _sortKey = v ?? 'Last Name'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => setState(() => _search = v),
                      ),
                    ),
                  ],
                ),
              ),
              if (students.isEmpty)
                const Expanded(child: Center(child: Text('No students found.')))
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: students.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final s = students[i];
                      return ListTile(
                        title: Text('${s.firstName} ${s.lastName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('ID: ${s.studentId}'),
                        onTap: () {
                          Navigator.push(context,
                          MaterialPageRoute(builder: (_) => StudentDetailScreen(student: s)));
                        },
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Open add student dialog
          showDialog(
            context: context,
            builder: (_) => StudentFormDialog(),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text('New Student'),
      ),
    );
  }
} 
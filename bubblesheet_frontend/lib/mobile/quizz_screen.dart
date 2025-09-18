import 'package:bubblesheet_frontend/mobile/quiz_detail_screen.dart';
import 'package:bubblesheet_frontend/mobile/quiz_form_dialog.dart';
import 'package:bubblesheet_frontend/models/exam_model.dart';
import 'package:bubblesheet_frontend/providers/class_provider.dart';
import 'package:bubblesheet_frontend/providers/exam_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class QuizzesScreen extends StatefulWidget {
  const QuizzesScreen({Key? key}) : super(key: key);

  @override
  State<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen> {
  String _search = '';
  String _sortKey = 'Date';
  final List<String> _sortOptions = ['Date', 'Name'];

  @override
  void initState() {
    super.initState();
    ApiService.setContext(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExamProvider>(context, listen: false).fetchExams(context);
    });
  }

  List<ExamModel> _filterAndSort(List<ExamModel> exams) {
    List<ExamModel> filtered = exams;
    // Search
    if (_search.isNotEmpty) {
      filtered = filtered.where((s) =>
      s.date.toLowerCase().contains(_search.toLowerCase()) ||
          s.name.toLowerCase().contains(_search.toLowerCase())
      ).toList();
    }
    // Sort
    switch (_sortKey) {
      case 'Date':
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'Name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final classProvider = Provider.of<ClassProvider>(context);
    if (classProvider.classes.isEmpty) {
      Future.microtask(() => Provider.of<ClassProvider>(context, listen: false).fetchClasses(context));
    }
    if (classProvider.isLoading || classProvider.classes.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final classCodeToName = {
      for (var c in classProvider.classes) c.class_code: c.class_name
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quizzes'),
        centerTitle: true,
      ),
      body: Consumer<ExamProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text('Error: \\${provider.error}', style: TextStyle(color: Colors.red)));
          }
          final exams = _filterAndSort(provider.exams);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    DropdownButton<String>(
                      value: _sortKey,
                      items: _sortOptions.map((e) => DropdownMenuItem(value: e, child: Text('Sort\n$e'))).toList(),
                      onChanged: (v) => setState(() => _sortKey = v ?? 'Date'),
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
              if (exams.isEmpty)
                const Expanded(child: Center(child: Text('No quizzes found.')))
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: exams.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final s = exams[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                  child: Text('${s.name}', style: const TextStyle(fontWeight: FontWeight.bold))),
                              Text('Papers: ${s.papers?.length ?? 0}', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                            ],
                          ),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(s.class_codes
                                    .map((code) => classCodeToName[code] ?? code)
                                    .join(', '),),
                              ),
                              Text(s.date),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (_) => QuizDetailScreen(quiz: s)));
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
} 
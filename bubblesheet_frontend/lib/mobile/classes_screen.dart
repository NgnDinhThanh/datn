import 'package:bubblesheet_frontend/mobile/class_detail_screen.dart';
import 'package:bubblesheet_frontend/mobile/class_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/class_provider.dart';
import '../models/class_model.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({Key? key}) : super(key: key);

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClassProvider>(context, listen: false).fetchClasses(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classes'),
        centerTitle: true,
      ),
      body: Consumer<ClassProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}', style: TextStyle(color: Colors.red)));
          }
          List<ClassModel> filtered = provider.classes
              .where((c) => c.class_name.toLowerCase().contains(_search.toLowerCase()) ||
                           c.class_code.toLowerCase().contains(_search.toLowerCase()))
              .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Search',
                    border: OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              if (filtered.isEmpty)
                const Expanded(child: Center(child: Text('No classes found.')))
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final c = filtered[i];
                      return ListTile(
                        title: Text(c.class_name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('ID: ${c.class_code} | ${c.student_count} Students | ${c.exam_ids.length} Quizzes'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ClassDetailScreen(classModel: c),
                            ),
                          );
                          if (updated == true && context.mounted) {
                            Provider.of<ClassProvider>(context, listen: false).fetchClasses(context);
                          }
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
          showDialog(
            context: context,
            builder: (_) => const ClassFormDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Class'),
      ),
    );
  }
} 